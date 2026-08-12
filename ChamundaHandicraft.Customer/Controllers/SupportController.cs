using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 14 · Customer Support. Self-service first, a human always one tap away.
/// Contact details are never hidden behind a bot.
/// </summary>
public class SupportController : StorefrontController
{
    public SupportController(IStorefrontClient client) : base(client) { }

    [HttpGet("/help")]
    public IActionResult Index()
    {
        ActiveNav("help");
        Page("Help centre", "Answers about delivery, returns, payments and handmade variation — plus how to reach a person.");
        Crumbs(("Home", "/"), ("Help Centre", null));
        return View();
    }

    [HttpGet("/help/tickets")]
    public IActionResult Tickets()
    {
        ActiveNav("account");
        Page("My support requests");
        Crumbs(("Home", "/"), ("Help Centre", "/help"), ("My Requests", null));
        return View();
    }
}
