using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Stock Rates, Cost vs Selling Prices, Profit Margins, and Inventory Valuation.
/// </summary>
public class StockRateController : Controller
{
    private readonly IAdminClient _client;

    public StockRateController(IAdminClient client)
    {
        _client = client;
    }

    public async Task<IActionResult> Index(
        int page = 1,
        string? search = null,
        int? warehouseId = null,
        CancellationToken ct = default)
    {
        var warehousesTask = _client.GetLookupAsync(ApiEndPoint.Warehouse.Lookup, null, ct);

        var endpoint = ApiEndPoint.StockRate.GridList;
        if (warehouseId.HasValue) endpoint += $"?warehouseId={warehouseId.Value}";

        var gridTask = _client.GetGridAsync<StockRateGridItem>(
            endpoint,
            new DataTableRequest { Page = page, PageSize = 25, Search = search },
            ct);

        await Task.WhenAll(warehousesTask, gridTask);

        ViewBag.Warehouses = warehousesTask.Result.Data ?? new List<IdNamePair>();
        ViewBag.SelectedWarehouse = warehouseId;
        ViewData["Search"] = search;

        var gridResult = gridTask.Result;
        if (!gridResult.IsSuccess)
        {
            TempData["ErrorMessage"] = gridResult.Message;
        }

        return View(gridResult.Data ?? PagedResult<StockRateGridItem>.Empty(25));
    }

    [HttpGet]
    public async Task<IActionResult> GetRate(int productId, int? variantId = null, CancellationToken ct = default)
    {
        var response = await _client.GetStockRateDetailAsync(productId, variantId, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            return Json(new { success = false, message = response.Message ?? "Product pricing not found." });
        }

        return Json(new { success = true, data = response.Data });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Save(StockRateSaveRequest request, CancellationToken ct = default)
    {
        if (!ModelState.IsValid)
        {
            var firstError = ModelState.Values.SelectMany(v => v.Errors).FirstOrDefault()?.ErrorMessage;
            TempData["ErrorMessage"] = string.IsNullOrWhiteSpace(firstError) ? "Please correct pricing values." : firstError;
            return RedirectToAction(nameof(Index));
        }

        var response = await _client.SaveStockRateAsync(request, ct);
        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message ?? "Failed to update stock rates.";
        }
        else
        {
            TempData["SuccessMessage"] = response.Message ?? "Stock rates and margins updated successfully.";
        }

        return RedirectToAction(nameof(Index));
    }
}
