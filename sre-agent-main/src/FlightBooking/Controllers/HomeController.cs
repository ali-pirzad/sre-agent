using FlightBooking.Data;
using FlightBooking.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FlightBooking.Controllers;

public class HomeController : Controller
{
    private readonly FlightBookingContext _context;

    public HomeController(FlightBookingContext context)
    {
        _context = context;
    }

    public async Task<IActionResult> Index()
    {
        var flights = await _context.Flights.ToListAsync();
        return View(flights);
    }
}
