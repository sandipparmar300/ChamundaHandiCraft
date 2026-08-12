using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// The shared shape of an admin module: a searchable grid, an add/edit form, a detail
/// screen, a delete and a status toggle.
///
/// Most of the 60 modules are exactly this against a different entity, so they derive
/// from it and declare only what differs — their <see cref="Module"/> name and their
/// two types. Modules with real behaviour beyond CRUD (orders, products, settings,
/// moderation) do not use this base; their semantics deserve explicit actions.
/// </summary>
/// <typeparam name="TGrid">The row type the listing view binds.</typeparam>
/// <typeparam name="TSave">The payload the create/edit form posts.</typeparam>
public abstract class AdminCrudController<TGrid, TSave> : Controller
    where TGrid : class
    where TSave : class, new()
{
    protected readonly IAdminClient Client;

    protected AdminCrudController(IAdminClient client) => Client = client;

    /// <summary>The module segment in <c>Admin/{Module}/GridList</c>.</summary>
    protected abstract string Module { get; }

    /// <summary>Rows per page. Overridable for grids with wide rows.</summary>
    protected virtual int PageSize => 25;

    public virtual async Task<IActionResult> Index(
        int page = 1, string? search = null, CancellationToken ct = default)
    {
        var response = await Client.GetGridAsync<TGrid>(
            ApiEndPoint.Crud.GridList(Module),
            new DataTableRequest { Page = page, PageSize = PageSize, Search = search },
            ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
        }

        ViewData["Search"] = search;

        return View(response.Data ?? PagedResult<TGrid>.Empty(PageSize));
    }

    public virtual IActionResult Add() => View("Create", new TSave());

    public virtual async Task<IActionResult> Edit(int id, CancellationToken ct = default)
    {
        var response = await Client.GetByIdAsync<TSave>(ApiEndPoint.Crud.GetById(Module), id, ct);

        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message;
            return RedirectToAction(nameof(Index));
        }

        return View("Create", response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public virtual async Task<IActionResult> Save(TSave request, CancellationToken ct = default)
    {
        if (!ModelState.IsValid)
        {
            return View("Create", request);
        }

        var response = await Client.SaveAsync(ApiEndPoint.Crud.Save(Module), request, ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
            return View("Create", request);
        }

        TempData["SuccessMessage"] = response.Message;
        return RedirectToAction(nameof(Index));
    }

    public virtual async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await Client.GetByIdAsync<TGrid>(ApiEndPoint.Crud.GetById(Module), id, ct);

        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message;
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public virtual async Task<IActionResult> Delete(int id, CancellationToken ct = default)
    {
        var response = await Client.DeleteAsync(ApiEndPoint.Crud.Delete(Module), id, ct);
        return Json(new { success = response.IsSuccess, message = response.Message });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public virtual async Task<IActionResult> UpdateStatus(UpdateStatusRequest request, CancellationToken ct = default)
    {
        var response = await Client.UpdateStatusAsync(ApiEndPoint.Crud.UpdateStatus(Module), request, ct);
        return Json(new { success = response.IsSuccess, message = response.Message });
    }
}

/// <summary>
/// Read-only modules — queues and logs an operator inspects but never creates:
/// approvals, audit trail, submissions, settlements, invoices.
/// </summary>
public abstract class AdminListController<TGrid> : Controller
    where TGrid : class
{
    protected readonly IAdminClient Client;

    protected AdminListController(IAdminClient client) => Client = client;

    protected abstract string Module { get; }
    protected virtual int PageSize => 25;

    public virtual async Task<IActionResult> Index(
        int page = 1, string? search = null, CancellationToken ct = default)
    {
        var response = await Client.GetGridAsync<TGrid>(
            ApiEndPoint.Crud.GridList(Module),
            new DataTableRequest { Page = page, PageSize = PageSize, Search = search },
            ct);

        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message;
        }

        ViewData["Search"] = search;

        return View(response.Data ?? PagedResult<TGrid>.Empty(PageSize));
    }

    public virtual async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await Client.GetByIdAsync<TGrid>(ApiEndPoint.Crud.GetById(Module), id, ct);

        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message;
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }
}
