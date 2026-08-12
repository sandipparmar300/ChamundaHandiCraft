using ChamundaHandicraft.Customer.Models;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 08 · Checkout and Module 09 · Payment —
/// docs/ui-ux-storefront/13-Modules-07-08-09-Cart-Checkout-Payment.md.
///
/// Single-page checkout, guest by default. Every cost is already visible from the
/// cart; nothing new appears once payment details are requested.
/// </summary>
public class CheckoutController : StorefrontController
{
    public CheckoutController(IStorefrontClient client) : base(client) { }

    [HttpGet("/checkout")]
    public IActionResult Index(bool guest = false)
    {
        MinimalChrome();
        Page("Checkout");

        var lines = DemoContent.CartLines();

        return View(new CheckoutViewModel
        {
            Lines = lines,
            Summary = DemoContent.Summary(lines),
            Addresses = DemoContent.Addresses(),
            IsGuest = guest
        });
    }

    [HttpGet("/checkout/success/{orderNumber}")]
    public IActionResult Success(string orderNumber)
    {
        MinimalChrome();
        Page("Order confirmed");
        ViewData["OrderNumber"] = orderNumber;

        var lines = DemoContent.CartLines();

        return View(new CheckoutViewModel
        {
            Lines = lines,
            Summary = DemoContent.Summary(lines),
            Addresses = DemoContent.Addresses()
        });
    }

    [HttpGet("/checkout/failed")]
    public IActionResult Failed(string? reason)
    {
        MinimalChrome();
        Page("Payment didn't go through");
        ViewData["Reason"] = reason ?? "Your bank declined the transaction.";
        return View();
    }
}
