using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Key-based RBAC. Each row is one <c>module.entity.action</c> key a role either holds
/// or does not — the same keys the API checks, so the panel cannot offer an action the
/// backend would refuse.
/// </summary>
public class PermissionController : Controller
{
    private readonly IAdminClient _client;

    public PermissionController(IAdminClient client) => _client = client;

    public async Task<IActionResult> Index(int? roleId, CancellationToken ct = default)
    {
        var response = await _client.GetPermissionMatrixAsync(roleId, ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
        }

        // The role picker drives the whole screen, so its options come from the same
        // source the Role module lists — never a hard-coded set that can drift.
        var roles = await _client.GetLookupAsync(ApiEndPoint.Crud.Lookup("Role"), null, ct);

        ViewData["RoleId"] = roleId;
        ViewData["Roles"] = roles.Data ?? new List<IdNamePair>();

        return View(response.Data ?? new List<PermissionMatrixItem>());
    }
}
