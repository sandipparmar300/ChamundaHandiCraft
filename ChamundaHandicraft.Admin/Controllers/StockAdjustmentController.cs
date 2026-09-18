using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Manual stock corrections with mandatory reason codes and audit logging.
/// </summary>
public class StockAdjustmentController : Controller
{
    private readonly IAdminClient _client;

    public StockAdjustmentController(IAdminClient client)
    {
        _client = client;
    }

    public async Task<IActionResult> Index(
        int page = 1,
        string? search = null,
        int? warehouseId = null,
        int? reasonCodeId = null,
        CancellationToken ct = default)
    {
        var warehousesTask = _client.GetLookupAsync(ApiEndPoint.Warehouse.Lookup, null, ct);

        var endpoint = ApiEndPoint.StockAdjustment.GridList;
        var queryParams = new List<string>();
        if (warehouseId.HasValue) queryParams.Add($"warehouseId={warehouseId.Value}");
        if (reasonCodeId.HasValue) queryParams.Add($"reasonCodeId={reasonCodeId.Value}");
        if (queryParams.Any()) endpoint += "?" + string.Join("&", queryParams);

        var gridTask = _client.GetGridAsync<StockAdjustmentGridItem>(
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

        return View(gridResult.Data ?? PagedResult<StockAdjustmentGridItem>.Empty(25));
    }

    public async Task<IActionResult> Add(CancellationToken ct = default)
    {
        await LoadLookupsAsync(ct);
        return View("Create", new StockAdjustmentSaveRequest
        {
            QuantityChange = 0,
            ReasonCodeId = 44 // Manual correction
        });
    }

    public async Task<IActionResult> Edit(int id, CancellationToken ct = default)
    {
        var response = await _client.GetStockAdjustmentDetailAsync(id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Stock adjustment not found.";
            return RedirectToAction(nameof(Index));
        }

        var d = response.Data;
        var request = new StockAdjustmentSaveRequest
        {
            Id = d.Id,
            AdjustmentNumber = d.AdjustmentNumber,
            WarehouseId = d.WarehouseId,
            ProductId = d.ProductId,
            VariantId = d.VariantId,
            ReasonCodeId = d.ReasonCodeId,
            Reason = d.Reason,
            QuantityBefore = d.QuantityBefore,
            QuantityChange = d.QuantityChange,
            QuantityAfter = d.QuantityAfter,
            Note = d.Note
        };

        await LoadLookupsAsync(ct);
        return View("Create", request);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Save(StockAdjustmentSaveRequest request, CancellationToken ct = default)
    {
        if (request.QuantityChange == 0)
        {
            ModelState.AddModelError(nameof(request.QuantityChange), "Quantity change cannot be zero (+ for increase, - for decrease).");
        }

        if (string.IsNullOrWhiteSpace(request.Reason) && request.ReasonCodeId.HasValue)
        {
            request.Reason = "Manual Adjustment";
            ModelState.Remove(nameof(request.Reason));
        }

        if (!ModelState.IsValid)
        {
            var firstError = ModelState.Values.SelectMany(v => v.Errors).FirstOrDefault()?.ErrorMessage;
            ViewData["ErrorMessage"] = string.IsNullOrWhiteSpace(firstError) ? "Please correct the errors in the form." : firstError;
            TempData.Remove("ErrorMessage");
            await LoadLookupsAsync(ct);
            return View("Create", request);
        }

        var response = await _client.SaveAsync(ApiEndPoint.StockAdjustment.Save, request, ct);
        if (!response.IsSuccess)
        {
            ViewData["ErrorMessage"] = response.Message ?? "Failed to save stock adjustment.";
            TempData.Remove("ErrorMessage");
            await LoadLookupsAsync(ct);
            return View("Create", request);
        }

        TempData["SuccessMessage"] = response.Message ?? "Stock adjustment recorded successfully.";
        return RedirectToAction(nameof(Index));
    }

    public async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await _client.GetStockAdjustmentDetailAsync(id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Stock adjustment not found.";
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id, CancellationToken ct = default)
    {
        var response = await _client.DeleteAsync(ApiEndPoint.StockAdjustment.Delete, id, ct);
        return Json(new { success = response.IsSuccess, message = response.Message });
    }

    [HttpGet]
    public async Task<IActionResult> GetStockOnHand(int warehouseId, int productId, int? variantId, CancellationToken ct = default)
    {
        if (warehouseId <= 0 || productId <= 0)
            return Json(new { success = true, onHand = 0 });

        var endpoint = $"{ApiEndPoint.Inventory.StockGridList}?warehouseId={warehouseId}";
        var res = await _client.GetGridAsync<StockGridItem>(endpoint, new DataTableRequest { Page = 1, PageSize = 100 }, ct);
        if (res.IsSuccess && res.Data?.Items != null)
        {
            var match = res.Data.Items.FirstOrDefault(s => s.ProductId == productId && (variantId == null || variantId == 0 ? (s.VariantId == null || s.VariantId == 0) : s.VariantId == variantId));
            if (match != null)
            {
                return Json(new { success = true, onHand = match.OnHand });
            }
        }
        return Json(new { success = true, onHand = 0 });
    }

    private async Task LoadLookupsAsync(CancellationToken ct)
    {
        var whRes = await _client.GetLookupAsync(ApiEndPoint.Warehouse.Lookup, null, ct);
        ViewBag.Warehouses = whRes.Data ?? new List<IdNamePair>();

        var prodRes = await _client.GetLookupAsync(ApiEndPoint.Product.Lookup, null, ct);
        ViewBag.Products = prodRes.Data ?? new List<IdNamePair>();

        var varRes = await _client.GetLookupAsync(ApiEndPoint.Product.VariantLookup, null, ct);
        ViewBag.Variants = varRes.Data ?? new List<IdNamePair>();

        // Pre-seeded reason codes for stock adjustment
        ViewBag.ReasonCodes = new List<IdNamePair>
        {
            new() { Id = 41, Name = "Counting error" },
            new() { Id = 42, Name = "Extra stock found" },
            new() { Id = 43, Name = "Lost stock" },
            new() { Id = 44, Name = "Manual correction" },
            new() { Id = 45, Name = "Physical verification" },
            new() { Id = 46, Name = "System correction" }
        };
    }
}
