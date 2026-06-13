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
        private readonly IWebHostEnvironment _environment;

        public PaymentsController(AppDbContext context, IWebHostEnvironment environment)
        {
            _context = context;
            _environment = environment;
        }

        // POST: /api/payments/upload-receipt
        [HttpPost("upload-receipt")]
        public async Task<IActionResult> UploadReceipt([FromForm] int bookingID, [FromForm] IFormFile receipt)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var clientId))
            {
                return Unauthorized();
            }

            if (receipt == null || receipt.Length == 0)
            {
                return BadRequest(new { message = "Receipt file is required." });
            }

            var extension = Path.GetExtension(receipt.FileName).ToLowerInvariant();
            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".pdf" };
            if (!allowedExtensions.Contains(extension))
            {
                return BadRequest(new { message = "Only JPG, PNG, and PDF receipt files are allowed." });
            }

            var bookingExists = await _context.Bookings.AnyAsync(b =>
                b.BookingID == bookingID && b.ClientID == clientId);
            if (!bookingExists)
            {
                return NotFound(new { message = $"Booking {bookingID} was not found." });
            }

            var uploadDir = Path.Combine(_environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"), "payment-receipts");
            Directory.CreateDirectory(uploadDir);

            var fileName = $"{bookingID}_{Guid.NewGuid():N}{extension}";
            var filePath = Path.Combine(uploadDir, fileName);
            await using (var stream = System.IO.File.Create(filePath))
            {
                await receipt.CopyToAsync(stream);
            }

            var proofUrl = $"/payment-receipts/{fileName}";
            return Ok(new { proofUrl });
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

            var paymentStatus = paymentMethod switch
            {
                PaymentMethod.Cash => PaymentStatus.Pending,
                PaymentMethod.BankTransfer => PaymentStatus.PendingReview,
                _ => PaymentStatus.Success
            };

            var statusReason = paymentMethod switch
            {
                PaymentMethod.Cash => "Awaiting cash collection confirmation.",
                PaymentMethod.BankTransfer => "Awaiting bank transfer review.",
                _ => "Payment confirmed automatically."
            };

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
                PaymentProofURL = dto.PaymentProofURL,
                StatusReason = statusReason,
                CreatedAt = DateTime.UtcNow,
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
                statusReason = payment.StatusReason,
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
        public string? PaymentProofURL { get; set; }
    }
}
