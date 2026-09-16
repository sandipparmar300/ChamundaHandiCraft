using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Storefront navigation.</summary>
public class MenuController : AdminCrudController<MenuGridItem, MenuGridItem>
{
    public MenuController(IAdminClient client) : base(client) { }

    protected override string Module => "Menu";

    [HttpGet]
    public async Task<IActionResult> Add(int? parentId = null, CancellationToken cancellationToken = default)
    {
        await LoadLookupsAsync(null);
        return View("Create", new MenuGridItem { ParentId = parentId, CreatedOn = DateTime.UtcNow });
    }

    public override async Task<IActionResult> Edit(int id, CancellationToken ct = default)
    {
        var response = await Client.GetByIdAsync<MenuGridItem>(ApiEndPoint.Crud.GetById(Module), id, ct);

        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Menu item not found.";
            return RedirectToAction(nameof(Index));
        }

        await LoadLookupsAsync(id);
        return View("Create", response.Data);
    }

    public override async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await Client.GetByIdAsync<MenuGridItem>(ApiEndPoint.Crud.GetById(Module), id, ct);

        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Menu item not found.";
            return RedirectToAction(nameof(Index));
        }

        var gridResponse = await Client.GetGridAsync<MenuGridItem>(
            ApiEndPoint.Crud.GridList(Module),
            new DataTableRequest { Page = 1, PageSize = 100 },
            ct);

        var allItems = gridResponse.Data?.Items ?? new List<MenuGridItem>();
        ViewBag.Children = allItems.Where(c => c.ParentId == id).ToList();

        return View(response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public override async Task<IActionResult> Save(MenuGridItem request, CancellationToken ct = default)
    {
        if (request.CreatedOn == DateTime.MinValue || request.CreatedOn.Year <= 1)
        {
            request.CreatedOn = DateTime.UtcNow;
        }

        if (!ModelState.IsValid)
        {
            var firstError = ModelState.Values.SelectMany(v => v.Errors).FirstOrDefault()?.ErrorMessage;
            TempData["ErrorMessage"] = string.IsNullOrWhiteSpace(firstError) ? "Please fill in all required fields correctly." : firstError;
            await LoadLookupsAsync(request.Id > 0 ? request.Id : null);
            return View("Create", request);
        }

        var response = await Client.SaveAsync(ApiEndPoint.Crud.Save(Module), request, ct);

        if (!response.IsSuccess)
        {
            var msg = response.Message;
            if (response.Errors != null && response.Errors.Count > 0)
            {
                var errList = response.Errors.Select(e => $"{e.Key}: {string.Join(", ", e.Value)}");
                msg = string.IsNullOrWhiteSpace(msg) ? string.Join("; ", errList) : $"{msg} ({string.Join("; ", errList)})";
            }
            if (string.IsNullOrWhiteSpace(msg))
            {
                msg = $"Failed to save menu item (HTTP {(int)response.StatusCode}).";
            }
            TempData["ErrorMessage"] = msg;
            await LoadLookupsAsync(request.Id > 0 ? request.Id : null);
            return View("Create", request);
        }

        TempData["SuccessMessage"] = response.Message ?? "Menu item saved successfully.";
        return RedirectToAction(nameof(Index));
    }

    private async Task LoadLookupsAsync(int? excludeId)
    {
        var menuParentsResponse = await Client.GetLookupAsync(ApiEndPoint.Crud.Lookup(Module));
        var parents = menuParentsResponse.Data ?? new List<IdNamePair>();
        if (excludeId.HasValue)
        {
            parents = parents.Where(p => p.Id != excludeId.Value).ToList();
        }
        ViewBag.Parents = parents;

        var categoryResponse = await Client.GetLookupAsync(ApiEndPoint.Category.Lookup);
        ViewBag.Categories = categoryResponse.Data ?? new List<IdNamePair>();
    }
}
