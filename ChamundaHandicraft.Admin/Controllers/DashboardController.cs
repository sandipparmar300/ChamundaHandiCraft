using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Module 01 · Dashboard — docs/Admin Flows/Dashboard.txt.
/// The tiles aggregate across Orders, Inventory, Reviews and Support, which is why the
/// action takes one composed response rather than the view calling five endpoints.
/// </summary>
public class DashboardController : Controller
{
    private readonly IAdminClient _client;

    public DashboardController(IAdminClient client) => _client = client;

    public async Task<IActionResult> Index(CancellationToken ct = default)
    {
        var response = await _client.GetDashboardAsync(ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
        }

        return View(response.Data ?? new AdminDashboardViewModel());
    }
}
