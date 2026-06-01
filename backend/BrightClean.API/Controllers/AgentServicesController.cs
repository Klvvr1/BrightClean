using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
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
            // Extract AgentID securely from JWT claims — never from the request body
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId))
            {
                return Unauthorized();
            }

            if (dto.ServiceIDs == null || dto.ServiceIDs.Count == 0)
            {
                return BadRequest(new { message = "يجب تحديد خدمة واحدة على الأقل." });
            }

            var addedServices = new List<int>();
            var skippedServices = new List<int>();

            foreach (var serviceId in dto.ServiceIDs)
            {
                // Validate the ServiceCatalogItem exists
                var service = await _context.ServiceCatalogItems.FindAsync(serviceId);
                if (service == null)
                {
                    return BadRequest(new { message = $"الخدمة ذات المعرّف {serviceId} غير موجودة في كتالوج الخدمات." });
                }

                // Check if already subscribed (unique composite index: LaundryAgentID + ServiceID)
                var alreadyExists = await _context.AgentServices
                    .AnyAsync(asvc => asvc.LaundryAgentID == agentId && asvc.ServiceID == serviceId);

                if (alreadyExists)
                {
                    skippedServices.Add(serviceId);
                    continue;
                }

                var agentService = new AgentService
                {
                    LaundryAgentID = agentId,
                    ServiceID = serviceId,
                    IsActive = false,  // Pending admin approval
                    Notes = "Pending activation by admin."
                };

                _context.AgentServices.Add(agentService);
                addedServices.Add(serviceId);
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "تم تقديم طلبات الاشتراك في الخدمات بنجاح. تنتظر موافقة المشرف للتفعيل.",
                addedServiceIds = addedServices,
                skippedServiceIds = skippedServices
            });
        }
    }

    public class AddAgentServicesDto
    {
        public List<int> ServiceIDs { get; set; } = new();
    }
}
