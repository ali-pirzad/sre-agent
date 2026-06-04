using FlightBooking.Data;
using FlightBooking.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;

namespace FlightBooking.Controllers;

public class BookingsController : Controller
{
    private readonly FlightBookingContext _context;

    public BookingsController(FlightBookingContext context)
    {
        _context = context;
    }

    public async Task<IActionResult> Index()
    {
        var bookings = await _context.Bookings
            .Include(b => b.Flight)
            .OrderByDescending(b => b.BookingDate)
            .ToListAsync();
        return View(bookings);
    }

    public async Task<IActionResult> Create(int? flightId)
    {
        ViewBag.Flights = new SelectList(
            await _context.Flights.ToListAsync(),
            "Id",
            "FlightNumber",
            flightId);
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(Booking booking)
    {
        if (ModelState.IsValid)
        {
            var flight = await _context.Flights.FindAsync(booking.FlightId);
            if (flight == null || flight.AvailableSeats < booking.NumberOfSeats)
            {
                ModelState.AddModelError("", "Flight not available or insufficient seats.");
                ViewBag.Flights = new SelectList(await _context.Flights.ToListAsync(), "Id", "FlightNumber");
                return View(booking);
            }

            flight.AvailableSeats -= booking.NumberOfSeats;
            booking.BookingDate = DateTime.UtcNow;
            booking.ConfirmationNumber = $"BK-{Guid.NewGuid().ToString()[..8].ToUpper()}";

            _context.Bookings.Add(booking);
            await _context.SaveChangesAsync();

            return RedirectToAction("Confirmation", new { id = booking.Id });
        }

        ViewBag.Flights = new SelectList(await _context.Flights.ToListAsync(), "Id", "FlightNumber");
        return View(booking);
    }

    public async Task<IActionResult> Confirmation(int id)
    {
        var booking = await _context.Bookings
            .Include(b => b.Flight)
            .FirstOrDefaultAsync(b => b.Id == id);

        if (booking == null) return NotFound();

        return View(booking);
    }
}
