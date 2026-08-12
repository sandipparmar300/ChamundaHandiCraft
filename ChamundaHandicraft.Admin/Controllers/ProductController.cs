using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Module 03 · Product Management — docs/Admin Flows/Product.txt.
///
/// The write end of the catalogue. What is saved and published here is what the
/// customer site serves at <c>/p/{slug}</c>, and the grid's Preview link opens exactly
/// that page. See docs/INTEGRATION-MAP.md §1.
/// </summary>
public class ProductController : Controller
{
    private readonly IAdminClient _client;

    public ProductController(IAdminClient client) => _client = client;

    public async Task<IActionResult> Index(int page = 1, string? search = null, CancellationToken ct = default)
    {
        var response = await _client.GetProductsAsync(
            new DataTableRequest { Page = page, PageSize = 25, Search = search }, ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
        }

        return View(response.Data ?? PagedResult<ProductGridItem>.Empty(25));
    }

    public IActionResult Add() => View("Create", new ProductSaveRequest());

    public async Task<IActionResult> Edit(int id, CancellationToken ct = default)
    {
        var response = await _client.GetProductAsync(id, ct);

        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message;
            return RedirectToAction(nameof(Index));
        }

        return View("Create", response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Save(ProductSaveRequest request, CancellationToken ct = default)
    {
        if (!ModelState.IsValid)
        {
            return View("Create", request);
        }

        var response = await _client.SaveProductAsync(request, ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
            return View("Create", request);
        }

        TempData["SuccessMessage"] = response.Message;
        return RedirectToAction(nameof(Index));
    }

    /// <summary>
    /// The publish gate. Nothing else makes a product visible to shoppers, so the
    /// confirmation names that consequence rather than saying "status updated".
    /// </summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateStatus(UpdateStatusRequest request, CancellationToken ct = default)
    {
        var response = await _client.UpdateProductStatusAsync(request, ct);
        return Json(new { success = response.IsSuccess, message = response.Message });
    }

    public async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await _client.GetProductAsync(id, ct);
        return View(response.Data ?? new ProductSaveRequest());
    }
}
