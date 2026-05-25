using System.Linq;
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
            var user = await _context.Users.FirstOrDefaultAsync(u => u.UserID == userId);

            if (user == null)
            {
                return NotFound(new { message = $"مستخدم بالمعرف {userId} غير موجود." });
            }

            if (user.IsApproved)
            {
                return BadRequest(new { message = "الحساب مفعل بالفعل." });
            }

            user.IsApproved = true;
            user.AccountStatus = AccountStatus.Active;

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
    }
}
