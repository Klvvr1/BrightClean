using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using BrightClean.Domain.Enums;

namespace BrightClean.Domain.Entities
{
    public class LaundryAgent : User
    {
        [Required]
        public string FatherName { get; set; } = string.Empty;

        [Required]
        public string GrandfatherName { get; set; } = string.Empty;

        [Required]
        [MaxLength(450)]
        public string NationalIDNumber { get; set; } = string.Empty;

        [Required]
        public string BusinessName { get; set; } = string.Empty;

        [Required]
        public string CommercialRegister { get; set; } = string.Empty;

        [Required]
        public string BankAcc { get; set; } = string.Empty;

        [Required]
        public bool IsStoreClosed { get; set; } = false;

        public int AddressID { get; set; }
        
        [ForeignKey(nameof(AddressID))]
        public virtual Address Address { get; set; } = null!;

        [NotMapped]
        public decimal AverageRating
        {
            get
            {
                if (Bookings == null || !Bookings.Any()) return 0m;

                var ratings = Bookings
                    .Where(b => b.Rating != null && b.Rating.AgentRating.HasValue)
                    .Select(b => b.Rating!.AgentRating!.Value)
                    .ToList();

                return ratings.Any() ? (decimal)ratings.Average() : 0m;
            }
        }

        [NotMapped]
        public int TotalRatings
        {
            get
            {
                if (Bookings == null) return 0;
                return Bookings
                    .Count(b => b.Rating != null && b.Rating.AgentRating.HasValue);
            }
        }

        // Navigation Properties
        public virtual ICollection<AgentService> SubscribedServices { get; set; }
        public virtual ICollection<Booking> Bookings { get; set; }
        public virtual ICollection<Offer> ScopedOffers { get; set; }

        public LaundryAgent()
        {
            Role = UserRole.LaundryAgent;
            IsApproved = false;
            SubscribedServices = new HashSet<AgentService>();
            Bookings = new HashSet<Booking>();
            ScopedOffers = new HashSet<Offer>();
        }
    }
}
