using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// User Management - Roles administration.
/// </summary>
public class RoleController : AdminCrudController<RoleGridItem, RoleSaveRequest>
{
    public RoleController(IAdminClient client) : base(client) { }

    protected override string Module => "Role";

    public override async Task<IActionResult> Add()
    {
        var matrixResponse = await Client.GetPermissionMatrixAsync(null);
        ViewBag.Permissions = matrixResponse.Data ?? new List<PermissionMatrixItem>();

        return View("Create", new RoleSaveRequest());
    }

    public override async Task<IActionResult> Edit(int id, CancellationToken ct = default)
    {
        var response = await Client.GetByIdAsync<RoleSaveRequest>(ApiEndPoint.Crud.GetById(Module), id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Role not found.";
            return RedirectToAction(nameof(Index));
        }

        var matrixResponse = await Client.GetPermissionMatrixAsync(id, ct);
        ViewBag.Permissions = matrixResponse.Data ?? new List<PermissionMatrixItem>();

        return View("Create", response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public override async Task<IActionResult> Save(RoleSaveRequest request, CancellationToken ct = default)
    {
        var permValues = Request.Form["PermissionIds"];
        if (permValues.Count > 0)
        {
            request.PermissionIds = permValues
                .SelectMany(v => (v ?? string.Empty).Split(',', StringSplitOptions.RemoveEmptyEntries))
                .Where(s => int.TryParse(s.Trim(), out _))
                .Select(s => int.Parse(s.Trim()))
                .Distinct()
                .ToList();
        }

        if (string.IsNullOrWhiteSpace(request.RoleName))
        {
            TempData["ErrorMessage"] = "Role Name is required.";
            var matrixResponse = await Client.GetPermissionMatrixAsync(request.Id > 0 ? request.Id : null, ct);
            ViewBag.Permissions = matrixResponse.Data ?? new List<PermissionMatrixItem>();
            return View("Create", request);
        }

        var response = await Client.SaveAsync(ApiEndPoint.Crud.Save(Module), request, ct);
        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message ?? "Failed to save role.";
            var matrixResponse = await Client.GetPermissionMatrixAsync(request.Id > 0 ? request.Id : null, ct);
            ViewBag.Permissions = matrixResponse.Data ?? new List<PermissionMatrixItem>();
            return View("Create", request);
        }

        TempData["SuccessMessage"] = response.Message ?? "Role saved successfully.";

        var saveAndNew = string.Equals(Request.Form["saveAndNew"], "true", StringComparison.OrdinalIgnoreCase);
        if (saveAndNew)
        {
            return RedirectToAction(nameof(Add));
        }

        return RedirectToAction(nameof(Index));
    }

    public override async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await Client.GetByIdAsync<RoleSaveRequest>(ApiEndPoint.Crud.GetById(Module), id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Role not found.";
            return RedirectToAction(nameof(Index));
        }

        var matrixResponse = await Client.GetPermissionMatrixAsync(id, ct);
        ViewBag.Permissions = matrixResponse.Data ?? new List<PermissionMatrixItem>();

        return View(response.Data);
    }
}
