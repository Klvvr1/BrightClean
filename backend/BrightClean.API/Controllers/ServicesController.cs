using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BrightClean.Infrastructure;
using BrightClean.Domain.Entities;

namespace BrightClean.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [AllowAnonymous]
    public class ServicesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ServicesController(AppDbContext context)
        {
            _context = context;
        }

        // GET: /api/services
        [HttpGet]
        public async Task<IActionResult> GetServices()
        {
            var services = await _context.ServiceCatalogItems
                .Where(s => s.IsAvailable)
                .Select(s => new ServiceCatalogItemDto
                {
                    ServiceID = s.ServiceID,
                    ServiceName = s.ServiceName,
                    Category = (int)s.Category,
                    Type = (int)s.Type,
                    Price = s.Price,
                    PricingModel = (int)s.PricingModel,
                    DeliveryModel = (int)s.DeliveryModel,
                    IsAvailable = s.IsAvailable
                })
                .ToListAsync();

            return Ok(services);
        }
    }

    public class ServiceCatalogItemDto
    {
        public int ServiceID { get; set; }
        public string ServiceName { get; set; } = string.Empty;
        public int Category { get; set; }
        public int Type { get; set; }
        public decimal Price { get; set; }
        public int PricingModel { get; set; }
        public int DeliveryModel { get; set; }
        public bool IsAvailable { get; set; }
    }
}
