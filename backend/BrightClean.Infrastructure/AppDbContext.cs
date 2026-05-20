using Microsoft.EntityFrameworkCore;
using System.Linq;
using BrightClean.Domain.Entities;

namespace BrightClean.Infrastructure
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        // DbSets for all 17 entities
        public DbSet<User> Users { get; set; } = null!;
        public DbSet<Client> Clients { get; set; } = null!;
        public DbSet<DeliveryStaff> DeliveryStaffs { get; set; } = null!;
        public DbSet<LaundryAgent> LaundryAgents { get; set; } = null!;
        public DbSet<Admin> Admins { get; set; } = null!;
        public DbSet<Address> Addresses { get; set; } = null!;
        public DbSet<UserDocument> UserDocuments { get; set; } = null!;
        public DbSet<ServiceCatalogItem> ServiceCatalogItems { get; set; } = null!;
        public DbSet<AgentService> AgentServices { get; set; } = null!;
        public DbSet<Offer> Offers { get; set; } = null!;
        public DbSet<Booking> Bookings { get; set; } = null!;
        public DbSet<BookingItem> BookingItems { get; set; } = null!;
        public DbSet<BookingRating> BookingRatings { get; set; } = null!;
        public DbSet<DeliveryTask> DeliveryTasks { get; set; } = null!;
        public DbSet<Payment> Payments { get; set; } = null!;
        public DbSet<AuditLog> AuditLogs { get; set; } = null!;
        public DbSet<SystemStatus> SystemStatuses { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // --- 1. TPT Inheritance Mapping ---
            modelBuilder.Entity<User>().ToTable("Users");
            modelBuilder.Entity<Client>().ToTable("Clients");
            modelBuilder.Entity<DeliveryStaff>().ToTable("DeliveryStaffs");
            modelBuilder.Entity<LaundryAgent>().ToTable("LaundryAgents");
            modelBuilder.Entity<Admin>().ToTable("Admins");

            // --- 2. Unique Constraints & Indexes ---
            
            // User unique fields
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasIndex(u => u.PhoneNo)
                .IsUnique();

            // DeliveryStaff unique fields
            modelBuilder.Entity<DeliveryStaff>()
                .HasIndex(d => d.NationalIDNumber)
                .IsUnique();

            modelBuilder.Entity<DeliveryStaff>()
                .HasIndex(d => d.PlateNumber)
                .IsUnique();

            // LaundryAgent unique fields
            modelBuilder.Entity<LaundryAgent>()
                .HasIndex(la => la.NationalIDNumber)
                .IsUnique();

            modelBuilder.Entity<LaundryAgent>()
                .HasIndex(la => la.CommercialRegister)
                .IsUnique();

            // AgentService composite unique index
            modelBuilder.Entity<AgentService>()
                .HasIndex(asvc => new { asvc.LaundryAgentID, asvc.ServiceID })
                .IsUnique();

            // Offer code unique
            modelBuilder.Entity<Offer>()
                .HasIndex(o => o.OfferCode)
                .IsUnique();

            // DeliveryTask uniqueness constraint for (BookingID, StageNumber)
            modelBuilder.Entity<DeliveryTask>()
                .HasIndex(dt => new { dt.BookingID, dt.StageNumber })
                .IsUnique();

            // Configure Booking RowVersion as concurrency token
            modelBuilder.Entity<Booking>()
                .Property(b => b.RowVersion)
                .IsRowVersion();

            // One-to-One Relationships
            modelBuilder.Entity<Booking>()
                .HasOne(b => b.Payment)
                .WithOne(p => p.Booking)
                .HasForeignKey<Payment>(p => p.BookingID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Booking>()
                .HasOne(b => b.Rating)
                .WithOne(r => r.Booking)
                .HasForeignKey<BookingRating>(r => r.BookingID)
                .OnDelete(DeleteBehavior.Cascade);

            // Enforce Unique Index in Db for 1-to-1 foreign keys explicitly
            modelBuilder.Entity<Payment>()
                .HasIndex(p => p.BookingID)
                .IsUnique();

            modelBuilder.Entity<BookingRating>()
                .HasIndex(r => r.BookingID)
                .IsUnique();

            // --- 3. Cascade Delete Protection (Restrict/NoAction) ---

            // Addresses Cascade Prevention
            modelBuilder.Entity<DeliveryTask>()
                .HasOne(dt => dt.PickupAddress)
                .WithMany(a => a.PickupTasks)
                .HasForeignKey(dt => dt.PickupAddressID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<DeliveryTask>()
                .HasOne(dt => dt.DropoffAddress)
                .WithMany(a => a.DropoffTasks)
                .HasForeignKey(dt => dt.DropoffAddressID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Booking>()
                .HasOne(b => b.Address)
                .WithMany(a => a.Bookings)
                .HasForeignKey(b => b.AddressID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<LaundryAgent>()
                .HasOne(la => la.Address)
                .WithMany()
                .HasForeignKey(la => la.AddressID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Address>()
                .HasOne(a => a.Client)
                .WithMany(c => c.Addresses)
                .HasForeignKey(a => a.ClientID)
                .OnDelete(DeleteBehavior.Restrict);

            // Core Relationships Cascade Prevention
            modelBuilder.Entity<Booking>()
                .HasOne(b => b.Client)
                .WithMany(c => c.Bookings)
                .HasForeignKey(b => b.ClientID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Booking>()
                .HasOne(b => b.LaundryAgent)
                .WithMany(la => la.Bookings)
                .HasForeignKey(b => b.LaundryAgentID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Booking>()
                .HasOne(b => b.Offer)
                .WithMany(o => o.Bookings)
                .HasForeignKey(b => b.OfferID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<DeliveryTask>()
                .HasOne(dt => dt.DeliveryStaff)
                .WithMany(ds => ds.DeliveryTasks)
                .HasForeignKey(dt => dt.DeliveryStaffID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<DeliveryTask>()
                .HasOne(dt => dt.Booking)
                .WithMany(b => b.DeliveryTasks)
                .HasForeignKey(dt => dt.BookingID)
                .OnDelete(DeleteBehavior.Cascade);

            // Other entity relationships
            modelBuilder.Entity<UserDocument>()
                .HasOne(ud => ud.User)
                .WithMany(u => u.Documents)
                .HasForeignKey(ud => ud.UserID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ServiceCatalogItem>()
                .HasOne(sci => sci.Admin)
                .WithMany(a => a.ManagedServices)
                .HasForeignKey(sci => sci.AdminID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<AgentService>()
                .HasOne(asvc => asvc.LaundryAgent)
                .WithMany(la => la.SubscribedServices)
                .HasForeignKey(asvc => asvc.LaundryAgentID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<AgentService>()
                .HasOne(asvc => asvc.ServiceCatalogItem)
                .WithMany(sci => sci.AgentServices)
                .HasForeignKey(asvc => asvc.ServiceID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Offer>()
                .HasOne(o => o.CreatorAdmin)
                .WithMany(a => a.CreatedOffers)
                .HasForeignKey(o => o.AdminID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<BookingItem>()
                .HasOne(bi => bi.Booking)
                .WithMany(b => b.BookingItems)
                .HasForeignKey(bi => bi.BookingID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<BookingItem>()
                .HasOne(bi => bi.ServiceCatalogItem)
                .WithMany(sci => sci.BookingItems)
                .HasForeignKey(bi => bi.ServiceID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<AuditLog>()
                .HasOne(al => al.Admin)
                .WithMany(a => a.AuditLogs)
                .HasForeignKey(al => al.AdminID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<SystemStatus>()
                .HasOne(ss => ss.Admin)
                .WithMany(a => a.SystemStatuses)
                .HasForeignKey(ss => ss.AdminID)
                .OnDelete(DeleteBehavior.Restrict);

            // --- 4. Decimal Precision Configuration (18, 3) ---
            foreach (var property in modelBuilder.Model.GetEntityTypes()
                .SelectMany(t => t.GetProperties())
                .Where(p => p.ClrType == typeof(decimal) || p.ClrType == typeof(decimal?)))
            {
                property.SetColumnType("decimal(18,3)");
            }

            // --- 5. GPS Coordinates Precision Override (18, 6) ---
            foreach (var property in modelBuilder.Model.GetEntityTypes()
                .SelectMany(t => t.GetProperties())
                .Where(p => (p.ClrType == typeof(decimal) || p.ClrType == typeof(decimal?)) &&
                           (p.Name == "Latitude" || p.Name == "Longitude" || p.Name == "Lat" || p.Name == "Lng")))
            {
                property.SetPrecision(18, 6);
            }
        }
    }
}
