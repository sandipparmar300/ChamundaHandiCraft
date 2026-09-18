using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Workshops and vendors we purchase stock from.</summary>
public class SupplierController : AdminCrudController<SupplierGridItem, SupplierSaveRequest>
{
    public SupplierController(IAdminClient client) : base(client) { }

    protected override string Module => "Supplier";

    public override async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await Client.GetSupplierDetailAsync(id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Supplier not found.";
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }
}
