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
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var clientId))
            {
                return Unauthorized();
            }

            if (!Enum.TryParse<PaymentMethod>(dto.Method, ignoreCase: true, out var paymentMethod))
            {
                return BadRequest(new { message = $"Payment method '{dto.Method}' is not supported." });
            }

            // Validate that the parsed enum value is defined (reject numeric strings for undefined members)
            if (!Enum.IsDefined(typeof(PaymentMethod), paymentMethod))
            {
                return BadRequest(new { message = $"Payment method '{dto.Method}' is not a valid payment method." });
            }

            using var transaction = await _context.Database.BeginTransactionAsync();

            var booking = await _context.Bookings
                .Include(b => b.Payment)
                .Include(b => b.Client)
                .Include(b => b.BookingItems)
                .FirstOrDefaultAsync(b => b.BookingID == dto.BookingID);

            if (booking == null)
            {
                return NotFound(new { message = $"Booking {dto.BookingID} was not found." });
            }

            if (booking.ClientID != clientId)
            {
                return StatusCode(403, new { message = "This booking does not belong to the authenticated client." });
            }

            if (booking.Payment != null)
            {
                return Conflict(new { message = "A payment already exists for this booking." });
            }

            if (booking.Status != BookingStatus.Pending)
            {
                return BadRequest(new { message = "Only pending bookings can be paid." });
            }

            if (!booking.FinalTotal.HasValue)
            {
                return BadRequest(new { message = "Booking total has not been calculated. Submit the booking before payment." });
            }

            var bookingTotal = booking.FinalTotal.Value;
            if (Math.Abs(dto.Amount - bookingTotal) > 0.01m)
            {
                return BadRequest(new { message = $"Paid amount ({dto.Amount}) does not match booking total ({bookingTotal})." });
            }

            var paymentStatus = paymentMethod == PaymentMethod.Cash || paymentMethod == PaymentMethod.BankTransfer
                ? PaymentStatus.Pending
                : PaymentStatus.Success;

            if (paymentMethod == PaymentMethod.Wallet)
            {
                if (booking.Client.WalletBalance < bookingTotal)
                {
                    return BadRequest(new { message = "Insufficient wallet balance." });
                }

                booking.Client.WalletBalance -= bookingTotal;
            }

            var payment = new Payment
            {
                BookingID = dto.BookingID,
                Amount = bookingTotal,
                Method = paymentMethod,
                Status = paymentStatus,
                TransactionRef = dto.TransactionRef,
                PaidAt = paymentStatus == PaymentStatus.Success ? DateTime.UtcNow : null
            };

            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            return Ok(new
            {
                paymentID = payment.PaymentID,
                bookingID = payment.BookingID,
                amount = payment.Amount,
                method = payment.Method.ToString(),
                status = payment.Status.ToString(),
                paidAt = payment.PaidAt,
                walletBalance = paymentMethod == PaymentMethod.Wallet ? booking.Client.WalletBalance : (decimal?)null,
                message = payment.Status == PaymentStatus.Success
                    ? "Payment recorded successfully."
                    : "Payment was recorded and is pending confirmation."
            });
        }
    }

    public class CreatePaymentDto
    {
        public int BookingID { get; set; }
        public decimal Amount { get; set; }
        public string Method { get; set; } = "Cash";
        public string? TransactionRef { get; set; }
    }
}
