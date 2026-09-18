using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Stock transfers between warehouses with dispatch and intake workflows.
/// </summary>
public class StockTransferController : Controller
{
    private readonly IAdminClient _client;

    public StockTransferController(IAdminClient client)
    {
        _client = client;
    }

    public async Task<IActionResult> Index(
        int page = 1,
        string? search = null,
        int? fromWarehouseId = null,
        int? toWarehouseId = null,
        string? status = null,
        CancellationToken ct = default)
    {
        var warehousesTask = _client.GetLookupAsync(ApiEndPoint.Warehouse.Lookup, null, ct);

        var endpoint = ApiEndPoint.StockTransfer.GridList;
        var queryParams = new List<string>();
        if (fromWarehouseId.HasValue) queryParams.Add($"fromWarehouseId={fromWarehouseId.Value}");
        if (toWarehouseId.HasValue) queryParams.Add($"toWarehouseId={toWarehouseId.Value}");
        if (!string.IsNullOrWhiteSpace(status)) queryParams.Add($"status={status}");
        if (queryParams.Any()) endpoint += "?" + string.Join("&", queryParams);

        var gridTask = _client.GetGridAsync<StockTransferGridItem>(
            endpoint,
            new DataTableRequest { Page = page, PageSize = 25, Search = search },
            ct);

        await Task.WhenAll(warehousesTask, gridTask);

        ViewBag.Warehouses = warehousesTask.Result.Data ?? new List<IdNamePair>();
        ViewBag.SelectedFrom = fromWarehouseId;
        ViewBag.SelectedTo = toWarehouseId;
        ViewBag.SelectedStatus = status;
        ViewData["Search"] = search;

        var gridResult = gridTask.Result;
        if (!gridResult.IsSuccess)
        {
            TempData["ErrorMessage"] = gridResult.Message;
        }

        return View(gridResult.Data ?? PagedResult<StockTransferGridItem>.Empty(25));
    }

    public async Task<IActionResult> Add(CancellationToken ct = default)
    {
        await LoadLookupsAsync(ct);
        return View("Create", new StockTransferSaveRequest
        {
            TransferDate = DateTime.Today,
            Status = "Draft",
            Lines = new List<StockTransferLineRequest>
            {
                new() { Quantity = 1 }
            }
        });
    }

    public async Task<IActionResult> Edit(int id, CancellationToken ct = default)
    {
        var response = await _client.GetStockTransferDetailAsync(id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Stock transfer not found.";
            return RedirectToAction(nameof(Index));
        }

        var d = response.Data;
        var request = new StockTransferSaveRequest
        {
            Id = d.Id,
            TransferNumber = d.TransferNumber,
            FromWarehouseId = d.FromWarehouseId,
            ToWarehouseId = d.ToWarehouseId,
            TransferDate = d.TransferDate,
            Carrier = d.Carrier,
            TrackingNumber = d.TrackingNumber,
            Notes = d.Notes,
            Status = d.Status,
            Lines = d.Lines.Select(l => new StockTransferLineRequest
            {
                Id = l.Id,
                ProductId = l.ProductId,
                VariantId = l.VariantId,
                Sku = l.Sku,
                ProductName = l.ProductName,
                Quantity = l.Quantity,
                Notes = l.Notes
            }).ToList()
        };

        if (request.Lines.Count == 0)
        {
            request.Lines.Add(new StockTransferLineRequest { Quantity = 1 });
        }

        await LoadLookupsAsync(ct);
        return View("Create", request);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Save(StockTransferSaveRequest request, CancellationToken ct = default)
    {
        if (request.FromWarehouseId == request.ToWarehouseId)
        {
            ModelState.AddModelError(nameof(request.ToWarehouseId), "Source and destination warehouses cannot be the same.");
        }

        if (request.Lines == null || !request.Lines.Any())
        {
            ModelState.AddModelError("Lines", "At least one product item is required for the transfer.");
        }

        if (!ModelState.IsValid)
        {
            var firstError = ModelState.Values.SelectMany(v => v.Errors).FirstOrDefault()?.ErrorMessage;
            ViewData["ErrorMessage"] = string.IsNullOrWhiteSpace(firstError) ? "Please correct errors in the transfer form." : firstError;
            TempData.Remove("ErrorMessage");
            await LoadLookupsAsync(ct);
            return View("Create", request);
        }

        var response = await _client.SaveAsync(ApiEndPoint.StockTransfer.Save, request, ct);
        if (!response.IsSuccess)
        {
            ViewData["ErrorMessage"] = response.Message ?? "Failed to save stock transfer.";
            TempData.Remove("ErrorMessage");
            await LoadLookupsAsync(ct);
            return View("Create", request);
        }

        TempData["SuccessMessage"] = response.Message ?? "Stock transfer initiated successfully.";
        return RedirectToAction(nameof(Index));
    }

    public async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await _client.GetStockTransferDetailAsync(id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Stock transfer not found.";
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateStatus(int id, int status, string? reason, CancellationToken ct = default)
    {
        var req = new UpdateStatusRequest { Id = id, Status = status, Reason = reason };
        var response = await _client.UpdateStatusAsync(ApiEndPoint.StockTransfer.UpdateStatus, req, ct);
        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message ?? "Failed to update transfer status.";
        }
        else
        {
            TempData["SuccessMessage"] = response.Message ?? "Transfer status updated successfully.";
        }

        return RedirectToAction(nameof(Details), new { id });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id, CancellationToken ct = default)
    {
        var response = await _client.DeleteAsync(ApiEndPoint.StockTransfer.Delete, id, ct);
        return Json(new { success = response.IsSuccess, message = response.Message });
    }

    private async Task LoadLookupsAsync(CancellationToken ct)
    {
        var whRes = await _client.GetLookupAsync(ApiEndPoint.Warehouse.Lookup, null, ct);
        ViewBag.Warehouses = whRes.Data ?? new List<IdNamePair>();

        var prodsRes = await _client.GetLookupAsync(ApiEndPoint.Product.Lookup, null, ct);
        ViewBag.Products = prodsRes.Data ?? new List<IdNamePair>();

        var varsRes = await _client.GetLookupAsync(ApiEndPoint.Product.VariantLookup, null, ct);
        ViewBag.Variants = varsRes.Data ?? new List<IdNamePair>();
    }
}
