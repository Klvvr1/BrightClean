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
                    u.CreatedAt
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

            var user = await _context.Users.FirstOrDefaultAsync(u => u.UserID == userId);

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
                return BadRequest(new { message = "لا يمكن تفعيل this type of accounts from here." });
            }

            user.IsApproved = true;
            user.AccountStatus = AccountStatus.Active;

            // Generate AuditLog entry
            string action = user.Role == UserRole.LaundryAgent ? "ACTIVATE_AGENT" : "ACTIVATE_DRIVER";
            var auditLog = new AuditLog
            {
                AdminID = adminId,
                Action = action,
                TargetEntity = "User",
                TargetID = user.UserID,
                PerformedAt = DateTime.UtcNow
            };
            _context.AuditLogs.Add(auditLog);

            await _context.SaveChangesAsync();

            return Ok(new { message = "تم تفعيل الحساب بنجاح.", userId = user.UserID, isApproved = user.IsApproved });
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
        public async Task<IActionResult> GetAuditLogs()
        {
            var logs = await _context.AuditLogs
                .Include(al => al.Admin)
                .OrderByDescending(al => al.PerformedAt)
                .Select(al => new
                {
                    al.LogID,
                    al.AdminID,
                    AdminName = al.Admin.FirstName + " " + al.Admin.LastName,
                    al.Action,
                    al.TargetEntity,
                    al.TargetID,
                    al.PerformedAt
                })
                .ToListAsync();

            return Ok(logs);
        }
    }
}
