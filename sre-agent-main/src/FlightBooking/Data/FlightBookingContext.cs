using FlightBooking.Models;
using Microsoft.EntityFrameworkCore;

namespace FlightBooking.Data;

public class FlightBookingContext : DbContext
{
    public FlightBookingContext(DbContextOptions<FlightBookingContext> options)
        : base(options) { }

    public DbSet<Flight> Flights => Set<Flight>();
    public DbSet<Booking> Bookings => Set<Booking>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Flight>().HasData(
            new Flight
            {
                Id = 1,
                FlightNumber = "AA101",
                Airline = "American Airlines",
                DepartureCity = "New York",
                ArrivalCity = "Los Angeles",
                DepartureTime = new DateTime(2026, 6, 15, 8, 0, 0),
                ArrivalTime = new DateTime(2026, 6, 15, 11, 30, 0),
                Price = 349.99m,
                AvailableSeats = 150
            },
            new Flight
            {
                Id = 2,
                FlightNumber = "UA202",
                Airline = "United Airlines",
                DepartureCity = "Chicago",
                ArrivalCity = "Miami",
                DepartureTime = new DateTime(2026, 6, 16, 10, 0, 0),
                ArrivalTime = new DateTime(2026, 6, 16, 14, 0, 0),
                Price = 279.99m,
                AvailableSeats = 120
            },
            new Flight
            {
                Id = 3,
                FlightNumber = "DL303",
                Airline = "Delta Airlines",
                DepartureCity = "San Francisco",
                ArrivalCity = "Seattle",
                DepartureTime = new DateTime(2026, 6, 17, 6, 30, 0),
                ArrivalTime = new DateTime(2026, 6, 17, 8, 45, 0),
                Price = 189.99m,
                AvailableSeats = 80
            },
            new Flight
            {
                Id = 4,
                FlightNumber = "SW404",
                Airline = "Southwest Airlines",
                DepartureCity = "Dallas",
                ArrivalCity = "Denver",
                DepartureTime = new DateTime(2026, 6, 18, 12, 0, 0),
                ArrivalTime = new DateTime(2026, 6, 18, 14, 15, 0),
                Price = 159.99m,
                AvailableSeats = 175
            },
            new Flight
            {
                Id = 5,
                FlightNumber = "JB505",
                Airline = "JetBlue",
                DepartureCity = "Boston",
                ArrivalCity = "Orlando",
                DepartureTime = new DateTime(2026, 6, 19, 7, 0, 0),
                ArrivalTime = new DateTime(2026, 6, 19, 10, 30, 0),
                Price = 229.99m,
                AvailableSeats = 100
            }
        );
    }
}
