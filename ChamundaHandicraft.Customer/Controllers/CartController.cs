using ChamundaHandicraft.Customer.Models;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 07 · Cart — docs/ui-ux-storefront/13-Modules-07-08-09-Cart-Checkout-Payment.md §7.
/// Every cost appears here. Nothing new is allowed to appear after payment
/// selection (CX principle 7).
/// </summary>
public class CartController : StorefrontController
{
    public CartController(IStorefrontClient client) : base(client) { }

    [HttpGet("/cart")]
    public IActionResult Index(bool empty = false)
    {
        ActiveNav("cart");
        Page("Your cart");
        Crumbs(("Home", "/"), ("Cart", null));

        var lines = empty ? new List<CartLineViewModel>() : DemoContent.CartLines();

        return View(new CartPageViewModel
        {
            Lines = lines,
            Summary = DemoContent.Summary(lines),
            SavedForLater = DemoContent.Products(3, 5)
        });
    }
}
