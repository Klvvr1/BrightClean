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

        // GET: /api/users/me
        [HttpGet("me")]
        public async Task<IActionResult> GetCurrentUser()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
            {
                return Unauthorized();
            }

            var user = await _context.Users
                .AsNoTracking()
                .Where(u => u.UserID == userId)
                .Select(u => new
                {
                    userId = u.UserID,
                    firstName = u.FirstName,
                    lastName = u.LastName,
                    email = u.Email,
                    phoneNo = u.PhoneNo,
                    role = u.Role.ToString(),
                    accountStatus = u.AccountStatus.ToString(),
                    isApproved = u.IsApproved,
                    documents = u.Documents.Select(d => new
                    {
                        d.DocumentID,
                        d.Type,
                        d.FileURL,
                        d.OriginalFileName,
                        d.ContentType,
                        d.FileSizeBytes,
                        d.ReviewStatus,
                        d.ReviewedAt,
                        d.ReviewNotes
                    })
                })
                .FirstOrDefaultAsync();

            if (user == null)
            {
                return NotFound(new { message = "User was not found." });
            }

            if (User.IsInRole("LaundryAgent"))
            {
                var agent = await _context.LaundryAgents
                    .AsNoTracking()
                    .Where(a => a.UserID == userId)
                    .Select(a => new
                    {
                        businessName = a.BusinessName,
                        commercialRegister = a.CommercialRegister,
                        nationalIDNumber = a.NationalIDNumber,
                        isStoreClosed = a.IsStoreClosed,
                        addressID = a.AddressID,
                        services = a.SubscribedServices
                            .Where(s => s.IsActive)
                            .Select(s => new
                            {
                                s.ServiceID,
                                s.ServiceCatalogItem.ServiceName,
                                s.ServiceCatalogItem.Category,
                                s.ServiceCatalogItem.Type,
                                s.ServiceCatalogItem.Price
                            })
                    })
                    .FirstOrDefaultAsync();

                return Ok(new { profile = user, agent });
            }

            if (User.IsInRole("DeliveryStaff"))
            {
                var driver = await _context.DeliveryStaffs
                    .AsNoTracking()
                    .Where(d => d.UserID == userId)
                    .Select(d => new
                    {
                        d.NationalIDNumber,
                        d.VehicleType,
                        d.VehicleMake,
                        d.VehicleModel,
                        d.PlateNumber
                    })
                    .FirstOrDefaultAsync();

                return Ok(new { profile = user, driver });
            }

            return Ok(new { profile = user });
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
        public async Task<IActionResult> GetApprovedAgents([FromQuery] List<int>? serviceIds)
        {
            // Validate that if serviceIds are provided, none are non-positive
            if (serviceIds != null && serviceIds.Any(id => id <= 0))
            {
                return BadRequest(new { message = "All service IDs must be positive integers." });
            }

            var agents = await _context.LaundryAgents
                .AsNoTracking()
                .Where(a => a.IsApproved && a.AccountStatus == AccountStatus.Active && !a.IsStoreClosed)
                .Include(a => a.Address)
                .Include(a => a.SubscribedServices)
                    .ThenInclude(s => s.ServiceCatalogItem)
                .ToListAsync();

            var agentIds = agents.Select(a => a.UserID).ToList();
            var ratings = await _context.BookingRatings
                .AsNoTracking()
                .Where(r => agentIds.Contains(r.Booking.LaundryAgentID) && r.AgentRating.HasValue)
                .Include(r => r.Booking)
                    .ThenInclude(b => b.Client)
                .ToListAsync();

            var requiredServiceIds = serviceIds?
                .Distinct()
                .ToList() ?? new List<int>();

            var response = agents.Select(a =>
            {
                var agentRatings = ratings
                    .Where(r => r.Booking.LaundryAgentID == a.UserID)
                    .ToList();
                var activeServices = a.SubscribedServices
                    .Where(s => s.IsActive && s.ServiceCatalogItem != null && s.ServiceCatalogItem.IsAvailable)
                    .ToList();
                var agentServiceIds = activeServices
                    .Select(s => s.ServiceID)
                    .ToList();

                return new
                {
                    id = a.UserID,
                    businessName = a.BusinessName,
                    address = a.Address == null ? null : new
                    {
                        a.Address.AddressID,
                        a.Address.Area,
                        a.Address.Street,
                        a.Address.Latitude,
                        a.Address.Longitude
                    },
                    isStoreClosed = a.IsStoreClosed,
                    serviceIds = agentServiceIds,
                    serviceCount = agentServiceIds.Count,
                    services = activeServices
                        .Select(s => new
                        {
                            s.ServiceCatalogItem.ServiceID,
                            s.ServiceCatalogItem.ServiceName,
                            s.ServiceCatalogItem.Category,
                            s.ServiceCatalogItem.Type,
                            s.ServiceCatalogItem.Price,
                            s.ServiceCatalogItem.PricingModel,
                            s.ServiceCatalogItem.DeliveryModel
                        })
                        .ToList(),
                    averageRating = agentRatings.Count == 0
                        ? 0
                        : agentRatings.Average(r => r.AgentRating!.Value),
                    reviewCount = agentRatings.Count,
                    recentReviews = agentRatings
                        .OrderByDescending(r => r.RatedAt)
                        .Take(3)
                        .Select(r => new
                        {
                            userName = $"{r.Booking.Client.FirstName} {r.Booking.Client.LastName}".Trim(),
                            rating = r.AgentRating,
                            comment = r.AgentComment,
                            ratedAt = r.RatedAt
                        })
                        .ToList()
                };
            })
            .Where(a => requiredServiceIds.Count == 0 ||
                        requiredServiceIds.All(id => a.serviceIds.Contains(id)))
            .ToList();

            return Ok(response);
        }

        // GET: /api/users/agents/{agentId}
        [HttpGet("agents/{agentId}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetAgentDetails(int agentId)
        {
            var agent = await _context.LaundryAgents
                .Include(a => a.Address)
                .Where(a => a.UserID == agentId &&
                            a.IsApproved &&
                            a.AccountStatus == AccountStatus.Active &&
                            !a.IsStoreClosed)
                .Select(a => new
                {
                    id = a.UserID,
                    businessName = a.BusinessName,
                    firstName = a.FirstName,
                    lastName = a.LastName,
                    phoneNo = a.PhoneNo,
                    address = a.Address == null ? null : new
                    {
                        a.Address.AddressID,
                        a.Address.Area,
                        a.Address.Street,
                        a.Address.Latitude,
                        a.Address.Longitude
                    },
                    isStoreClosed = a.IsStoreClosed,
                    serviceIds = a.SubscribedServices
                        .Where(s => s.IsActive && s.ServiceCatalogItem.IsAvailable)
                        .Select(s => s.ServiceID)
                        .ToList(),
                    serviceCount = a.SubscribedServices
                        .Count(s => s.IsActive && s.ServiceCatalogItem.IsAvailable),
                    averageRating = _context.BookingRatings
                        .Where(r => r.Booking.LaundryAgentID == a.UserID && r.AgentRating.HasValue)
                        .Average(r => (double?)r.AgentRating) ?? 0,
                    reviewCount = _context.BookingRatings
                        .Count(r => r.Booking.LaundryAgentID == a.UserID && r.AgentRating.HasValue),
                    services = a.SubscribedServices
                        .Where(s => s.IsActive && s.ServiceCatalogItem.IsAvailable)
                        .Select(s => new
                        {
                            s.ServiceCatalogItem.ServiceID,
                            s.ServiceCatalogItem.ServiceName,
                            s.ServiceCatalogItem.Category,
                            s.ServiceCatalogItem.Type,
                            s.ServiceCatalogItem.Price,
                            s.ServiceCatalogItem.PricingModel,
                            s.ServiceCatalogItem.DeliveryModel
                        })
                        .ToList(),
                    recentReviews = _context.BookingRatings
                        .Where(r => r.Booking.LaundryAgentID == a.UserID && r.AgentRating.HasValue)
                        .OrderByDescending(r => r.RatedAt)
                        .Take(5)
                        .Select(r => new
                        {
                            userName = r.Booking.Client.FirstName + " " + r.Booking.Client.LastName,
                            rating = r.AgentRating,
                            comment = r.AgentComment,
                            ratedAt = r.RatedAt
                        })
                        .ToList()
                })
                .FirstOrDefaultAsync();

            if (agent == null)
            {
                return NotFound(new { message = "Laundry agent was not found or is not currently available." });
            }

            return Ok(agent);
        }

        // GET: /api/users/agents/{agentId}/ratings-summary
        [HttpGet("agents/{agentId}/ratings-summary")]
        [AllowAnonymous]
        public async Task<IActionResult> GetAgentRatingsSummary(int agentId)
        {
            var agentExists = await _context.LaundryAgents.AnyAsync(a =>
                a.UserID == agentId &&
                a.IsApproved &&
                a.AccountStatus == AccountStatus.Active &&
                !a.IsStoreClosed);

            if (!agentExists)
            {
                return NotFound(new { message = "Laundry agent was not found or is not currently available." });
            }

            var ratings = await _context.BookingRatings
                .Where(r => r.Booking.LaundryAgentID == agentId && r.AgentRating.HasValue)
                .Select(r => r.AgentRating!.Value)
                .ToListAsync();

            return Ok(new
            {
                agentId,
                averageRating = ratings.Count == 0 ? 0 : ratings.Average(),
                reviewCount = ratings.Count,
                fiveStar = ratings.Count(r => r == 5),
                fourStar = ratings.Count(r => r == 4),
                threeStar = ratings.Count(r => r == 3),
                twoStar = ratings.Count(r => r == 2),
                oneStar = ratings.Count(r => r == 1)
            });
        }
    }

    public class UpdateProfileDto
    {
        [Required]
        [RegularExpression(@"^(?=.*\S).+$", ErrorMessage = "First name cannot be empty or contain only whitespace.")]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [RegularExpression(@"^(?=.*\S).+$", ErrorMessage = "Last name cannot be empty or contain only whitespace.")]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [RegularExpression(@"^[0-9]{9}$", ErrorMessage = "Phone number must be exactly 9 digits.")]
        public string PhoneNo { get; set; } = string.Empty;
    }
}
