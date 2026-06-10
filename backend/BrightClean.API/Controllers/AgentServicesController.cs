using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
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
        private readonly ILogger<AgentServicesController> _logger;

        public AgentServicesController(AppDbContext context, ILogger<AgentServicesController> logger)
        {
            _context = context;
            _logger = logger;
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

            var addedServices = new List<int>();
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
                    if (!existingService.IsActive && !existingService.PendingActivation)
                    {
                        existingService.PendingActivation = true;
                        existingService.RequestedAction = AgentServiceRequestedAction.Activate;
                        existingService.Notes = "Agent requested activation.";
                        addedServices.Add(serviceId);
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
                    IsActive = false,
                    PendingActivation = true,
                    RequestedAction = AgentServiceRequestedAction.Activate,
                    ActivatedAt = null,
                    Notes = "Pending activation by admin."
                });

                addedServices.Add(serviceId);
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Service subscription requests were submitted and are waiting for admin approval.",
                addedServiceIds = addedServices,
                activatedServiceIds = Array.Empty<int>(),
                skippedServiceIds = skippedServices
            });
        }

        // POST: /api/agents/services/{serviceId}/request
        [HttpPost("/api/agents/services/{serviceId}/request")]
        public async Task<IActionResult> RequestServiceActivation(int serviceId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId))
            {
                return Unauthorized();
            }

            var agent = await _context.LaundryAgents
                .FirstOrDefaultAsync(a => a.UserID == agentId);
            if (agent == null)
            {
                return NotFound(new { message = "Laundry agent was not found." });
            }

            if (!agent.IsApproved || agent.AccountStatus != AccountStatus.Active)
            {
                return BadRequest(new { message = "Only approved active laundry agents can request service changes." });
            }

            var service = await _context.ServiceCatalogItems
                .FirstOrDefaultAsync(s => s.ServiceID == serviceId);
            if (service == null)
            {
                return NotFound(new { message = $"Service {serviceId} was not found." });
            }

            if (!service.IsAvailable || service.IsDeleted)
            {
                return BadRequest(new { message = $"Service {serviceId} is not available for activation." });
            }

            var agentService = await _context.AgentServices
                .FirstOrDefaultAsync(asvc => asvc.LaundryAgentID == agentId && asvc.ServiceID == serviceId);

            if (agentService != null && agentService.PendingActivation)
            {
                return Conflict(new { message = "A service activation request is already pending for this service." });
            }

            var requestedAction = "Activate";

            if (agentService == null)
            {
                agentService = new AgentService
                {
                    LaundryAgentID = agentId,
                    ServiceID = serviceId,
                    IsActive = false,
                    PendingActivation = true,
                    RequestedAction = AgentServiceRequestedAction.Activate,
                    Notes = "Agent requested activation."
                };
                _context.AgentServices.Add(agentService);
            }
            else if (agentService.IsActive)
            {
                requestedAction = "Deactivate";
                agentService.PendingActivation = true;
                agentService.RequestedAction = AgentServiceRequestedAction.Deactivate;
                agentService.Notes = "Agent requested deactivation.";
            }
            else
            {
                agentService.PendingActivation = true;
                agentService.RequestedAction = AgentServiceRequestedAction.Activate;
                agentService.Notes = "Agent requested activation.";
            }

            await _context.SaveChangesAsync();

            _logger.LogInformation(
                "Laundry agent {AgentId} requested {RequestedAction} for service {ServiceId}.",
                agentId,
                requestedAction,
                serviceId);

            return Ok(new
            {
                agentId,
                serviceId,
                requestedAction,
                agentService.IsActive,
                agentService.PendingActivation
            });
        }
    }

    public class AddAgentServicesDto
    {
        public List<int> ServiceIDs { get; set; } = new();
    }
}
