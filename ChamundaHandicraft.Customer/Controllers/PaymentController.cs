using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 09 · Payment — the interstitial the shopper sees while the gateway
/// works, plus the callback landing. It never lets the shopper think the page
/// has hung, and never invites them to refresh.
/// </summary>
public class PaymentController : StorefrontController
{
    public PaymentController(IStorefrontClient client) : base(client) { }

    [HttpGet("/payment/processing")]
    public IActionResult Processing(string? method)
    {
        MinimalChrome();
        Page("Completing your payment");
        ViewData["Method"] = method ?? "UPI";
        return View();
    }
}
