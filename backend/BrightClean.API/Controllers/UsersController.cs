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
using System.ComponentModel.DataAnnotations;

namespace BrightClean.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public UsersController(AppDbContext context)
        {
            _context = context;
        }

        // PUT: /api/users/profile
        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
            {
                return Unauthorized();
            }

            var user = await _context.Users.FirstOrDefaultAsync(u => u.UserID == userId);
            if (user == null)
            {
                return NotFound(new { message = "المستخدم غير موجود." });
            }

            // Update user properties
            user.FirstName = dto.FirstName;
            user.LastName = dto.LastName;
            user.PhoneNo = dto.PhoneNo;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                userId = user.UserID,
                firstName = user.FirstName,
                lastName = user.LastName,
                email = user.Email,
                phoneNo = user.PhoneNo,
                role = user.Role.ToString()
            });
        }

        // GET: /api/users/agents
        // CRIT-009: Returns all active, approved laundry agents so the cart screen
        // can let the user choose an agent dynamically instead of using a hardcoded ID.
        [HttpGet("agents")]
        [AllowAnonymous] // Allow guests/clients to load agents before logging in or during checkout
        public async Task<IActionResult> GetApprovedAgents()
        {
            var agents = await _context.LaundryAgents
                .Where(a => a.IsApproved && a.AccountStatus == AccountStatus.Active && !a.IsStoreClosed)
                .Select(a => new
                {
                    id = a.UserID,
                    businessName = a.BusinessName
                })
                .ToListAsync();

            return Ok(agents);
        }
    }

    public class UpdateProfileDto
    {
        [Required]
        [MinLength(1, ErrorMessage = "First name cannot be empty or whitespace.")]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MinLength(1, ErrorMessage = "Last name cannot be empty or whitespace.")]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [RegularExpression(@"^[0-9]{9}$", ErrorMessage = "Phone number must be exactly 9 digits.")]
        public string PhoneNo { get; set; } = string.Empty;
    }
}
