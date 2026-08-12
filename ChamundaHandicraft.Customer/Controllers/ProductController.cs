using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 04 · Product Details — docs/ui-ux-storefront/12-Modules-04-05-06-PDP-Compare-Wishlist.md.
///
/// The single most important conversion surface. The gallery, price, variation
/// notice, delivery estimate and trust row all sit above the fold on desktop and
/// within one scroll on mobile.
/// </summary>
public class ProductController : StorefrontController
{
    public ProductController(IStorefrontClient client) : base(client) { }

    [HttpGet("/p/{slug}")]
    public IActionResult Details(string slug)
    {
        ActiveNav("shop");

        var product = DemoContent.Product(slug);

        Page(product.Name, product.ShortDescription);
        Crumbs(
            ("Home", "/"),
            (product.CategoryName, $"/c/{product.CategorySlug}"),
            ("Vases", $"/c/{product.CategorySlug}/vases"),
            (product.Name.Length > 40 ? product.Name[..40] + "…" : product.Name, null));

        return View(product);
    }
}
