using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BrightClean.Domain.Entities
{
    public class BookingRating
    {
        [Key]
        public int RatingID { get; set; }

        [Required]
        public int BookingID { get; set; }

        [ForeignKey(nameof(BookingID))]
        public virtual Booking Booking { get; set; } = null!;

        public int? AgentRating { get; set; }

        public string? AgentComment { get; set; }

        public int? DeliveryRating { get; set; }

        public string? DeliveryComment { get; set; }

        [Required]
        public DateTime RatedAt { get; set; } = DateTime.UtcNow;
    }
}
