using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using BrightClean.Domain.Enums;

namespace BrightClean.Domain.Entities
{
    public class Client : User
    {
        [Required]
        public Gender Gender { get; set; }

        [Required]
        public decimal WalletBalance { get; set; } = 0m;

        // Navigation Properties
        public virtual ICollection<Address> Addresses { get; set; }
        public virtual ICollection<Booking> Bookings { get; set; }

        public Client()
        {
            Role = UserRole.Client;
            IsApproved = true;
            Addresses = new HashSet<Address>();
            Bookings = new HashSet<Booking>();
        }
    }
}
