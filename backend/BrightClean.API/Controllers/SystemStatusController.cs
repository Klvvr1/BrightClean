using System;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BrightClean.Infrastructure;
using BrightClean.Domain.Entities;
using BrightClean.Domain.DTOs;

namespace BrightClean.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SystemStatusController : ControllerBase
    {
        private readonly AppDbContext _context;

        public SystemStatusController(AppDbContext context)
        {
            _context = context;
        }

        // GET: /api/systemstatus/status
        // Anonymous access allowed so the app can check before login
        [HttpGet("status")]
        [AllowAnonymous]
        public async Task<IActionResult> GetStatus()
        {
            var status = await _context.SystemStatuses
                .OrderByDescending(s => s.ChangedAt)
                .FirstOrDefaultAsync();

            if (status == null)
            {
                // Default to true if no record exists
                return Ok(new SystemStatusDto
                {
                    LoginEnabled = true,
                    Message = null,
                    ChangedAt = DateTime.UtcNow
                });
            }

            return Ok(new SystemStatusDto
            {
                LoginEnabled = status.LoginEnabled,
                Message = status.Message,
                ChangedAt = status.ChangedAt
            });
        }

        // POST: /api/systemstatus/toggle
        // Only Admin can toggle maintenance mode
        [HttpPost("toggle")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> ToggleStatus([FromBody] SystemStatusUpdateDto dto)
        {
            var adminIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (adminIdClaim == null || !int.TryParse(adminIdClaim.Value, out var adminId))
            {
                return Unauthorized(new { message = "فشلت عملية التحقق من هوية المسؤول." });
            }

            var newStatus = new SystemStatus
            {
                LoginEnabled = dto.LoginEnabled,
                Message = dto.Message,
                ChangedAt = DateTime.UtcNow,
                AdminID = adminId
            };

            _context.SystemStatuses.Add(newStatus);
            
            // Optionally: keep only the latest status to avoid table bloat over time
            // Or just let it act as a history log. We'll leave it as a log.

            await _context.SaveChangesAsync();

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId,
                Action = "TOGGLE_MAINTENANCE",
                TargetEntity = "SystemStatus",
                TargetID = newStatus.StatusID,
                Details = dto.LoginEnabled
                    ? "Maintenance mode was disabled."
                    : "Maintenance mode was enabled.",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new SystemStatusDto
            {
                LoginEnabled = newStatus.LoginEnabled,
                Message = newStatus.Message,
                ChangedAt = newStatus.ChangedAt
            });
        }
    }
}
