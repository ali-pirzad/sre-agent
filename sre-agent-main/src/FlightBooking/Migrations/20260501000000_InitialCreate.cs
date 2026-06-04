using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814

namespace FlightBooking.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Flights",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FlightNumber = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Airline = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    DepartureCity = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ArrivalCity = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    DepartureTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ArrivalTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Price = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    AvailableSeats = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Flights", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Bookings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PassengerName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Email = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Phone = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    FlightId = table.Column<int>(type: "int", nullable: false),
                    NumberOfSeats = table.Column<int>(type: "int", nullable: false),
                    BookingDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ConfirmationNumber = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Bookings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Bookings_Flights_FlightId",
                        column: x => x.FlightId,
                        principalTable: "Flights",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Flights",
                columns: new[] { "Id", "Airline", "ArrivalCity", "ArrivalTime", "AvailableSeats", "DepartureCity", "DepartureTime", "FlightNumber", "Price" },
                values: new object[,]
                {
                    { 1, "American Airlines", "Los Angeles", new DateTime(2026, 6, 15, 11, 30, 0, 0, DateTimeKind.Unspecified), 150, "New York", new DateTime(2026, 6, 15, 8, 0, 0, 0, DateTimeKind.Unspecified), "AA101", 349.99m },
                    { 2, "United Airlines", "Miami", new DateTime(2026, 6, 16, 14, 0, 0, 0, DateTimeKind.Unspecified), 120, "Chicago", new DateTime(2026, 6, 16, 10, 0, 0, 0, DateTimeKind.Unspecified), "UA202", 279.99m },
                    { 3, "Delta Airlines", "Seattle", new DateTime(2026, 6, 17, 8, 45, 0, 0, DateTimeKind.Unspecified), 80, "San Francisco", new DateTime(2026, 6, 17, 6, 30, 0, 0, DateTimeKind.Unspecified), "DL303", 189.99m },
                    { 4, "Southwest Airlines", "Denver", new DateTime(2026, 6, 18, 14, 15, 0, 0, DateTimeKind.Unspecified), 175, "Dallas", new DateTime(2026, 6, 18, 12, 0, 0, 0, DateTimeKind.Unspecified), "SW404", 159.99m },
                    { 5, "JetBlue", "Orlando", new DateTime(2026, 6, 19, 10, 30, 0, 0, DateTimeKind.Unspecified), 100, "Boston", new DateTime(2026, 6, 19, 7, 0, 0, 0, DateTimeKind.Unspecified), "JB505", 229.99m }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_FlightId",
                table: "Bookings",
                column: "FlightId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "Bookings");
            migrationBuilder.DropTable(name: "Flights");
        }
    }
}
