using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Module 06 · Order Management — docs/Admin Flows/Orders.txt.
///
/// Orders are created by checkout, never by an admin, so there is no Add action —
/// only listing, detail and the status transitions. Each transition is what the
/// customer's tracking page renders as the next timeline step, which is why
/// <see cref="OrderStatusUpdateRequest.NotifyCustomer"/> defaults to true.
/// See docs/INTEGRATION-MAP.md §4.
/// </summary>
public class OrderController : Controller
{
    private readonly IAdminClient _client;

    public OrderController(IAdminClient client) => _client = client;

    public async Task<IActionResult> Index(int page = 1, string? search = null, CancellationToken ct = default)
    {
        var response = await _client.GetOrdersAsync(
            new DataTableRequest { Page = page, PageSize = 25, Search = search }, ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
        }

        return View(response.Data ?? PagedResult<OrderGridItem>.Empty(25));
    }

    public async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await _client.GetOrderAsync(id, ct);

        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message;
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateStatus(OrderStatusUpdateRequest request, CancellationToken ct = default)
    {
        var response = await _client.UpdateOrderStatusAsync(request, ct);
        return Json(new { success = response.IsSuccess, message = response.Message });
    }
}
