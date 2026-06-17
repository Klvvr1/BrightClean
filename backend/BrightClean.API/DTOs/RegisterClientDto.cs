using System;
using System.ComponentModel.DataAnnotations;
using BrightClean.Domain.Enums;

namespace BrightClean.API.DTOs
{
    public class RegisterClientDto
    {
        [Required]
        [MinLength(1, ErrorMessage = "First name cannot be empty or whitespace.")]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MinLength(1, ErrorMessage = "Last name cannot be empty or whitespace.")]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [RegularExpression(@"^[a-zA-Z0-9._%+-]+@(gmail\.com|hotmail\.com|yahoo\.com|outlook\.com)$", ErrorMessage = "Only gmail.com, hotmail.com, yahoo.com, and outlook.com email domains are allowed.")]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MinLength(6, ErrorMessage = "Password must be at least 6 characters.")]
        public string Password { get; set; } = string.Empty;

        [Required]
        [RegularExpression(@"^(77|78|73|71|70)[0-9]{7}$", ErrorMessage = "رقم الهاتف يجب أن يتكون من 9 أرقام ويبدأ بـ (77, 78, 73, 71, 70).")]
        public string PhoneNo { get; set; } = string.Empty;

        [Required]
        public DateTime DateOfBirth { get; set; }

        [Required]
        public Gender Gender { get; set; }

        [Required]
        [MinLength(1, ErrorMessage = "Address area cannot be empty or whitespace.")]
        public string Area { get; set; } = string.Empty;

        [Required]
        [MinLength(1, ErrorMessage = "Address street cannot be empty or whitespace.")]
        public string Street { get; set; } = string.Empty;

        [Required]
        [Range(-90, 90, ErrorMessage = "Latitude must be between -90 and 90.")]
        public decimal Latitude { get; set; }

        [Required]
        [Range(-180, 180, ErrorMessage = "Longitude must be between -180 and 180.")]
        public decimal Longitude { get; set; }
    }
}
