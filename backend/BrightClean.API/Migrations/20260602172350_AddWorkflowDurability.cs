using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BrightClean.API.Migrations
{
    /// <inheritdoc />
    public partial class AddWorkflowDurability : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserDocuments_UserID",
                table: "UserDocuments");

            migrationBuilder.AddColumn<string>(
                name: "ContentType",
                table: "UserDocuments",
                type: "nvarchar(120)",
                maxLength: 120,
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "FileSizeBytes",
                table: "UserDocuments",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "OriginalFileName",
                table: "UserDocuments",
                type: "nvarchar(260)",
                maxLength: 260,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ReviewNotes",
                table: "UserDocuments",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ReviewStatus",
                table: "UserDocuments",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "ReviewedAt",
                table: "UserDocuments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ReviewedByAdminID",
                table: "UserDocuments",
                type: "int",
                nullable: true);

            // Backfill review state from existing approved users
            // For LaundryAgents and DeliveryStaff who are already approved, mark their documents as Approved
            migrationBuilder.Sql(@"
                UPDATE ud
                SET ud.ReviewStatus = 1,  -- DocumentReviewStatus.Approved
                    ud.ReviewedAt = u.VerifiedAt
                FROM UserDocuments ud
                INNER JOIN Users u ON ud.UserID = u.UserID
                WHERE u.IsApproved = 1
                  AND u.VerifiedAt IS NOT NULL
                  AND (u.Role = 2 OR u.Role = 3);  -- LaundryAgent = 2, DeliveryStaff = 3
            ");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Payments",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()");

            migrationBuilder.AddColumn<string>(
                name: "PaymentProofURL",
                table: "Payments",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ReviewedAt",
                table: "Payments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ReviewedByAdminID",
                table: "Payments",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "StatusReason",
                table: "Payments",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Details",
                table: "AuditLogs",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "IpAddress",
                table: "AuditLogs",
                type: "nvarchar(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserDocuments_ReviewedByAdminID",
                table: "UserDocuments",
                column: "ReviewedByAdminID");

            migrationBuilder.CreateIndex(
                name: "IX_UserDocuments_ReviewStatus",
                table: "UserDocuments",
                column: "ReviewStatus");

            migrationBuilder.CreateIndex(
                name: "IX_UserDocuments_UserID_Type",
                table: "UserDocuments",
                columns: new[] { "UserID", "Type" });

            migrationBuilder.CreateIndex(
                name: "IX_Payments_CreatedAt",
                table: "Payments",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_Method",
                table: "Payments",
                column: "Method");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_ReviewedByAdminID",
                table: "Payments",
                column: "ReviewedByAdminID");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_Status",
                table: "Payments",
                column: "Status");

            migrationBuilder.AddForeignKey(
                name: "FK_Payments_Admins_ReviewedByAdminID",
                table: "Payments",
                column: "ReviewedByAdminID",
                principalTable: "Admins",
                principalColumn: "UserID",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_UserDocuments_Admins_ReviewedByAdminID",
                table: "UserDocuments",
                column: "ReviewedByAdminID",
                principalTable: "Admins",
                principalColumn: "UserID",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Payments_Admins_ReviewedByAdminID",
                table: "Payments");

            migrationBuilder.DropForeignKey(
                name: "FK_UserDocuments_Admins_ReviewedByAdminID",
                table: "UserDocuments");

            migrationBuilder.DropIndex(
                name: "IX_UserDocuments_ReviewedByAdminID",
                table: "UserDocuments");

            migrationBuilder.DropIndex(
                name: "IX_UserDocuments_ReviewStatus",
                table: "UserDocuments");

            migrationBuilder.DropIndex(
                name: "IX_UserDocuments_UserID_Type",
                table: "UserDocuments");

            migrationBuilder.DropIndex(
                name: "IX_Payments_CreatedAt",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Payments_Method",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Payments_ReviewedByAdminID",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Payments_Status",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "ContentType",
                table: "UserDocuments");

            migrationBuilder.DropColumn(
                name: "FileSizeBytes",
                table: "UserDocuments");

            migrationBuilder.DropColumn(
                name: "OriginalFileName",
                table: "UserDocuments");

            migrationBuilder.DropColumn(
                name: "ReviewNotes",
                table: "UserDocuments");

            migrationBuilder.DropColumn(
                name: "ReviewStatus",
                table: "UserDocuments");

            migrationBuilder.DropColumn(
                name: "ReviewedAt",
                table: "UserDocuments");

            migrationBuilder.DropColumn(
                name: "ReviewedByAdminID",
                table: "UserDocuments");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "PaymentProofURL",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "ReviewedAt",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "ReviewedByAdminID",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "StatusReason",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "Details",
                table: "AuditLogs");

            migrationBuilder.DropColumn(
                name: "IpAddress",
                table: "AuditLogs");

            migrationBuilder.CreateIndex(
                name: "IX_UserDocuments_UserID",
                table: "UserDocuments",
                column: "UserID");
        }
    }
}
