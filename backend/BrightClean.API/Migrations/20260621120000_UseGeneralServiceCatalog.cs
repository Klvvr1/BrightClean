using BrightClean.Infrastructure;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BrightClean.API.Migrations
{
    [DbContext(typeof(AppDbContext))]
    [Migration("20260621120000_UseGeneralServiceCatalog")]
    public partial class UseGeneralServiceCatalog : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                DECLARE @adminId int = (SELECT TOP (1) UserID FROM Admins ORDER BY UserID);
                IF @adminId IS NULL
                BEGIN
                    SELECT TOP (1) @adminId = AdminID FROM ServiceCatalogItems ORDER BY ServiceID;
                END

                IF @adminId IS NOT NULL
                BEGIN
                    IF EXISTS (SELECT 1 FROM ServiceCatalogItems WHERE Type = 0)
                    BEGIN
                        UPDATE ServiceCatalogItems
                        SET ServiceName = N'الملابس',
                            Category = 0,
                            Price = 1200,
                            PricingModel = 0,
                            DeliveryModel = 0,
                            IsAvailable = CAST(1 AS bit),
                            IsDeleted = CAST(0 AS bit),
                            AdminID = @adminId
                        WHERE ServiceID = (SELECT MIN(ServiceID) FROM ServiceCatalogItems WHERE Type = 0);
                    END
                    ELSE
                    BEGIN
                        INSERT INTO ServiceCatalogItems (ServiceName, Category, Type, Price, PricingModel, DeliveryModel, IsAvailable, IsDeleted, AdminID)
                        VALUES (N'الملابس', 0, 0, 1200, 0, 0, CAST(1 AS bit), CAST(0 AS bit), @adminId);
                    END

                    IF EXISTS (SELECT 1 FROM ServiceCatalogItems WHERE Type = 6)
                    BEGIN
                        UPDATE ServiceCatalogItems
                        SET ServiceName = N'السجاد والمفروشات',
                            Category = 1,
                            Price = 2500,
                            PricingModel = 0,
                            DeliveryModel = 0,
                            IsAvailable = CAST(1 AS bit),
                            IsDeleted = CAST(0 AS bit),
                            AdminID = @adminId
                        WHERE ServiceID = (SELECT MIN(ServiceID) FROM ServiceCatalogItems WHERE Type = 6);
                    END
                    ELSE
                    BEGIN
                        INSERT INTO ServiceCatalogItems (ServiceName, Category, Type, Price, PricingModel, DeliveryModel, IsAvailable, IsDeleted, AdminID)
                        VALUES (N'السجاد والمفروشات', 1, 6, 2500, 0, 0, CAST(1 AS bit), CAST(0 AS bit), @adminId);
                    END

                    IF EXISTS (SELECT 1 FROM ServiceCatalogItems WHERE Type = 11)
                    BEGIN
                        UPDATE ServiceCatalogItems
                        SET ServiceName = N'السيارات',
                            Category = 3,
                            Price = 5000,
                            PricingModel = 1,
                            DeliveryModel = 1,
                            IsAvailable = CAST(1 AS bit),
                            IsDeleted = CAST(0 AS bit),
                            AdminID = @adminId
                        WHERE ServiceID = (SELECT MIN(ServiceID) FROM ServiceCatalogItems WHERE Type = 11);
                    END
                    ELSE
                    BEGIN
                        INSERT INTO ServiceCatalogItems (ServiceName, Category, Type, Price, PricingModel, DeliveryModel, IsAvailable, IsDeleted, AdminID)
                        VALUES (N'السيارات', 3, 11, 5000, 1, 1, CAST(1 AS bit), CAST(0 AS bit), @adminId);
                    END

                    IF EXISTS (SELECT 1 FROM ServiceCatalogItems WHERE Type = 8)
                    BEGIN
                        UPDATE ServiceCatalogItems
                        SET ServiceName = N'تنظيف المكيفات',
                            Category = 2,
                            Price = 6000,
                            PricingModel = 1,
                            DeliveryModel = 1,
                            IsAvailable = CAST(1 AS bit),
                            IsDeleted = CAST(0 AS bit),
                            AdminID = @adminId
                        WHERE ServiceID = (SELECT MIN(ServiceID) FROM ServiceCatalogItems WHERE Type = 8);
                    END
                    ELSE
                    BEGIN
                        INSERT INTO ServiceCatalogItems (ServiceName, Category, Type, Price, PricingModel, DeliveryModel, IsAvailable, IsDeleted, AdminID)
                        VALUES (N'تنظيف المكيفات', 2, 8, 6000, 1, 1, CAST(1 AS bit), CAST(0 AS bit), @adminId);
                    END

                    IF EXISTS (SELECT 1 FROM ServiceCatalogItems WHERE Type = 7)
                    BEGIN
                        UPDATE ServiceCatalogItems
                        SET ServiceName = N'عاملات النظافة',
                            Category = 2,
                            Price = 15000,
                            PricingModel = 1,
                            DeliveryModel = 1,
                            IsAvailable = CAST(1 AS bit),
                            IsDeleted = CAST(0 AS bit),
                            AdminID = @adminId
                        WHERE ServiceID = (SELECT MIN(ServiceID) FROM ServiceCatalogItems WHERE Type = 7);
                    END
                    ELSE
                    BEGIN
                        INSERT INTO ServiceCatalogItems (ServiceName, Category, Type, Price, PricingModel, DeliveryModel, IsAvailable, IsDeleted, AdminID)
                        VALUES (N'عاملات النظافة', 2, 7, 15000, 1, 1, CAST(1 AS bit), CAST(0 AS bit), @adminId);
                    END

                    IF EXISTS (SELECT 1 FROM ServiceCatalogItems WHERE Type = 9)
                    BEGIN
                        UPDATE ServiceCatalogItems
                        SET ServiceName = N'تنظيف الخزانات',
                            Category = 2,
                            Price = 10000,
                            PricingModel = 1,
                            DeliveryModel = 1,
                            IsAvailable = CAST(1 AS bit),
                            IsDeleted = CAST(0 AS bit),
                            AdminID = @adminId
                        WHERE ServiceID = (SELECT MIN(ServiceID) FROM ServiceCatalogItems WHERE Type = 9);
                    END
                    ELSE
                    BEGIN
                        INSERT INTO ServiceCatalogItems (ServiceName, Category, Type, Price, PricingModel, DeliveryModel, IsAvailable, IsDeleted, AdminID)
                        VALUES (N'تنظيف الخزانات', 2, 9, 10000, 1, 1, CAST(1 AS bit), CAST(0 AS bit), @adminId);
                    END

                    IF EXISTS (SELECT 1 FROM ServiceCatalogItems WHERE Type = 10)
                    BEGIN
                        UPDATE ServiceCatalogItems
                        SET ServiceName = N'غسيل الألواح الشمسية',
                            Category = 2,
                            Price = 12000,
                            PricingModel = 1,
                            DeliveryModel = 1,
                            IsAvailable = CAST(1 AS bit),
                            IsDeleted = CAST(0 AS bit),
                            AdminID = @adminId
                        WHERE ServiceID = (SELECT MIN(ServiceID) FROM ServiceCatalogItems WHERE Type = 10);
                    END
                    ELSE
                    BEGIN
                        INSERT INTO ServiceCatalogItems (ServiceName, Category, Type, Price, PricingModel, DeliveryModel, IsAvailable, IsDeleted, AdminID)
                        VALUES (N'غسيل الألواح الشمسية', 2, 10, 12000, 1, 1, CAST(1 AS bit), CAST(0 AS bit), @adminId);
                    END
                END

                IF OBJECT_ID('tempdb..#ServiceTypeMap') IS NOT NULL DROP TABLE #ServiceTypeMap;
                CREATE TABLE #ServiceTypeMap (SourceType int NOT NULL, TargetType int NOT NULL);
                INSERT INTO #ServiceTypeMap (SourceType, TargetType)
                VALUES
                    (0, 0), (1, 0), (2, 0),
                    (3, 6), (4, 6), (5, 6), (6, 6),
                    (7, 7), (8, 8), (9, 9), (10, 10),
                    (11, 11), (12, 11);

                IF OBJECT_ID('tempdb..#TargetServices') IS NOT NULL DROP TABLE #TargetServices;
                SELECT Type, MIN(ServiceID) AS TargetServiceID
                INTO #TargetServices
                FROM ServiceCatalogItems
                WHERE Type IN (0, 6, 7, 8, 9, 10, 11)
                GROUP BY Type;

                IF OBJECT_ID('tempdb..#ServiceMap') IS NOT NULL DROP TABLE #ServiceMap;
                SELECT source.ServiceID AS SourceServiceID,
                       target.TargetServiceID
                INTO #ServiceMap
                FROM ServiceCatalogItems source
                INNER JOIN #ServiceTypeMap map ON map.SourceType = source.Type
                INNER JOIN #TargetServices target ON target.Type = map.TargetType
                WHERE source.ServiceID <> target.TargetServiceID;

                IF OBJECT_ID('tempdb..#AgentServiceRollup') IS NOT NULL DROP TABLE #AgentServiceRollup;
                SELECT agentService.LaundryAgentID,
                       serviceMap.TargetServiceID,
                       MAX(CASE WHEN agentService.IsActive = 1 THEN 1 ELSE 0 END) AS HasActive,
                       MAX(CASE WHEN agentService.PendingActivation = 1 AND agentService.RequestedAction <> 2 THEN 1 ELSE 0 END) AS HasPending,
                       MAX(CASE WHEN agentService.RequestedAction = 2 THEN 1 ELSE 0 END) AS HasPendingDeactivation,
                       MAX(agentService.ActivatedAt) AS ActivatedAt
                INTO #AgentServiceRollup
                FROM AgentServices agentService
                INNER JOIN #ServiceMap serviceMap ON serviceMap.SourceServiceID = agentService.ServiceID
                GROUP BY agentService.LaundryAgentID, serviceMap.TargetServiceID;

                UPDATE existing
                SET IsActive =
                        CASE WHEN rollup.HasActive = 1 THEN CAST(1 AS bit) ELSE existing.IsActive END,
                    PendingActivation =
                        CASE
                            WHEN rollup.HasActive = 1 THEN CAST(0 AS bit)
                            WHEN existing.IsActive = 0 AND rollup.HasPending = 1 THEN CAST(1 AS bit)
                            ELSE existing.PendingActivation
                        END,
                    RequestedAction =
                        CASE
                            WHEN rollup.HasActive = 1 THEN 0
                            WHEN existing.IsActive = 0 AND rollup.HasPending = 1 THEN
                                CASE WHEN rollup.HasPendingDeactivation = 1 THEN 2 ELSE 1 END
                            ELSE existing.RequestedAction
                        END,
                    ActivatedAt = COALESCE(existing.ActivatedAt, rollup.ActivatedAt),
                    Notes = COALESCE(existing.Notes, 'Migrated to general service catalog.')
                FROM AgentServices existing
                INNER JOIN #AgentServiceRollup rollup
                    ON rollup.LaundryAgentID = existing.LaundryAgentID
                   AND rollup.TargetServiceID = existing.ServiceID;

                INSERT INTO AgentServices
                    (LaundryAgentID, ServiceID, IsActive, PendingActivation, RequestedAction, ActivatedAt, Notes)
                SELECT rollup.LaundryAgentID,
                       rollup.TargetServiceID,
                       CASE WHEN rollup.HasActive = 1 THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END,
                       CASE WHEN rollup.HasActive = 1 THEN CAST(0 AS bit) ELSE CAST(rollup.HasPending AS bit) END,
                       CASE
                           WHEN rollup.HasActive = 1 THEN 0
                           WHEN rollup.HasPendingDeactivation = 1 THEN 2
                           WHEN rollup.HasPending = 1 THEN 1
                           ELSE 0
                       END,
                       CASE WHEN rollup.HasActive = 1 THEN COALESCE(rollup.ActivatedAt, GETUTCDATE()) ELSE NULL END,
                       'Migrated to general service catalog.'
                FROM #AgentServiceRollup rollup
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM AgentServices existing
                    WHERE existing.LaundryAgentID = rollup.LaundryAgentID
                      AND existing.ServiceID = rollup.TargetServiceID
                );

                DELETE agentService
                FROM AgentServices agentService
                INNER JOIN #ServiceMap serviceMap ON serviceMap.SourceServiceID = agentService.ServiceID;

                UPDATE bookingItem
                SET ServiceID = serviceMap.TargetServiceID
                FROM BookingItems bookingItem
                INNER JOIN #ServiceMap serviceMap ON serviceMap.SourceServiceID = bookingItem.ServiceID;

                UPDATE service
                SET IsDeleted = CAST(1 AS bit),
                    IsAvailable = CAST(0 AS bit)
                FROM ServiceCatalogItems service
                INNER JOIN #ServiceMap serviceMap ON serviceMap.SourceServiceID = service.ServiceID;
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                UPDATE ServiceCatalogItems
                SET IsDeleted = CAST(0 AS bit),
                    IsAvailable = CAST(1 AS bit)
                WHERE Type NOT IN (0, 6, 7, 8, 9, 10, 11);
            ");
        }
    }
}
