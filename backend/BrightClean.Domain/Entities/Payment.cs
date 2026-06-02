using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using BrightClean.Domain.Enums;

namespace BrightClean.Domain.Entities
{
    public class Payment
    {
        [Key]
        public int PaymentID { get; set; }

        [Required]
        public int BookingID { get; set; }

        [ForeignKey(nameof(BookingID))]
        public virtual Booking Booking { get; set; } = null!;

        [Required]
        public decimal Amount { get; set; }

        [Required]
        public PaymentMethod Method { get; set; }

        [Required]
        public PaymentStatus Status { get; set; } = PaymentStatus.Pending;

        public string? TransactionRef { get; set; }

        public string? PaymentProofURL { get; set; }

        public string? StatusReason { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? PaidAt { get; set; }

        public DateTime? ReviewedAt { get; set; }

        public int? ReviewedByAdminID { get; set; }

        [ForeignKey(nameof(ReviewedByAdminID))]
        public virtual Admin? ReviewedByAdmin { get; set; }
    }
}
