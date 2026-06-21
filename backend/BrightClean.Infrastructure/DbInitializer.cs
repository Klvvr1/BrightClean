using System;
using System.Collections.Generic;
using System.Linq;
using BrightClean.Domain.Entities;
using BrightClean.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace BrightClean.Infrastructure
{
    public static class DbInitializer
    {
        public static void Seed(AppDbContext context)
        {
            context.Database.Migrate();
            SeedServiceCatalog(context);
        }

        private static void SeedServiceCatalog(AppDbContext context)
        {
            var defaultServices = DefaultServices().ToList();
            var existingServices = context.ServiceCatalogItems.ToList();

            var missingServices = defaultServices
                .Where(service => !existingServices.Any(existing =>
                    existing.Category == service.Category &&
                    existing.Type == service.Type))
                .ToList();

            if (missingServices.Count == 0 &&
                existingServices.All(service => service.IsAvailable && !service.IsDeleted))
            {
                return;
            }

            var admin = context.Admins.FirstOrDefault();
            if (admin == null)
            {
                admin = new Admin
                {
                    FirstName = "System",
                    LastName = "Admin",
                    Email = "system.admin@brightclean.local",
                    PasswordHash = "SEEDED_NOT_FOR_LOGIN",
                    PhoneNo = "700000000",
                    DateOfBirth = new DateTime(1990, 1, 1),
                    TermsAccepted = true,
                    AccountStatus = AccountStatus.Active,
                    VerifiedAt = DateTime.UtcNow,
                    IsApproved = true
                };
                context.Admins.Add(admin);
                context.SaveChanges();
            }

            foreach (var service in defaultServices)
            {
                var existing = existingServices.FirstOrDefault(item =>
                    item.Category == service.Category && item.Type == service.Type);

                if (existing == null)
                {
                    service.AdminID = admin.UserID;
                    context.ServiceCatalogItems.Add(service);
                }
                else
                {
                    existing.ServiceName = service.ServiceName;
                    existing.Price = service.Price;
                    existing.PricingModel = service.PricingModel;
                    existing.DeliveryModel = service.DeliveryModel;
                    existing.IsAvailable = true;
                    existing.IsDeleted = false;
                    existing.AdminID = admin.UserID;
                }
            }

            context.SaveChanges();
            Console.WriteLine("Service catalog seeded with 7 general services.");
        }

        private static IEnumerable<ServiceCatalogItem> DefaultServices()
        {
            yield return CreateService(
                "الملابس",
                ServiceCategory.Laundry,
                ServiceType.WashAndIron,
                1200m,
                PricingModel.PerItem,
                DeliveryModel.TwoStage);
            yield return CreateService(
                "السجاد والمفروشات",
                ServiceCategory.HomeWovens,
                ServiceType.Carpets,
                2500m,
                PricingModel.PerItem,
                DeliveryModel.TwoStage);
            yield return CreateService(
                "السيارات",
                ServiceCategory.VehicleWash,
                ServiceType.CarWash,
                5000m,
                PricingModel.FlatFee,
                DeliveryModel.TechnicianDispatch);
            yield return CreateService(
                "تنظيف المكيفات",
                ServiceCategory.HomeServices,
                ServiceType.ACCleaning,
                6000m,
                PricingModel.FlatFee,
                DeliveryModel.TechnicianDispatch);
            yield return CreateService(
                "عاملات النظافة",
                ServiceCategory.HomeServices,
                ServiceType.HomeCleaning,
                15000m,
                PricingModel.FlatFee,
                DeliveryModel.TechnicianDispatch);
            yield return CreateService(
                "تنظيف الخزانات",
                ServiceCategory.HomeServices,
                ServiceType.WaterTankCleaning,
                10000m,
                PricingModel.FlatFee,
                DeliveryModel.TechnicianDispatch);
            yield return CreateService(
                "غسيل الألواح الشمسية",
                ServiceCategory.HomeServices,
                ServiceType.SolarPanelCleaning,
                12000m,
                PricingModel.FlatFee,
                DeliveryModel.TechnicianDispatch);
        }

        private static ServiceCatalogItem CreateService(
            string name,
            ServiceCategory category,
            ServiceType type,
            decimal price,
            PricingModel pricingModel,
            DeliveryModel deliveryModel)
        {
            return new ServiceCatalogItem
            {
                ServiceName = name,
                Category = category,
                Type = type,
                Price = price,
                PricingModel = pricingModel,
                DeliveryModel = deliveryModel,
                IsAvailable = true,
                IsDeleted = false
            };
        }
    }
}
