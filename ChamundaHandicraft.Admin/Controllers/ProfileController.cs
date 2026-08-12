using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>The signed-in operator's own profile and security settings.</summary>
public class ProfileController : Controller
{
    private readonly IAdminClient _client;

    public ProfileController(IAdminClient client) => _client = client;

    public async Task<IActionResult> Index(CancellationToken ct = default)
    {
        var response = await _client.GetProfileAsync(ct);
        return View(response.Data ?? new AdminProfileViewModel());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Save(AdminProfileViewModel request, CancellationToken ct = default)
    {
        var response = await _client.SaveProfileAsync(request, ct);

        TempData[response.IsSuccess ? "SuccessMessage" : "ErrorMessage"] = response.Message;

        return RedirectToAction(nameof(Index));
    }
}
