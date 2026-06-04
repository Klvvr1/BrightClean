using System;
using System.ComponentModel.DataAnnotations;

namespace BrightClean.API.DTOs
{
    public class RegisterAgentDto
    {
        [Required]
        [MinLength(1, ErrorMessage = "First name cannot be empty or whitespace.")]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MinLength(1, ErrorMessage = "Last name cannot be empty or whitespace.")]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [RegularExpression(@"^[a-zA-Z0-9._%+-]+@(?i:gmail\.com|hotmail\.com|yahoo\.com|outlook\.com)$", ErrorMessage = "Only gmail.com, hotmail.com, yahoo.com, and outlook.com email domains are allowed.")]
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
        [MinLength(1, ErrorMessage = "Father name cannot be empty or whitespace.")]
        public string FatherName { get; set; } = string.Empty;

        [Required]
        [MinLength(1, ErrorMessage = "Grandfather name cannot be empty or whitespace.")]
        public string GrandfatherName { get; set; } = string.Empty;

        [Required]
        public string NationalIDNumber { get; set; } = string.Empty;

        [Required]
        [MinLength(1, ErrorMessage = "Business name cannot be empty or whitespace.")]
        public string BusinessName { get; set; } = string.Empty;

        [Required]
        public string CommercialRegister { get; set; } = string.Empty;

        [Required]
        public string BankAcc { get; set; } = string.Empty;

        // Address details
        [Required]
        public string Area { get; set; } = string.Empty;

        [Required]
        public string Street { get; set; } = string.Empty;

        [Required]
        public decimal Latitude { get; set; }

        [Required]
        public decimal Longitude { get; set; }

        // Comma-separated ServiceCategory numeric values selected by the agent UI.
        // Example: "0,3" means Laundry and VehicleWash.
        public string? SelectedServiceCategories { get; set; }
    }
}
