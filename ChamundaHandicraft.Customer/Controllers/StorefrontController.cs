using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Base for every storefront controller.
///
/// The header/footer state is resolved through <see cref="IStorefrontClient"/> before
/// each action, so the cart badge, wishlist count and points chip arrive from the same
/// seam as everything else rather than from a field a controller happens to set.
/// </summary>
public abstract class StorefrontController : Controller
{
    protected readonly IStorefrontClient Client;

    protected ShellViewModel Shell { get; private set; } = new();

    protected StorefrontController(IStorefrontClient client) => Client = client;

    public override async Task OnActionExecutionAsync(
        ActionExecutingContext context, ActionExecutionDelegate next)
    {
        Shell = await Client.GetShellAsync(context.HttpContext.RequestAborted);
        ViewData["Shell"] = Shell;

        await next();
    }

    /// <summary>Highlights the matching primary nav item and mobile tab.</summary>
    protected void ActiveNav(string key) => Shell.ActiveNav = key;

    /// <summary>Switches to the minimal chrome used on checkout and payment.</summary>
    protected void MinimalChrome()
    {
        Shell.FooterVariant = "Minimal";
        Shell.ShowBottomTabs = false;
        Shell.ShowAnnouncement = false;
    }

    protected void Page(string title, string? description = null)
    {
        ViewData["Title"] = title;
        if (description is not null) ViewData["Description"] = description;
    }

    protected void Crumbs(params (string Label, string? Url)[] items) =>
        ViewData["Breadcrumbs"] = items
            .Select(i => new BreadcrumbItem { Label = i.Label, Url = i.Url })
            .ToList();

    /// <summary>
    /// Turns a failed envelope into the right storefront response: the error page with
    /// the API's own message and status, rather than a generic one that tells the
    /// shopper nothing about how to recover (CX principle 12).
    /// </summary>
    protected IActionResult Problem<T>(ResponseViewModel<T> response)
    {
        ViewData["StatusCode"] = (int)response.StatusCode;
        ViewData["Title"] = response.Message;
        Response.StatusCode = (int)response.StatusCode;

        return View("Error");
    }
}
