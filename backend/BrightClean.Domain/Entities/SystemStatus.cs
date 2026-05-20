using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BrightClean.Domain.Entities
{
    public class SystemStatus
    {
        [Key]
        public int StatusID { get; set; }

        [Required]
        public bool LoginEnabled { get; set; }

        public string? Message { get; set; }

        [Required]
        public DateTime ChangedAt { get; set; } = DateTime.UtcNow;

        [Required]
        public int AdminID { get; set; }

        [ForeignKey(nameof(AdminID))]
        public virtual Admin Admin { get; set; } = null!;
    }
}
