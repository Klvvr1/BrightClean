using System;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BrightClean.Infrastructure;
using BrightClean.Domain.Entities;
using BrightClean.Domain.Enums;

namespace BrightClean.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class BookingsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public BookingsController(AppDbContext context)
        {
            _context = context;
        }

        // POST: /api/bookings
        [HttpPost]
        public async Task<IActionResult> CreateBooking([FromBody] CreateBookingDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var clientId))
            {
                return Unauthorized();
            }

            if (dto.Items == null || !dto.Items.Any())
            {
                return BadRequest(new { message = "يجب اختيار خدمة واحدة على الأقل." });
            }

            var agent = await _context.LaundryAgents.FindAsync(dto.LaundryAgentID);
            if (agent == null)
            {
                agent = await _context.LaundryAgents.FirstOrDefaultAsync();
                if (agent == null)
                {
                    return BadRequest(new { message = "وكيل الغسيل غير موجود." });
                }
            }

            int addressId = dto.AddressID ?? 0;
            if (addressId == 0)
            {
                var defaultAddress = await _context.Addresses.FirstOrDefaultAsync(a => a.ClientID == clientId);
                if (defaultAddress == null)
                {
                    return BadRequest(new { message = "يجب تسجيل عنوان العميل أولاً لإنشاء الحجز." });
                }
                addressId = defaultAddress.AddressID;
            }

            var booking = new Booking
            {
                ClientID = clientId,
                LaundryAgentID = agent.UserID,
                AddressID = addressId,
                Status = BookingStatus.Draft,
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddDays(1)
            };

            foreach (var itemDto in dto.Items)
            {
                var service = await _context.ServiceCatalogItems.FindAsync(itemDto.ServiceID);
                if (service == null)
                {
                    service = await _context.ServiceCatalogItems.FirstOrDefaultAsync();
                    if (service == null)
                    {
                        return BadRequest(new { message = "الخدمة المطلوبة غير موجودة في النظام." });
                    }
                }

                var bookingItem = new BookingItem
                {
                    ServiceID = service.ServiceID,
                    Quantity = itemDto.Quantity,
                    UnitPriceAtTimeOfBooking = service.Price
                };
                booking.BookingItems.Add(bookingItem);
            }

            _context.Bookings.Add(booking);
            await _context.SaveChangesAsync();

            return Ok(new { bookingID = booking.BookingID });
        }

        // POST: /api/bookings/submit
        [HttpPost("submit")]
        public async Task<IActionResult> SubmitBooking([FromBody] SubmitBookingDto dto)
        {
            var booking = await _context.Bookings
                .Include(b => b.BookingItems)
                    .ThenInclude(bi => bi.ServiceCatalogItem)
                .Include(b => b.Offer)
                .FirstOrDefaultAsync(b => b.BookingID == dto.BookingID);

            if (booking == null)
            {
                return NotFound($"Booking with ID {dto.BookingID} not found.");
            }

            // Verify caller owns the booking
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId) || booking.ClientID != userId)
            {
                return Forbid();
            }

            if (booking.Status != BookingStatus.Draft)
            {
                return BadRequest("Only draft bookings can be submitted.");
            }

            // Calculate subtotal
            decimal total = 0m;
            foreach (var item in booking.BookingItems)
            {
                total += item.SubTotal;
            }

            // Apply offer if valid
            if (booking.Offer != null && booking.Offer.IsValid)
            {
                if (booking.Offer.Type == OfferType.Percentage)
                {
                    total -= total * (booking.Offer.DiscountValue / 100m);
                }
                else if (booking.Offer.Type == OfferType.FixedAmount)
                {
                    total -= booking.Offer.DiscountValue;
                }

                if (total < 0m) total = 0m;
            }

            booking.FinalTotal = total;
            booking.Status = BookingStatus.Pending;

            await _context.SaveChangesAsync();

            return Ok(booking);
        }

        // GET: /api/bookings/agent/{agentId}/pending
        [HttpGet("agent/{agentId}/pending")]
        public async Task<IActionResult> GetPendingBookings(int agentId)
        {
            var bookings = await _context.Bookings
                .Include(b => b.BookingItems)
                    .ThenInclude(bi => bi.ServiceCatalogItem)
                .Where(b => b.LaundryAgentID == agentId && b.Status == BookingStatus.Pending)
                .ToListAsync();

            return Ok(bookings);
        }

        // POST: /api/bookings/{bookingId}/accept
        [HttpPost("{bookingId}/accept")]
        [Authorize(Roles = "LaundryAgent")]
        public async Task<IActionResult> AcceptBooking(int bookingId)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var booking = await _context.Bookings
                    .Include(b => b.BookingItems)
                        .ThenInclude(bi => bi.ServiceCatalogItem)
                    .FirstOrDefaultAsync(b => b.BookingID == bookingId);

                if (booking == null)
                {
                    return NotFound($"Booking with ID {bookingId} not found.");
                }

                // Verify caller is the Laundry Agent assigned to the booking
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
                if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId) || booking.LaundryAgentID != agentId)
                {
                    return Forbid();
                }

                // Check store status
                var agent = await _context.LaundryAgents.FindAsync(agentId);
                if (agent != null && agent.IsStoreClosed)
                {
                    return StatusCode(StatusCodes.Status403Forbidden, new { message = "المغسلة مغلقة حالياً. لا يمكن قبول الطلبات." });
                }

                if (booking.Status != BookingStatus.Pending)
                {
                    return BadRequest("Only pending bookings can be accepted.");
                }

                booking.Status = BookingStatus.Accepted;

                // Save status change first
                await _context.SaveChangesAsync();

                // Check if any items belong to a TwoStage delivery model
                bool isTwoStage = booking.BookingItems.Any(bi => bi.ServiceCatalogItem.DeliveryModel == DeliveryModel.TwoStage);

                if (isTwoStage)
                {
                    var laundryAgent = await _context.LaundryAgents.FindAsync(booking.LaundryAgentID);
                    if (laundryAgent == null)
                    {
                        return BadRequest("Laundry Agent associated with booking does not exist.");
                    }

                    // Add Pickup Task (Stage 1)
                    var pickupTask = new DeliveryTask
                    {
                        BookingID = booking.BookingID,
                        StageNumber = 1,
                        Type = TaskType.PickupFromClient,
                        Status = DeliveryTaskStatus.Unassigned,
                        PickupAddressID = booking.AddressID,      // From Client Address
                        DropoffAddressID = laundryAgent.AddressID, // To Laundry Agent Address
                        DeliveryFee = 1.500m                      // Simulated flat rate
                    };

                    // Add Delivery Task (Stage 2)
                    var deliveryTask = new DeliveryTask
                    {
                        BookingID = booking.BookingID,
                        StageNumber = 2,
                        Type = TaskType.DeliveryToClient,
                        Status = DeliveryTaskStatus.Unassigned,
                        PickupAddressID = laundryAgent.AddressID, // From Laundry Agent Address
                        DropoffAddressID = booking.AddressID,      // To Client Address
                        DeliveryFee = 1.500m                      // Simulated flat rate
                    };

                    _context.DeliveryTasks.AddRange(pickupTask, deliveryTask);
                    await _context.SaveChangesAsync();
                }

                await transaction.CommitAsync();
                return Ok(booking);
            }
            catch (DbUpdateConcurrencyException)
            {
                await transaction.RollbackAsync();
                return Conflict("The booking was modified by another process. Please retry.");
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        // POST: /api/bookings/{bookingId}/ready
        [HttpPost("{bookingId}/ready")]
        [Authorize(Roles = "LaundryAgent")]
        public async Task<IActionResult> MarkBookingReady(int bookingId)
        {
            var booking = await _context.Bookings.FindAsync(bookingId);

            if (booking == null)
            {
                return NotFound($"Booking with ID {bookingId} not found.");
            }

            // Verify caller is the Laundry Agent assigned to the booking
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId) || booking.LaundryAgentID != agentId)
            {
                return Forbid();
            }

            // Check store status
            var agent = await _context.LaundryAgents.FindAsync(agentId);
            if (agent != null && agent.IsStoreClosed)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { message = "المغسلة مغلقة حالياً. لا يمكن معالجة الطلبات." });
            }

            if (booking.Status != BookingStatus.InProgress && booking.Status != BookingStatus.Accepted)
            {
                return BadRequest("Booking must be Accepted or InProgress to be marked as Ready.");
            }

            booking.Status = BookingStatus.Ready;
            await _context.SaveChangesAsync();

            return Ok(booking);
        }

        // POST: /api/bookings/toggle-store-status
        [HttpPost("toggle-store-status")]
        [Authorize(Roles = "LaundryAgent")]
        public async Task<IActionResult> ToggleStoreStatus()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId))
            {
                return Unauthorized();
            }

            var agent = await _context.LaundryAgents.FindAsync(agentId);
            if (agent == null)
            {
                return NotFound(new { message = "وكيل الغسيل غير موجود." });
            }

            agent.IsStoreClosed = !agent.IsStoreClosed;
            await _context.SaveChangesAsync();

            return Ok(new { isStoreClosed = agent.IsStoreClosed, message = agent.IsStoreClosed ? "تم إغلاق المغسلة بنجاح." : "تم فتح المغسلة بنجاح." });
        }

        // GET: /api/bookings/store-status
        [HttpGet("store-status")]
        [Authorize(Roles = "LaundryAgent")]
        public async Task<IActionResult> GetStoreStatus()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId))
            {
                return Unauthorized();
            }

            var agent = await _context.LaundryAgents.FindAsync(agentId);
            if (agent == null)
            {
                return NotFound(new { message = "وكيل الغسيل غير موجود." });
            }

            return Ok(new { isStoreClosed = agent.IsStoreClosed });
        }
    }

    public class SubmitBookingDto
    {
        public int BookingID { get; set; }
    }

    public class CreateBookingDto
    {
        public int LaundryAgentID { get; set; }
        public System.Collections.Generic.List<CreateBookingItemDto> Items { get; set; } = new();
        public int? AddressID { get; set; }
    }

    public class CreateBookingItemDto
    {
        public int ServiceID { get; set; }
        public int Quantity { get; set; }
    }
}
