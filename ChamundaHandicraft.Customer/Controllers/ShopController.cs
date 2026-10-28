using ChamundaHandicraft.Customer.Models;
using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
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
    public async Task<IActionResult> Index(
        string? category,
        string? sort,
        string? view,
        string? material,
        decimal? minPrice,
        decimal? maxPrice,
        bool? inStock,
        int? rating,
        int page = 1,
        int pageSize = 20,
        CancellationToken ct = default)
    {
        ActiveNav("shop");
        Page("All Handcrafted Collections", "Every handmade piece we stock — décor, textiles, brass, pottery and jewellery, from authentic Indian master artisans.");
        Crumbs(("Home", "/"), ("Shop", null));

        var paging = new PagedRequest { Page = page <= 0 ? 1 : page, PageSize = pageSize <= 0 ? 20 : pageSize };
        var response = await Client.GetListingAsync(category, null, paging, sort, material, minPrice, maxPrice, inStock, rating, ct);

        var data = response.Data ?? new ProductListingViewModel();

        var model = new ListingViewModel
        {
            Heading = !string.IsNullOrWhiteSpace(data.Heading) ? data.Heading : "All Handcrafted Collections",
            Intro = !string.IsNullOrWhiteSpace(data.IntroCopy) ? data.IntroCopy : "Everything we stock, from master artisans across verified craft clusters.",
            CategorySlug = category,
            Sort = sort ?? "popularity",
            View = view == "list" ? "list" : "grid",
            Products = data.Products.Items,
            TotalCount = data.Products.TotalCount,
            Page = paging.Page,
            PageSize = paging.PageSize,
            Facets = data.Facets,
            SubCategories = data.SubCategories,
            SelectedMaterial = material,
            SelectedMinPrice = minPrice,
            SelectedMaxPrice = maxPrice,
            InStockOnly = inStock,
            Rating = rating
        };

        return View("Listing", model);
    }

    [HttpGet("/c/{category}")]
    [HttpGet("/c/{category}/{subCategory}")]
    public async Task<IActionResult> Category(
        string category,
        string? subCategory,
        string? sort,
        string? view,
        string? material,
        decimal? minPrice,
        decimal? maxPrice,
        bool? inStock,
        int? rating,
        int page = 1,
        int pageSize = 20,
        CancellationToken ct = default)
    {
        ActiveNav("shop");

        var effectiveCategory = !string.IsNullOrWhiteSpace(Request.Query["category"])
            ? Request.Query["category"].ToString()
            : category;

        var paging = new PagedRequest { Page = page <= 0 ? 1 : page, PageSize = pageSize <= 0 ? 20 : pageSize };
        var response = await Client.GetListingAsync(effectiveCategory, subCategory, paging, sort, material, minPrice, maxPrice, inStock, rating, ct);

        var data = response.Data ?? new ProductListingViewModel();

        var title = !string.IsNullOrWhiteSpace(data.Heading) ? data.Heading : Titleise(subCategory ?? category);
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

        var defaultIntro = subCategory is null
            ? $"Our {title.ToLowerInvariant()} are made by hand in workshops we buy from directly — "
              + "wheel-thrown, hand-beaten, block-printed or hand-stitched, depending on the craft. "
              + "Each piece names its maker and their cluster."
            : $"Every {title.ToLowerInvariant()} here is one of a kind. Filter by material or maker "
              + "to narrow the shelf, and check the delivery date on any product page before you buy.";

        var model = new ListingViewModel
        {
            Heading = title,
            Intro = !string.IsNullOrWhiteSpace(data.IntroCopy) ? data.IntroCopy : defaultIntro,
            CategorySlug = category,
            Sort = sort ?? "popularity",
            View = view == "list" ? "list" : "grid",
            Products = data.Products.Items,
            TotalCount = data.Products.TotalCount,
            Page = paging.Page,
            PageSize = paging.PageSize,
            Facets = data.Facets,
            SubCategories = data.SubCategories,
            SelectedMaterial = material,
            SelectedMinPrice = minPrice,
            SelectedMaxPrice = maxPrice,
            InStockOnly = inStock,
            Rating = rating
        };

        return View("Listing", model);
    }

    private static string Titleise(string slug) =>
        string.Join(' ', slug.Split('-')
            .Select(word => word.Length switch
            {
                0 => word,
                _ => char.ToUpperInvariant(word[0]) + word[1..]
            }));
}
