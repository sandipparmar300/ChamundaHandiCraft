using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Flash sales and category offers.</summary>
public class OfferController : AdminCrudController<OfferGridItem, FlashSaleSaveRequest>
{
    private readonly IFileUploadService _fileUploadService;

    public OfferController(IAdminClient client, IFileUploadService fileUploadService) : base(client)
    {
        _fileUploadService = fileUploadService;
    }

    protected override string Module => "Offer";

    [HttpPost]
    [ValidateAntiForgeryToken]
    public override async Task<IActionResult> Save(FlashSaleSaveRequest request, CancellationToken ct = default)
    {
        if (Request.Form.Files["Photo"] is { Length: > 0 } photoFile)
        {
            var bannerUrl = await _fileUploadService.SaveFileAsync(photoFile, "offers", ct);
            if (!string.IsNullOrEmpty(bannerUrl))
            {
                request.BannerUrl = bannerUrl;
            }
        }

        ModelState.Remove(nameof(request.BannerUrl));
        ModelState.Remove("BannerUrl");

        return await base.Save(request, ct);
    }
}
