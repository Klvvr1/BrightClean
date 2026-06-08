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

        // GET: /api/admin/pending-approvals
        [HttpGet("pending-approvals")]
        public async Task<IActionResult> GetPendingApprovals()
        {
            var pendingUsers = await _context.Users
                .Where(u => !u.IsApproved && (u.Role == UserRole.LaundryAgent || u.Role == UserRole.DeliveryStaff))
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
}
