using System;
using System.ComponentModel.DataAnnotations;
using BrightClean.Domain.Enums;

namespace BrightClean.API.DTOs
{
    public class RegisterDriverDto
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
        [MinLength(1, ErrorMessage = "Father name cannot be empty or whitespace.")]
        public string FatherName { get; set; } = string.Empty;

        [Required]
        [MinLength(1, ErrorMessage = "Grandfather name cannot be empty or whitespace.")]
        public string GrandfatherName { get; set; } = string.Empty;

        [Required]
        [RegularExpression(@"^[0-9]{11}$", ErrorMessage = "رقم الهوية الوطنية يجب أن يتكون من 11 رقماً.")]
        public string NationalIDNumber { get; set; } = string.Empty;

        [Required]
        public VehicleType VehicleType { get; set; }

        [Required]
        public string VehicleMake { get; set; } = string.Empty;

        [Required]
        public string VehicleModel { get; set; } = string.Empty;

        [Required]
        [RegularExpression(@"^[0-9]{1,6}$", ErrorMessage = "رقم اللوحة يجب أن يتكون من 1 إلى 6 أرقام.")]
        public string PlateNumber { get; set; } = string.Empty;

        [Required]
        [RegularExpression(@"^[0-9]{5,9}$", ErrorMessage = "رقم الحساب يجب أن يتكون من 5 إلى 9 أرقام (حسب البنك).")]
        public string BankAcc { get; set; } = string.Empty;
    }
}
