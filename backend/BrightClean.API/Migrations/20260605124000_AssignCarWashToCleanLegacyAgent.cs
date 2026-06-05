using BrightClean.Infrastructure;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BrightClean.API.Migrations
{
    [DbContext(typeof(AppDbContext))]
    [Migration("20260605124000_AssignCarWashToCleanLegacyAgent")]
    public partial class AssignCarWashToCleanLegacyAgent : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                INSERT INTO AgentServices
                    (LaundryAgentID, ServiceID, IsActive, PendingActivation, ActivatedAt, Notes)
                SELECT
                    agent.UserID,
                    service.ServiceID,
                    1,
                    0,
                    GETUTCDATE(),
                    'Assigned by legacy data repair for car wash availability.'
                FROM LaundryAgents agent
                INNER JOIN Users userAccount
                    ON userAccount.UserID = agent.UserID
                INNER JOIN ServiceCatalogItems service
                    ON service.Category = 3
                   AND service.Type = 11
                   AND service.IsAvailable = 1
                WHERE agent.UserID = 1009
                  AND userAccount.IsApproved = 1
                  AND userAccount.AccountStatus = 1
                  AND agent.IsStoreClosed = 0
                  AND NOT EXISTS
                  (
                      SELECT 1
                      FROM AgentServices existing
                      WHERE existing.LaundryAgentID = agent.UserID
                        AND existing.ServiceID = service.ServiceID
                  );
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                DELETE FROM AgentServices
                WHERE LaundryAgentID = 1009
                  AND Notes = 'Assigned by legacy data repair for car wash availability.';
            ");
        }
    }
}
