using BrightClean.Infrastructure;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BrightClean.API.Migrations
{
    [DbContext(typeof(AppDbContext))]
    [Migration("20260605121000_ActivateApprovedAgentPendingServices")]
    public partial class ActivateApprovedAgentPendingServices : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                UPDATE agentService
                SET agentService.IsActive = 1,
                    agentService.PendingActivation = 0,
                    agentService.ActivatedAt = COALESCE(agentService.ActivatedAt, GETUTCDATE()),
                    agentService.Notes = 'Activated for an already approved agent.'
                FROM AgentServices agentService
                INNER JOIN Users userAccount
                    ON userAccount.UserID = agentService.LaundryAgentID
                WHERE userAccount.IsApproved = 1
                  AND userAccount.AccountStatus = 1
                  AND agentService.IsActive = 0
                  AND agentService.PendingActivation = 1;
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
        }
    }
}
