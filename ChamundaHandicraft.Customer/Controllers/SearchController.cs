using ChamundaHandicraft.Customer.Models;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 13 · Search — docs/ui-ux-storefront/11-Modules-03-13-Shop-Search.md.
/// Search results use the same listing pattern as the PLP, with relevance sort
/// and a no-results state that always offers a way forward.
/// </summary>
public class SearchController : StorefrontController
{
    public SearchController(IStorefrontClient client) : base(client) { }

    [HttpGet("/search")]
    public IActionResult Index(string? q, string? sort, string? view)
    {
        ActiveNav("search");

        var query = q?.Trim();

        Page(string.IsNullOrEmpty(query) ? "Search" : $"Search results for “{query}”");
        Crumbs(("Home", "/"), ("Search", null));

        // Empty query is a browse surface, not an error.
        var products = string.IsNullOrEmpty(query)
            ? new List<ProductCardViewModel>()
            : query.Contains("xyz", StringComparison.OrdinalIgnoreCase)
                ? new List<ProductCardViewModel>()
                : DemoContent.AllProducts();

        return View(new ListingViewModel
        {
            Heading = string.IsNullOrEmpty(query) ? "Search" : $"Results for “{query}”",
            Intro = "",
            Query = query ?? "",
            CorrectedFrom = query is not null && query.Equals("potery", StringComparison.OrdinalIgnoreCase) ? "potery" : null,
            Sort = sort ?? "relevance",
            View = view == "list" ? "list" : "grid",
            Products = products,
            TotalCount = products.Count
        });
    }
}
