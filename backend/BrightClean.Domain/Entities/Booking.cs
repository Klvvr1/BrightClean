using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using BrightClean.Domain.Enums;

namespace BrightClean.Domain.Entities
{
    public class Booking
    {
        [Key]
        public int BookingID { get; set; }

        [Required]
        public int ClientID { get; set; }

        [ForeignKey(nameof(ClientID))]
        public virtual Client Client { get; set; } = null!;

        [Required]
        public int LaundryAgentID { get; set; }

        [ForeignKey(nameof(LaundryAgentID))]
        public virtual LaundryAgent LaundryAgent { get; set; } = null!;

        [Required]
        public int AddressID { get; set; }

        [ForeignKey(nameof(AddressID))]
        public virtual Address Address { get; set; } = null!;

        public int? OfferID { get; set; }

        [ForeignKey(nameof(OfferID))]
        public virtual Offer? Offer { get; set; }

        [Required]
        public BookingStatus Status { get; set; } = BookingStatus.Draft;

        public decimal? FinalTotal { get; set; }

        [Timestamp]
        public byte[]? RowVersion { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? ExpiresAt { get; set; }

        public DateTime? ScheduledAt { get; set; }

        public string? SpecialInstructions { get; set; }

        // Navigation Properties (One-to-One reference properties are virtual)
        public virtual BookingRating? Rating { get; set; }
        public virtual Payment? Payment { get; set; }

        public virtual ICollection<BookingItem> BookingItems { get; set; }
        public virtual ICollection<DeliveryTask> DeliveryTasks { get; set; }

        public Booking()
        {
            BookingItems = new HashSet<BookingItem>();
            DeliveryTasks = new HashSet<DeliveryTask>();
        }
    }
}
