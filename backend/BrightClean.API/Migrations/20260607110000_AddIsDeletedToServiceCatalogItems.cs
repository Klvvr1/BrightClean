using BrightClean.Infrastructure;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BrightClean.API.Migrations
{
    [DbContext(typeof(AppDbContext))]
    [Migration("20260607110000_AddIsDeletedToServiceCatalogItems")]
    public partial class AddIsDeletedToServiceCatalogItems : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                IF COL_LENGTH('ServiceCatalogItems', 'IsDeleted') IS NULL
                BEGIN
                    ALTER TABLE ServiceCatalogItems
                    ADD IsDeleted bit NOT NULL
                        CONSTRAINT DF_ServiceCatalogItems_IsDeleted DEFAULT CAST(0 AS bit);
                END
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                IF COL_LENGTH('ServiceCatalogItems', 'IsDeleted') IS NOT NULL
                BEGIN
                    DECLARE @constraintName sysname;

                    SELECT @constraintName = dc.name
                    FROM sys.default_constraints dc
                    INNER JOIN sys.columns c
                        ON c.default_object_id = dc.object_id
                    INNER JOIN sys.tables t
                        ON t.object_id = c.object_id
                    WHERE t.name = 'ServiceCatalogItems'
                      AND c.name = 'IsDeleted';

                    IF @constraintName IS NOT NULL
                    BEGIN
                        EXEC('ALTER TABLE ServiceCatalogItems DROP CONSTRAINT ' + QUOTENAME(@constraintName));
                    END

                    ALTER TABLE ServiceCatalogItems DROP COLUMN IsDeleted;
                END
            ");
        }
    }
}
