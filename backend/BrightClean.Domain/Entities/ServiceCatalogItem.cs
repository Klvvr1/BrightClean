using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using BrightClean.Domain.Enums;

namespace BrightClean.Domain.Entities
{
    public class ServiceCatalogItem
    {
        [Key]
        public int ServiceID { get; set; }

        [Required]
        public string ServiceName { get; set; } = string.Empty;

        [Required]
        public ServiceCategory Category { get; set; }

        [Required]
        public ServiceType Type { get; set; }

        [Required]
        public decimal Price { get; set; }

        [Required]
        public PricingModel PricingModel { get; set; }

        [Required]
        public DeliveryModel DeliveryModel { get; set; }

        [Required]
        public bool IsAvailable { get; set; } = true;

        [Required]
        public int AdminID { get; set; }

        [ForeignKey(nameof(AdminID))]
        public virtual Admin Admin { get; set; } = null!;

        // Navigation Properties
        public virtual ICollection<AgentService> AgentServices { get; set; }
        public virtual ICollection<BookingItem> BookingItems { get; set; }

        public ServiceCatalogItem()
        {
            AgentServices = new HashSet<AgentService>();
            BookingItems = new HashSet<BookingItem>();
        }
    }
}
