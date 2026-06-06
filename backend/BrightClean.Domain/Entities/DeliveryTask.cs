using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using BrightClean.Domain.Enums;

namespace BrightClean.Domain.Entities
{
    public class DeliveryTask
    {
        [Key]
        public int TaskID { get; set; }

        [Required]
        public int BookingID { get; set; }

        [ForeignKey(nameof(BookingID))]
        public virtual Booking Booking { get; set; } = null!;

        public int? DeliveryStaffID { get; set; }

        [ForeignKey(nameof(DeliveryStaffID))]
        public virtual DeliveryStaff? DeliveryStaff { get; set; }

        [Required]
        public int PickupAddressID { get; set; }

        [ForeignKey(nameof(PickupAddressID))]
        public virtual Address PickupAddress { get; set; } = null!;

        [Required]
        public int DropoffAddressID { get; set; }

        [ForeignKey(nameof(DropoffAddressID))]
        public virtual Address DropoffAddress { get; set; } = null!;

        [Required]
        public int StageNumber { get; set; }

        [Required]
        public TaskType Type { get; set; }

        [Required]
        public DeliveryTaskStatus Status { get; set; } = DeliveryTaskStatus.Unassigned;

        [Required]
        public decimal DeliveryFee { get; set; }

        public DateTime? AssignedAt { get; set; }

        [Required]
        public int CurrentStep { get; set; } = 0;

        public DateTime? StartedAt { get; set; }

        public DateTime? LastProgressUpdatedAt { get; set; }

        public DateTime? CompletedAt { get; set; }
    }
}
