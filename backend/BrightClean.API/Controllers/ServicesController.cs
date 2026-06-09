using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BrightClean.Infrastructure;
using BrightClean.Domain.Entities;
using BrightClean.Domain.Enums;

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
                .Where(s => s.IsAvailable && !s.IsDeleted)
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

        // GET: /api/services/agents/{agentId}
        [HttpGet("agents/{agentId}")]
        public async Task<IActionResult> GetServicesByAgent(int agentId)
        {
            var agent = await _context.LaundryAgents
                .AsNoTracking()
                .FirstOrDefaultAsync(a => a.UserID == agentId);

            if (agent == null)
            {
                return NotFound(new { message = "Laundry agent was not found." });
            }

            if (!agent.IsApproved || agent.AccountStatus != AccountStatus.Active || agent.IsStoreClosed)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { message = "Laundry agent is not currently available." });
            }

            var services = await _context.AgentServices
                .AsNoTracking()
                .Where(s => s.LaundryAgentID == agentId &&
                            s.IsActive &&
                            !s.PendingActivation &&
                            s.ServiceCatalogItem.IsAvailable &&
                            !s.ServiceCatalogItem.IsDeleted)
                .OrderBy(s => s.ServiceCatalogItem.Category)
                .ThenBy(s => s.ServiceCatalogItem.Type)
                .Select(s => new ServiceCatalogItemDto
                {
                    ServiceID = s.ServiceCatalogItem.ServiceID,
                    ServiceName = s.ServiceCatalogItem.ServiceName,
                    Category = (int)s.ServiceCatalogItem.Category,
                    Type = (int)s.ServiceCatalogItem.Type,
                    Price = s.ServiceCatalogItem.Price,
                    PricingModel = (int)s.ServiceCatalogItem.PricingModel,
                    DeliveryModel = (int)s.ServiceCatalogItem.DeliveryModel,
                    IsAvailable = s.ServiceCatalogItem.IsAvailable
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
