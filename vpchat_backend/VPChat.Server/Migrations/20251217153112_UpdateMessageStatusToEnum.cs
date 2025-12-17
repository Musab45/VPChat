using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VPChat.Server.Migrations
{
    /// <inheritdoc />
    public partial class UpdateMessageStatusToEnum : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<int>(
                name: "IsRead",
                table: "Messages",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(bool),
                oldType: "INTEGER");

            migrationBuilder.RenameColumn(
                name: "IsRead",
                table: "Messages",
                newName: "Status");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Status",
                table: "Messages",
                newName: "IsRead");

            migrationBuilder.AlterColumn<bool>(
                name: "IsRead",
                table: "Messages",
                type: "INTEGER",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "INTEGER");
        }
    }
}
