using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Module 20 · Settings.
///
/// This screen writes the figures the storefront quotes — the free-shipping threshold
/// on every cart, the COD fee on every checkout, the return window on every order page.
/// Saving here changes what every shopper sees, which is why it is versioned and has a
/// history screen. See docs/INTEGRATION-MAP.md §9.
/// </summary>
public class SettingsController : Controller
{
    private readonly IAdminClient _client;

    public SettingsController(IAdminClient client) => _client = client;

    public async Task<IActionResult> Index(string section = SettingsSection.Storefront, CancellationToken ct = default)
    {
        var response = await _client.GetSettingsAsync(section, ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
        }

        ViewData["Section"] = section;

        return View(response.Data ?? new Dictionary<string, string?>());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Save(SettingsSectionRequest request, CancellationToken ct = default)
    {
        var response = await _client.SaveSettingsAsync(request, ct);

        TempData[response.IsSuccess ? "SuccessMessage" : "ErrorMessage"] = response.Message;

        return RedirectToAction(nameof(Index), new { section = request.Section });
    }

    public async Task<IActionResult> History(CancellationToken ct = default)
    {
        var response = await _client.GetSettingsHistoryAsync(ct);
        return View(response.Data ?? new List<SettingsHistoryItem>());
    }
}
