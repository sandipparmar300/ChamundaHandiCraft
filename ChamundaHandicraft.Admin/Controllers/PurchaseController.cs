using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Purchase Orders raised against artisan workshops and material suppliers.
/// </summary>
public class PurchaseController : Controller
{
    private readonly IAdminClient _client;

    public PurchaseController(IAdminClient client)
    {
        _client = client;
    }

    public async Task<IActionResult> Index(
        int page = 1,
        string? search = null,
        int? supplierId = null,
        int? warehouseId = null,
        string? status = null,
        CancellationToken ct = default)
    {
        var suppliersTask = _client.GetLookupAsync(ApiEndPoint.Supplier.Lookup, null, ct);
        var warehousesTask = _client.GetLookupAsync(ApiEndPoint.Warehouse.Lookup, null, ct);

        var endpoint = ApiEndPoint.Purchase.GridList;
        var queryParams = new List<string>();
        if (supplierId.HasValue) queryParams.Add($"supplierId={supplierId.Value}");
        if (warehouseId.HasValue) queryParams.Add($"warehouseId={warehouseId.Value}");
        if (!string.IsNullOrWhiteSpace(status)) queryParams.Add($"status={status}");
        if (queryParams.Any()) endpoint += "?" + string.Join("&", queryParams);

        var gridTask = _client.GetGridAsync<PurchaseOrderGridItem>(
            endpoint,
            new DataTableRequest { Page = page, PageSize = 25, Search = search },
            ct);

        await Task.WhenAll(suppliersTask, warehousesTask, gridTask);

        ViewBag.Suppliers = suppliersTask.Result.Data ?? new List<IdNamePair>();
        ViewBag.Warehouses = warehousesTask.Result.Data ?? new List<IdNamePair>();
        ViewBag.SelectedSupplier = supplierId;
        ViewBag.SelectedWarehouse = warehouseId;
        ViewBag.SelectedStatus = status;
        ViewData["Search"] = search;

        var gridResult = gridTask.Result;
        if (!gridResult.IsSuccess)
        {
            TempData["ErrorMessage"] = gridResult.Message;
        }

        return View(gridResult.Data ?? PagedResult<PurchaseOrderGridItem>.Empty(25));
    }

    public async Task<IActionResult> Add(CancellationToken ct = default)
    {
        await LoadLookupsAsync(ct);
        return View("Create", new PurchaseOrderSaveRequest
        {
            OrderDate = DateTime.Today,
            ExpectedDate = DateTime.Today.AddDays(7),
            Status = "Draft",
            Lines = new List<PurchaseOrderLineRequest>
            {
                new() { OrderedQuantity = 1, UnitCost = 0, TaxPercent = 0 }
            }
        });
    }

    public async Task<IActionResult> Edit(int id, CancellationToken ct = default)
    {
        var response = await _client.GetPurchaseDetailAsync(id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Purchase order not found.";
            return RedirectToAction(nameof(Index));
        }

        await LoadLookupsAsync(ct);

        var model = new PurchaseOrderSaveRequest
        {
            Id = response.Data.Id,
            PoNumber = response.Data.PoNumber,
            SupplierId = response.Data.SupplierId,
            WarehouseId = response.Data.WarehouseId,
            OrderDate = response.Data.OrderDate,
            ExpectedDate = response.Data.ExpectedDate,
            PaymentTerms = response.Data.PaymentTerms,
            Notes = response.Data.Notes,
            SubTotal = response.Data.SubTotal,
            TaxAmount = response.Data.TaxAmount,
            ShippingAmount = response.Data.ShippingAmount,
            TotalAmount = response.Data.TotalAmount,
            Status = response.Data.Status,
            Lines = response.Data.Lines.Select(l => new PurchaseOrderLineRequest
            {
                Id = l.Id,
                ProductId = l.ProductId,
                VariantId = l.VariantId,
                Sku = l.Sku,
                ProductName = l.ProductName,
                OrderedQuantity = l.QuantityOrdered,
                UnitCost = l.UnitCost,
                TaxPercent = l.TaxPercent,
                TaxAmount = l.TaxAmount,
                LineTotal = l.LineTotal
            }).ToList()
        };

        return View("Create", model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Save(PurchaseOrderSaveRequest request, CancellationToken ct = default)
    {
        if (request.Lines == null || !request.Lines.Any())
        {
            ModelState.AddModelError("Lines", "At least one item row is required.");
        }

        if (!ModelState.IsValid)
        {
            var firstError = ModelState.Values.SelectMany(v => v.Errors).FirstOrDefault()?.ErrorMessage;
            ViewData["ErrorMessage"] = string.IsNullOrWhiteSpace(firstError) ? "Please correct errors in the purchase order." : firstError;
            TempData.Remove("ErrorMessage");
            await LoadLookupsAsync(ct);
            return View("Create", request);
        }

        var response = await _client.SaveAsync(ApiEndPoint.Purchase.Save, request, ct);
        if (!response.IsSuccess)
        {
            ViewData["ErrorMessage"] = response.Message ?? "Failed to save purchase order.";
            TempData.Remove("ErrorMessage");
            await LoadLookupsAsync(ct);
            return View("Create", request);
        }

        TempData["SuccessMessage"] = response.Message ?? "Purchase order saved successfully.";
        return RedirectToAction(nameof(Index));
    }

    public async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await _client.GetPurchaseDetailAsync(id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Purchase order not found.";
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Receive(int id, CancellationToken ct = default)
    {
        var response = await _client.ReceivePurchaseOrderAsync(id, ct);
        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message ?? "Failed to receive purchase order stock.";
        }
        else
        {
            TempData["SuccessMessage"] = response.Message ?? "Stock received and inventory reconciled successfully.";
        }

        return RedirectToAction(nameof(Details), new { id });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id, CancellationToken ct = default)
    {
        var response = await _client.DeleteAsync(ApiEndPoint.Purchase.Delete, id, ct);
        return Json(new { success = response.IsSuccess, message = response.Message });
    }

    private async Task LoadLookupsAsync(CancellationToken ct)
    {
        var supRes = await _client.GetLookupAsync(ApiEndPoint.Supplier.Lookup, null, ct);
        ViewBag.Suppliers = supRes.Data ?? new List<IdNamePair>();

        var whRes = await _client.GetLookupAsync(ApiEndPoint.Warehouse.Lookup, null, ct);
        ViewBag.Warehouses = whRes.Data ?? new List<IdNamePair>();

        var prodsRes = await _client.GetLookupAsync(ApiEndPoint.Product.Lookup, null, ct);
        ViewBag.Products = prodsRes.Data ?? new List<IdNamePair>();

        var varsRes = await _client.GetLookupAsync(ApiEndPoint.Product.VariantLookup, null, ct);
        ViewBag.Variants = varsRes.Data ?? new List<IdNamePair>();
    }
}
