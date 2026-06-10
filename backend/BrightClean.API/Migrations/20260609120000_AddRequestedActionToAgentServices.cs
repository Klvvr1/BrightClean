using BrightClean.Infrastructure;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BrightClean.API.Migrations
{
    [DbContext(typeof(AppDbContext))]
    [Migration("20260609120000_AddRequestedActionToAgentServices")]
    public partial class AddRequestedActionToAgentServices : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                IF COL_LENGTH('AgentServices', 'RequestedAction') IS NULL
                BEGIN
                    ALTER TABLE AgentServices
                    ADD RequestedAction int NOT NULL
                        CONSTRAINT DF_AgentServices_RequestedAction DEFAULT 0;
                END

                EXEC(N'
                    UPDATE AgentServices
                    SET RequestedAction =
                        CASE
                            WHEN PendingActivation = 1 AND (
                                LOWER(COALESCE(Notes, '''')) LIKE ''%deactivat%'' OR
                                LOWER(COALESCE(Notes, '''')) LIKE ''%disable%'' OR
                                LOWER(COALESCE(Notes, '''')) LIKE ''%decommission%''
                            ) THEN 2
                            WHEN PendingActivation = 1 THEN 1
                            ELSE 0
                        END;
                ');
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                IF COL_LENGTH('AgentServices', 'RequestedAction') IS NOT NULL
                BEGIN
                    DECLARE @constraintName sysname;

                    SELECT @constraintName = dc.name
                    FROM sys.default_constraints dc
                    INNER JOIN sys.columns c
                        ON c.default_object_id = dc.object_id
                    INNER JOIN sys.tables t
                        ON t.object_id = c.object_id
                    WHERE t.name = 'AgentServices'
                      AND c.name = 'RequestedAction';

                    IF @constraintName IS NOT NULL
                    BEGIN
                        EXEC('ALTER TABLE AgentServices DROP CONSTRAINT ' + QUOTENAME(@constraintName));
                    END

                    ALTER TABLE AgentServices DROP COLUMN RequestedAction;
                END
            ");
        }
    }
}
