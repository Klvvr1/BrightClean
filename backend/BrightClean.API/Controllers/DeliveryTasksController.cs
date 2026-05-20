using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BrightClean.Infrastructure;
using BrightClean.Domain.Entities;
using BrightClean.Domain.Enums;

namespace BrightClean.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DeliveryTasksController : ControllerBase
    {
        private readonly AppDbContext _context;

        public DeliveryTasksController(AppDbContext context)
        {
            _context = context;
        }

        // GET: /api/deliverytasks/pool
        [HttpGet("pool")]
        public async Task<IActionResult> GetTaskPool()
        {
            var pool = await _context.DeliveryTasks
                .Include(t => t.Booking)
                .Include(t => t.PickupAddress)
                .Include(t => t.DropoffAddress)
                .Where(t => t.Status == DeliveryTaskStatus.Unassigned &&
                    (t.StageNumber == 1 ||
                    (t.StageNumber == 2 &&
                     _context.DeliveryTasks.Any(prev =>
                        prev.BookingID == t.BookingID &&
                        prev.StageNumber == 1 &&
                        prev.Status == DeliveryTaskStatus.Completed) &&
                     _context.Bookings.Any(b => b.BookingID == t.BookingID && b.Status == BookingStatus.Ready))))
                .ToListAsync();

            return Ok(pool);
        }

        // POST: /api/deliverytasks/{taskId}/claim
        [HttpPost("{taskId}/claim")]
        public async Task<IActionResult> ClaimTask(int taskId, [FromBody] ClaimTaskDto dto)
        {
            // Verify delivery staff exists
            var staff = await _context.DeliveryStaffs.FindAsync(dto.DeliveryStaffID);
            if (staff == null)
            {
                return NotFound($"Delivery staff with ID {dto.DeliveryStaffID} not found.");
            }

            // Atomic conditional update
            var assignedAt = DateTime.UtcNow;
            var rowsAffected = await _context.Database.ExecuteSqlInterpolatedAsync(
                $@"UPDATE DeliveryTasks
                   SET DeliveryStaffID = {dto.DeliveryStaffID},
                       Status = {(int)DeliveryTaskStatus.Assigned},
                       AssignedAt = {assignedAt}
                   WHERE TaskID = {taskId}
                     AND Status = {(int)DeliveryTaskStatus.Unassigned}"
            );

            if (rowsAffected == 0)
            {
                return Conflict("Task is not available for claiming or does not exist.");
            }

            // Retrieve the updated task
            var task = await _context.DeliveryTasks.FindAsync(taskId);

            return Ok(task);
        }

        // POST: /api/deliverytasks/{taskId}/complete
        [HttpPost("{taskId}/complete")]
        public async Task<IActionResult> CompleteTask(int taskId)
        {
            var task = await _context.DeliveryTasks
                .Include(t => t.Booking)
                .FirstOrDefaultAsync(t => t.TaskID == taskId);

            if (task == null)
            {
                return NotFound($"Delivery task with ID {taskId} not found.");
            }

            if (task.Status != DeliveryTaskStatus.Assigned)
            {
                return BadRequest("Only assigned tasks can be completed.");
            }

            task.Status = DeliveryTaskStatus.Completed;
            task.CompletedAt = DateTime.UtcNow;

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
}
