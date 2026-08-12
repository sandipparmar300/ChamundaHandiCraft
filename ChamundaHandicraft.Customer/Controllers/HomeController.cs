using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>Module 02 · Home — docs/ui-ux-storefront/10-Modules-01-02-Auth-Home.md §2.</summary>
public class HomeController : StorefrontController
{
    public HomeController(IStorefrontClient client) : base(client) { }

    [HttpGet("/")]
    public IActionResult Index()
    {
        ActiveNav("home");
        Page("Handmade by Indian artisans",
            "Brass diyas, blue pottery, kantha textiles and jewellery bought direct from named artisans. "
            + "Free delivery above ₹999, 7-day returns, secure payments.");

        return View();
    }

    [HttpGet("/error")]
    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error(int? code)
    {
        ViewData["StatusCode"] = code ?? 500;
        Response.StatusCode = code ?? 500;
        return View("Error");
    }
}
