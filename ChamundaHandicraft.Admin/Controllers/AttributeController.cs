using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Product attributes — these become the PLP facets and PDP option selectors.</summary>
public class AttributeController : AdminCrudController<AttributeGridItem, AttributeSaveRequest>
{
    public AttributeController(IAdminClient client) : base(client) { }

    protected override string Module => "Attribute";

    public override async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await Client.GetByIdAsync<AttributeSaveRequest>(ApiEndPoint.Crud.GetById(Module), id, ct);

        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message;
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }
}

