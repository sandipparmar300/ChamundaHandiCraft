using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.ViewModel.Customer;
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
    [HttpGet("/product/{slug}")]
    public async Task<IActionResult> Details(string slug, CancellationToken ct = default)
    {
        ActiveNav("shop");

        var response = await Client.GetProductAsync(slug, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            return NotFound();
        }

        var product = response.Data;

        var trendingResp = await Client.GetRailAsync("trending", 6, ct: ct);
        ViewBag.TrendingProducts = trendingResp.IsSuccess && trendingResp.Data != null 
            ? trendingResp.Data 
            : new List<ProductCardViewModel>();

        Page(product.Name, product.ShortDescription);

        var crumbs = new List<(string Label, string? Url)>
        {
            ("Home", "/"),
            ("Shop", "/shop")
        };

        if (!string.IsNullOrWhiteSpace(product.CategorySlug))
        {
            crumbs.Add((product.CategoryName, $"/c/{product.CategorySlug}"));
        }

        crumbs.Add((product.Name.Length > 40 ? product.Name[..40] + "…" : product.Name, null));

        Crumbs(crumbs.ToArray());

        return View(product);
    }
}
