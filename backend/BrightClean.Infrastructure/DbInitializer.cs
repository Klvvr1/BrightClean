using System;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using BrightClean.Domain.Entities;
using BrightClean.Domain.Enums;
using BCrypt.Net;

namespace BrightClean.Infrastructure
{
    public static class DbInitializer
    {
        public static void Seed(AppDbContext context)
        {
            context.Database.Migrate();

            // Check if seeding is already done
            if (context.Users.Any())
            {
                return; // DB has been seeded
            }

            // Read secure seed password hash from environment variable
            var seedPasswordHash = Environment.GetEnvironmentVariable("SEED_ADMIN_PASSWORD_HASH");
            if (string.IsNullOrEmpty(seedPasswordHash))
            {
                throw new InvalidOperationException("SEED_ADMIN_PASSWORD_HASH environment variable is not set. Set a BCrypt hash for seed user passwords.");
            }

            using var transaction = context.Database.BeginTransaction();
            try
            {
                // 1. Seed Addresses
            var clientAddress = new Address
            {
                Area = "Salmiya",
                Street = "Hamad Al-Mubarak St",
                Latitude = 29.3375m,
                Longitude = 48.0775m,
                IsArchived = false
            };

            var agentAddress = new Address
            {
                Area = "Hawally",
                Street = "Tunis St",
                Latitude = 29.3392m,
                Longitude = 48.0163m,
                IsArchived = false
            };

            context.Addresses.AddRange(clientAddress, agentAddress);
            context.SaveChanges(); // Persist addresses to get IDs

            // 2. Seed Users (TPT Inheritance)
            var client = new Client
            {
                FirstName = "Ahmad",
                LastName = "Al-Mutairi",
                Email = "client@brightclean.com",
                PasswordHash = seedPasswordHash,
                PhoneNo = "96590001",
                DateOfBirth = new DateTime(1995, 1, 1),
                ProfilePhotoURL = null,
                TermsAccepted = true,
                AccountStatus = AccountStatus.Active,
                VerifiedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                Gender = Gender.Male,
                WalletBalance = 50.000m
            };

            var agent = new LaundryAgent
            {
                FirstName = "Yasir",
                LastName = "Al-Harbi",
                Email = "agent@brightclean.com",
                PasswordHash = seedPasswordHash,
                PhoneNo = "96590002",
                DateOfBirth = new DateTime(1988, 5, 12),
                ProfilePhotoURL = null,
                TermsAccepted = true,
                AccountStatus = AccountStatus.Active,
                VerifiedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                FatherName = "Mohammad",
                GrandfatherName = "Ali",
                NationalIDNumber = "288051212345",
                BusinessName = "Golden Clean Laundry",
                CommercialRegister = "CR-123456",
                BankAcc = "KW1234567890123456789012",
                AddressID = agentAddress.AddressID,
                IsApproved = true
            };

            var driver = new DeliveryStaff
            {
                FirstName = "Khaled",
                LastName = "Al-Otaibi",
                Email = "driver@brightclean.com",
                PasswordHash = seedPasswordHash,
                PhoneNo = "96590003",
                DateOfBirth = new DateTime(1992, 8, 20),
                ProfilePhotoURL = null,
                TermsAccepted = true,
                AccountStatus = AccountStatus.Active,
                VerifiedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                FatherName = "Fahad",
                GrandfatherName = "Khalid",
                NationalIDNumber = "292082012345",
                VehicleType = VehicleType.Motorcycle,
                VehicleMake = "Honda",
                VehicleModel = "Super Cub",
                PlateNumber = "M-9988",
                BankAcc = "KW9876543210987654321098",
                IsApproved = true
            };

            var admin = new Admin
            {
                FirstName = "Admin",
                LastName = "System",
                Email = "admin@brightclean.com",
                PasswordHash = seedPasswordHash,
                PhoneNo = "96590004",
                DateOfBirth = new DateTime(1985, 3, 15),
                ProfilePhotoURL = null,
                TermsAccepted = true,
                AccountStatus = AccountStatus.Active,
                VerifiedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                LastLoginAt = null
            };

            context.Clients.Add(client);
            context.LaundryAgents.Add(agent);
            context.DeliveryStaffs.Add(driver);
            context.Admins.Add(admin);
            context.SaveChanges();

            // Link client address to client
            clientAddress.ClientID = client.UserID;
            context.SaveChanges();

            // 3. Seed ServiceCatalogItem
            var service = new ServiceCatalogItem
            {
                ServiceName = "Wash & Iron",
                Category = ServiceCategory.Laundry,
                Type = ServiceType.WashAndIron,
                Price = 2.500m,
                PricingModel = PricingModel.PerItem,
                DeliveryModel = DeliveryModel.TwoStage,
                IsAvailable = true,
                AdminID = admin.UserID
            };

            var maawazService = new ServiceCatalogItem
            {
                ServiceName = "المعوز",
                Category = ServiceCategory.Laundry,
                Type = ServiceType.WashAndIron,
                Price = 1500.00m,
                PricingModel = PricingModel.PerItem,
                DeliveryModel = DeliveryModel.TwoStage,
                IsAvailable = true,
                AdminID = admin.UserID
            };

            var imamaService = new ServiceCatalogItem
            {
                ServiceName = "العمامة",
                Category = ServiceCategory.Laundry,
                Type = ServiceType.WashAndIron,
                Price = 1000.00m,
                PricingModel = PricingModel.PerItem,
                DeliveryModel = DeliveryModel.TwoStage,
                IsAvailable = true,
                AdminID = admin.UserID
            };

            context.ServiceCatalogItems.AddRange(service, maawazService, imamaService);
            context.SaveChanges();

            // 4. Seed AgentService Subscription
            var agentServices = new[]
            {
                new AgentService
                {
                    LaundryAgentID = agent.UserID,
                    ServiceID = service.ServiceID,
                    IsActive = true,
                    ActivatedAt = DateTime.UtcNow,
                    Notes = "Subscribed via DB Seeding"
                },
                new AgentService
                {
                    LaundryAgentID = agent.UserID,
                    ServiceID = maawazService.ServiceID,
                    IsActive = true,
                    ActivatedAt = DateTime.UtcNow,
                    Notes = "Subscribed via DB Seeding"
                },
                new AgentService
                {
                    LaundryAgentID = agent.UserID,
                    ServiceID = imamaService.ServiceID,
                    IsActive = true,
                    ActivatedAt = DateTime.UtcNow,
                    Notes = "Subscribed via DB Seeding"
                }
            };

            context.AgentServices.AddRange(agentServices);
            context.SaveChanges();

            // 5. Seed Draft Booking (BookingID = 1)
            var booking = new Booking
            {
                ClientID = client.UserID,
                LaundryAgentID = agent.UserID,
                AddressID = clientAddress.AddressID,
                Status = BookingStatus.Draft,
                FinalTotal = null, // Will be locked upon submission
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddDays(1),
                ScheduledAt = null,
                SpecialInstructions = "Please use sensitive detergent"
            };

            context.Bookings.Add(booking);
            context.SaveChanges();

            // 6. Seed BookingItem
            var bookingItem = new BookingItem
            {
                BookingID = booking.BookingID,
                ServiceID = service.ServiceID,
                Quantity = 3,
                UnitPriceAtTimeOfBooking = service.Price
            };

            context.BookingItems.Add(bookingItem);
            context.SaveChanges();

            // 7. Seed Notifications
            var notifications = new[]
            {
                new Notification
                {
                    UserID = client.UserID,
                    Title = "تم استلام طلبك",
                    Message = "لقد بدأنا العمل على طلب غسيل السجاد الخاص بك.",
                    Date = DateTime.UtcNow.AddMinutes(-10)
                },
                new Notification
                {
                    UserID = client.UserID,
                    Title = "السائق في الطريق",
                    Message = "السائق أحمد في طريقه لاستلام الملابس من موقعك.",
                    Date = DateTime.UtcNow.AddHours(-1)
                },
                new Notification
                {
                    UserID = agent.UserID,
                    Title = "طلب جديد متاح",
                    Message = "هناك طلب غسيل جديد ينتظر قبولك.",
                    Date = DateTime.UtcNow.AddMinutes(-5)
                },
                new Notification
                {
                    UserID = agent.UserID,
                    Title = "تحديث النظام",
                    Message = "تم تحديث تطبيق المغسلة لإصدار أسرع وأكثر استقراراً.",
                    Date = DateTime.UtcNow.AddDays(-1)
                }
            };

            context.Notifications.AddRange(notifications);
            context.SaveChanges();

                transaction.Commit();
            }
            catch
            {
                transaction.Rollback();
                throw;
            }
        }
    }
}
