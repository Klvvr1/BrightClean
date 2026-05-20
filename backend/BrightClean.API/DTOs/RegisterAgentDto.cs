using System;
using System.ComponentModel.DataAnnotations;

namespace BrightClean.API.DTOs
{
    public class RegisterAgentDto
    {
        [Required]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MinLength(6, ErrorMessage = "Password must be at least 6 characters.")]
        public string Password { get; set; } = string.Empty;

        [Required]
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
    }
}
