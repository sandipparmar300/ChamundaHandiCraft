using ChamundaHandicraft.Customer.Models;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 03 · Shop / Product Listing — docs/ui-ux-storefront/11-Modules-03-13-Shop-Search.md.
///
/// Filters and sort are encoded in the URL so a filtered view is shareable and
/// bookmarkable (FL-05), and the back button behaves.
/// </summary>
public class ShopController : StorefrontController
{
    public ShopController(IStorefrontClient client) : base(client) { }

    [HttpGet("/shop")]
    public IActionResult Index(string? sort, string? view)
    {
        ActiveNav("shop");
        Page("All products", "Every handmade piece we stock — décor, textiles, brass, pottery and jewellery, from 240 named artisans.");
        Crumbs(("Home", "/"), ("Shop", null));

        return View("Listing", BuildListing("All products",
            "Everything we stock, from 240 artisans across 18 craft clusters. "
            + "Filter by material, colour, cluster or the maker's name.",
            sort, view));
    }

    [HttpGet("/c/{category}")]
    [HttpGet("/c/{category}/{subCategory}")]
    public IActionResult Category(string category, string? subCategory, string? sort, string? view)
    {
        ActiveNav("shop");

        var title = Titleise(subCategory ?? category);
        var parent = Titleise(category);

        Page(title, $"Handmade {title.ToLowerInvariant()} bought direct from Indian artisans. Free delivery above ₹999.");

        if (subCategory is null)
        {
            Crumbs(("Home", "/"), (parent, null));
        }
        else
        {
            Crumbs(("Home", "/"), (parent, $"/c/{category}"), (title, null));
        }

        var intro = subCategory is null
            ? $"Our {title.ToLowerInvariant()} are made by hand in workshops we buy from directly — "
              + "wheel-thrown, hand-beaten, block-printed or hand-stitched, depending on the craft. "
              + "Each piece names its maker and their cluster, and each carries the small variations "
              + "that come with being made by a person rather than a machine."
            : $"Every {title.ToLowerInvariant()} here is one of a kind. Filter by material, colour or maker "
              + "to narrow the shelf, and check the delivery date on any product page before you buy.";

        return View("Listing", BuildListing(title, intro, sort, view, category));
    }

    private ListingViewModel BuildListing(
        string heading, string intro, string? sort, string? view, string? categorySlug = null)
    {
        var products = DemoContent.AllProducts();

        // Out-of-stock items sort last but are still shown (filter registry, Availability).
        products = (sort switch
        {
            "price-asc" => products.OrderBy(p => p.Price),
            "price-desc" => products.OrderByDescending(p => p.Price),
            "rating" => products.OrderByDescending(p => p.ReviewCount >= 3 ? p.Rating : 0),
            "discount" => products.OrderByDescending(p => p.DiscountPercent),
            "latest" => products.OrderByDescending(p => p.Badges.Contains(ProductBadge.New)),
            "bestselling" => products.OrderByDescending(p => p.ReviewCount),
            _ => products.OrderByDescending(p => p.ReviewCount * p.Rating)
        })
        .ThenBy(p => p.Stock == StockState.OutOfStock ? 1 : 0)
        .ToList();

        return new ListingViewModel
        {
            Heading = heading,
            Intro = intro,
            CategorySlug = categorySlug,
            Sort = sort ?? "popularity",
            View = view == "list" ? "list" : "grid",
            Products = products,
            TotalCount = 84
        };
    }

    private static string Titleise(string slug) =>
        string.Join(' ', slug.Split('-')
            .Select(word => word.Length switch
            {
                0 => word,
                _ => char.ToUpperInvariant(word[0]) + word[1..]
            }));
}
