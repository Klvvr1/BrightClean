using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BrightClean.Infrastructure;
using BrightClean.Domain.Enums;

namespace BrightClean.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class OffersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public OffersController(AppDbContext context)
        {
            _context = context;
        }

        // POST: /api/offers/validate
        // CRIT-007: Replaces client-side static coupon list with server-side validation.
        [HttpPost("validate")]
        public async Task<IActionResult> ValidateOffer([FromBody] ValidateOfferDto dto)
        {
            if (dto == null || string.IsNullOrWhiteSpace(dto.Code))
            {
                return BadRequest(new { message = "كود الكوبون مطلوب." });
            }

            // Resolve the calling client's ID from JWT
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var clientId))
            {
                return Unauthorized();
            }

            // Look up the offer by code (case-insensitive)
            var normalizedCode = dto.Code.Trim().ToUpper();
            var offer = await _context.Offers
                .FirstOrDefaultAsync(o => o.OfferCode.ToUpper() == normalizedCode);

            if (offer == null || !offer.IsValid)
            {
                return BadRequest(new { message = "كود الكوبون غير صحيح أو منتهي الصلاحية" });
            }

            // Load booking and verify ownership
            var booking = await _context.Bookings
                .Include(b => b.BookingItems)
                    .ThenInclude(bi => bi.ServiceCatalogItem)
                .FirstOrDefaultAsync(b => b.BookingID == dto.BookingId);

            if (booking == null)
            {
                return NotFound(new { message = "الحجز غير موجود" });
            }

            if (booking.ClientID != clientId)
            {
                return Forbid();
            }

            // Only allow offer modification on draft bookings
            if (booking.Status != BookingStatus.Draft)
            {
                return BadRequest(new { message = "لا يمكن تعديل الكوبون على حجز غير مسودة" });
            }

            if (offer.Scope == OfferScope.SpecificAgent && offer.LaundryAgentID != booking.LaundryAgentID)
            {
                return BadRequest(new { message = "هذا الكوبون غير متاح للمغسلة المختارة" });
            }

            // Compute order subtotal
            decimal subtotal = booking.BookingItems.Sum(bi => bi.SubTotal);

            // Check minimum order value
            if (offer.MinOrderValue.HasValue && subtotal < offer.MinOrderValue.Value)
            {
                return BadRequest(new
                {
                    message = $"هذا العرض يتطلب طلبًا بقيمة لا تقل عن {offer.MinOrderValue.Value:F0} ريال. المبلغ الحالي هو {subtotal:F0} ريال."
                });
            }

            // Calculate discount amount
            decimal discountAmount;
            string displayText;
            if (offer.Type == OfferType.Percentage)
            {
                discountAmount = subtotal * (offer.DiscountValue / 100m);
                displayText = $"خصم {offer.DiscountValue}%";
            }
            else // FixedAmount
            {
                discountAmount = offer.DiscountValue;
                displayText = $"خصم {offer.DiscountValue:F0} ريال";
            }

            if (discountAmount > subtotal) discountAmount = subtotal;

            // Link offer to booking
            booking.OfferID = offer.OfferID;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                isValid = true,
                discountAmount = (double)discountAmount,
                offerType = offer.Type.ToString(),
                displayText = displayText
            });
        }

        // POST: /api/offers/remove
        // CRIT-007: Lets the user remove a previously applied coupon from their active booking.
        [HttpPost("remove")]
        public async Task<IActionResult> RemoveOffer([FromBody] RemoveOfferDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var clientId))
            {
                return Unauthorized();
            }

            var booking = await _context.Bookings
                .FirstOrDefaultAsync(b => b.BookingID == dto.BookingId);

            if (booking == null)
            {
                return NotFound(new { message = "الحجز غير موجود" });
            }

            if (booking.ClientID != clientId)
            {
                return Forbid();
            }

            // Only allow offer modification on draft bookings
            if (booking.Status != BookingStatus.Draft)
            {
                return BadRequest(new { message = "لا يمكن تعديل الكوبون على حجز غير مسودة" });
            }

            booking.OfferID = null;
            await _context.SaveChangesAsync();

            return Ok(new { message = "تم إلغاء الكوبون بنجاح" });
        }
    }

    public class ValidateOfferDto
    {
        public string Code { get; set; } = string.Empty;
        public int BookingId { get; set; }
    }

    public class RemoveOfferDto
    {
        public int BookingId { get; set; }
    }
}
