using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Feedback.Migrations
{
    /// <inheritdoc />
    public partial class OneFeedbackPerTrainee : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Source",
                schema: "mv7_app",
                table: "SessionFeedbacks",
                type: "text",
                nullable: false,
                defaultValue: "web");

            migrationBuilder.CreateIndex(
                name: "IX_SessionFeedbacks_SessionId_ContactId",
                schema: "mv7_app",
                table: "SessionFeedbacks",
                columns: new[] { "SessionId", "ContactId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_SessionFeedbacks_SessionId_ContactId",
                schema: "mv7_app",
                table: "SessionFeedbacks");

            migrationBuilder.DropColumn(
                name: "Source",
                schema: "mv7_app",
                table: "SessionFeedbacks");
        }
    }
}
