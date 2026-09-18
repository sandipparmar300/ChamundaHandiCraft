using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Module 03 · Product Management — docs/Admin Flows/Product.txt.
/// The write end of the catalogue. What is saved and published here is what the
/// customer site serves at /p/{slug}.
/// </summary>
public class ProductController : Controller
{
    private readonly IAdminClient _client;
    private readonly IFileUploadService _fileUploadService;

    public ProductController(IAdminClient client, IFileUploadService fileUploadService)
    {
        _client = client;
        _fileUploadService = fileUploadService;
    }

    public async Task<IActionResult> Index(int page = 1, string? search = null, CancellationToken ct = default)
    {
        var response = await _client.GetProductsAsync(
            new DataTableRequest { Page = page, PageSize = 25, Search = search }, ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
        }

        ViewData["Search"] = search;
        return View(response.Data ?? PagedResult<ProductGridItem>.Empty(25));
    }

    public async Task<IActionResult> Add(CancellationToken ct = default)
    {
        await LoadLookupsAsync(ct);
        return View("Create", new ProductSaveRequest());
    }

    public async Task<IActionResult> Edit(int id, CancellationToken ct = default)
    {
        var response = await _client.GetProductAsync(id, ct);

        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message;
            return RedirectToAction(nameof(Index));
        }

        await LoadLookupsAsync(ct);
        return View("Create", response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Save(ProductSaveRequest request, CancellationToken ct = default)
    {
        // Handle direct form file uploads for ProductImages if present
        var uploadedFiles = Request.Form.Files.GetFiles("ProductImages");
        if (uploadedFiles.Count > 0)
        {
            var savedUrls = await _fileUploadService.SaveFilesAsync(uploadedFiles, "products", ct);
            foreach (var url in savedUrls)
            {
                request.Media.Add(new MediaViewModel
                {
                    Url = url,
                    IsPrimary = request.Media.Count == 0,
                    AltText = request.Name
                });
            }
        }

        // Ensure every media item has valid AltText and at least one primary item
        if (request.Media is { Count: > 0 })
        {
            var hasPrimary = false;
            for (int i = 0; i < request.Media.Count; i++)
            {
                if (string.IsNullOrWhiteSpace(request.Media[i].AltText))
                {
                    request.Media[i].AltText = string.IsNullOrWhiteSpace(request.Name) ? "Product Image" : request.Name;
                }
                request.Media[i].SortOrder = i;
                if (request.Media[i].IsPrimary)
                {
                    hasPrimary = true;
                }
            }
            if (!hasPrimary)
            {
                request.Media[0].IsPrimary = true;
            }
        }

        // Auto-enable HasVariants if variants list has rows
        if (request.Variants is { Count: > 0 })
        {
            request.HasVariants = true;
        }

        if (!ModelState.IsValid)
        {
            await LoadLookupsAsync(ct);
            return View("Create", request);
        }

        var response = await _client.SaveProductAsync(request, ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
            await LoadLookupsAsync(ct);
            return View("Create", request);
        }

        TempData["SuccessMessage"] = response.Message;
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> UploadImage(IFormFile file, CancellationToken ct = default)
    {
        if (file == null || file.Length == 0)
            return Json(new { success = false, message = "No file received." });

        var url = await _fileUploadService.SaveFileAsync(file, "products", ct);
        return Json(new { success = !string.IsNullOrEmpty(url), url });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id, CancellationToken ct = default)
    {
        var response = await _client.DeleteProductAsync(id, ct);
        return Json(new { success = response.IsSuccess, message = response.Message });
    }

    /// <summary>
    /// The publish gate. Moving a product to Published makes it appear on storefront.
    /// </summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateStatus(UpdateStatusRequest request, CancellationToken ct = default)
    {
        var response = await _client.UpdateProductStatusAsync(request, ct);
        return Json(new { success = response.IsSuccess, message = response.Message });
    }

    public async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await _client.GetProductAsync(id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message;
            return RedirectToAction(nameof(Index));
        }

        await LoadLookupsAsync(ct);
        return View(response.Data);
    }

    private async Task LoadLookupsAsync(CancellationToken ct)
    {
        var lookupsResponse = await _client.GetProductLookupsAsync(ct);
        var lookups = lookupsResponse.Data ?? new ProductLookupsViewModel();
        if (lookups.Warehouses.Count == 0)
        {
            var whRes = await _client.GetLookupAsync(ApiEndPoint.Warehouse.Lookup, null, ct);
            lookups.Warehouses = whRes.Data ?? new List<IdNamePair>();
        }
        ViewBag.Lookups = lookups;
    }
}
