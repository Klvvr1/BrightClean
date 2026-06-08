using BrightClean.Infrastructure;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BrightClean.API.Migrations
{
    [DbContext(typeof(AppDbContext))]
    [Migration("20260608120000_AddDeliveryStaffAvailability")]
    public partial class AddDeliveryStaffAvailability : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsAvailable",
                table: "DeliveryStaffs",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsAvailable",
                table: "DeliveryStaffs");
        }
    }
}
