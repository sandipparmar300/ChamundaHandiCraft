using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>The makers credited on every product page.</summary>
public class ArtisanController : AdminCrudController<ArtisanGridItem, ArtisanSaveRequest>
{
    private readonly IFileUploadService _fileUploadService;

    public ArtisanController(IAdminClient client, IFileUploadService fileUploadService) : base(client)
    {
        _fileUploadService = fileUploadService;
    }

    protected override string Module => "Artisan";

    [HttpPost]
    [ValidateAntiForgeryToken]
    public override async Task<IActionResult> Save(ArtisanSaveRequest request, CancellationToken ct = default)
    {
        if (Request.Form.Files["Photo"] is { Length: > 0 } photoFile)
        {
            var photoUrl = await _fileUploadService.SaveFileAsync(photoFile, "artisans", ct);
            if (!string.IsNullOrEmpty(photoUrl))
            {
                request.PhotoUrl = photoUrl;
            }
        }

        return await base.Save(request, ct);
    }

    [HttpPost]
    public async Task<IActionResult> UploadPhoto(IFormFile file, CancellationToken ct = default)
    {
        if (file == null || file.Length == 0)
            return Json(new { success = false, message = "No file uploaded." });

        var url = await _fileUploadService.SaveFileAsync(file, "artisans", ct);
        return Json(new { success = !string.IsNullOrEmpty(url), url });
    }

    public override async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await Client.GetByIdAsync<ArtisanSaveRequest>(ApiEndPoint.Crud.GetById(Module), id, ct);

        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message;
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }
}

