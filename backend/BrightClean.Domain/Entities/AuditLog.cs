using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BrightClean.Domain.Entities
{
    public class AuditLog
    {
        [Key]
        public int LogID { get; set; }

        [Required]
        public int AdminID { get; set; }

        [ForeignKey(nameof(AdminID))]
        public virtual Admin Admin { get; set; } = null!;

        [Required]
        public string Action { get; set; } = string.Empty;

        [Required]
        public string TargetEntity { get; set; } = string.Empty;

        [Required]
        public int TargetID { get; set; }

        [Required]
        public DateTime PerformedAt { get; set; } = DateTime.UtcNow;
    }
}
