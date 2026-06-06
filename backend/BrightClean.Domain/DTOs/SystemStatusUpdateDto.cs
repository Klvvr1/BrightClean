using System;
using System.ComponentModel.DataAnnotations;

namespace BrightClean.Domain.DTOs
{
    public class SystemStatusUpdateDto
    {
        [Required]
        public bool LoginEnabled { get; set; }

        public string? Message { get; set; }
    }
}
