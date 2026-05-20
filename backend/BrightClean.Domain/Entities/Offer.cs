using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using BrightClean.Domain.Enums;

namespace BrightClean.Domain.Entities
{
    public class Offer
    {
        [Key]
        public int OfferID { get; set; }

        [Required]
        public string OfferCode { get; set; } = string.Empty;

        [Required]
        public OfferType Type { get; set; }

        [Required]
        public OfferScope Scope { get; set; }

        [Required]
        public decimal DiscountValue { get; set; }

        [Required]
        public DateTime StartDate { get; set; }

        [Required]
        public DateTime EndDate { get; set; }

        public decimal? MinOrderValue { get; set; }

        public int? MaxUsageCount { get; set; }

        [Required]
        public int UsageCount { get; set; } = 0;

        public int? LaundryAgentID { get; set; }

        [ForeignKey(nameof(LaundryAgentID))]
        public virtual LaundryAgent? ScopedAgent { get; set; }

        [Required]
        public int AdminID { get; set; }

        [ForeignKey(nameof(AdminID))]
        public virtual Admin CreatorAdmin { get; set; } = null!;

        [NotMapped]
        public bool IsValid
        {
            get
            {
                var now = DateTime.UtcNow;
                return now >= StartDate && 
                       now <= EndDate && 
                       (!MaxUsageCount.HasValue || UsageCount < MaxUsageCount.Value);
            }
        }

        // Navigation Properties
        public virtual ICollection<Booking> Bookings { get; set; }

        public Offer()
        {
            Bookings = new HashSet<Booking>();
        }
    }
}
