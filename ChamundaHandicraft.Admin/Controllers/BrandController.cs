using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Workshops and studio lines.</summary>
public class BrandController : AdminCrudController<BrandGridItem, BrandSaveRequest>
{
    private readonly IFileUploadService _fileUploadService;

    public BrandController(IAdminClient client, IFileUploadService fileUploadService) : base(client)
    {
        _fileUploadService = fileUploadService;
    }

    protected override string Module => "Brand";

    [HttpPost]
    [ValidateAntiForgeryToken]
    public override async Task<IActionResult> Save(BrandSaveRequest request, CancellationToken ct = default)
    {
        if (Request.Form.Files["Photo"] is { Length: > 0 } photoFile)
        {
            var logoUrl = await _fileUploadService.SaveFileAsync(photoFile, "brands", ct);
            if (!string.IsNullOrEmpty(logoUrl))
            {
                request.LogoUrl = logoUrl;
            }
        }

        return await base.Save(request, ct);
    }

    [HttpPost]
    public async Task<IActionResult> UploadLogo(IFormFile file, CancellationToken ct = default)
    {
        if (file == null || file.Length == 0)
            return Json(new { success = false, message = "No file uploaded." });

        var url = await _fileUploadService.SaveFileAsync(file, "brands", ct);
        return Json(new { success = !string.IsNullOrEmpty(url), url });
    }

    public override async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await Client.GetByIdAsync<BrandSaveRequest>(ApiEndPoint.Crud.GetById(Module), id, ct);

        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message;
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }
}

