using System;
using System.Collections.Generic;
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
    [Authorize(Roles = "LaundryAgent")]
    public class AgentServicesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AgentServicesController(AppDbContext context)
        {
            _context = context;
        }

        // POST: /api/agentservices
        [HttpPost]
        public async Task<IActionResult> AddAgentServices([FromBody] AddAgentServicesDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId))
            {
                return Unauthorized();
            }

            if (dto.ServiceIDs == null || dto.ServiceIDs.Count == 0)
            {
                return BadRequest(new { message = "At least one service must be selected." });
            }

            var agent = await _context.LaundryAgents
                .FirstOrDefaultAsync(a => a.UserID == agentId);
            if (agent == null)
            {
                return NotFound(new { message = "Laundry agent was not found." });
            }

            var activateImmediately = agent.IsApproved &&
                agent.AccountStatus == AccountStatus.Active;

            var addedServices = new List<int>();
            var activatedServices = new List<int>();
            var skippedServices = new List<int>();

            foreach (var serviceId in dto.ServiceIDs)
            {
                var service = await _context.ServiceCatalogItems.FindAsync(serviceId);
                if (service == null)
                {
                    return BadRequest(new { message = $"Service {serviceId} was not found in the catalog." });
                }

                if (!service.IsAvailable || service.IsDeleted)
                {
                    return BadRequest(new { message = $"Service {serviceId} is not available for assignment." });
                }

                var existingService = await _context.AgentServices
                    .FirstOrDefaultAsync(asvc => asvc.LaundryAgentID == agentId && asvc.ServiceID == serviceId);

                if (existingService != null)
                {
                    if (activateImmediately && !existingService.IsActive)
                    {
                        existingService.IsActive = true;
                        existingService.PendingActivation = false;
                        existingService.ActivatedAt = DateTime.UtcNow;
                        existingService.Notes = "Activated because the agent account is already approved.";
                        activatedServices.Add(serviceId);
                    }
                    else
                    {
                        skippedServices.Add(serviceId);
                    }

                    continue;
                }

                _context.AgentServices.Add(new AgentService
                {
                    LaundryAgentID = agentId,
                    ServiceID = serviceId,
                    IsActive = activateImmediately,
                    PendingActivation = !activateImmediately,
                    ActivatedAt = activateImmediately ? DateTime.UtcNow : null,
                    Notes = activateImmediately
                        ? "Activated because the agent account is already approved."
                        : "Pending activation by admin."
                });

                addedServices.Add(serviceId);
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = activateImmediately
                    ? "Services were saved and activated."
                    : "Service subscription requests were submitted and are waiting for admin approval.",
                addedServiceIds = addedServices,
                activatedServiceIds = activatedServices,
                skippedServiceIds = skippedServices
            });
        }
    }

    public class AddAgentServicesDto
    {
        public List<int> ServiceIDs { get; set; } = new();
    }
}
