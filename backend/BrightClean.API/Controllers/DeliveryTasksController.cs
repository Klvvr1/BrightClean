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
                    (t.StageNumber == 2 && _context.DeliveryTasks.Any(prev =>
                        prev.BookingID == t.BookingID &&
                        prev.StageNumber == 1 &&
                        prev.Status == DeliveryTaskStatus.Completed))))
                .ToListAsync();

            return Ok(pool);
        }

        // POST: /api/deliverytasks/{taskId}/claim
        [HttpPost("{taskId}/claim")]
        public async Task<IActionResult> ClaimTask(int taskId, [FromBody] ClaimTaskDto dto)
        {
            var task = await _context.DeliveryTasks.FindAsync(taskId);

            if (task == null)
            {
                return NotFound($"Delivery task with ID {taskId} not found.");
            }

            if (task.Status != DeliveryTaskStatus.Unassigned)
            {
                return BadRequest("Task is not in Unassigned status and cannot be claimed.");
            }

            task.DeliveryStaffID = dto.DeliveryStaffID;
            task.Status = DeliveryTaskStatus.Assigned;
            task.AssignedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

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
