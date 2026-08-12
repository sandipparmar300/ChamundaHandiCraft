using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 12 · Order Tracking. Works for guests — order number plus the email or
/// phone used at checkout. No account required to see where a parcel is.
/// </summary>
public class TrackController : StorefrontController
{
    public TrackController(IStorefrontClient client) : base(client) { }

    [HttpGet("/track")]
    public IActionResult Index()
    {
        ActiveNav("track");
        Page("Track your order", "Enter your order number to see exactly where your parcel is. No account needed.");
        Crumbs(("Home", "/"), ("Track Order", null));
        return View();
    }

    [HttpGet("/track/{orderNumber}")]
    public IActionResult Details(string orderNumber)
    {
        ActiveNav("track");
        Page($"Tracking {orderNumber}");
        Crumbs(("Home", "/"), ("Track Order", "/track"), (orderNumber, null));

        ViewData["OrderNumber"] = orderNumber;
        return View(DemoContent.Orders().FirstOrDefault(o => o.OrderNumber == orderNumber) ?? DemoContent.Orders()[0]);
    }
}
