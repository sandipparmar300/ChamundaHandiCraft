using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Stock locations.</summary>
public class WarehouseController : AdminCrudController<WarehouseGridItem, WarehouseSaveRequest>
{
    public WarehouseController(IAdminClient client) : base(client) { }

    protected override string Module => "Warehouse";

    public override async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await Client.GetWarehouseDetailAsync(id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Warehouse not found.";
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }
}
