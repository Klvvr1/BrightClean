using System;
using System.Collections.Generic;
using System.Linq;
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
    [Authorize(Roles = "Admin")]
    public class AdminController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ILogger<AdminController> _logger;
        private static readonly string UnauthorizedAdminMessage = "فشلت عملية التحقق من هوية المسؤول.";

        public AdminController(AppDbContext context, ILogger<AdminController> logger)
        {
            _context = context;
            _logger = logger;
        }

        // GET: /api/admin/recent-orders
        [HttpGet("recent-orders")]
        public async Task<IActionResult> GetRecentOrders()
        {
            var orders = await _context.Bookings
                .AsNoTracking()
                .Include(b => b.Client)
                .Include(b => b.LaundryAgent)
                .Include(b => b.BookingItems)
                .Where(b => b.Status != BookingStatus.Draft)
                .OrderByDescending(b => b.CreatedAt)
                .Take(5)
                .Select(b => new
                {
                    b.BookingID,
                    b.Status,
                    b.FinalTotal,
                    b.CreatedAt,
                    ClientName = (b.Client.FirstName + " " + b.Client.LastName).Trim(),
                    LaundryName = b.LaundryAgent.BusinessName,
                    ItemCount = b.BookingItems.Count
                })
                .ToListAsync();

            _logger.LogInformation("Loaded {OrderCount} recent orders for admin dashboard.", orders.Count);

            return Ok(orders);
        }

        // GET: /api/admin/summary
        [HttpGet("summary")]
        public async Task<IActionResult> GetSummary()
        {
            var summary = new AdminSummaryDto
            {
                CustomersCount = await _context.Users.CountAsync(u => u.Role == UserRole.Client),
                LaundryAgentsCount = await _context.Users.CountAsync(u => u.Role == UserRole.LaundryAgent && u.IsApproved),
                DriversCount = await _context.Users.CountAsync(u => u.Role == UserRole.DeliveryStaff && u.IsApproved),
                TotalOrders = await _context.Bookings.CountAsync(b => b.Status != BookingStatus.Draft),
                PendingOrders = await _context.Bookings.CountAsync(b => b.Status == BookingStatus.Pending),
                CompletedOrders = await _context.Bookings.CountAsync(b => b.Status == BookingStatus.Completed),
                TotalRevenue = await _context.Payments
                    .Where(p => p.Status == PaymentStatus.Success || p.Status == PaymentStatus.Collected)
                    .SumAsync(p => (decimal?)p.Amount) ?? 0
            };

            _logger.LogInformation("Loaded admin dashboard summary metrics.");

            return Ok(summary);
        }

        // POST: /api/admin/notifications
        [HttpPost("notifications")]
        public async Task<IActionResult> SendNotification([FromBody] AdminNotificationCreateDto dto)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = UnauthorizedAdminMessage });
            }

            if (string.IsNullOrWhiteSpace(dto.Title) || string.IsNullOrWhiteSpace(dto.Message))
            {
                return BadRequest(new { message = "Notification title and message are required." });
            }

            if (dto.Title.Trim().Length > 200)
            {
                return BadRequest(new { message = "Notification title cannot exceed 200 characters." });
            }

            if (dto.Message.Trim().Length > 1000)
            {
                return BadRequest(new { message = "Notification message cannot exceed 1000 characters." });
            }

            if (!TryParseNotificationTargetRole(dto.TargetRole, out var targetRole))
            {
                return BadRequest(new { message = "Invalid notification target role." });
            }

            var targetUserIds = await _context.Users
                .Where(u => u.Role == targetRole && u.IsApproved)
                .Select(u => u.UserID)
                .ToListAsync();

            var trimmedTitle = dto.Title.Trim();
            var trimmedMessage = dto.Message.Trim();

            var now = DateTime.UtcNow;
            foreach (var userId in targetUserIds)
            {
                _context.Notifications.Add(new Notification
                {
                    UserID = userId,
                    Title = trimmedTitle,
                    Message = trimmedMessage,
                    Date = now
                });
            }

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = "SEND_NOTIFICATION",
                TargetEntity = "Notification",
                TargetID = 0,
                Details = $"Sent notification to {targetRole}. Recipient count: {targetUserIds.Count}.",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = now
            });

            await _context.SaveChangesAsync();

            _logger.LogInformation("Admin {AdminId} sent notification to {TargetRole}. Recipients: {RecipientCount}.", adminId.Value, targetRole, targetUserIds.Count);

            return Ok(new
            {
                message = "Notification sent successfully.",
                targetRole = targetRole.ToString(),
                recipientCount = targetUserIds.Count
            });
        }

        // GET: /api/admin/notifications
        [HttpGet("notifications")]
        public async Task<IActionResult> GetNotificationHistory()
        {
            var notifications = await _context.Notifications
                .AsNoTracking()
                .GroupBy(n => new { n.Title, n.Message, n.Date })
                .OrderByDescending(g => g.Key.Date)
                .Take(50)
                .Select(g => new
                {
                    title = g.Key.Title,
                    message = g.Key.Message,
                    date = g.Key.Date,
                    recipientCount = g.Count()
                })
                .ToListAsync();

            return Ok(notifications);
        }

        // GET: /api/admin/offers
        [HttpGet("offers")]
        public async Task<IActionResult> GetOffers()
        {
            var now = DateTime.UtcNow;
            var offers = await _context.Offers
                .AsNoTracking()
                .Include(o => o.ScopedAgent)
                .OrderByDescending(o => o.StartDate)
                .Select(o => new
                {
                    o.OfferID,
                    o.OfferCode,
                    Type = o.Type.ToString(),
                    Scope = o.Scope.ToString(),
                    o.DiscountValue,
                    o.StartDate,
                    o.EndDate,
                    o.MinOrderValue,
                    o.MaxUsageCount,
                    o.UsageCount,
                    o.LaundryAgentID,
                    LaundryAgentName = o.ScopedAgent != null ? o.ScopedAgent.BusinessName : null,
                    IsValid = now >= o.StartDate &&
                        now <= o.EndDate &&
                        (!o.MaxUsageCount.HasValue || o.UsageCount < o.MaxUsageCount.Value)
                })
                .ToListAsync();

            return Ok(offers);
        }

        // POST: /api/admin/offers
        [HttpPost("offers")]
        public async Task<IActionResult> CreateOffer([FromBody] AdminOfferCreateDto dto)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = UnauthorizedAdminMessage });
            }

            var validation = await ValidateOfferCreateDto(dto);
            if (validation != null)
            {
                return validation;
            }

            var offerCode = dto.OfferCode.Trim().ToUpperInvariant();
            var existingCode = await _context.Offers.AnyAsync(o => o.OfferCode.ToUpper() == offerCode);
            if (existingCode)
            {
                return Conflict(new { message = "Offer code already exists." });
            }

            var offer = new Offer
            {
                OfferCode = offerCode,
                Type = dto.Type,
                Scope = dto.Scope,
                DiscountValue = dto.DiscountValue,
                StartDate = dto.StartDate,
                EndDate = dto.EndDate,
                MinOrderValue = dto.MinOrderValue,
                MaxUsageCount = dto.MaxUsageCount,
                LaundryAgentID = dto.Scope == OfferScope.SpecificAgent ? dto.LaundryAgentID : null,
                AdminID = adminId.Value
            };

            _context.Offers.Add(offer);

            if (dto.SendNotificationToClients)
            {
                var clientIds = await _context.Users
                    .Where(u => u.Role == UserRole.Client && u.IsApproved)
                    .Select(u => u.UserID)
                    .ToListAsync();

                var now = DateTime.UtcNow;
                var discountText = dto.Type == OfferType.Percentage
                    ? $"{dto.DiscountValue:0}%"
                    : $"{dto.DiscountValue:0} ريال";
                var message = $"عرض جديد متاح: استخدم الكود {offerCode} للحصول على خصم {discountText} حتى {dto.EndDate:yyyy-MM-dd}.";

                const string notificationTitle = "عرض جديد متاح";
                if (notificationTitle.Length > 200)
                {
                    return BadRequest(new { message = "Notification title too long." });
                }
                if (message.Length > 1000)
                {
                    return BadRequest(new { message = "Notification message too long." });
                }

                foreach (var clientId in clientIds)
                {
                    _context.Notifications.Add(new Notification
                    {
                        UserID = clientId,
                        Title = notificationTitle,
                        Message = message,
                        Date = now
                    });
                }

                _logger.LogInformation("Offer {OfferCode} will notify {RecipientCount} clients.", offerCode, clientIds.Count);
            }

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = "CREATE_OFFER",
                TargetEntity = "Offer",
                TargetID = 0,
                Details = $"Created offer {offerCode}. Scope: {dto.Scope}.",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            _logger.LogInformation("Admin {AdminId} created offer {OfferCode}.", adminId.Value, offerCode);

            return Ok(new
            {
                offer.OfferID,
                offer.OfferCode,
                Type = offer.Type.ToString(),
                Scope = offer.Scope.ToString(),
                offer.DiscountValue,
                offer.StartDate,
                offer.EndDate,
                offer.MinOrderValue,
                offer.MaxUsageCount,
                offer.UsageCount,
                offer.LaundryAgentID,
                IsValid = offer.IsValid
            });
        }

        // DELETE: /api/admin/offers/{offerId}
        [HttpDelete("offers/{offerId}")]
        public async Task<IActionResult> DeleteOffer(int offerId)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = UnauthorizedAdminMessage });
            }

            var offer = await _context.Offers.FirstOrDefaultAsync(o => o.OfferID == offerId);
            if (offer == null)
            {
                return NotFound(new { message = "Offer was not found." });
            }

            var hasBookings = await _context.Bookings.AnyAsync(b => b.OfferID == offerId);
            var now = DateTime.UtcNow;
            var deletionType = "HardDeleted";
            if (hasBookings)
            {
                offer.EndDate = now.AddSeconds(-1);
                deletionType = "Expired";
            }
            else
            {
                _context.Offers.Remove(offer);
            }

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = hasBookings ? "EXPIRE_OFFER" : "DELETE_OFFER",
                TargetEntity = "Offer",
                TargetID = offerId,
                Details = $"{deletionType} offer {offer.OfferCode}.",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = now
            });

            await _context.SaveChangesAsync();

            _logger.LogInformation("Admin {AdminId} removed offer {OfferId} with mode {DeletionType}.", adminId.Value, offerId, deletionType);

            return Ok(new { offerId, deletionType });
        }

        // GET: /api/admin/pending-approvals
        [HttpGet("pending-approvals")]
        public async Task<IActionResult> GetPendingApprovals()
        {
            var pendingUsers = await _context.Users
                .Where(u => !u.IsApproved
                    && u.AccountStatus == AccountStatus.PendingVerification
                    && (u.Role == UserRole.LaundryAgent || u.Role == UserRole.DeliveryStaff))
                .Select(u => new
                {
                    u.UserID,
                    u.FirstName,
                    u.LastName,
                    u.Email,
                    u.PhoneNo,
                    u.Role,
                    u.CreatedAt,
                    BusinessName = _context.LaundryAgents
                        .Where(a => a.UserID == u.UserID)
                        .Select(a => a.BusinessName)
                        .FirstOrDefault(),
                    CommercialRegister = _context.LaundryAgents
                        .Where(a => a.UserID == u.UserID)
                        .Select(a => a.CommercialRegister)
                        .FirstOrDefault(),
                    NationalIDNumber = _context.LaundryAgents
                        .Where(a => a.UserID == u.UserID)
                        .Select(a => a.NationalIDNumber)
                        .FirstOrDefault() ?? _context.DeliveryStaffs
                        .Where(d => d.UserID == u.UserID)
                        .Select(d => d.NationalIDNumber)
                        .FirstOrDefault(),
                    VehicleType = _context.DeliveryStaffs
                        .Where(d => d.UserID == u.UserID)
                        .Select(d => (VehicleType?)d.VehicleType)
                        .FirstOrDefault(),
                    PlateNumber = _context.DeliveryStaffs
                        .Where(d => d.UserID == u.UserID)
                        .Select(d => d.PlateNumber)
                        .FirstOrDefault(),
                    RequestedServices = _context.AgentServices
                        .Where(service => service.LaundryAgentID == u.UserID && service.PendingActivation)
                        .OrderBy(service => service.ServiceCatalogItem.ServiceName)
                        .Select(service => new
                        {
                            service.ServiceID,
                            service.ServiceCatalogItem.ServiceName
                        })
                        .ToList(),
                    Documents = u.Documents.Select(d => new
                    {
                        d.DocumentID,
                        d.Type,
                        d.FileURL,
                        d.OriginalFileName,
                        d.ContentType,
                        d.FileSizeBytes,
                        d.UploadedAt,
                        d.ReviewStatus
                    })
                })
                .ToListAsync();

            _logger.LogInformation("Loaded {PendingApprovalCount} pending approvals with requested laundry services.", pendingUsers.Count);

            return Ok(pendingUsers);
        }

        // POST: /api/admin/approve/{userId}
        [HttpPost("approve/{userId}")]
        public async Task<IActionResult> ApproveUser(int userId)
        {
            var adminIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (adminIdClaim == null || !int.TryParse(adminIdClaim.Value, out var adminId))
            {
                return Unauthorized(new { message = "فشلت عملية التحقق من هوية المسؤول." });
            }

            var user = await _context.Users
                .Include(u => u.Documents)
                .FirstOrDefaultAsync(u => u.UserID == userId);

            if (user == null)
            {
                return NotFound(new { message = $"مستخدم بالمعرف {userId} غير موجود." });
            }

            if (user.IsApproved)
            {
                return BadRequest(new { message = "الحساب مفعل بالفعل." });
            }

            // CRIT-006: Only LaundryAgent and DeliveryStaff accounts require admin approval
            if (user.Role != UserRole.LaundryAgent && user.Role != UserRole.DeliveryStaff)
            {
                return BadRequest(new { message = "لا يمكن تفعيل هذا النوع من الحسابات من هنا." });
            }

            user.IsApproved = true;
            user.AccountStatus = AccountStatus.Active;
            user.VerifiedAt = DateTime.UtcNow;

            foreach (var document in user.Documents)
            {
                document.ReviewStatus = DocumentReviewStatus.Approved;
                document.ReviewedAt = DateTime.UtcNow;
                document.ReviewedByAdminID = adminId;
                document.ReviewNotes = "Approved as part of account approval.";
            }

            if (user.Role == UserRole.LaundryAgent)
            {
                var pendingAgentServices = await _context.AgentServices
                    .Where(service => service.LaundryAgentID == user.UserID && !service.IsActive && service.PendingActivation)
                    .ToListAsync();

                foreach (var service in pendingAgentServices)
                {
                    service.IsActive = true;
                    service.PendingActivation = false;
                    service.RequestedAction = AgentServiceRequestedAction.None;
                    service.ActivatedAt = DateTime.UtcNow;
                    service.Notes = "Activated as part of account approval.";
                }
            }

            // Generate AuditLog entry
            string action = user.Role == UserRole.LaundryAgent ? "ACTIVATE_AGENT" : "ACTIVATE_DRIVER";
            var auditLog = new AuditLog
            {
                AdminID = adminId,
                Action = action,
                TargetEntity = "User",
                TargetID = user.UserID,
                Details = $"Approved {user.Role} account and {user.Documents.Count} attached document(s).",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = DateTime.UtcNow
            };
            _context.AuditLogs.Add(auditLog);

            await _context.SaveChangesAsync();

            return Ok(new { message = "تم تفعيل الحساب بنجاح.", userId = user.UserID, isApproved = user.IsApproved });
        }

        // POST: /api/admin/reject/{userId}
        [HttpPost("reject/{userId}")]
        public async Task<IActionResult> RejectUser(int userId)
        {
            var adminIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (adminIdClaim == null || !int.TryParse(adminIdClaim.Value, out var adminId))
            {
                return Unauthorized(new { message = UnauthorizedAdminMessage });
            }

            var user = await _context.Users
                .Include(u => u.Documents)
                .FirstOrDefaultAsync(u => u.UserID == userId);

            if (user == null)
            {
                return NotFound(new { message = $"مستخدم بالمعرف {userId} غير موجود." });
            }

            if (user.IsApproved)
            {
                return BadRequest(new { message = "لا يمكن رفض حساب مفعل بالفعل." });
            }

            if (user.Role != UserRole.LaundryAgent && user.Role != UserRole.DeliveryStaff)
            {
                return BadRequest(new { message = "لا يمكن رفض هذا النوع من الحسابات من هنا." });
            }

            if (user.AccountStatus == AccountStatus.Deactivated)
            {
                return BadRequest(new { message = "تم رفض هذا الحساب مسبقاً." });
            }

            user.IsApproved = false;
            user.AccountStatus = AccountStatus.Deactivated;
            user.VerifiedAt = null;

            foreach (var document in user.Documents)
            {
                document.ReviewStatus = DocumentReviewStatus.Rejected;
                document.ReviewedAt = DateTime.UtcNow;
                document.ReviewedByAdminID = adminId;
                document.ReviewNotes = "Rejected as part of account registration review.";
            }

            if (user.Role == UserRole.LaundryAgent)
            {
                var pendingAgentServices = await _context.AgentServices
                    .Where(service => service.LaundryAgentID == user.UserID && service.PendingActivation)
                    .ToListAsync();

                foreach (var service in pendingAgentServices)
                {
                    service.IsActive = false;
                    service.PendingActivation = false;
                    service.RequestedAction = AgentServiceRequestedAction.None;
                    service.Notes = "Rejected as part of account registration review.";
                }
            }

            string action = user.Role == UserRole.LaundryAgent ? "REJECT_AGENT" : "REJECT_DRIVER";
            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId,
                Action = action,
                TargetEntity = "User",
                TargetID = user.UserID,
                Details = $"Rejected {user.Role} account and {user.Documents.Count} attached document(s).",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new { message = "تم رفض الحساب بنجاح.", userId = user.UserID, accountStatus = user.AccountStatus.ToString() });
        }

        // POST: /api/admin/agents/{agentId}/services
        [HttpPost("agents/{agentId}/services")]
        public async Task<IActionResult> SetAgentServices(int agentId, [FromBody] SetAgentServicesDto dto)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = UnauthorizedAdminMessage });
            }

            var agent = await _context.LaundryAgents
                .FirstOrDefaultAsync(a => a.UserID == agentId);

            if (agent == null)
            {
                return NotFound(new { message = "Laundry agent was not found." });
            }

            if (dto.ServiceIDs == null)
            {
                ModelState.AddModelError("ServiceIDs", "ServiceIDs is required");
                return BadRequest(ModelState);
            }

            var requestedServiceIds = dto.ServiceIDs
                .Where(id => id > 0)
                .Distinct()
                .ToList();

            if (requestedServiceIds.Count == 0)
            {
                return BadRequest(new { message = "At least one service ID must be selected." });
            }

            var validServiceIds = await _context.ServiceCatalogItems
                .Where(service => requestedServiceIds.Contains(service.ServiceID) && service.IsAvailable && !service.IsDeleted)
                .Select(service => service.ServiceID)
                .ToListAsync();

            var invalidServiceIds = requestedServiceIds.Except(validServiceIds).ToList();
            if (invalidServiceIds.Count > 0)
            {
                return BadRequest(new
                {
                    message = "One or more services do not exist or are unavailable.",
                    invalidServiceIds
                });
            }

            var existingServices = await _context.AgentServices
                .Where(service => service.LaundryAgentID == agentId)
                .ToListAsync();

            foreach (var existing in existingServices)
            {
                existing.IsActive = requestedServiceIds.Contains(existing.ServiceID);
                existing.PendingActivation = false;
                existing.RequestedAction = AgentServiceRequestedAction.None;
                existing.ActivatedAt = existing.IsActive ? DateTime.UtcNow : existing.ActivatedAt;
                existing.Notes = existing.IsActive
                    ? "Activated by admin service assignment."
                    : "Deactivated by admin service assignment.";
            }

            var existingServiceIds = existingServices.Select(service => service.ServiceID).ToHashSet();
            foreach (var serviceId in requestedServiceIds.Where(id => !existingServiceIds.Contains(id)))
            {
                _context.AgentServices.Add(new AgentService
                {
                    LaundryAgentID = agentId,
                    ServiceID = serviceId,
                    IsActive = true,
                    PendingActivation = false,
                    RequestedAction = AgentServiceRequestedAction.None,
                    ActivatedAt = DateTime.UtcNow,
                    Notes = "Assigned by admin."
                });
            }

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = "UPDATE_AGENT_SERVICES",
                TargetEntity = "LaundryAgent",
                TargetID = agentId,
                Details = $"Updated laundry agent services. Active service IDs: {string.Join(",", requestedServiceIds)}.",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                agentId,
                activeServiceIds = requestedServiceIds
            });
        }

        // GET: /api/admin/service-activation-requests
        [HttpGet("service-activation-requests")]
        public async Task<IActionResult> GetServiceActivationRequests()
        {
            var requests = await _context.AgentServices
                .AsNoTracking()
                .Include(service => service.LaundryAgent)
                .Include(service => service.ServiceCatalogItem)
                .Where(service => service.PendingActivation)
                .OrderBy(service => service.LaundryAgent.BusinessName)
                .ThenBy(service => service.ServiceCatalogItem.ServiceName)
                .ToListAsync();

            _logger.LogInformation("Loaded {RequestCount} service activation requests for admin.", requests.Count);

            return Ok(requests.Select(service => new
            {
                service.AgentServiceID,
                AgentID = service.LaundryAgentID,
                BusinessName = service.LaundryAgent.BusinessName,
                service.ServiceID,
                ServiceName = service.ServiceCatalogItem.ServiceName,
                RequestedAction = service.RequestedAction,
                service.IsActive,
                service.PendingActivation,
                service.Notes
            }));
        }

        // POST: /api/admin/agents/{agentId}/services/{serviceId}/approve
        [HttpPost("agents/{agentId}/services/{serviceId}/approve")]
        public async Task<IActionResult> ApproveAgentServiceRequest(int agentId, int serviceId)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = UnauthorizedAdminMessage });
            }

            var agentService = await _context.AgentServices
                .Include(service => service.ServiceCatalogItem)
                .FirstOrDefaultAsync(service => service.LaundryAgentID == agentId && service.ServiceID == serviceId);

            if (agentService == null)
            {
                return NotFound(new { message = "Agent service request was not found." });
            }

            if (!agentService.PendingActivation)
            {
                return BadRequest(new { message = "There is no pending request for this agent service." });
            }

            var requestedAction = agentService.RequestedAction;

            if (requestedAction == AgentServiceRequestedAction.Activate)
            {
                if (agentService.ServiceCatalogItem == null ||
                    !agentService.ServiceCatalogItem.IsAvailable ||
                    agentService.ServiceCatalogItem.IsDeleted)
                {
                    return BadRequest(new { message = "This service is not available for activation." });
                }

                agentService.IsActive = true;
                agentService.ActivatedAt = DateTime.UtcNow;
                agentService.Notes = "Activation approved by admin.";
            }
            else if (requestedAction == AgentServiceRequestedAction.Deactivate)
            {
                agentService.IsActive = false;
                agentService.Notes = "Deactivation approved by admin.";
            }
            else
            {
                return BadRequest(new { message = "Pending request action is missing." });
            }

            agentService.PendingActivation = false;
            agentService.RequestedAction = AgentServiceRequestedAction.None;

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = requestedAction == AgentServiceRequestedAction.Activate ? "APPROVE_AGENT_SERVICE_ACTIVATION" : "APPROVE_AGENT_SERVICE_DEACTIVATION",
                TargetEntity = "AgentService",
                TargetID = agentService.AgentServiceID,
                Details = $"Approved {requestedAction.ToString().ToLower()} request for agent {agentId} and service {serviceId}.",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                agentId,
                serviceId,
                requestedAction = requestedAction.ToString(),
                agentService.IsActive,
                agentService.PendingActivation,
                message = "Service request was approved."
            });
        }

        // POST: /api/admin/agents/{agentId}/services/{serviceId}/reject
        [HttpPost("agents/{agentId}/services/{serviceId}/reject")]
        public async Task<IActionResult> RejectAgentServiceRequest(int agentId, int serviceId)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = UnauthorizedAdminMessage });
            }

            var agentService = await _context.AgentServices
                .FirstOrDefaultAsync(service => service.LaundryAgentID == agentId && service.ServiceID == serviceId);

            if (agentService == null)
            {
                return NotFound(new { message = "Agent service request was not found." });
            }

            if (!agentService.PendingActivation)
            {
                return BadRequest(new { message = "There is no pending request for this agent service." });
            }

            var requestedAction = agentService.RequestedAction;

            if (requestedAction == AgentServiceRequestedAction.Activate)
            {
                agentService.Notes = "Activation request rejected by admin.";
            }
            else if (requestedAction == AgentServiceRequestedAction.Deactivate)
            {
                agentService.Notes = "Deactivation request rejected by admin.";
            }
            else
            {
                return BadRequest(new { message = "Pending request action is invalid or missing." });
            }

            agentService.PendingActivation = false;
            agentService.RequestedAction = AgentServiceRequestedAction.None;

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = requestedAction == AgentServiceRequestedAction.Activate ? "REJECT_AGENT_SERVICE_ACTIVATION" : "REJECT_AGENT_SERVICE_DEACTIVATION",
                TargetEntity = "AgentService",
                TargetID = agentService.AgentServiceID,
                Details = $"Rejected {requestedAction.ToString().ToLower()} request for agent {agentId} and service {serviceId}.",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                agentId,
                serviceId,
                requestedAction = requestedAction.ToString(),
                agentService.IsActive,
                agentService.PendingActivation,
                message = "Service request was rejected."
            });
        }

        // GET: /api/admin/services
        [HttpGet("services")]
        public async Task<IActionResult> GetServices()
        {
            var services = await _context.ServiceCatalogItems
                .OrderBy(service => service.Category)
                .ThenBy(service => service.Type)
                .ThenBy(service => service.ServiceName)
                .Select(service => new AdminServiceCatalogItemDto
                {
                    ServiceID = service.ServiceID,
                    ServiceName = service.ServiceName,
                    Category = (int)service.Category,
                    Type = (int)service.Type,
                    Price = service.Price,
                    PricingModel = (int)service.PricingModel,
                    DeliveryModel = (int)service.DeliveryModel,
                    IsAvailable = service.IsAvailable,
                    IsDeleted = service.IsDeleted,
                    LinkedAgentCount = service.AgentServices.Count(),
                    ActiveAgentCount = service.AgentServices.Count(agentService => agentService.IsActive),
                    HasHistoricalUsage = service.BookingItems.Any(),
                    CanDelete = !service.AgentServices.Any() && !service.BookingItems.Any(),
                    CanDisable = !service.IsDeleted && service.IsAvailable
                })
                .ToListAsync();

            return Ok(services);
        }

        // POST: /api/admin/services
        [HttpPost("services")]
        public async Task<IActionResult> CreateService([FromBody] ServiceCatalogItemUpsertDto dto)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = UnauthorizedAdminMessage });
            }

            var validationResult = ValidateServiceCatalogItemDto(dto);
            if (validationResult != null)
            {
                return validationResult;
            }

            var service = new ServiceCatalogItem
            {
                ServiceName = dto.ServiceName.Trim(),
                Category = (ServiceCategory)dto.Category,
                Type = (ServiceType)dto.Type,
                Price = dto.Price,
                PricingModel = (PricingModel)dto.PricingModel,
                DeliveryModel = (DeliveryModel)dto.DeliveryModel,
                IsAvailable = dto.IsAvailable,
                IsDeleted = false,
                AdminID = adminId.Value
            };

            _context.ServiceCatalogItems.Add(service);

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = "CREATE_SERVICE",
                TargetEntity = "ServiceCatalogItem",
                TargetID = service.ServiceID,
                Details = $"Created service '{service.ServiceName}' with price {service.Price}.",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                service.ServiceID,
                service.ServiceName,
                service.Category,
                service.Type,
                service.Price,
                service.PricingModel,
                service.DeliveryModel,
                service.IsAvailable,
                service.IsDeleted
            });
        }

        // PUT: /api/admin/services/{serviceId}
        [HttpPut("services/{serviceId}")]
        public async Task<IActionResult> UpdateService(int serviceId, [FromBody] ServiceCatalogItemUpsertDto dto)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = UnauthorizedAdminMessage });
            }

            var validationResult = ValidateServiceCatalogItemDto(dto);
            if (validationResult != null)
            {
                return validationResult;
            }

            var service = await _context.ServiceCatalogItems.FirstOrDefaultAsync(s => s.ServiceID == serviceId);
            if (service == null)
            {
                return NotFound(new { message = $"Service {serviceId} was not found." });
            }

            service.ServiceName = dto.ServiceName.Trim();
            service.Category = (ServiceCategory)dto.Category;
            service.Type = (ServiceType)dto.Type;
            service.Price = dto.Price;
            service.PricingModel = (PricingModel)dto.PricingModel;
            service.DeliveryModel = (DeliveryModel)dto.DeliveryModel;
            service.IsAvailable = dto.IsAvailable && !service.IsDeleted;

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = "UPDATE_SERVICE",
                TargetEntity = "ServiceCatalogItem",
                TargetID = service.ServiceID,
                Details = $"Updated service '{service.ServiceName}'.",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                service.ServiceID,
                service.ServiceName,
                service.Category,
                service.Type,
                service.Price,
                service.PricingModel,
                service.DeliveryModel,
                service.IsAvailable,
                service.IsDeleted
            });
        }

        // PATCH: /api/admin/services/{serviceId}/availability
        [HttpPatch("services/{serviceId}/availability")]
        public async Task<IActionResult> SetServiceAvailability(int serviceId, [FromBody] ServiceAvailabilityDto dto)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = UnauthorizedAdminMessage });
            }

            var service = await _context.ServiceCatalogItems.FirstOrDefaultAsync(s => s.ServiceID == serviceId);
            if (service == null)
            {
                return NotFound(new { message = $"Service {serviceId} was not found." });
            }

            if (service.IsDeleted)
            {
                return BadRequest(new { message = "Deleted services must be restored before changing availability." });
            }

            service.IsAvailable = dto.IsAvailable;

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = dto.IsAvailable ? "ENABLE_SERVICE" : "DISABLE_SERVICE",
                TargetEntity = "ServiceCatalogItem",
                TargetID = service.ServiceID,
                Details = $"{(dto.IsAvailable ? "Enabled" : "Disabled")} service '{service.ServiceName}'.",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                service.ServiceID,
                service.ServiceName,
                service.IsAvailable,
                service.IsDeleted
            });
        }

        // DELETE: /api/admin/services/{serviceId}
        [HttpDelete("services/{serviceId}")]
        public async Task<IActionResult> DeleteService(int serviceId)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = UnauthorizedAdminMessage });
            }

            var service = await _context.ServiceCatalogItems.FirstOrDefaultAsync(s => s.ServiceID == serviceId);
            if (service == null)
            {
                return NotFound(new { message = $"Service {serviceId} was not found." });
            }

            if (service.IsDeleted)
            {
                return Ok(new
                {
                    service.ServiceID,
                    deletionType = "AlreadySoftDeleted",
                    message = "Service was already soft deleted."
                });
            }

            var hasAgentServices = await _context.AgentServices.AnyAsync(s => s.ServiceID == serviceId);
            var hasBookingItems = await _context.BookingItems.AnyAsync(i => i.ServiceID == serviceId);

            if (!hasAgentServices && !hasBookingItems)
            {
                _context.AuditLogs.Add(new AuditLog
                {
                    AdminID = adminId.Value,
                    Action = "HARD_DELETE_SERVICE",
                    TargetEntity = "ServiceCatalogItem",
                    TargetID = service.ServiceID,
                    Details = $"Hard deleted unused service '{service.ServiceName}'.",
                    IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                    PerformedAt = DateTime.UtcNow
                });

                _context.ServiceCatalogItems.Remove(service);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    serviceId,
                    deletionType = "HardDeleted",
                    message = "Service was permanently deleted because it had no historical relationships."
                });
            }

            service.IsDeleted = true;
            service.IsAvailable = false;

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = "SOFT_DELETE_SERVICE",
                TargetEntity = "ServiceCatalogItem",
                TargetID = service.ServiceID,
                Details = $"Soft deleted service '{service.ServiceName}'. Agent links: {hasAgentServices}. Booking history: {hasBookingItems}.",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                service.ServiceID,
                deletionType = "SoftDeleted",
                service.IsAvailable,
                service.IsDeleted,
                message = "Service was soft deleted and disabled."
            });
        }

        // PATCH: /api/admin/services/{serviceId}/restore
        [HttpPatch("services/{serviceId}/restore")]
        public async Task<IActionResult> RestoreService(int serviceId)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = UnauthorizedAdminMessage });
            }

            var service = await _context.ServiceCatalogItems.FirstOrDefaultAsync(s => s.ServiceID == serviceId);
            if (service == null)
            {
                return NotFound(new { message = $"Service {serviceId} was not found." });
            }

            service.IsDeleted = false;

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = "RESTORE_SERVICE",
                TargetEntity = "ServiceCatalogItem",
                TargetID = service.ServiceID,
                Details = $"Restored service '{service.ServiceName}'. Availability remains {service.IsAvailable}.",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                service.ServiceID,
                service.ServiceName,
                service.IsAvailable,
                service.IsDeleted
            });
        }

        // GET: /api/admin/payments/pending-review
        [HttpGet("payments/pending-review")]
        public async Task<IActionResult> GetPaymentsPendingReview()
        {
            var payments = await _context.Payments
                .Include(p => p.Booking)
                    .ThenInclude(b => b.Client)
                .Where(p => p.Status == PaymentStatus.Pending || p.Status == PaymentStatus.PendingReview)
                .OrderBy(p => p.CreatedAt)
                .Select(p => new
                {
                    p.PaymentID,
                    p.BookingID,
                    p.Amount,
                    p.Method,
                    p.Status,
                    p.TransactionRef,
                    p.PaymentProofURL,
                    p.StatusReason,
                    p.CreatedAt,
                    Client = new
                    {
                        p.Booking.Client.UserID,
                        p.Booking.Client.FirstName,
                        p.Booking.Client.LastName,
                        p.Booking.Client.PhoneNo
                    }
                })
                .ToListAsync();

            return Ok(payments);
        }

        // POST: /api/admin/payments/{paymentId}/confirm
        [HttpPost("payments/{paymentId}/confirm")]
        public async Task<IActionResult> ConfirmPayment(int paymentId, [FromBody] PaymentReviewDto dto)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = "فشلت عملية التحقق من هوية المسؤول." });
            }

            var now = DateTime.UtcNow;
            var newStatus = PaymentStatus.Success;
            var statusReason = string.IsNullOrWhiteSpace(dto.Reason)
                ? "Payment confirmed by admin."
                : dto.Reason.Trim();

            // Use ExecuteUpdateAsync to atomically update only payments in Pending or PendingReview status
            var affectedRows = await _context.Payments
                .Where(p => p.PaymentID == paymentId &&
                           (p.Status == PaymentStatus.Pending || p.Status == PaymentStatus.PendingReview))
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(p => p.Status, p => p.Method == PaymentMethod.Cash ? PaymentStatus.Collected : newStatus)
                    .SetProperty(p => p.PaidAt, now)
                    .SetProperty(p => p.ReviewedAt, now)
                    .SetProperty(p => p.ReviewedByAdminID, adminId.Value)
                    .SetProperty(p => p.StatusReason, statusReason)
                );

            if (affectedRows == 0)
            {
                // Either payment doesn't exist or it's not in a reviewable state
                var existingPayment = await _context.Payments.FirstOrDefaultAsync(p => p.PaymentID == paymentId);
                if (existingPayment == null)
                {
                    return NotFound(new { message = $"Payment {paymentId} was not found." });
                }
                return Conflict(new { message = "Payment status has changed. Only pending payments can be confirmed." });
            }

            // Apply optional fields if provided (requires separate update since ExecuteUpdateAsync doesn't support conditional SetProperty)
            if (!string.IsNullOrWhiteSpace(dto.TransactionRef) || !string.IsNullOrWhiteSpace(dto.PaymentProofURL))
            {
                var payment = await _context.Payments.FirstOrDefaultAsync(p => p.PaymentID == paymentId);
                if (payment != null)
                {
                    if (!string.IsNullOrWhiteSpace(dto.TransactionRef))
                    {
                        payment.TransactionRef = dto.TransactionRef.Trim();
                    }
                    if (!string.IsNullOrWhiteSpace(dto.PaymentProofURL))
                    {
                        payment.PaymentProofURL = dto.PaymentProofURL.Trim();
                    }
                    await _context.SaveChangesAsync();
                }
            }

            // Fetch the updated payment for the response
            var updatedPayment = await _context.Payments.FirstOrDefaultAsync(p => p.PaymentID == paymentId);
            if (updatedPayment == null)
            {
                return NotFound(new { message = $"Payment {paymentId} was not found after update." });
            }

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = "CONFIRM_PAYMENT",
                TargetEntity = "Payment",
                TargetID = updatedPayment.PaymentID,
                Details = $"Confirmed {updatedPayment.Method} payment for booking {updatedPayment.BookingID} with status {updatedPayment.Status}.",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = now
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                updatedPayment.PaymentID,
                updatedPayment.BookingID,
                updatedPayment.Amount,
                method = updatedPayment.Method.ToString(),
                status = updatedPayment.Status.ToString(),
                updatedPayment.PaidAt,
                updatedPayment.ReviewedAt,
                updatedPayment.StatusReason
            });
        }

        // POST: /api/admin/payments/{paymentId}/fail
        [HttpPost("payments/{paymentId}/fail")]
        public async Task<IActionResult> FailPayment(int paymentId, [FromBody] PaymentReviewDto dto)
        {
            var adminId = GetAdminId();
            if (adminId == null)
            {
                return Unauthorized(new { message = "فشلت عملية التحقق من هوية المسؤول." });
            }

            var payment = await _context.Payments.FirstOrDefaultAsync(p => p.PaymentID == paymentId);
            if (payment == null)
            {
                return NotFound(new { message = $"Payment {paymentId} was not found." });
            }

            if (payment.Status != PaymentStatus.Pending && payment.Status != PaymentStatus.PendingReview)
            {
                return BadRequest(new { message = "Only pending payments can be rejected." });
            }

            var now = DateTime.UtcNow;
            payment.Status = PaymentStatus.Failed;
            payment.PaidAt = null;
            payment.ReviewedAt = now;
            payment.ReviewedByAdminID = adminId.Value;
            payment.StatusReason = string.IsNullOrWhiteSpace(dto.Reason)
                ? "Payment rejected by admin."
                : dto.Reason.Trim();

            _context.AuditLogs.Add(new AuditLog
            {
                AdminID = adminId.Value,
                Action = "REJECT_PAYMENT",
                TargetEntity = "Payment",
                TargetID = payment.PaymentID,
                Details = $"Rejected {payment.Method} payment for booking {payment.BookingID}. Reason: {payment.StatusReason}",
                IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                PerformedAt = now
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                payment.PaymentID,
                payment.BookingID,
                payment.Amount,
                method = payment.Method.ToString(),
                status = payment.Status.ToString(),
                payment.ReviewedAt,
                payment.StatusReason
            });
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
                    u.CreatedAt,
                    BusinessName = _context.LaundryAgents
                        .Where(a => a.UserID == u.UserID)
                        .Select(a => a.BusinessName)
                        .FirstOrDefault(),
                    CommercialRegister = _context.LaundryAgents
                        .Where(a => a.UserID == u.UserID)
                        .Select(a => a.CommercialRegister)
                        .FirstOrDefault(),
                    NationalIDNumber = _context.LaundryAgents
                        .Where(a => a.UserID == u.UserID)
                        .Select(a => a.NationalIDNumber)
                        .FirstOrDefault() ?? _context.DeliveryStaffs
                        .Where(d => d.UserID == u.UserID)
                        .Select(d => d.NationalIDNumber)
                        .FirstOrDefault(),
                    VehicleType = _context.DeliveryStaffs
                        .Where(d => d.UserID == u.UserID)
                        .Select(d => (VehicleType?)d.VehicleType)
                        .FirstOrDefault(),
                    PlateNumber = _context.DeliveryStaffs
                        .Where(d => d.UserID == u.UserID)
                        .Select(d => d.PlateNumber)
                        .FirstOrDefault(),
                    Rating = u.Role == UserRole.LaundryAgent
                        ? (_context.BookingRatings
                            .Where(r => r.Booking.LaundryAgentID == u.UserID && r.AgentRating.HasValue)
                            .Average(r => (double?)r.AgentRating) ?? 0)
                        : (_context.BookingRatings
                            .Where(r => r.Booking.DeliveryTasks.Any(t => t.DeliveryStaffID == u.UserID) && r.DeliveryRating.HasValue)
                            .Average(r => (double?)r.DeliveryRating) ?? 0),
                    Documents = u.Documents.Select(d => new
                    {
                        d.DocumentID,
                        d.Type,
                        d.FileURL,
                        d.OriginalFileName,
                        d.ContentType,
                        d.FileSizeBytes,
                        d.UploadedAt,
                        d.ReviewStatus
                    })
                })
                .ToListAsync();

            return Ok(staff);
        }

        // GET: /api/admin/audit-logs
        [HttpGet("audit-logs")]
        public async Task<IActionResult> GetAuditLogs(int page = 1, int pageSize = 50)
        {
            const int maxPageSize = 200;
            pageSize = pageSize > maxPageSize ? maxPageSize : pageSize;

            var baseQuery = _context.AuditLogs
                .Include(al => al.Admin)
                .OrderByDescending(al => al.PerformedAt);

            var totalCount = await baseQuery.CountAsync();

            var logs = await baseQuery
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(al => new
                {
                    al.LogID,
                    al.AdminID,
                    AdminName = al.Admin.FirstName + " " + al.Admin.LastName,
                    al.Action,
                    al.TargetEntity,
                    al.TargetID,
                    al.Details,
                    al.IpAddress,
                    al.PerformedAt
                })
                .ToListAsync();

            return Ok(new
            {
                data = logs,
                currentPage = page,
                pageSize = pageSize,
                totalCount = totalCount
            });
        }

        private int? GetAdminId()
        {
            var adminIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            return adminIdClaim != null && int.TryParse(adminIdClaim.Value, out var adminId)
                ? adminId
                : null;
        }

        private bool TryParseNotificationTargetRole(string? value, out UserRole role)
        {
            role = UserRole.Client;
            if (string.IsNullOrWhiteSpace(value))
            {
                return false;
            }

            var normalized = value.Trim();
            if (normalized.Equals("Clients", StringComparison.OrdinalIgnoreCase) ||
                normalized.Equals("Client", StringComparison.OrdinalIgnoreCase))
            {
                role = UserRole.Client;
                return true;
            }

            if (normalized.Equals("Drivers", StringComparison.OrdinalIgnoreCase) ||
                normalized.Equals("Driver", StringComparison.OrdinalIgnoreCase) ||
                normalized.Equals("DeliveryStaff", StringComparison.OrdinalIgnoreCase))
            {
                role = UserRole.DeliveryStaff;
                return true;
            }

            if (normalized.Equals("LaundryAgents", StringComparison.OrdinalIgnoreCase) ||
                normalized.Equals("LaundryAgent", StringComparison.OrdinalIgnoreCase))
            {
                role = UserRole.LaundryAgent;
                return true;
            }

            return false;
        }

        private async Task<IActionResult?> ValidateOfferCreateDto(AdminOfferCreateDto? dto)
        {
            if (dto == null)
            {
                return BadRequest(new { message = "Offer payload is required." });
            }

            if (string.IsNullOrWhiteSpace(dto.OfferCode))
            {
                return BadRequest(new { message = "OfferCode is required." });
            }

            if (!Enum.IsDefined(typeof(OfferType), dto.Type))
            {
                return BadRequest(new { message = "Invalid offer type." });
            }

            if (!Enum.IsDefined(typeof(OfferScope), dto.Scope))
            {
                return BadRequest(new { message = "Invalid offer scope." });
            }

            if (dto.DiscountValue <= 0)
            {
                return BadRequest(new { message = "DiscountValue must be greater than zero." });
            }

            if (dto.Type == OfferType.Percentage && dto.DiscountValue > 100)
            {
                return BadRequest(new { message = "Percentage discount cannot be greater than 100." });
            }

            if (dto.EndDate <= dto.StartDate)
            {
                return BadRequest(new { message = "EndDate must be after StartDate." });
            }

            if (dto.MinOrderValue.HasValue && dto.MinOrderValue.Value < 0)
            {
                return BadRequest(new { message = "MinOrderValue cannot be negative." });
            }

            if (dto.MaxUsageCount.HasValue && dto.MaxUsageCount.Value <= 0)
            {
                return BadRequest(new { message = "MaxUsageCount must be greater than zero." });
            }

            if (dto.Scope == OfferScope.SpecificAgent)
            {
                if (!dto.LaundryAgentID.HasValue)
                {
                    return BadRequest(new { message = "LaundryAgentID is required for a specific-agent offer." });
                }

                var agentExists = await _context.LaundryAgents
                    .AnyAsync(a => a.UserID == dto.LaundryAgentID.Value && a.IsApproved);
                if (!agentExists)
                {
                    return BadRequest(new { message = "Selected laundry agent was not found or is not approved." });
                }
            }

            return null;
        }

        private IActionResult? ValidateServiceCatalogItemDto(ServiceCatalogItemUpsertDto? dto)
        {
            if (dto == null)
            {
                return BadRequest(new { message = "Service payload is required." });
            }

            if (string.IsNullOrWhiteSpace(dto.ServiceName))
            {
                return BadRequest(new { message = "ServiceName is required." });
            }

            if (dto.Price < 0)
            {
                return BadRequest(new { message = "Price must be zero or greater." });
            }

            if (!Enum.IsDefined(typeof(ServiceCategory), dto.Category))
            {
                return BadRequest(new { message = "Invalid service category." });
            }

            if (!Enum.IsDefined(typeof(ServiceType), dto.Type))
            {
                return BadRequest(new { message = "Invalid service type." });
            }

            if (!Enum.IsDefined(typeof(PricingModel), dto.PricingModel))
            {
                return BadRequest(new { message = "Invalid pricing model." });
            }

            if (!Enum.IsDefined(typeof(DeliveryModel), dto.DeliveryModel))
            {
                return BadRequest(new { message = "Invalid delivery model." });
            }

            return null;
        }
    }

    public class AdminServiceCatalogItemDto
    {
        public int ServiceID { get; set; }
        public string ServiceName { get; set; } = string.Empty;
        public int Category { get; set; }
        public int Type { get; set; }
        public decimal Price { get; set; }
        public int PricingModel { get; set; }
        public int DeliveryModel { get; set; }
        public bool IsAvailable { get; set; }
        public bool IsDeleted { get; set; }
        public int LinkedAgentCount { get; set; }
        public int ActiveAgentCount { get; set; }
        public bool HasHistoricalUsage { get; set; }
        public bool CanDelete { get; set; }
        public bool CanDisable { get; set; }
    }

    public class AdminSummaryDto
    {
        public int CustomersCount { get; set; }
        public int LaundryAgentsCount { get; set; }
        public int DriversCount { get; set; }
        public int TotalOrders { get; set; }
        public int PendingOrders { get; set; }
        public int CompletedOrders { get; set; }
        public decimal TotalRevenue { get; set; }
    }

    public class ServiceCatalogItemUpsertDto
    {
        public string ServiceName { get; set; } = string.Empty;
        public int Category { get; set; }
        public int Type { get; set; }
        public decimal Price { get; set; }
        public int PricingModel { get; set; }
        public int DeliveryModel { get; set; }
        public bool IsAvailable { get; set; } = true;
    }

    public class ServiceAvailabilityDto
    {
        public bool IsAvailable { get; set; }
    }

    public class PaymentReviewDto
    {
        public string? Reason { get; set; }
        public string? TransactionRef { get; set; }
        public string? PaymentProofURL { get; set; }
    }

    public class SetAgentServicesDto
    {
        public List<int> ServiceIDs { get; set; } = new();
    }

    public class AdminNotificationCreateDto
    {
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public string TargetRole { get; set; } = string.Empty;
    }

    public class AdminOfferCreateDto
    {
        public string OfferCode { get; set; } = string.Empty;
        public OfferType Type { get; set; }
        public OfferScope Scope { get; set; }
        public decimal DiscountValue { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public decimal? MinOrderValue { get; set; }
        public int? MaxUsageCount { get; set; }
        public int? LaundryAgentID { get; set; }
        public bool SendNotificationToClients { get; set; }
    }
}
