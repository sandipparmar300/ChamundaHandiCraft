using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Live stock management: On-hand quantities, thresholds, bin locations, audit ledger, and KPIs.
/// </summary>
public class InventoryController : Controller
{
    private readonly IAdminClient _client;

    public InventoryController(IAdminClient client)
    {
        _client = client;
    }

    public async Task<IActionResult> Index(
        int page = 1,
        string? search = null,
        int? warehouseId = null,
        string? stockStatus = null,
        CancellationToken ct = default)
    {
        var kpisTask = _client.GetInventoryKpisAsync(ct);
        var warehousesTask = _client.GetLookupAsync(ApiEndPoint.Warehouse.Lookup, null, ct);

        var endpoint = ApiEndPoint.Inventory.StockGridList;
        if (warehouseId.HasValue || !string.IsNullOrWhiteSpace(stockStatus))
        {
            var queryParams = new List<string>();
            if (warehouseId.HasValue) queryParams.Add($"warehouseId={warehouseId.Value}");
            if (!string.IsNullOrWhiteSpace(stockStatus)) queryParams.Add($"stockStatus={stockStatus}");
            endpoint += "?" + string.Join("&", queryParams);
        }

        var gridTask = _client.GetGridAsync<StockGridItem>(
            endpoint,
            new DataTableRequest { Page = page, PageSize = 25, Search = search },
            ct);

        await Task.WhenAll(kpisTask, warehousesTask, gridTask);

        ViewBag.Kpis = kpisTask.Result.Data ?? new InventoryKpiSummaryViewModel();
        ViewBag.Warehouses = warehousesTask.Result.Data ?? new List<IdNamePair>();
        ViewBag.SelectedWarehouse = warehouseId;
        ViewBag.SelectedStockStatus = stockStatus;
        ViewData["Search"] = search;

        var gridResult = gridTask.Result;
        if (!gridResult.IsSuccess)
        {
            TempData["ErrorMessage"] = gridResult.Message;
        }

        return View(gridResult.Data ?? PagedResult<StockGridItem>.Empty(25));
    }

    public async Task<IActionResult> Add(CancellationToken ct = default)
    {
        await LoadLookupsAsync(ct);
        return View("Create", new StockSaveRequest { OnHand = 0, LowStockThreshold = 5 });
    }

    public async Task<IActionResult> Edit(long id, CancellationToken ct = default)
    {
        var response = await _client.GetByIdAsync<StockSaveRequest>(ApiEndPoint.Inventory.GetById, (int)id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Stock record not found.";
            return RedirectToAction(nameof(Index));
        }

        await LoadLookupsAsync(ct);
        return View("Create", response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Save(StockSaveRequest request, CancellationToken ct = default)
    {
        if (!ModelState.IsValid)
        {
            var firstError = ModelState.Values.SelectMany(v => v.Errors).FirstOrDefault()?.ErrorMessage;
            ViewData["ErrorMessage"] = string.IsNullOrWhiteSpace(firstError) ? "Please correct the errors in the form." : firstError;
            TempData.Remove("ErrorMessage");
            await LoadLookupsAsync(ct);
            return View("Create", request);
        }

        var response = await _client.SaveStockAsync(request, ct);
        if (!response.IsSuccess)
        {
            ViewData["ErrorMessage"] = response.Message ?? "Failed to save stock position.";
            TempData.Remove("ErrorMessage");
            await LoadLookupsAsync(ct);
            return View("Create", request);
        }

        TempData["SuccessMessage"] = response.Message ?? "Stock position updated successfully.";
        return RedirectToAction(nameof(Index));
    }

    public async Task<IActionResult> Details(long id, CancellationToken ct = default)
    {
        var response = await _client.GetInventoryDetailAsync(id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Stock record not found.";
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(long id, CancellationToken ct = default)
    {
        var response = await _client.DeleteStockAsync(id, ct);
        return Json(new { success = response.IsSuccess, message = response.Message });
    }

    private async Task LoadLookupsAsync(CancellationToken ct)
    {
        var whRes = await _client.GetLookupAsync(ApiEndPoint.Warehouse.Lookup, null, ct);
        ViewBag.Warehouses = whRes.Data ?? new List<IdNamePair>();

        var prodRes = await _client.GetLookupAsync(ApiEndPoint.Product.Lookup, null, ct);
        ViewBag.Products = prodRes.Data ?? new List<IdNamePair>();

        var varRes = await _client.GetLookupAsync(ApiEndPoint.Product.VariantLookup, null, ct);
        ViewBag.Variants = varRes.Data ?? new List<IdNamePair>();
    }
}
