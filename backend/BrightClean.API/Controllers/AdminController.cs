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
    [Authorize(Roles = "Admin")]
    public class AdminController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AdminController(AppDbContext context)
        {
            _context = context;
        }

        // GET: /api/admin/pending-approvals
        [HttpGet("pending-approvals")]
        public async Task<IActionResult> GetPendingApprovals()
        {
            var pendingUsers = await _context.Users
                .Where(u => !u.IsApproved && (u.Role == UserRole.LaundryAgent || u.Role == UserRole.DeliveryStaff))
                .Select(u => new
                {
                    u.UserID,
                    u.FirstName,
                    u.LastName,
                    u.Email,
                    u.PhoneNo,
                    u.Role,
                    u.CreatedAt,
                    Documents = u.Documents.Select(d => new
                    {
                        d.DocumentID,
                        d.Type,
                        d.FileURL,
                        d.OriginalFileName,
                        d.ContentType,
                        d.FileSizeBytes,
                        d.UploadedAt,
                        d.ReviewStatus
                    })
                })
                .ToListAsync();

            return Ok(pendingUsers);
        }

        // POST: /api/admin/approve/{userId}
        [HttpPost("approve/{userId}")]
        public async Task<IActionResult> ApproveUser(int userId)
        {
            var adminIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (adminIdClaim == null || !int.TryParse(adminIdClaim.Value, out var adminId))
            {
                return Unauthorized(new { message = "فشلت عملية التحقق من هوية المسؤول." });
            }

            var user = await _context.Users
                .Include(u => u.Documents)
                .FirstOrDefaultAsync(u => u.UserID == userId);

            if (user == null)
            {
                return NotFound(new { message = $"مستخدم بالمعرف {userId} غير موجود." });
            }

            if (user.IsApproved)
            {
                return BadRequest(new { message = "الحساب مفعل بالفعل." });
            }

            // CRIT-006: Only LaundryAgent and DeliveryStaff accounts require admin approval
            if (user.Role != UserRole.LaundryAgent && user.Role != UserRole.DeliveryStaff)
            {
                return BadRequest(new { message = "لا يمكن تفعيل هذا النوع من الحسابات من هنا." });
            }

            user.IsApproved = true;
            user.AccountStatus = AccountStatus.Active;
            user.VerifiedAt = DateTime.UtcNow;

            foreach (var document in user.Documents)
            {
                document.ReviewStatus = DocumentReviewStatus.Approved;
                document.ReviewedAt = DateTime.UtcNow;
                document.ReviewedByAdminID = adminId;
                document.ReviewNotes = "Approved as part of account approval.";
            }

            // Generate AuditLog entry
            string action = user.Role == UserRole.LaundryAgent ? "ACTIVATE_AGENT" : "ACTIVATE_DRIVER";
            var auditLog = new AuditLog
            {
                AdminID = adminId,
                Action = action,
                TargetEntity = "User",
                TargetID = user.UserID,
                Details = $"Approved {user.Role} account and {user.Documents.Count} attached document(s).",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = DateTime.UtcNow
            };
            _context.AuditLogs.Add(auditLog);

            await _context.SaveChangesAsync();

            return Ok(new { message = "تم تفعيل الحساب بنجاح.", userId = user.UserID, isApproved = user.IsApproved });
        }

        // GET: /api/admin/payments/pending-review
        [HttpGet("payments/pending-review")]
        public async Task<IActionResult> GetPaymentsPendingReview()
        {
            var payments = await _context.Payments
                .Include(p => p.Booking)
                    .ThenInclude(b => b.Client)
                .Where(p => p.Status == PaymentStatus.Pending || p.Status == PaymentStatus.PendingReview)
                .OrderBy(p => p.CreatedAt)
                .Select(p => new
                {
                    p.PaymentID,
                    p.BookingID,
                    p.Amount,
                    p.Method,
                    p.Status,
                    p.TransactionRef,
                    p.PaymentProofURL,
                    p.StatusReason,
                    p.CreatedAt,
                    Client = new
                    {
                        p.Booking.Client.UserID,
                        p.Booking.Client.FirstName,
                        p.Booking.Client.LastName,
                        p.Booking.Client.PhoneNo
                    }
                })
                .ToListAsync();

            return Ok(payments);
        }

        // POST: /api/admin/payments/{paymentId}/confirm
        [HttpPost("payments/{paymentId}/confirm")]
        public async Task<IActionResult> ConfirmPayment(int paymentId, [FromBody] PaymentReviewDto dto)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = "فشلت عملية التحقق من هوية المسؤول." });
            }

            var payment = await _context.Payments.FirstOrDefaultAsync(p => p.PaymentID == paymentId);
            if (payment == null)
            {
                return NotFound(new { message = $"Payment {paymentId} was not found." });
            }

            if (payment.Status != PaymentStatus.Pending && payment.Status != PaymentStatus.PendingReview)
            {
                return BadRequest(new { message = "Only pending payments can be confirmed." });
            }

            var now = DateTime.UtcNow;
            payment.Status = payment.Method == PaymentMethod.Cash
                ? PaymentStatus.Collected
                : PaymentStatus.Success;
            payment.PaidAt = now;
            payment.ReviewedAt = now;
            payment.ReviewedByAdminID = adminId.Value;
            payment.StatusReason = string.IsNullOrWhiteSpace(dto.Reason)
                ? "Payment confirmed by admin."
                : dto.Reason.Trim();

            if (!string.IsNullOrWhiteSpace(dto.TransactionRef))
            {
                payment.TransactionRef = dto.TransactionRef.Trim();
            }

            if (!string.IsNullOrWhiteSpace(dto.PaymentProofURL))
            {
                payment.PaymentProofURL = dto.PaymentProofURL.Trim();
            }

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = "CONFIRM_PAYMENT",
                TargetEntity = "Payment",
                TargetID = payment.PaymentID,
                Details = $"Confirmed {payment.Method} payment for booking {payment.BookingID} with status {payment.Status}.",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = now
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                payment.PaymentID,
                payment.BookingID,
                payment.Amount,
                method = payment.Method.ToString(),
                status = payment.Status.ToString(),
                payment.PaidAt,
                payment.ReviewedAt,
                payment.StatusReason
            });
        }

        // POST: /api/admin/payments/{paymentId}/fail
        [HttpPost("payments/{paymentId}/fail")]
        public async Task<IActionResult> FailPayment(int paymentId, [FromBody] PaymentReviewDto dto)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = "فشلت عملية التحقق من هوية المسؤول." });
            }

            var payment = await _context.Payments.FirstOrDefaultAsync(p => p.PaymentID == paymentId);
            if (payment == null)
            {
                return NotFound(new { message = $"Payment {paymentId} was not found." });
            }

            if (payment.Status != PaymentStatus.Pending && payment.Status != PaymentStatus.PendingReview)
            {
                return BadRequest(new { message = "Only pending payments can be rejected." });
            }

            var now = DateTime.UtcNow;
            payment.Status = PaymentStatus.Failed;
            payment.PaidAt = null;
            payment.ReviewedAt = now;
            payment.ReviewedByAdminID = adminId.Value;
            payment.StatusReason = string.IsNullOrWhiteSpace(dto.Reason)
                ? "Payment rejected by admin."
                : dto.Reason.Trim();

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = "REJECT_PAYMENT",
                TargetEntity = "Payment",
                TargetID = payment.PaymentID,
                Details = $"Rejected {payment.Method} payment for booking {payment.BookingID}. Reason: {payment.StatusReason}",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = now
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                payment.PaymentID,
                payment.BookingID,
                payment.Amount,
                method = payment.Method.ToString(),
                status = payment.Status.ToString(),
                payment.ReviewedAt,
                payment.StatusReason
            });
        }

        // GET: /api/admin/staff
        [HttpGet("staff")]
        public async Task<IActionResult> GetApprovedStaff()
        {
            var staff = await _context.Users
                .Where(u => u.IsApproved && (u.Role == UserRole.LaundryAgent || u.Role == UserRole.DeliveryStaff))
                .Select(u => new
                {
                    u.UserID,
                    u.FirstName,
                    u.LastName,
                    u.Email,
                    u.PhoneNo,
                    u.Role,
                    u.CreatedAt
                })
                .ToListAsync();

            return Ok(staff);
        }

        // GET: /api/admin/audit-logs
        [HttpGet("audit-logs")]
        public async Task<IActionResult> GetAuditLogs(int page = 1, int pageSize = 50)
        {
            const int maxPageSize = 200;
            pageSize = pageSize > maxPageSize ? maxPageSize : pageSize;

            var baseQuery = _context.AuditLogs
                .Include(al => al.Admin)
                .OrderByDescending(al => al.PerformedAt);

            var totalCount = await baseQuery.CountAsync();

            var logs = await baseQuery
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(al => new
                {
                    al.LogID,
                    al.AdminID,
                    AdminName = al.Admin.FirstName + " " + al.Admin.LastName,
                    al.Action,
                    al.TargetEntity,
                    al.TargetID,
                    al.Details,
                    al.IpAddress,
                    al.PerformedAt
                })
                .ToListAsync();

            return Ok(new
            {
                data = logs,
                currentPage = page,
                pageSize = pageSize,
                totalCount = totalCount
            });
        }

        private int? GetAdminId()
        {
            var adminIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            return adminIdClaim != null && int.TryParse(adminIdClaim.Value, out var adminId)
                ? adminId
                : null;
        }
    }

    public class PaymentReviewDto
    {
        public string? Reason { get; set; }
        public string? TransactionRef { get; set; }
        public string? PaymentProofURL { get; set; }
    }
}
