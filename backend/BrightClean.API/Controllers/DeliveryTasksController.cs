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
using BrightClean.Domain.Enums;

namespace BrightClean.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "DeliveryStaff")]
    public class DeliveryTasksController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ILogger<DeliveryTasksController> _logger;

        public DeliveryTasksController(AppDbContext context, ILogger<DeliveryTasksController> logger)
        {
            _context = context;
            _logger = logger;
        }

        private static int MaxStepForTask(DeliveryTask task)
        {
            return task.Type == TaskType.PickupFromClient ? 3 : 2;
        }

        private static object ProjectTaskDetails(DeliveryTask task)
        {
            return new
            {
                task.TaskID,
                task.BookingID,
                task.DeliveryStaffID,
                task.PickupAddressID,
                task.DropoffAddressID,
                task.StageNumber,
                task.Type,
                task.Status,
                task.DeliveryFee,
                task.AssignedAt,
                task.CurrentStep,
                task.StartedAt,
                task.LastProgressUpdatedAt,
                task.CompletedAt,
                pickupAddress = new
                {
                    task.PickupAddress.AddressID,
                    task.PickupAddress.Area,
                    task.PickupAddress.Street,
                    task.PickupAddress.Latitude,
                    task.PickupAddress.Longitude
                },
                dropoffAddress = new
                {
                    task.DropoffAddress.AddressID,
                    task.DropoffAddress.Area,
                    task.DropoffAddress.Street,
                    task.DropoffAddress.Latitude,
                    task.DropoffAddress.Longitude
                },
                booking = new
                {
                    task.Booking.BookingID,
                    task.Booking.Status,
                    task.Booking.FinalTotal,
                    task.Booking.CreatedAt,
                    task.Booking.ScheduledAt,
                    task.Booking.SpecialInstructions,
                    client = new
                    {
                        task.Booking.Client.UserID,
                        task.Booking.Client.FirstName,
                        task.Booking.Client.LastName,
                        task.Booking.Client.PhoneNo
                    },
                    laundryAgent = new
                    {
                        task.Booking.LaundryAgent.UserID,
                        task.Booking.LaundryAgent.BusinessName,
                        task.Booking.LaundryAgent.PhoneNo
                    },
                    bookingItems = task.Booking.BookingItems.Select(i => new
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
                            i.ServiceCatalogItem.DeliveryModel
                        }
                    })
                }
            };
        }

        private async Task<bool> IsTaskAvailableForDriverAsync(DeliveryTask task)
        {
            if (task.Status != DeliveryTaskStatus.Unassigned)
            {
                return false;
            }

            if (task.StageNumber == 1)
            {
                return true;
            }

            return await _context.DeliveryTasks.AnyAsync(prev =>
                       prev.BookingID == task.BookingID &&
                       prev.StageNumber == 1 &&
                       prev.Status == DeliveryTaskStatus.Completed) &&
                   await _context.Bookings.AnyAsync(b =>
                       b.BookingID == task.BookingID &&
                       b.Status == BookingStatus.Ready);
        }

        // GET: /api/deliverytasks/availability
        [HttpGet("availability")]
        public async Task<IActionResult> GetAvailability()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var driverId))
            {
                return Unauthorized(new { message = "Invalid token." });
            }

            var driver = await _context.DeliveryStaffs
                .AsNoTracking()
                .Where(d => d.UserID == driverId)
                .Select(d => new { d.IsAvailable })
                .FirstOrDefaultAsync();

            if (driver == null)
            {
                return NotFound(new { message = "Delivery staff profile was not found." });
            }

            return Ok(new { isAvailable = driver.IsAvailable });
        }

        // PATCH: /api/deliverytasks/availability
        [HttpPatch("availability")]
        public async Task<IActionResult> UpdateAvailability([FromBody] DriverAvailabilityRequest request)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var driverId))
            {
                return Unauthorized(new { message = "Invalid token." });
            }

            var driver = await _context.DeliveryStaffs.FirstOrDefaultAsync(d => d.UserID == driverId);
            if (driver == null)
            {
                return NotFound(new { message = "Delivery staff profile was not found." });
            }

            driver.IsAvailable = request.IsAvailable;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Delivery staff {DriverId} availability changed to {IsAvailable}.", driverId, request.IsAvailable);

            return Ok(new { isAvailable = driver.IsAvailable });
        }

        // GET: /api/deliverytasks/my
        [HttpGet("my")]
        public async Task<IActionResult> GetMyTasks()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var driverId))
            {
                return Unauthorized(new { message = "Invalid token." });
            }

            var tasks = await _context.DeliveryTasks
                .AsNoTracking()
                .Include(t => t.PickupAddress)
                .Include(t => t.DropoffAddress)
                .Include(t => t.Booking).ThenInclude(b => b.Client)
                .Include(t => t.Booking).ThenInclude(b => b.LaundryAgent)
                .Include(t => t.Booking).ThenInclude(b => b.BookingItems).ThenInclude(i => i.ServiceCatalogItem)
                .Where(t => t.DeliveryStaffID == driverId)
                .OrderByDescending(t => t.CompletedAt ?? t.LastProgressUpdatedAt ?? t.AssignedAt ?? DateTime.MinValue)
                .ToListAsync();

            _logger.LogInformation("Loaded {TaskCount} delivery tasks for driver {DriverId}.", tasks.Count, driverId);

            return Ok(tasks.Select(ProjectTaskDetails));
        }

        // GET: /api/deliverytasks/pool
        [HttpGet("pool")]
        public async Task<IActionResult> GetTaskPool()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var driverId))
            {
                return Unauthorized();
            }

            var pool = await _context.DeliveryTasks
                .Include(t => t.Booking)
                .Include(t => t.PickupAddress)
                .Include(t => t.DropoffAddress)
                .Where(t => (t.Status == DeliveryTaskStatus.Unassigned &&
                    (t.StageNumber == 1 ||
                    (t.StageNumber == 2 &&
                     _context.DeliveryTasks.Any(prev =>
                        prev.BookingID == t.BookingID &&
                        prev.StageNumber == 1 &&
                        prev.Status == DeliveryTaskStatus.Completed) &&
                     _context.Bookings.Any(b => b.BookingID == t.BookingID && b.Status == BookingStatus.Ready)))) ||
                    ((t.Status == DeliveryTaskStatus.Assigned || t.Status == DeliveryTaskStatus.InProgress) &&
                     t.DeliveryStaffID == driverId))
                .ToListAsync();

            return Ok(pool);
        }

        // GET: /api/deliverytasks/{taskId}
        [HttpGet("{taskId}")]
        public async Task<IActionResult> GetTaskDetails(int taskId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var driverId))
            {
                return Unauthorized();
            }

            var task = await _context.DeliveryTasks
                .AsNoTracking()
                .Include(t => t.PickupAddress)
                .Include(t => t.DropoffAddress)
                .Include(t => t.Booking)
                    .ThenInclude(b => b.Client)
                .Include(t => t.Booking)
                    .ThenInclude(b => b.LaundryAgent)
                .Include(t => t.Booking)
                    .ThenInclude(b => b.BookingItems)
                        .ThenInclude(i => i.ServiceCatalogItem)
                .FirstOrDefaultAsync(t => t.TaskID == taskId);

            if (task == null)
            {
                return NotFound($"Delivery task with ID {taskId} not found.");
            }

            if (task.DeliveryStaffID.HasValue && task.DeliveryStaffID.Value != driverId)
            {
                return Forbid();
            }

            if (!task.DeliveryStaffID.HasValue && !await IsTaskAvailableForDriverAsync(task))
            {
                return Forbid();
            }

            return Ok(ProjectTaskDetails(task));
        }

        // POST: /api/deliverytasks/{taskId}/claim
        [HttpPost("{taskId}/claim")]
        public async Task<IActionResult> ClaimTask(int taskId, [FromBody] ClaimTaskDto? dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var driverId))
            {
                return Unauthorized();
            }

            // Verify delivery staff exists
            var staff = await _context.DeliveryStaffs.FindAsync(driverId);
            if (staff == null)
            {
                return NotFound($"Delivery staff with ID {driverId} not found.");
            }

            // Atomic conditional update
            var assignedAt = DateTime.UtcNow;
            var rowsAffected = await _context.Database.ExecuteSqlInterpolatedAsync(
                $@"UPDATE DeliveryTasks
                   SET DeliveryStaffID = {driverId},
                       Status = {(int)DeliveryTaskStatus.Assigned},
                       AssignedAt = {assignedAt}
                   WHERE TaskID = {taskId}
                     AND Status = {(int)DeliveryTaskStatus.Unassigned}
                     AND (
                        StageNumber = 1
                        OR (
                            StageNumber = 2
                            AND EXISTS (
                                SELECT 1
                                FROM DeliveryTasks previousTask
                                WHERE previousTask.BookingID = DeliveryTasks.BookingID
                                  AND previousTask.StageNumber = 1
                                  AND previousTask.Status = {(int)DeliveryTaskStatus.Completed}
                            )
                            AND EXISTS (
                                SELECT 1
                                FROM Bookings booking
                                WHERE booking.BookingID = DeliveryTasks.BookingID
                                  AND booking.Status = {(int)BookingStatus.Ready}
                            )
                        )
                     )"
            );

            if (rowsAffected == 0)
            {
                return Conflict("Task is not available for claiming or does not exist.");
            }

            // Retrieve the updated task
            var task = await _context.DeliveryTasks.FindAsync(taskId);

            return Ok(task);
        }

        // POST: /api/deliverytasks/{taskId}/start
        [HttpPost("{taskId}/start")]
        public async Task<IActionResult> StartTask(int taskId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var driverId))
            {
                return Unauthorized();
            }

            var task = await _context.DeliveryTasks.FindAsync(taskId);

            if (task == null)
            {
                return NotFound($"Delivery task with ID {taskId} not found.");
            }

            if (task.DeliveryStaffID != driverId)
            {
                return Forbid();
            }

            if (task.Status != DeliveryTaskStatus.Assigned)
            {
                return BadRequest("Only assigned tasks can be started.");
            }

            var now = DateTime.UtcNow;
            task.Status = DeliveryTaskStatus.InProgress;
            task.StartedAt ??= now;
            task.LastProgressUpdatedAt = now;

            await _context.SaveChangesAsync();

            return Ok(task);
        }

        // PATCH: /api/deliverytasks/{taskId}/progress
        [HttpPatch("{taskId}/progress")]
        public async Task<IActionResult> UpdateTaskProgress(int taskId, [FromBody] UpdateTaskProgressDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var driverId))
            {
                return Unauthorized();
            }

            var task = await _context.DeliveryTasks.FindAsync(taskId);

            if (task == null)
            {
                return NotFound($"Delivery task with ID {taskId} not found.");
            }

            if (task.DeliveryStaffID != driverId)
            {
                return Forbid();
            }

            if (task.Status != DeliveryTaskStatus.Assigned && task.Status != DeliveryTaskStatus.InProgress)
            {
                return BadRequest("Only assigned or in-progress tasks can be updated.");
            }

            var maxStep = MaxStepForTask(task);
            if (dto.CurrentStep < 0 || dto.CurrentStep > maxStep)
            {
                return BadRequest($"CurrentStep must be between 0 and {maxStep} for this task.");
            }

            if (dto.CurrentStep < task.CurrentStep)
            {
                return BadRequest("Task progress cannot move backward.");
            }

            if (dto.CurrentStep > task.CurrentStep + 1)
            {
                return BadRequest("Task progress must be updated one step at a time.");
            }

            var now = DateTime.UtcNow;
            task.CurrentStep = dto.CurrentStep;
            task.LastProgressUpdatedAt = now;
            if (task.Status == DeliveryTaskStatus.Assigned && dto.CurrentStep > 0)
            {
                task.Status = DeliveryTaskStatus.InProgress;
                task.StartedAt ??= now;
            }

            await _context.SaveChangesAsync();

            return Ok(task);
        }

        // POST: /api/deliverytasks/{taskId}/complete
        [HttpPost("{taskId}/complete")]
        public async Task<IActionResult> CompleteTask(int taskId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var driverId))
            {
                return Unauthorized();
            }

            var task = await _context.DeliveryTasks
                .Include(t => t.Booking)
                .FirstOrDefaultAsync(t => t.TaskID == taskId);

            if (task == null)
            {
                return NotFound($"Delivery task with ID {taskId} not found.");
            }

            // Verify task belongs to the logged-in driver
            if (task.DeliveryStaffID != driverId)
            {
                return Forbid();
            }

            if (task.Status != DeliveryTaskStatus.Assigned && task.Status != DeliveryTaskStatus.InProgress)
            {
                return BadRequest("Only assigned or in-progress tasks can be completed.");
            }

            task.Status = DeliveryTaskStatus.Completed;
            task.CompletedAt = DateTime.UtcNow;
            task.CurrentStep = MaxStepForTask(task);
            task.LastProgressUpdatedAt = task.CompletedAt;

            // State Machine transitions based on logistics stage
            if (task.StageNumber == 1)
            {
                // Stage 1 (Pickup completed): Clothes are now at the laundry agent, work starts
                task.Booking.Status = BookingStatus.InProgress;
            }
            else if (task.StageNumber == 2)
            {
                // Stage 2 (Delivery completed): Order is fully delivered
                task.Booking.Status = BookingStatus.Completed;
            }

            await _context.SaveChangesAsync();

            return Ok(task);
        }
    }

    public class ClaimTaskDto
    {
        public int DeliveryStaffID { get; set; }
    }

    public class UpdateTaskProgressDto
    {
        public int CurrentStep { get; set; }
    }

    public class DriverAvailabilityRequest
    {
        public bool IsAvailable { get; set; }
    }
}
