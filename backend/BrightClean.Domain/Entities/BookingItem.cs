using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using BrightClean.Domain.Enums;

namespace BrightClean.Domain.Entities
{
    public class BookingItem
    {
        [Key]
        public int BookingItemID { get; set; }

        [Required]
        public int BookingID { get; set; }

        [ForeignKey(nameof(BookingID))]
        public virtual Booking Booking { get; set; } = null!;

        [Required]
        public int ServiceID { get; set; }

        [ForeignKey(nameof(ServiceID))]
        public virtual ServiceCatalogItem ServiceCatalogItem { get; set; } = null!;

        [Required]
        public int Quantity { get; set; }

        [Required]
        public decimal UnitPriceAtTimeOfBooking { get; set; }

        [NotMapped]
        public decimal SubTotal
        {
            get
            {
                if (ServiceCatalogItem == null)
                {
                    return Quantity * UnitPriceAtTimeOfBooking;
                }
                return ServiceCatalogItem.PricingModel == PricingModel.PerItem
                    ? Quantity * UnitPriceAtTimeOfBooking
                    : UnitPriceAtTimeOfBooking;
            }
        }
    }
}
