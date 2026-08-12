using ChamundaHandicraft.Customer.Models;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 06 · Wishlist — works signed-out via a session wishlist, so saving is
/// never gated behind an account.
/// </summary>
public class WishlistController : StorefrontController
{
    public WishlistController(IStorefrontClient client) : base(client) { }

    [HttpGet("/wishlist")]
    public IActionResult Index(bool empty = false)
    {
        ActiveNav("wishlist");
        Page("Your wishlist", "Pieces you've saved. We'll tell you if one drops in price or is running low.");
        Crumbs(("Home", "/"), ("Wishlist", null));

        var products = empty ? new List<ProductCardViewModel>() : DemoContent.Products(6);
        products.ForEach(p => p.IsWishlisted = true);

        return View(products);
    }
}
