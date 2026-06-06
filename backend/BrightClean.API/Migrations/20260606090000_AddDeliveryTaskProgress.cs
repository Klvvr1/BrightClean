using BrightClean.Infrastructure;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BrightClean.API.Migrations
{
    [DbContext(typeof(AppDbContext))]
    [Migration("20260606090000_AddDeliveryTaskProgress")]
    public partial class AddDeliveryTaskProgress : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                IF COL_LENGTH('DeliveryTasks', 'CurrentStep') IS NULL
                BEGIN
                    ALTER TABLE DeliveryTasks
                    ADD CurrentStep int NOT NULL
                        CONSTRAINT DF_DeliveryTasks_CurrentStep DEFAULT 0;
                END

                IF COL_LENGTH('DeliveryTasks', 'StartedAt') IS NULL
                BEGIN
                    ALTER TABLE DeliveryTasks
                    ADD StartedAt datetime2 NULL;
                END

                IF COL_LENGTH('DeliveryTasks', 'LastProgressUpdatedAt') IS NULL
                BEGIN
                    ALTER TABLE DeliveryTasks
                    ADD LastProgressUpdatedAt datetime2 NULL;
                END
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                IF COL_LENGTH('DeliveryTasks', 'CurrentStep') IS NOT NULL
                BEGIN
                    DECLARE @currentStepConstraint sysname;

                    SELECT @currentStepConstraint = dc.name
                    FROM sys.default_constraints dc
                    INNER JOIN sys.columns c
                        ON c.default_object_id = dc.object_id
                    INNER JOIN sys.tables t
                        ON t.object_id = c.object_id
                    WHERE t.name = 'DeliveryTasks'
                      AND c.name = 'CurrentStep';

                    IF @currentStepConstraint IS NOT NULL
                    BEGIN
                        EXEC('ALTER TABLE DeliveryTasks DROP CONSTRAINT ' + QUOTENAME(@currentStepConstraint));
                    END

                    ALTER TABLE DeliveryTasks DROP COLUMN CurrentStep;
                END

                IF COL_LENGTH('DeliveryTasks', 'StartedAt') IS NOT NULL
                BEGIN
                    ALTER TABLE DeliveryTasks DROP COLUMN StartedAt;
                END

                IF COL_LENGTH('DeliveryTasks', 'LastProgressUpdatedAt') IS NOT NULL
                BEGIN
                    ALTER TABLE DeliveryTasks DROP COLUMN LastProgressUpdatedAt;
                END
            ");
        }
    }
}
