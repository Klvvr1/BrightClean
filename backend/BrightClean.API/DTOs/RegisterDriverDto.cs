using System;
using System.ComponentModel.DataAnnotations;
using BrightClean.Domain.Enums;

namespace BrightClean.API.DTOs
{
    public class RegisterDriverDto
    {
        [Required]
        public string FirstName { get; set; } = string.Empty;

        [Required]
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
    }
}
