using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// System pages — maintenance and offline. Both keep the shopper's cart promise
/// visible and give a way back in.
/// </summary>
public class SystemController : StorefrontController
{
    public SystemController(IStorefrontClient client) : base(client) { }

    [HttpGet("/maintenance")]
    public IActionResult Maintenance()
    {
        Page("We're back shortly");
        return View();
    }

    [HttpGet("/offline")]
    public IActionResult Offline()
    {
        Page("You're offline");
        return View();
    }

    [HttpGet("/sitemap")]
    public IActionResult Sitemap()
    {
        Page("Sitemap");
        Crumbs(("Home", "/"), ("Sitemap", null));
        return View();
    }
}
