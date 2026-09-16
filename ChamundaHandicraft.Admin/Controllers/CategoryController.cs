using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Module 04 · Categories — the storefront taxonomy behind the mega menu, the PLP and
/// every breadcrumb.
/// </summary>
public class CategoryController : Controller
{
    private readonly IAdminClient _client;
    private readonly IFileUploadService _fileUploadService;

    public CategoryController(IAdminClient client, IFileUploadService fileUploadService)
    {
        _client = client;
        _fileUploadService = fileUploadService;
    }

    public async Task<IActionResult> Index(CancellationToken ct = default)
    {
        var response = await _client.GetCategoryTreeAsync(ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
        }

        return View(response.Data ?? new List<CategoryViewModel>());
    }

    public async Task<IActionResult> Add(int? parentId = null, CancellationToken ct = default)
    {
        await LoadParentsAsync(null, ct);
        return View("Create", new CategorySaveRequest { ParentId = parentId });
    }

    public async Task<IActionResult> Edit(int id, CancellationToken ct = default)
    {
        var response = await _client.GetCategoryAsync(id, ct);

        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Category not found.";
            return RedirectToAction(nameof(Index));
        }

        await LoadParentsAsync(id, ct);
        return View("Create", response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Save(CategorySaveRequest request, CancellationToken ct = default)
    {
        // Handle file upload if posted directly
        if (Request.Form.Files["Photo"] is { Length: > 0 } photoFile)
        {
            var imageUrl = await _fileUploadService.SaveFileAsync(photoFile, "categories", ct);
            if (!string.IsNullOrEmpty(imageUrl))
            {
                request.ImageUrl = imageUrl;
            }
        }

        if (!ModelState.IsValid)
        {
            var firstError = ModelState.Values.SelectMany(v => v.Errors).FirstOrDefault()?.ErrorMessage;
            TempData["ErrorMessage"] = string.IsNullOrWhiteSpace(firstError) ? "Please fill in all required fields correctly." : firstError;
            await LoadParentsAsync(request.Id > 0 ? request.Id : null, ct);
            return View("Create", request);
        }

        var response = await _client.SaveCategoryAsync(request, ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
            await LoadParentsAsync(request.Id > 0 ? request.Id : null, ct);
            return View("Create", request);
        }

        TempData["SuccessMessage"] = response.Message ?? "Category saved successfully.";
        return RedirectToAction(nameof(Index));
    }

    public async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await _client.GetCategoryAsync(id, ct);

        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Category not found.";
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id, CancellationToken ct = default)
    {
        var response = await _client.DeleteCategoryAsync(id, ct);
        return Json(new { success = response.IsSuccess, message = response.Message });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateStatus(UpdateStatusRequest request, CancellationToken ct = default)
    {
        var response = await _client.UpdateCategoryStatusAsync(request, ct);
        return Json(new { success = response.IsSuccess, message = response.Message });
    }

    [HttpPost]
    public async Task<IActionResult> UploadImage(IFormFile file, CancellationToken ct = default)
    {
        if (file == null || file.Length == 0)
            return Json(new { success = false, message = "No file uploaded." });

        var url = await _fileUploadService.SaveFileAsync(file, "categories", ct);
        return Json(new { success = !string.IsNullOrEmpty(url), url });
    }

    private async Task LoadParentsAsync(int? excludeId, CancellationToken ct)
    {
        var lookupResponse = await _client.GetCategoryLookupAsync(ct);
        var parents = lookupResponse.Data ?? new List<IdNamePair>();
        if (excludeId.HasValue)
        {
            parents = parents.Where(p => p.Id != excludeId.Value).ToList();
        }
        // Only root categories can be parents
        parents = parents.Where(p => p.ParentId == null).ToList();
        ViewBag.Parents = parents;
    }
}
