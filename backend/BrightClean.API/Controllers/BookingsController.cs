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

namespace BrightClean.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class BookingsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public BookingsController(AppDbContext context)
        {
            _context = context;
        }

        private static object ProjectAgentBooking(Booking b)
        {
            return new
            {
                b.BookingID,
                b.ClientID,
                client = new
                {
                    id = b.Client.UserID,
                    firstName = b.Client.FirstName,
                    lastName = b.Client.LastName,
                    phoneNo = b.Client.PhoneNo
                },
                b.LaundryAgentID,
                b.AddressID,
                address = new
                {
                    b.Address.AddressID,
                    b.Address.Area,
                    b.Address.Street,
                    b.Address.Latitude,
                    b.Address.Longitude
                },
                b.Status,
                b.FinalTotal,
                b.CreatedAt,
                b.ScheduledAt,
                b.SpecialInstructions,
                payment = b.Payment == null ? null : new
                {
                    b.Payment.PaymentID,
                    b.Payment.Amount,
                    b.Payment.Method,
                    b.Payment.Status
                },
                bookingItems = b.BookingItems.Select(i => new
                {
                    i.BookingItemID,
                    i.ServiceID,
                    i.Quantity,
                    i.UnitPriceAtTimeOfBooking,
                    serviceCatalogItem = new
                    {
                        i.ServiceCatalogItem.ServiceID,
                        i.ServiceCatalogItem.ServiceName,
                        i.ServiceCatalogItem.Category,
                        i.ServiceCatalogItem.Type,
                        i.ServiceCatalogItem.Price,
                        i.ServiceCatalogItem.DeliveryModel
                    }
                })
            };
        }

        private IActionResult? ValidateScheduledAt(DateTime? scheduledAt)
        {
            if (!scheduledAt.HasValue)
            {
                return null; // No validation needed if not provided
            }

            // Check if scheduled date is in the past
            if (scheduledAt.Value < DateTime.UtcNow.Date)
            {
                return BadRequest(new { message = "تاريخ الموعد لا يمكن أن يكون في الماضي." });
            }

            // Check if scheduled date is beyond 30 days (maximum future window enforced by UI)
            var maxFutureDate = DateTime.UtcNow.AddDays(30);
            if (scheduledAt.Value > maxFutureDate)
            {
                return BadRequest(new { message = "تاريخ الموعد لا يمكن أن يكون بعد 30 يوماً من الآن." });
            }

            return null;
        }

        // GET: /api/bookings
        [HttpGet]
        public async Task<IActionResult> GetBookings()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
            {
                return Unauthorized();
            }

            var bookings = await _context.Bookings
                .Include(b => b.BookingItems)
                    .ThenInclude(bi => bi.ServiceCatalogItem)
                .Where(b => b.ClientID == userId)
                .OrderByDescending(b => b.CreatedAt)
                .ToListAsync();

            return Ok(bookings);
        }

        // GET: /api/bookings/my
        [HttpGet("my")]
        [Authorize(Roles = "Client")]
        public async Task<IActionResult> GetMyBookings()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var clientId))
            {
                return Unauthorized();
            }

            var bookings = await _context.Bookings
                .AsNoTracking()
                .Where(b => b.ClientID == clientId && b.Status != BookingStatus.Draft)
                .OrderByDescending(b => b.CreatedAt)
                .Select(b => new
                {
                    b.BookingID,
                    b.ClientID,
                    b.LaundryAgentID,
                    laundryAgent = new
                    {
                        id = b.LaundryAgent.UserID,
                        businessName = b.LaundryAgent.BusinessName
                    },
                    b.AddressID,
                    address = new
                    {
                        b.Address.AddressID,
                        b.Address.Area,
                        b.Address.Street,
                        b.Address.Latitude,
                        b.Address.Longitude
                    },
                    b.OfferID,
                    b.Status,
                    b.FinalTotal,
                    b.CreatedAt,
                    b.ExpiresAt,
                    b.ScheduledAt,
                    b.SpecialInstructions,
                    payment = b.Payment == null ? null : new
                    {
                        b.Payment.PaymentID,
                        b.Payment.Amount,
                        b.Payment.Method,
                        b.Payment.Status,
                        b.Payment.StatusReason,
                        b.Payment.PaidAt
                    },
                    rating = b.Rating == null ? null : new
                    {
                        b.Rating.RatingID,
                        b.Rating.AgentRating,
                        b.Rating.DeliveryRating,
                        b.Rating.RatedAt
                    },
                    bookingItems = b.BookingItems.Select(i => new
                    {
                        i.BookingItemID,
                        i.BookingID,
                        i.ServiceID,
                        i.Quantity,
                        i.UnitPriceAtTimeOfBooking,
                        serviceCatalogItem = new
                        {
                            i.ServiceCatalogItem.ServiceID,
                            i.ServiceCatalogItem.ServiceName,
                            i.ServiceCatalogItem.Category,
                            i.ServiceCatalogItem.Type,
                            i.ServiceCatalogItem.Price,
                            i.ServiceCatalogItem.PricingModel,
                            i.ServiceCatalogItem.DeliveryModel,
                            i.ServiceCatalogItem.IsAvailable
                        }
                    })
                })
                .ToListAsync();

            return Ok(bookings);
        }

        // GET: /api/bookings/agent/my
        [HttpGet("agent/my")]
        [Authorize(Roles = "LaundryAgent")]
        public async Task<IActionResult> GetMyAgentBookings()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId))
            {
                return Unauthorized();
            }

            var bookings = await _context.Bookings
                .AsNoTracking()
                .Include(b => b.Client)
                .Include(b => b.Address)
                .Include(b => b.Payment)
                .Include(b => b.BookingItems)
                    .ThenInclude(i => i.ServiceCatalogItem)
                .Where(b => b.LaundryAgentID == agentId && b.Status != BookingStatus.Draft)
                .OrderByDescending(b => b.CreatedAt)
                .ToListAsync();

            return Ok(bookings.Select(ProjectAgentBooking));
        }

        // POST: /api/bookings
        [HttpPost]
        [Authorize(Roles = "Client")]
        public async Task<IActionResult> CreateBooking([FromBody] CreateBookingDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var clientId))
            {
                return Unauthorized();
            }

            if (dto.Items == null || !dto.Items.Any())
            {
                return BadRequest(new { message = "يجب اختيار خدمة واحدة على الأقل." });
            }

            var agent = await _context.LaundryAgents.FindAsync(dto.LaundryAgentID);
            if (agent == null)
            {
                return BadRequest(new { message = "وكيل الغسيل غير موجود." });
            }

            if (!agent.IsApproved || agent.AccountStatus != AccountStatus.Active || agent.IsStoreClosed)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { message = "The selected laundry agent is not currently available." });
            }

            var requestedServiceIds = dto.Items
                .Select(i => i.ServiceID)
                .Distinct()
                .ToList();

            var activeAgentServiceIds = await _context.AgentServices
                .Where(s => s.LaundryAgentID == agent.UserID && s.IsActive)
                .Select(s => s.ServiceID)
                .ToListAsync();

            var unsupportedServiceIds = requestedServiceIds
                .Where(id => !activeAgentServiceIds.Contains(id))
                .ToList();

            if (unsupportedServiceIds.Any())
            {
                return BadRequest(new
                {
                    message = "The selected laundry agent does not provide one or more requested services.",
                    unsupportedServiceIds
                });
            }

            var requestedDeliveryModels = await _context.ServiceCatalogItems
                .Where(s => requestedServiceIds.Contains(s.ServiceID))
                .Select(s => s.DeliveryModel)
                .Distinct()
                .ToListAsync();

            if (requestedDeliveryModels.Count > 1)
            {
                return BadRequest(new { message = "Services with delivery pickup and on-site technician dispatch cannot be mixed in the same booking." });
            }

            int addressId = dto.AddressID ?? 0;
            if (addressId == 0)
            {
                var defaultAddress = await _context.Addresses.FirstOrDefaultAsync(a => a.ClientID == clientId);
                if (defaultAddress == null)
                {
                    return BadRequest(new { message = "يجب تسجيل عنوان العميل أولاً لإنشاء الحجز." });
                }
                addressId = defaultAddress.AddressID;
            }
            else
            {
                // Verify the provided address belongs to the authenticated client
                var addressOwnership = await _context.Addresses
                    .FirstOrDefaultAsync(a => a.AddressID == addressId && a.ClientID == clientId);
                if (addressOwnership == null)
                {
                    return BadRequest(new { message = "العنوان المحدد غير موجود أو لا ينتمي لهذا العميل." });
                }
            }

            // Validate ScheduledAt before creating booking
            var scheduledAtValidation = ValidateScheduledAt(dto.ScheduledAt);
            if (scheduledAtValidation != null)
            {
                return scheduledAtValidation;
            }

            var booking = new Booking
            {
                ClientID = clientId,
                LaundryAgentID = agent.UserID,
                AddressID = addressId,
                Status = BookingStatus.Draft,
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddDays(1),
                ScheduledAt = dto.ScheduledAt,
                SpecialInstructions = dto.SpecialInstructions
            };

            foreach (var itemDto in dto.Items)
            {
                // Validate quantity is positive
                if (itemDto.Quantity <= 0)
                {
                    return BadRequest(new { message = "الكمية يجب أن تكون أكبر من صفر." });
                }

                var service = await _context.ServiceCatalogItems.FindAsync(itemDto.ServiceID);
                if (service == null)
                {
                    return BadRequest(new { message = "الخدمة المطلوبة غير موجودة في النظام." });
                }

                var bookingItem = new BookingItem
                {
                    ServiceID = service.ServiceID,
                    Quantity = itemDto.Quantity,
                    UnitPriceAtTimeOfBooking = service.Price
                };
                booking.BookingItems.Add(bookingItem);
            }

            _context.Bookings.Add(booking);
            await _context.SaveChangesAsync();

            return Ok(new { bookingID = booking.BookingID });
        }

        // POST: /api/bookings/submit
        [HttpPost("submit")]
        [Authorize(Roles = "Client")]
        public async Task<IActionResult> SubmitBooking([FromBody] SubmitBookingDto dto)
        {
            var booking = await _context.Bookings
                .Include(b => b.BookingItems)
                    .ThenInclude(bi => bi.ServiceCatalogItem)
                .Include(b => b.Offer)
                .FirstOrDefaultAsync(b => b.BookingID == dto.BookingID);

            if (booking == null)
            {
                return NotFound($"Booking with ID {dto.BookingID} not found.");
            }

            // Verify caller owns the booking
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId) || booking.ClientID != userId)
            {
                return Forbid();
            }

            // If already pending with FinalTotal, allow updates to ScheduledAt and SpecialInstructions
            if (booking.Status == BookingStatus.Pending && booking.FinalTotal.HasValue)
            {
                // Validate ScheduledAt before updating
                var scheduledAtValidation = ValidateScheduledAt(dto.ScheduledAt);
                if (scheduledAtValidation != null)
                {
                    return scheduledAtValidation;
                }

                // Apply schedule and instruction updates even for pending bookings (deferred payment retry flow)
                if (dto.ScheduledAt.HasValue)
                {
                    booking.ScheduledAt = dto.ScheduledAt;
                }

                if (!string.IsNullOrWhiteSpace(dto.SpecialInstructions))
                {
                    booking.SpecialInstructions = dto.SpecialInstructions;
                }

                await _context.SaveChangesAsync();
                return Ok(booking);
            }

            if (booking.Status != BookingStatus.Draft)
            {
                return BadRequest("Only draft bookings can be submitted.");
            }

            if (booking.ExpiresAt.HasValue && booking.ExpiresAt.Value < DateTime.UtcNow)
            {
                return BadRequest("This draft booking has expired. Please create a new booking.");
            }

            // Validate ScheduledAt before updating booking
            var scheduledAtValidation2 = ValidateScheduledAt(dto.ScheduledAt);
            if (scheduledAtValidation2 != null)
            {
                return scheduledAtValidation2;
            }

            if (dto.ScheduledAt.HasValue)
            {
                booking.ScheduledAt = dto.ScheduledAt;
            }

            if (!string.IsNullOrWhiteSpace(dto.SpecialInstructions))
            {
                booking.SpecialInstructions = dto.SpecialInstructions;
            }

            // Calculate subtotal
            decimal total = 0m;
            foreach (var item in booking.BookingItems)
            {
                total += item.SubTotal;
            }

            // Apply offer if valid
            if (booking.Offer != null && booking.Offer.IsValid)
            {
                if (booking.Offer.Type == OfferType.Percentage)
                {
                    total -= total * (booking.Offer.DiscountValue / 100m);
                }
                else if (booking.Offer.Type == OfferType.FixedAmount)
                {
                    total -= booking.Offer.DiscountValue;
                }

                if (total < 0m) total = 0m;
            }

            booking.FinalTotal = total;
            booking.Status = BookingStatus.Pending;

            await _context.SaveChangesAsync();

            return Ok(booking);
        }

        // GET: /api/bookings/agent/{agentId}/pending
        [HttpGet("agent/{agentId}/pending")]
        [Authorize(Roles = "LaundryAgent")]
        public async Task<IActionResult> GetPendingBookings(int agentId)
        {
            // CRIT-004: Verify the requesting user is the same agent they are querying for
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var callerId) || callerId != agentId)
            {
                return Forbid();
            }

            var bookings = await _context.Bookings
                .Include(b => b.BookingItems)
                    .ThenInclude(bi => bi.ServiceCatalogItem)
                .Where(b => b.LaundryAgentID == agentId && b.Status == BookingStatus.Pending)
                .ToListAsync();

            return Ok(bookings);
        }

        // POST: /api/bookings/{bookingId}/accept
        [HttpPost("{bookingId}/accept")]
        [Authorize(Roles = "LaundryAgent")]
        public async Task<IActionResult> AcceptBooking(int bookingId)
        {
            // CRIT-002: All read-only guards run BEFORE opening the transaction so that early
            // returns are clean and do not leave an uncommitted transaction open.

            var booking = await _context.Bookings
                .Include(b => b.BookingItems)
                    .ThenInclude(bi => bi.ServiceCatalogItem)
                .FirstOrDefaultAsync(b => b.BookingID == bookingId);

            if (booking == null)
            {
                return NotFound($"Booking with ID {bookingId} not found.");
            }

            // Verify caller is the Laundry Agent assigned to the booking
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId) || booking.LaundryAgentID != agentId)
            {
                return Forbid();
            }

            // Check store status
            var agent = await _context.LaundryAgents.FindAsync(agentId);
            if (agent != null && agent.IsStoreClosed)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { message = "المغسلة مغلقة حالياً. لا يمكن قبول الطلبات." });
            }

            if (booking.Status != BookingStatus.Pending)
            {
                return BadRequest("Only pending bookings can be accepted.");
            }

            // All guards passed — open transaction only for the mutation
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                booking.Status = BookingStatus.Accepted;

                // Save status change first
                await _context.SaveChangesAsync();

                var deliveryModels = booking.BookingItems
                    .Select(bi => bi.ServiceCatalogItem.DeliveryModel)
                    .Distinct()
                    .ToList();

                if (deliveryModels.Count > 1)
                {
                    await transaction.RollbackAsync();
                    return BadRequest("Bookings cannot mix delivery pickup services with on-site technician dispatch services.");
                }

                // Check if the booking belongs to a TwoStage delivery model
                bool isTwoStage = deliveryModels.Contains(DeliveryModel.TwoStage);

                if (isTwoStage)
                {
                    var laundryAgent = await _context.LaundryAgents.FindAsync(booking.LaundryAgentID);
                    if (laundryAgent == null)
                    {
                        await transaction.RollbackAsync();
                        return BadRequest("Laundry Agent associated with booking does not exist.");
                    }

                    // Add Pickup Task (Stage 1)
                    var pickupTask = new DeliveryTask
                    {
                        BookingID = booking.BookingID,
                        StageNumber = 1,
                        Type = TaskType.PickupFromClient,
                        Status = DeliveryTaskStatus.Unassigned,
                        PickupAddressID = booking.AddressID,      // From Client Address
                        DropoffAddressID = laundryAgent.AddressID, // To Laundry Agent Address
                        DeliveryFee = 1.500m                      // Simulated flat rate
                    };

                    // Add Delivery Task (Stage 2)
                    var deliveryTask = new DeliveryTask
                    {
                        BookingID = booking.BookingID,
                        StageNumber = 2,
                        Type = TaskType.DeliveryToClient,
                        Status = DeliveryTaskStatus.Unassigned,
                        PickupAddressID = laundryAgent.AddressID, // From Laundry Agent Address
                        DropoffAddressID = booking.AddressID,      // To Client Address
                        DeliveryFee = 1.500m                      // Simulated flat rate
                    };

                    _context.DeliveryTasks.AddRange(pickupTask, deliveryTask);
                    await _context.SaveChangesAsync();
                }

                await transaction.CommitAsync();
                return Ok(booking);
            }
            catch (DbUpdateConcurrencyException)
            {
                await transaction.RollbackAsync();
                return Conflict("The booking was modified by another process. Please retry.");
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        // POST: /api/bookings/{bookingId}/reject
        [HttpPost("{bookingId}/reject")]
        [Authorize(Roles = "LaundryAgent")]
        public async Task<IActionResult> RejectBooking(int bookingId, [FromBody] RejectBookingDto? dto)
        {
            var booking = await _context.Bookings.FindAsync(bookingId);

            if (booking == null)
            {
                return NotFound($"Booking with ID {bookingId} not found.");
            }

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId) || booking.LaundryAgentID != agentId)
            {
                return Forbid();
            }

            if (booking.Status != BookingStatus.Pending)
            {
                return BadRequest("Only pending bookings can be rejected.");
            }

            booking.Status = BookingStatus.Cancelled;
            if (!string.IsNullOrWhiteSpace(dto?.Reason))
            {
                var existingNotes = string.IsNullOrWhiteSpace(booking.SpecialInstructions)
                    ? string.Empty
                    : booking.SpecialInstructions + Environment.NewLine;
                booking.SpecialInstructions = existingNotes + $"Rejection reason: {dto.Reason.Trim()}";
            }

            await _context.SaveChangesAsync();

            return Ok(new { booking.BookingID, booking.Status });
        }

        // POST: /api/bookings/{bookingId}/start
        [HttpPost("{bookingId}/start")]
        [Authorize(Roles = "LaundryAgent")]
        public async Task<IActionResult> StartBookingWork(int bookingId)
        {
            var booking = await _context.Bookings.FindAsync(bookingId);

            if (booking == null)
            {
                return NotFound($"Booking with ID {bookingId} not found.");
            }

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId) || booking.LaundryAgentID != agentId)
            {
                return Forbid();
            }

            if (booking.Status != BookingStatus.Accepted)
            {
                return BadRequest("Only accepted bookings can be moved to in progress.");
            }

            booking.Status = BookingStatus.InProgress;
            await _context.SaveChangesAsync();

            return Ok(new { booking.BookingID, booking.Status });
        }

        // POST: /api/bookings/{bookingId}/ready
        [HttpPost("{bookingId}/ready")]
        [Authorize(Roles = "LaundryAgent")]
        public async Task<IActionResult> MarkBookingReady(int bookingId)
        {
            var booking = await _context.Bookings
                .Include(b => b.BookingItems)
                    .ThenInclude(bi => bi.ServiceCatalogItem)
                .FirstOrDefaultAsync(b => b.BookingID == bookingId);

            if (booking == null)
            {
                return NotFound($"Booking with ID {bookingId} not found.");
            }

            // Verify caller is the Laundry Agent assigned to the booking
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId) || booking.LaundryAgentID != agentId)
            {
                return Forbid();
            }

            // Check store status
            var agent = await _context.LaundryAgents.FindAsync(agentId);
            if (agent != null && agent.IsStoreClosed)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { message = "المغسلة مغلقة حالياً. لا يمكن معالجة الطلبات." });
            }

            if (booking.Status != BookingStatus.InProgress && booking.Status != BookingStatus.Accepted)
            {
                return BadRequest("Booking must be Accepted or InProgress to be marked as Ready.");
            }

            if (!booking.BookingItems.Any(bi => bi.ServiceCatalogItem.DeliveryModel == DeliveryModel.TwoStage))
            {
                return BadRequest("Technician dispatch bookings should be completed by the laundry agent, not marked ready for delivery.");
            }

            booking.Status = BookingStatus.Ready;
            await _context.SaveChangesAsync();

            return Ok(booking);
        }

        // POST: /api/bookings/{bookingId}/complete
        [HttpPost("{bookingId}/complete")]
        [Authorize(Roles = "LaundryAgent")]
        public async Task<IActionResult> CompleteTechnicianDispatchBooking(int bookingId)
        {
            var booking = await _context.Bookings
                .Include(b => b.BookingItems)
                    .ThenInclude(bi => bi.ServiceCatalogItem)
                .FirstOrDefaultAsync(b => b.BookingID == bookingId);

            if (booking == null)
            {
                return NotFound($"Booking with ID {bookingId} not found.");
            }

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId) || booking.LaundryAgentID != agentId)
            {
                return Forbid();
            }

            var agent = await _context.LaundryAgents.FindAsync(agentId);
            if (agent != null && agent.IsStoreClosed)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { message = "Ø§Ù„Ù…ØºØ³Ù„Ø© Ù…ØºÙ„Ù‚Ø© Ø­Ø§Ù„ÙŠØ§Ù‹. Ù„Ø§ ÙŠÙ…ÙƒÙ† Ù…Ø¹Ø§Ù„Ø¬Ø© Ø§Ù„Ø·Ù„Ø¨Ø§Øª." });
            }

            if (booking.BookingItems.Any(bi => bi.ServiceCatalogItem.DeliveryModel == DeliveryModel.TwoStage))
            {
                return BadRequest("Two-stage bookings are completed after the delivery-to-client task is completed.");
            }

            if (booking.Status != BookingStatus.Accepted && booking.Status != BookingStatus.InProgress && booking.Status != BookingStatus.Ready)
            {
                return BadRequest("Only accepted, in-progress, or ready technician dispatch bookings can be completed.");
            }

            booking.Status = BookingStatus.Completed;
            await _context.SaveChangesAsync();

            return Ok(new { booking.BookingID, booking.Status });
        }

        // POST: /api/bookings/toggle-store-status
        [HttpPost("toggle-store-status")]
        [Authorize(Roles = "LaundryAgent")]
        public async Task<IActionResult> ToggleStoreStatus()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId))
            {
                return Unauthorized();
            }

            var agent = await _context.LaundryAgents.FindAsync(agentId);
            if (agent == null)
            {
                return NotFound(new { message = "وكيل الغسيل غير موجود." });
            }

            agent.IsStoreClosed = !agent.IsStoreClosed;
            await _context.SaveChangesAsync();

            return Ok(new { isStoreClosed = agent.IsStoreClosed, message = agent.IsStoreClosed ? "تم إغلاق المغسلة بنجاح." : "تم فتح المغسلة بنجاح." });
        }

        // GET: /api/bookings/store-status
        [HttpGet("store-status")]
        [Authorize(Roles = "LaundryAgent")]
        public async Task<IActionResult> GetStoreStatus()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var agentId))
            {
                return Unauthorized();
            }

            var agent = await _context.LaundryAgents.FindAsync(agentId);
            if (agent == null)
            {
                return NotFound(new { message = "وكيل الغسيل غير موجود." });
            }

            return Ok(new { isStoreClosed = agent.IsStoreClosed });
        }

        // POST: /api/bookings/{id}/rate
        [HttpPost("{id}/rate")]
        [Authorize(Roles = "Client")]
        public async Task<IActionResult> RateBooking(int id, [FromBody] RateBookingDto dto)
        {
            // Extract ClientID securely from JWT claims
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var clientId))
            {
                return Unauthorized();
            }

            // Load booking with existing rating
            var booking = await _context.Bookings
                .Include(b => b.Rating)
                .FirstOrDefaultAsync(b => b.BookingID == id);

            if (booking == null)
            {
                return NotFound(new { message = $"الحجز ذو المعرّف {id} غير موجود." });
            }

            // Validate ownership
            if (booking.ClientID != clientId)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { message = "غير مسموح: هذا الحجز لا ينتمي لحسابك." });
            }

            // Validate booking is Completed
            if (booking.Status != BookingStatus.Completed)
            {
                return BadRequest(new { message = "لا يمكن تقييم حجز إلا بعد اكتمال تنفيذه (الحالة: Completed)." });
            }

            // Prevent duplicate ratings
            if (booking.Rating != null)
            {
                return Conflict(new { message = "تم تقييم هذا الحجز مسبقاً." });
            }

            // Validate AgentRating range (1-5)
            if (dto.AgentRating.HasValue && (dto.AgentRating.Value < 1 || dto.AgentRating.Value > 5))
            {
                return BadRequest(new { message = "تقييم الوكيل يجب أن يكون بين 1 و 5." });
            }

            // Validate DeliveryRating range (1-5)
            if (dto.DeliveryRating.HasValue && (dto.DeliveryRating.Value < 1 || dto.DeliveryRating.Value > 5))
            {
                return BadRequest(new { message = "تقييم التوصيل يجب أن يكون بين 1 و 5." });
            }

            var rating = new BookingRating
            {
                BookingID = id,
                AgentRating = dto.AgentRating,
                AgentComment = dto.AgentComment,
                DeliveryRating = dto.DeliveryRating,
                DeliveryComment = dto.DeliveryComment,
                RatedAt = DateTime.UtcNow
            };

            _context.BookingRatings.Add(rating);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                ratingID = rating.RatingID,
                bookingID = rating.BookingID,
                message = "شكراً! تم إرسال تقييمك بنجاح."
            });
        }
    }

    public class SubmitBookingDto
    {
        public int BookingID { get; set; }
        public DateTime? ScheduledAt { get; set; }
        public string? SpecialInstructions { get; set; }
    }

    public class CreateBookingDto
    {
        public int LaundryAgentID { get; set; }
        public System.Collections.Generic.List<CreateBookingItemDto> Items { get; set; } = new();
        public int? AddressID { get; set; }
        public DateTime? ScheduledAt { get; set; }
        public string? SpecialInstructions { get; set; }
    }

    public class CreateBookingItemDto
    {
        public int ServiceID { get; set; }
        public int Quantity { get; set; }
    }

    public class RateBookingDto
    {
        public int? AgentRating { get; set; }
        public string? AgentComment { get; set; }
        public int? DeliveryRating { get; set; }
        public string? DeliveryComment { get; set; }
    }

    public class RejectBookingDto
    {
        public string? Reason { get; set; }
    }
}

