using System;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using BrightClean.Infrastructure;
using BrightClean.Domain.Entities;

namespace BrightClean.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Client")]
    public class AddressesController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ILogger<AddressesController> _logger;

        public AddressesController(AppDbContext context, ILogger<AddressesController> logger)
        {
            _context = context;
            _logger = logger;
        }

        // GET: /api/addresses
        [HttpGet]
        public async Task<IActionResult> GetMyAddresses()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var clientId))
            {
                return Unauthorized();
            }

            var addresses = await _context.Addresses
                .AsNoTracking()
                .Where(address => address.ClientID == clientId && !address.IsArchived)
                .OrderByDescending(address => address.AddressID)
                .Select(address => new
                {
                    address.AddressID,
                    address.Area,
                    address.Street,
                    address.Latitude,
                    address.Longitude
                })
                .ToListAsync();

            _logger.LogInformation("Loaded {AddressCount} addresses for client {ClientId}.", addresses.Count, clientId);

            return Ok(addresses);
        }

        // POST: /api/addresses
        [HttpPost]
        public async Task<IActionResult> CreateAddress([FromBody] CreateAddressDto dto)
        {
            // Extract ClientID securely from JWT claims — never from the request body
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var clientId))
            {
                return Unauthorized();
            }

            if (string.IsNullOrWhiteSpace(dto.Area) || string.IsNullOrWhiteSpace(dto.Street))
            {
                return BadRequest(new { message = "Address area and street are required." });
            }

            if (dto.Latitude == 0m && dto.Longitude == 0m)
            {
                return BadRequest(new { message = "A valid delivery address location is required." });
            }

            var address = new Address
            {
                ClientID = clientId,
                Area = dto.Area,
                Street = dto.Street,
                Latitude = dto.Latitude,
                Longitude = dto.Longitude,
                IsArchived = false
            };

            _context.Addresses.Add(address);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Created address {AddressId} for client {ClientId}.", address.AddressID, clientId);

            return Ok(new
            {
                addressID = address.AddressID,
                area = address.Area,
                street = address.Street,
                latitude = address.Latitude,
                longitude = address.Longitude,
                message = "تم إضافة العنوان بنجاح."
            });
        }

        // DELETE: /api/addresses/{addressId}
        [HttpDelete("{addressId}")]
        public async Task<IActionResult> DeleteAddress(int addressId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var clientId))
            {
                return Unauthorized();
            }

            var address = await _context.Addresses
                .FirstOrDefaultAsync(item => item.AddressID == addressId && item.ClientID == clientId && !item.IsArchived);

            if (address == null)
            {
                return NotFound(new { message = "Address was not found." });
            }

            address.IsArchived = true;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Archived address {AddressId} for client {ClientId}.", addressId, clientId);

            return NoContent();
        }
    }

    public class CreateAddressDto
    {
        public string Area { get; set; } = string.Empty;
        public string Street { get; set; } = string.Empty;
        public decimal Latitude { get; set; }
        public decimal Longitude { get; set; }
    }
}
