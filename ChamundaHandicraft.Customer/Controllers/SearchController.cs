using ChamundaHandicraft.Customer.Models;
using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
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
    public async Task<IActionResult> Index(
        string? q,
        string? sort,
        string? view,
        int page = 1,
        int pageSize = 20,
        CancellationToken ct = default)
    {
        ActiveNav("search");

        var query = q?.Trim();

        Page(string.IsNullOrEmpty(query) ? "Search Catalog" : $"Search results for “{query}”");
        Crumbs(("Home", "/"), ("Search", null));

        if (string.IsNullOrWhiteSpace(query))
        {
            var categoriesResp = await Client.GetCategoriesAsync(ct);
            return View(new ListingViewModel
            {
                Heading = "Search Catalog",
                Intro = "Find handcrafted treasures across brass, pottery, woodwork, and textiles.",
                Query = string.Empty,
                Sort = sort ?? "relevance",
                View = view == "list" ? "list" : "grid",
                Products = new List<ProductCardViewModel>(),
                TotalCount = 0,
                SubCategories = categoriesResp.IsSuccess && categoriesResp.Data != null ? categoriesResp.Data : new List<CategoryViewModel>()
            });
        }

        var paging = new PagedRequest { Page = page <= 0 ? 1 : page, PageSize = pageSize <= 0 ? 20 : pageSize };
        var response = await Client.SearchAsync(query, paging, sort, ct);
        var data = response.Data ?? new ProductListingViewModel();

        if (data.Products.TotalCount == 0)
        {
            var popularResp = await Client.GetRailAsync("trending", 6, ct: ct);
            ViewBag.PopularProducts = popularResp.IsSuccess && popularResp.Data != null ? popularResp.Data : new List<ProductCardViewModel>();
        }

        var model = new ListingViewModel
        {
            Heading = $"Results for “{query}”",
            Intro = $"Found {data.Products.TotalCount} authentic handcrafted items matching “{query}”.",
            Query = query,
            Sort = sort ?? "relevance",
            View = view == "list" ? "list" : "grid",
            Products = data.Products.Items,
            TotalCount = data.Products.TotalCount,
            Page = paging.Page,
            PageSize = paging.PageSize,
            Facets = data.Facets,
            SubCategories = data.SubCategories
        };

        return View(model);
    }

    [HttpGet("/search/suggest")]
    public async Task<IActionResult> Suggest(string? q, int limit = 8, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(q))
        {
            return Json(new { isSuccess = true, data = new ProductSearchResultViewModel() });
        }

        var response = await Client.GetSearchSuggestionsAsync(q.Trim(), limit, ct);
        return Json(response);
    }
}
