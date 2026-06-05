using BrightClean.Infrastructure;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BrightClean.API.Migrations
{
    [DbContext(typeof(AppDbContext))]
    [Migration("20260605120000_AddPendingActivationToAgentServices")]
    public partial class AddPendingActivationToAgentServices : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                IF COL_LENGTH('AgentServices', 'PendingActivation') IS NULL
                BEGIN
                    ALTER TABLE AgentServices
                    ADD PendingActivation bit NOT NULL
                        CONSTRAINT DF_AgentServices_PendingActivation DEFAULT CAST(0 AS bit);
                END
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                IF COL_LENGTH('AgentServices', 'PendingActivation') IS NOT NULL
                BEGIN
                    DECLARE @constraintName sysname;

                    SELECT @constraintName = dc.name
                    FROM sys.default_constraints dc
                    INNER JOIN sys.columns c
                        ON c.default_object_id = dc.object_id
                    INNER JOIN sys.tables t
                        ON t.object_id = c.object_id
                    WHERE t.name = 'AgentServices'
                      AND c.name = 'PendingActivation';

                    IF @constraintName IS NOT NULL
                    BEGIN
                        EXEC('ALTER TABLE AgentServices DROP CONSTRAINT ' + QUOTENAME(@constraintName));
                    END

                    ALTER TABLE AgentServices DROP COLUMN PendingActivation;
                END
            ");
        }
    }
}
