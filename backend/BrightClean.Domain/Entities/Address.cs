using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BrightClean.Domain.Entities
{
    public class Address
    {
        [Key]
        public int AddressID { get; set; }

        [Required]
        public string Area { get; set; } = string.Empty;

        [Required]
        public string Street { get; set; } = string.Empty;

        [Required]
        public decimal Latitude { get; set; }

        [Required]
        public decimal Longitude { get; set; }

        [Required]
        public bool IsArchived { get; set; } = false;

        // Foreign Key to Client (Optional, since LaundryAgent also has Address)
        public int? ClientID { get; set; }
        
        [ForeignKey(nameof(ClientID))]
        public virtual Client? Client { get; set; }

        // Navigation Properties
        public virtual ICollection<Booking> Bookings { get; set; }
        public virtual ICollection<DeliveryTask> PickupTasks { get; set; }
        public virtual ICollection<DeliveryTask> DropoffTasks { get; set; }

        public Address()
        {
            Bookings = new HashSet<Booking>();
            PickupTasks = new HashSet<DeliveryTask>();
            DropoffTasks = new HashSet<DeliveryTask>();
        }
    }
}
