using System;
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
    [Authorize(Roles = "Client")]
    public class PaymentsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PaymentsController(AppDbContext context)
        {
            _context = context;
        }

        // POST: /api/payments
        [HttpPost]
        public async Task<IActionResult> CreatePayment([FromBody] CreatePaymentDto dto)
        {
            // Extract ClientID securely from JWT claims — never from the request body
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var clientId))
            {
                return Unauthorized();
            }

            // Validate the Booking exists and belongs to the authenticated client
            var booking = await _context.Bookings
                .Include(b => b.Payment)
                .Include(b => b.BookingItems)
                .FirstOrDefaultAsync(b => b.BookingID == dto.BookingID);

            if (booking == null)
            {
                return NotFound(new { message = $"الحجز ذو المعرّف {dto.BookingID} غير موجود." });
            }

            if (booking.ClientID != clientId)
            {
                return StatusCode(403, new { message = "غير مسموح: هذا الحجز لا ينتمي لحسابك." });
            }

            // Prevent duplicate payments for the same booking (one-to-one constraint)
            if (booking.Payment != null)
            {
                return Conflict(new { message = "تم تسجيل دفعة لهذا الحجز مسبقاً." });
            }

            // Parse payment method (map string to enum)
            if (!Enum.TryParse<PaymentMethod>(dto.Method, ignoreCase: true, out var paymentMethod))
            {
                return BadRequest(new { message = $"طريقة الدفع '{dto.Method}' غير مدعومة. الأساليب المتاحة: CreditCard, Cash, Wallet, BankTransfer." });
            }

            // Validate payment amount against server-side booking total
            decimal bookingTotal = booking.FinalTotal ?? 0m;
            if (Math.Abs(dto.Amount - bookingTotal) > 0.01m) // Allow for minor rounding differences
            {
                return BadRequest(new { message = $"المبلغ المدفوع ({dto.Amount}) لا يطابق المبلغ المستحق ({bookingTotal})." });
            }

            // ARCHITECTURAL RULE: Insert Payment record with its own status.
            // We do NOT update Booking.Status — it is strictly operational.
            var payment = new Payment
            {
                BookingID = dto.BookingID,
                Amount = bookingTotal, // Use server-side amount
                Method = paymentMethod,
                Status = PaymentStatus.Success,
                TransactionRef = dto.TransactionRef,
                PaidAt = DateTime.UtcNow
            };

            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                paymentID = payment.PaymentID,
                bookingID = payment.BookingID,
                status = payment.Status.ToString(),
                paidAt = payment.PaidAt,
                message = "تم تسجيل الدفعة بنجاح."
            });
        }
    }

    public class CreatePaymentDto
    {
        public int BookingID { get; set; }
        public decimal Amount { get; set; }

        /// <summary>
        /// Accepts: "CreditCard", "Cash", "Wallet", or "BankTransfer"
        /// </summary>
        public string Method { get; set; } = "Cash";
        public string? TransactionRef { get; set; }
    }
}
