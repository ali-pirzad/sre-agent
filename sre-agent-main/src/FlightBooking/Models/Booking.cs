using System.ComponentModel.DataAnnotations;

namespace FlightBooking.Models;

public class Booking
{
    public int Id { get; set; }

    [Required]
    [Display(Name = "Passenger Name")]
    public string PassengerName { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [Phone]
    [Display(Name = "Phone Number")]
    public string Phone { get; set; } = string.Empty;

    [Required]
    [Display(Name = "Flight")]
    public int FlightId { get; set; }

    public Flight? Flight { get; set; }

    [Display(Name = "Number of Seats")]
    [Range(1, 10)]
    public int NumberOfSeats { get; set; } = 1;

    [Display(Name = "Booking Date")]
    public DateTime BookingDate { get; set; } = DateTime.UtcNow;

    [Display(Name = "Confirmation Number")]
    public string ConfirmationNumber { get; set; } = string.Empty;
}
