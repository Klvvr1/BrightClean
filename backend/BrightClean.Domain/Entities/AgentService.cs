using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using BrightClean.Domain.Enums;

namespace BrightClean.Domain.Entities
{
    public class AgentService
    {
        [Key]
        public int AgentServiceID { get; set; }

        [Required]
        public int LaundryAgentID { get; set; }

        [ForeignKey(nameof(LaundryAgentID))]
        public virtual LaundryAgent LaundryAgent { get; set; } = null!;

        [Required]
        public int ServiceID { get; set; }

        [ForeignKey(nameof(ServiceID))]
        public virtual ServiceCatalogItem ServiceCatalogItem { get; set; } = null!;

        [Required]
        public bool IsActive { get; set; } = false;

        [Required]
        public bool PendingActivation { get; set; } = true;

        [Required]
        public AgentServiceRequestedAction RequestedAction { get; set; } = AgentServiceRequestedAction.None;

        public DateTime? ActivatedAt { get; set; }

        public string? Notes { get; set; }
    }
}
