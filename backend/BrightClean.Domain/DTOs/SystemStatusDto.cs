using System;

namespace BrightClean.Domain.DTOs
{
    public class SystemStatusDto
    {
        public bool LoginEnabled { get; set; }
        public string? Message { get; set; }
        public DateTime ChangedAt { get; set; }
    }
}
