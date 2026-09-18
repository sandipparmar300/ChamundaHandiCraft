using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Physical counts and their discrepancies.</summary>
public class StockTakeController : AdminCrudController<StockTakeGridItem, StockTakeGridItem>
{
    public StockTakeController(IAdminClient client) : base(client) { }

    protected override string Module => "StockTake";

    private async Task LoadWarehousesAsync(CancellationToken ct = default)
    {
        var res = await Client.GetLookupAsync(ApiEndPoint.Warehouse.Lookup, null, ct);
        ViewBag.Warehouses = res.Data ?? new List<IdNamePair>();
    }

    public override async Task<IActionResult> Add()
    {
        await LoadWarehousesAsync();
        return View("Create", new StockTakeGridItem { StartedOn = DateTime.Today });
    }

    public override async Task<IActionResult> Edit(int id, CancellationToken ct = default)
    {
        await LoadWarehousesAsync(ct);
        return await base.Edit(id, ct);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public override async Task<IActionResult> Save(StockTakeGridItem request, CancellationToken ct = default)
    {
        await LoadWarehousesAsync(ct);
        return await base.Save(request, ct);
    }
}
