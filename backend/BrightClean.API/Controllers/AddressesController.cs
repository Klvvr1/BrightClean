using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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

        public AddressesController(AppDbContext context)
        {
            _context = context;
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

            return Ok(new
            {
                addressID = address.AddressID,
                message = "تم إضافة العنوان بنجاح."
            });
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
