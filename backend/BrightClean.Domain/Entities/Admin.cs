using System;
using System.Collections.Generic;
using BrightClean.Domain.Enums;

namespace BrightClean.Domain.Entities
{
    public class Admin : User
    {
        public DateTime? LastLoginAt { get; set; }

        // Navigation Properties
        public virtual ICollection<ServiceCatalogItem> ManagedServices { get; set; }
        public virtual ICollection<Offer> CreatedOffers { get; set; }
        public virtual ICollection<AuditLog> AuditLogs { get; set; }
        public virtual ICollection<SystemStatus> SystemStatuses { get; set; }

        public Admin()
        {
            Role = UserRole.Admin;
            ManagedServices = new HashSet<ServiceCatalogItem>();
            CreatedOffers = new HashSet<Offer>();
            AuditLogs = new HashSet<AuditLog>();
            SystemStatuses = new HashSet<SystemStatus>();
        }
    }
}
