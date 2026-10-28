using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Http;
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
        // Ensure guest cart tracking cookie exists
        if (!context.HttpContext.Request.Cookies.TryGetValue(SessionKeys.GuestTokenCookie, out var guestToken) || string.IsNullOrWhiteSpace(guestToken))
        {
            guestToken = Guid.NewGuid().ToString("N");
            context.HttpContext.Response.Cookies.Append(SessionKeys.GuestTokenCookie, guestToken, new CookieOptions
            {
                Expires = DateTimeOffset.UtcNow.AddDays(30),
                HttpOnly = true,
                IsEssential = true,
                SameSite = SameSiteMode.Lax
            });
            context.HttpContext.Request.Headers.Append("Cookie", $"{SessionKeys.GuestTokenCookie}={guestToken}");
        }

        Shell = await Client.GetShellAsync(context.HttpContext.RequestAborted);

        var cartResp = await Client.GetCartAsync(context.HttpContext.RequestAborted);
        var cart = cartResp.IsSuccess && cartResp.Data is not null ? cartResp.Data : new CartViewModel();
        Shell.CartCount = cart.Summary?.ItemCount ?? 0;
        ViewData["Cart"] = cart;

        bool isAuthenticated = context.HttpContext.User.Identity?.IsAuthenticated == true;
        Shell.IsSignedIn = isAuthenticated;

        if (isAuthenticated)
        {
            var name = context.HttpContext.User.Identity?.Name;
            if (!string.IsNullOrWhiteSpace(name))
            {
                Shell.FirstName = name.Split(' ')[0];
            }
            var pointsClaim = context.HttpContext.User.FindFirst("RewardPoints")?.Value;
            if (int.TryParse(pointsClaim, out int pts))
            {
                Shell.RewardPoints = pts;
            }
        }
        else
        {
            Shell.FirstName = string.Empty;
            Shell.RewardPoints = 0;
        }

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
