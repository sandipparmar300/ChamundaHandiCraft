using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Quotes shown on the home page.</summary>
public class TestimonialController : AdminCrudController<TestimonialGridItem, TestimonialSaveRequest>
{
    private readonly IFileUploadService _fileUploadService;

    public TestimonialController(IAdminClient client, IFileUploadService fileUploadService) : base(client)
    {
        _fileUploadService = fileUploadService;
    }

    protected override string Module => "Testimonial";

    [HttpPost]
    [ValidateAntiForgeryToken]
    public override async Task<IActionResult> Save(TestimonialSaveRequest request, CancellationToken ct = default)
    {
        if (Request.Form.Files["Photo"] is { Length: > 0 } photoFile)
        {
            var photoUrl = await _fileUploadService.SaveFileAsync(photoFile, "testimonials", ct);
            if (!string.IsNullOrEmpty(photoUrl))
            {
                request.PhotoUrl = photoUrl;
            }
        }

        ModelState.Remove(nameof(request.PhotoUrl));
        ModelState.Remove("PhotoUrl");

        return await base.Save(request, ct);
    }
}
