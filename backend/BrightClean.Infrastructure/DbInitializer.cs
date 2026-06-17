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
        }

        private static IEnumerable<ServiceCatalogItem> DefaultServices()
        {
            yield return CreateService(
                "غسيل وكي",
                ServiceCategory.Laundry,
                ServiceType.WashAndIron,
                1200m,
                PricingModel.PerItem,
                DeliveryModel.TwoStage);
            yield return CreateService(
                "تنظيف جاف",
                ServiceCategory.Laundry,
                ServiceType.DryClean,
                1800m,
                PricingModel.PerItem,
                DeliveryModel.TwoStage);
            yield return CreateService(
                "كي فقط",
                ServiceCategory.Laundry,
                ServiceType.IronOnly,
                700m,
                PricingModel.PerItem,
                DeliveryModel.TwoStage);
            yield return CreateService(
                "ستائر",
                ServiceCategory.HomeWovens,
                ServiceType.Curtains,
                2500m,
                PricingModel.PerItem,
                DeliveryModel.TwoStage);
            yield return CreateService(
                "مفارش",
                ServiceCategory.HomeWovens,
                ServiceType.Bedsheets,
                1500m,
                PricingModel.PerItem,
                DeliveryModel.TwoStage);
            yield return CreateService(
                "بطانيات",
                ServiceCategory.HomeWovens,
                ServiceType.Blankets,
                2000m,
                PricingModel.PerItem,
                DeliveryModel.TwoStage);
            yield return CreateService(
                "سجاد",
                ServiceCategory.HomeWovens,
                ServiceType.Carpets,
                2500m,
                PricingModel.PerItem,
                DeliveryModel.TwoStage);
            yield return CreateService(
                "تنظيف منزل",
                ServiceCategory.HomeServices,
                ServiceType.HomeCleaning,
                15000m,
                PricingModel.FlatFee,
                DeliveryModel.TechnicianDispatch);
            yield return CreateService(
                "تنظيف مكيفات",
                ServiceCategory.HomeServices,
                ServiceType.ACCleaning,
                6000m,
                PricingModel.FlatFee,
                DeliveryModel.TechnicianDispatch);
            yield return CreateService(
                "تنظيف خزانات",
                ServiceCategory.HomeServices,
                ServiceType.WaterTankCleaning,
                10000m,
                PricingModel.FlatFee,
                DeliveryModel.TechnicianDispatch);
            yield return CreateService(
                "تنظيف ألواح شمسية",
                ServiceCategory.HomeServices,
                ServiceType.SolarPanelCleaning,
                12000m,
                PricingModel.FlatFee,
                DeliveryModel.TechnicianDispatch);
            yield return CreateService(
                "غسيل سيارة",
                ServiceCategory.VehicleWash,
                ServiceType.CarWash,
                5000m,
                PricingModel.FlatFee,
                DeliveryModel.TechnicianDispatch);
            yield return CreateService(
                "غسيل دراجة",
                ServiceCategory.VehicleWash,
                ServiceType.MotorcycleWash,
                2500m,
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
