using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using BrightClean.Domain.Enums;

namespace BrightClean.Domain.Entities
{
    public abstract class User
    {
        [Key]
        public int UserID { get; set; }

        [Required]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [MaxLength(256)]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string PasswordHash { get; set; } = string.Empty;

        [Required]
        [MaxLength(20)]
        public string PhoneNo { get; set; } = string.Empty;

        [Required]
        public DateTime DateOfBirth { get; set; }

        public string? ProfilePhotoURL { get; set; }

        [Required]
        public bool TermsAccepted { get; set; }

        [Required]
        public AccountStatus AccountStatus { get; set; } = AccountStatus.PendingVerification;

        [Required]
        public UserRole Role { get; set; }

        public DateTime? VerifiedAt { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation Property
        public virtual ICollection<UserDocument> Documents { get; set; }

        protected User()
        {
            Documents = new HashSet<UserDocument>();
        }
    }
}
