using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using BrightClean.Domain.Enums;

namespace BrightClean.Domain.Entities
{
    public class DeliveryStaff : User
    {
        [Required]
        public string FatherName { get; set; } = string.Empty;

        [Required]
        public string GrandfatherName { get; set; } = string.Empty;

        [Required]
        public string NationalIDNumber { get; set; } = string.Empty;

        [Required]
        public VehicleType VehicleType { get; set; }

        [Required]
        public string VehicleMake { get; set; } = string.Empty;

        [Required]
        public string VehicleModel { get; set; } = string.Empty;

        [Required]
        public string PlateNumber { get; set; } = string.Empty;

        [Required]
        public string BankAcc { get; set; } = string.Empty;

        [NotMapped]
        public decimal AverageRating
        {
            get
            {
                if (DeliveryTasks == null || !DeliveryTasks.Any()) return 0m;
                
                var ratings = DeliveryTasks
                    .Where(t => t.Booking?.Rating != null && t.Booking.Rating.DeliveryRating.HasValue)
                    .Select(t => t.Booking.Rating!.DeliveryRating!.Value)
                    .ToList();

                return ratings.Any() ? (decimal)ratings.Average() : 0m;
            }
        }

        [NotMapped]
        public int TotalRatings
        {
            get
            {
                if (DeliveryTasks == null) return 0;
                return DeliveryTasks
                    .Count(t => t.Booking?.Rating != null && t.Booking.Rating.DeliveryRating.HasValue);
            }
        }

        // Navigation Properties
        public virtual ICollection<DeliveryTask> DeliveryTasks { get; set; }

        public DeliveryStaff()
        {
            Role = UserRole.DeliveryStaff;
            DeliveryTasks = new HashSet<DeliveryTask>();
        }
    }
}
