using System.ComponentModel.DataAnnotations;

namespace FlightBooking.Models;

public class Flight
{
    public int Id { get; set; }

    [Required]
    [Display(Name = "Flight Number")]
    public string FlightNumber { get; set; } = string.Empty;

    [Required]
    public string Airline { get; set; } = string.Empty;

    [Required]
    [Display(Name = "Departure City")]
    public string DepartureCity { get; set; } = string.Empty;

    [Required]
    [Display(Name = "Arrival City")]
    public string ArrivalCity { get; set; } = string.Empty;

    [Required]
    [Display(Name = "Departure Time")]
    public DateTime DepartureTime { get; set; }

    [Required]
    [Display(Name = "Arrival Time")]
    public DateTime ArrivalTime { get; set; }

    [Required]
    [Range(0, 10000)]
    public decimal Price { get; set; }

    [Required]
    [Display(Name = "Available Seats")]
    [Range(0, 500)]
    public int AvailableSeats { get; set; }
}
