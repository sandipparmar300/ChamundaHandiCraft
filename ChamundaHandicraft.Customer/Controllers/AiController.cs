using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 20 · AI Shopping. Every AI surface is labelled as AI, its suggestions
/// are traceable to real products, and the shopper can always reach a human.
/// </summary>
public class AiController : StorefrontController
{
    public AiController(IStorefrontClient client) : base(client) { }

    [HttpGet("/assistant")]
    public IActionResult Index()
    {
        ActiveNav("assistant");
        Page("Shopping assistant", "Describe what you're looking for — a room, an occasion, a budget — and we'll suggest pieces.");
        Crumbs(("Home", "/"), ("Shopping Assistant", null));
        return View();
    }
}

/// <summary>Footer newsletter subscribe. Consent is explicit and unticked by default.</summary>
public class NewsletterController : StorefrontController
{
    public NewsletterController(IStorefrontClient client) : base(client) { }

    [HttpPost("/newsletter/subscribe")]
    public IActionResult Subscribe(string email) => Redirect("/?subscribed=1");
}
