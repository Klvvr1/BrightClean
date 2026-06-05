using BrightClean.Infrastructure;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BrightClean.API.Migrations
{
    [DbContext(typeof(AppDbContext))]
    [Migration("20260605123000_RemoveLegacyAllServiceAgentAssignments")]
    public partial class RemoveLegacyAllServiceAgentAssignments : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                DELETE FROM AgentServices
                WHERE Notes = 'Assigned by legacy data repair migration.';
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
        }
    }
}
