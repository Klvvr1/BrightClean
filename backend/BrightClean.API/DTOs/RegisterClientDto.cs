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
        [RegularExpression(@"^[0-9]{9}$", ErrorMessage = "Phone number must be exactly 9 digits.")]
        public string PhoneNo { get; set; } = string.Empty;

        [Required]
        public DateTime DateOfBirth { get; set; }

        [Required]
        public Gender Gender { get; set; }
    }
}
