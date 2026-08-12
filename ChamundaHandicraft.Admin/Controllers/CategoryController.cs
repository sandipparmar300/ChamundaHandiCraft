using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Module 04 · Categories — the storefront taxonomy behind the mega menu, the PLP and
/// every breadcrumb. See docs/INTEGRATION-MAP.md §2.
///
/// The listing is a tree rather than a flat page, because the hierarchy is the point:
/// a category's parent decides where it appears in the menu.
/// </summary>
public class CategoryController : AdminCrudController<CategoryViewModel, CategorySaveRequest>
{
    public CategoryController(IAdminClient client) : base(client) { }

    protected override string Module => "Category";

    public override async Task<IActionResult> Index(
        int page = 1, string? search = null, CancellationToken ct = default)
    {
        var response = await Client.GetCategoryTreeAsync(ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
        }

        return View(response.Data ?? new List<CategoryViewModel>());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public override async Task<IActionResult> Save(CategorySaveRequest request, CancellationToken ct = default)
    {
        if (!ModelState.IsValid)
        {
            return View("Create", request);
        }

        var response = await Client.SaveCategoryAsync(request, ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
            return View("Create", request);
        }

        TempData["SuccessMessage"] = response.Message;
        return RedirectToAction(nameof(Index));
    }
}
