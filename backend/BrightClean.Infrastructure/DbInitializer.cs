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
                EnsureDefaultCatalogServices(context);
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

            var vehicleAgentAddress = new Address
            {
                Area = "Riyadh",
                Street = "King Fahd Rd",
                Latitude = 24.7136m,
                Longitude = 46.6753m,
                IsArchived = false
            };

            context.Addresses.AddRange(clientAddress, agentAddress, vehicleAgentAddress);
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

            var vehicleAgent = new LaundryAgent
            {
                FirstName = "Sara",
                LastName = "Al-Qahtani",
                Email = "vehicle-agent@brightclean.com",
                PasswordHash = seedPasswordHash,
                PhoneNo = "965900005",
                DateOfBirth = new DateTime(1990, 7, 10),
                ProfilePhotoURL = null,
                TermsAccepted = true,
                AccountStatus = AccountStatus.Active,
                VerifiedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                FatherName = "Abdullah",
                GrandfatherName = "Nasser",
                NationalIDNumber = "290071012345",
                BusinessName = "Rapid Vehicle Wash",
                CommercialRegister = "CR-654321",
                BankAcc = "KW5555555555555555555555",
                AddressID = vehicleAgentAddress.AddressID,
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
            context.LaundryAgents.Add(vehicleAgent);
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

            var carWashService = new ServiceCatalogItem
            {
                ServiceName = "Car Wash",
                Category = ServiceCategory.VehicleWash,
                Type = ServiceType.CarWash,
                Price = 5.000m,
                PricingModel = PricingModel.PerItem,
                DeliveryModel = DeliveryModel.TechnicianDispatch,
                IsAvailable = true,
                AdminID = admin.UserID
            };

            var motorcycleWashService = new ServiceCatalogItem
            {
                ServiceName = "Motorcycle Wash",
                Category = ServiceCategory.VehicleWash,
                Type = ServiceType.MotorcycleWash,
                Price = 3.000m,
                PricingModel = PricingModel.PerItem,
                DeliveryModel = DeliveryModel.TechnicianDispatch,
                IsAvailable = true,
                AdminID = admin.UserID
            };

            var carpetService = new ServiceCatalogItem
            {
                ServiceName = "Carpet Cleaning",
                Category = ServiceCategory.HomeWovens,
                Type = ServiceType.Carpets,
                Price = 3.000m,
                PricingModel = PricingModel.PerItem,
                DeliveryModel = DeliveryModel.TwoStage,
                IsAvailable = true,
                AdminID = admin.UserID
            };

            var homeCleaningService = new ServiceCatalogItem
            {
                ServiceName = "Home Cleaning",
                Category = ServiceCategory.HomeServices,
                Type = ServiceType.HomeCleaning,
                Price = 4.000m,
                PricingModel = PricingModel.PerItem,
                DeliveryModel = DeliveryModel.TechnicianDispatch,
                IsAvailable = true,
                AdminID = admin.UserID
            };

            var acCleaningService = new ServiceCatalogItem
            {
                ServiceName = "AC Cleaning",
                Category = ServiceCategory.HomeServices,
                Type = ServiceType.ACCleaning,
                Price = 6.000m,
                PricingModel = PricingModel.PerItem,
                DeliveryModel = DeliveryModel.TechnicianDispatch,
                IsAvailable = true,
                AdminID = admin.UserID
            };

            var waterTankCleaningService = new ServiceCatalogItem
            {
                ServiceName = "Water Tank Cleaning",
                Category = ServiceCategory.HomeServices,
                Type = ServiceType.WaterTankCleaning,
                Price = 8.000m,
                PricingModel = PricingModel.PerItem,
                DeliveryModel = DeliveryModel.TechnicianDispatch,
                IsAvailable = true,
                AdminID = admin.UserID
            };

            var solarPanelCleaningService = new ServiceCatalogItem
            {
                ServiceName = "Solar Panel Cleaning",
                Category = ServiceCategory.HomeServices,
                Type = ServiceType.SolarPanelCleaning,
                Price = 4.000m,
                PricingModel = PricingModel.PerItem,
                DeliveryModel = DeliveryModel.TechnicianDispatch,
                IsAvailable = true,
                AdminID = admin.UserID
            };

            context.ServiceCatalogItems.AddRange(
                service,
                maawazService,
                imamaService,
                carWashService,
                motorcycleWashService,
                carpetService,
                homeCleaningService,
                acCleaningService,
                waterTankCleaningService,
                solarPanelCleaningService);
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
                },
                new AgentService
                {
                    LaundryAgentID = agent.UserID,
                    ServiceID = carpetService.ServiceID,
                    IsActive = true,
                    ActivatedAt = DateTime.UtcNow,
                    Notes = "Subscribed via DB Seeding"
                },
                new AgentService
                {
                    LaundryAgentID = vehicleAgent.UserID,
                    ServiceID = carWashService.ServiceID,
                    IsActive = true,
                    ActivatedAt = DateTime.UtcNow,
                    Notes = "Subscribed via DB Seeding"
                },
                new AgentService
                {
                    LaundryAgentID = vehicleAgent.UserID,
                    ServiceID = motorcycleWashService.ServiceID,
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

        private static void EnsureDefaultCatalogServices(AppDbContext context)
        {
            var adminId = context.Admins
                .Select(a => (int?)a.UserID)
                .FirstOrDefault();

            if (adminId == null)
            {
                return;
            }

            var defaultServices = new[]
            {
                new ServiceCatalogItem
                {
                    ServiceName = "Car Wash",
                    Category = ServiceCategory.VehicleWash,
                    Type = ServiceType.CarWash,
                    Price = 5.000m,
                    PricingModel = PricingModel.PerItem,
                    DeliveryModel = DeliveryModel.TechnicianDispatch,
                    IsAvailable = true,
                    AdminID = adminId.Value
                },
                new ServiceCatalogItem
                {
                    ServiceName = "Motorcycle Wash",
                    Category = ServiceCategory.VehicleWash,
                    Type = ServiceType.MotorcycleWash,
                    Price = 3.000m,
                    PricingModel = PricingModel.PerItem,
                    DeliveryModel = DeliveryModel.TechnicianDispatch,
                    IsAvailable = true,
                    AdminID = adminId.Value
                },
                new ServiceCatalogItem
                {
                    ServiceName = "Carpet Cleaning",
                    Category = ServiceCategory.HomeWovens,
                    Type = ServiceType.Carpets,
                    Price = 3.000m,
                    PricingModel = PricingModel.PerItem,
                    DeliveryModel = DeliveryModel.TwoStage,
                    IsAvailable = true,
                    AdminID = adminId.Value
                },
                new ServiceCatalogItem
                {
                    ServiceName = "Home Cleaning",
                    Category = ServiceCategory.HomeServices,
                    Type = ServiceType.HomeCleaning,
                    Price = 4.000m,
                    PricingModel = PricingModel.PerItem,
                    DeliveryModel = DeliveryModel.TechnicianDispatch,
                    IsAvailable = true,
                    AdminID = adminId.Value
                },
                new ServiceCatalogItem
                {
                    ServiceName = "AC Cleaning",
                    Category = ServiceCategory.HomeServices,
                    Type = ServiceType.ACCleaning,
                    Price = 6.000m,
                    PricingModel = PricingModel.PerItem,
                    DeliveryModel = DeliveryModel.TechnicianDispatch,
                    IsAvailable = true,
                    AdminID = adminId.Value
                },
                new ServiceCatalogItem
                {
                    ServiceName = "Water Tank Cleaning",
                    Category = ServiceCategory.HomeServices,
                    Type = ServiceType.WaterTankCleaning,
                    Price = 8.000m,
                    PricingModel = PricingModel.PerItem,
                    DeliveryModel = DeliveryModel.TechnicianDispatch,
                    IsAvailable = true,
                    AdminID = adminId.Value
                },
                new ServiceCatalogItem
                {
                    ServiceName = "Solar Panel Cleaning",
                    Category = ServiceCategory.HomeServices,
                    Type = ServiceType.SolarPanelCleaning,
                    Price = 4.000m,
                    PricingModel = PricingModel.PerItem,
                    DeliveryModel = DeliveryModel.TechnicianDispatch,
                    IsAvailable = true,
                    AdminID = adminId.Value
                }
            };

            foreach (var defaultService in defaultServices)
            {
                var exists = context.ServiceCatalogItems.Any(s =>
                    s.Category == defaultService.Category &&
                    s.Type == defaultService.Type);

                if (!exists)
                {
                    context.ServiceCatalogItems.Add(defaultService);
                }
            }

            context.SaveChanges();
        }

    }
}
