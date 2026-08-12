using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Module 15 · Review moderation.
///
/// Approving publishes the review to the PDP and recalculates the product's average;
/// rejecting keeps it hidden and shows the author why. Nothing here edits the
/// shopper's words, and rejecting a review for being negative is out of policy —
/// the reason going back to the author is what keeps that honest.
/// See docs/INTEGRATION-MAP.md §8.
/// </summary>
public class ReviewController : Controller
{
    private readonly IAdminClient _client;

    public ReviewController(IAdminClient client) => _client = client;

    public async Task<IActionResult> Index(int page = 1, string? search = null, CancellationToken ct = default)
    {
        var response = await _client.GetReviewQueueAsync(
            new DataTableRequest { Page = page, PageSize = 25, Search = search }, ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
        }

        return View(response.Data ?? PagedResult<ReviewModerationItem>.Empty(25));
    }

    public async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await _client.GetReviewAsync(id, ct);

        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message;
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Moderate(int id, bool approve, string? reason, CancellationToken ct = default)
    {
        var response = await _client.ModerateReviewAsync(id, approve, reason, ct);
        return Json(new { success = response.IsSuccess, message = response.Message });
    }
}
