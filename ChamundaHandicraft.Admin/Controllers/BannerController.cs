using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Home hero and injected placements.</summary>
public class BannerController : AdminCrudController<BannerViewModel, BannerSaveRequest>
{
    private readonly IFileUploadService _fileUploadService;

    public BannerController(IAdminClient client, IFileUploadService fileUploadService) : base(client)
    {
        _fileUploadService = fileUploadService;
    }

    protected override string Module => "Banner";

    [HttpPost]
    [ValidateAntiForgeryToken]
    public override async Task<IActionResult> Save(BannerSaveRequest request, CancellationToken ct = default)
    {
        if (Request.Form.Files["Photo"] is { Length: > 0 } photoFile)
        {
            var bannerUrl = await _fileUploadService.SaveFileAsync(photoFile, "banners", ct);
            if (!string.IsNullOrEmpty(bannerUrl))
            {
                request.ImageUrl = bannerUrl;
            }
        }

        if (string.IsNullOrWhiteSpace(request.ImageUrl))
        {
            request.ImageUrl = "/assets/images/default-banner.png";
        }

        ModelState.Remove(nameof(request.ImageUrl));
        ModelState.Remove("ImageUrl");

        if (string.IsNullOrWhiteSpace(request.ImageAlt))
        {
            request.ImageAlt = string.IsNullOrWhiteSpace(request.Heading) ? "Banner" : request.Heading;
        }

        ModelState.Remove(nameof(request.ImageAlt));
        ModelState.Remove("ImageAlt");

        return await base.Save(request, ct);
    }
}
