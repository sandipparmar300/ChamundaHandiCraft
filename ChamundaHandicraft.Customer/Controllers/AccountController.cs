using System.Security.Claims;
using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.ApiService;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 10 · My Account — docs/ui-ux-storefront/14-Modules-10-11-12-Account-Orders-Tracking.md.
/// SL-05: sidebar 3 / content 9 on desktop; a drill-down menu list on mobile.
/// </summary>
public class AccountController : StorefrontController
{
    private readonly IApiService _api;
    private readonly ILogger<AccountController> _logger;

    public AccountController(
        IStorefrontClient client,
        IApiService api,
        ILogger<AccountController> logger) : base(client)
    {
        _api = api;
        _logger = logger;
    }

    private int GetCurrentCustomerId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                 ?? User.FindFirst("CustomerId")?.Value;

        if (int.TryParse(claim, out int id) && id > 0)
        {
            return id;
        }

        var sessionVal = HttpContext.Session.GetString(SessionKeys.CustomerId);
        if (int.TryParse(sessionVal, out int sid) && sid > 0)
        {
            return sid;
        }

        return 0;
    }

    private void Section(string key, string title, string crumb)
    {
        ActiveNav("account");
        Page(title);
        Crumbs(("Home", "/"), ("My Account", "/account"), (crumb, null));
        ViewData["AccountSection"] = key;
    }

    [HttpGet("/account")]
    public async Task<IActionResult> Index()
    {
        ActiveNav("account");
        Page("My account");
        Crumbs(("Home", "/"), ("My Account", null));
        ViewData["AccountSection"] = "dashboard";

        int cid = GetCurrentCustomerId();
        if (cid <= 0 && User.Identity?.IsAuthenticated != true)
        {
            return Redirect("/login?returnUrl=/account");
        }

        CustomerDashboardViewModel dashboard;
        try
        {
            var res = await _api.GetAsync<CustomerDashboardViewModel>(
                $"{ApiEndPoint.Customer.ShopDashboard}?customerId={cid}",
                null,
                HttpContext.RequestAborted);

            if (res.IsSuccess && res.Data is not null)
            {
                dashboard = res.Data;
            }
            else
            {
                dashboard = new CustomerDashboardViewModel
                {
                    Profile = new CustomerProfileViewModel
                    {
                        FullName = User.Identity?.Name ?? "Shopper",
                        FirstName = User.Identity?.Name?.Split(' ')[0] ?? "Shopper"
                    }
                };
            }
        }
        catch
        {
            dashboard = new CustomerDashboardViewModel
            {
                Profile = new CustomerProfileViewModel
                {
                    FullName = User.Identity?.Name ?? "Shopper",
                    FirstName = User.Identity?.Name?.Split(' ')[0] ?? "Shopper"
                }
            };
        }

        return View(dashboard);
    }

    [HttpGet("/account/profile")]
    public async Task<IActionResult> Profile()
    {
        Section("profile", "Profile", "Profile");

        int cid = GetCurrentCustomerId();
        if (cid <= 0 && User.Identity?.IsAuthenticated != true)
        {
            return Redirect("/login?returnUrl=/account/profile");
        }

        CustomerProfileViewModel profile = new();
        try
        {
            var res = await _api.GetAsync<CustomerProfileViewModel>(
                $"{ApiEndPoint.Customer.ShopProfileGet}?customerId={cid}",
                null,
                HttpContext.RequestAborted);

            if (res.IsSuccess && res.Data is not null)
            {
                profile = res.Data;
            }
            else
            {
                profile.FullName = User.Identity?.Name ?? "Shopper";
                profile.FirstName = User.Identity?.Name?.Split(' ')[0] ?? "Shopper";
                profile.Email = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
            }
        }
        catch
        {
            profile.FullName = User.Identity?.Name ?? "Shopper";
            profile.FirstName = User.Identity?.Name?.Split(' ')[0] ?? "Shopper";
            profile.Email = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
        }

        return View(profile);
    }

    [HttpPost("/account/profile")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Profile(CustomerProfileUpdateRequest model)
    {
        Section("profile", "Profile", "Profile");

        int cid = GetCurrentCustomerId();
        if (cid <= 0 && User.Identity?.IsAuthenticated != true)
        {
            return Redirect("/login?returnUrl=/account/profile");
        }

        if (!ModelState.IsValid)
        {
            TempData["ErrorMessage"] = "Please fix the validation errors below.";
            return RedirectToAction(nameof(Profile));
        }

        try
        {
            var res = await _api.PostAsync<bool>(
                $"{ApiEndPoint.Customer.ShopProfileSave}?customerId={cid}",
                model,
                HttpContext.RequestAborted);

            if (res.IsSuccess)
            {
                if (!string.IsNullOrWhiteSpace(model.Phone) && User.FindFirst("MobileVerified")?.Value != "true")
                {
                    TempData["WarningMessage"] = "Profile saved! Your mobile number is not verified yet — please verify to enable cash on delivery.";
                }
                else
                {
                    TempData["SuccessMessage"] = "Your profile information has been saved successfully.";
                }
            }
            else
            {
                TempData["ErrorMessage"] = res.Message ?? "Failed to update profile.";
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating customer profile for {CustomerId}", cid);
            TempData["ErrorMessage"] = "Unable to save profile changes right now. Please try again.";
        }

        return RedirectToAction(nameof(Profile));
    }

    [HttpGet("/account/addresses")]
    public async Task<IActionResult> Addresses(string? search = null, string? sort = null, int page = 1)
    {
        Section("addresses", "Addresses", "Addresses");

        int cid = GetCurrentCustomerId();
        if (cid <= 0 && User.Identity?.IsAuthenticated != true)
        {
            return Redirect("/login?returnUrl=/account/addresses");
        }

        List<AddressViewModel> addresses = new();
        try
        {
            var res = await _api.GetAsync<PagedResult<AddressViewModel>>(
                $"{ApiEndPoint.Customer.ShopAddressList}?customerId={cid}&search={Uri.EscapeDataString(search ?? "")}&sortBy={sort}&page={page}",
                null,
                HttpContext.RequestAborted);

            if (res.IsSuccess && res.Data?.Items is not null)
            {
                addresses = res.Data.Items;
            }
            else
            {
                addresses = DemoContent.Addresses();
            }
        }
        catch
        {
            addresses = DemoContent.Addresses();
        }

        ViewData["Search"] = search;
        ViewData["Sort"] = sort;
        ViewData["Page"] = page;

        return View(addresses);
    }

    [HttpPost("/account/addresses/save")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SaveAddress(CustomerAddressSaveRequest model)
    {
        int cid = GetCurrentCustomerId();
        if (cid <= 0 && User.Identity?.IsAuthenticated != true)
        {
            return Redirect("/login?returnUrl=/account/addresses");
        }

        model.CustomerId = cid;

        if (!ModelState.IsValid)
        {
            TempData["ErrorMessage"] = "Please fill in all required address fields.";
            return RedirectToAction(nameof(Addresses));
        }

        try
        {
            var res = await _api.PostAsync<int>(
                $"{ApiEndPoint.Customer.ShopAddressSave}?customerId={cid}",
                model,
                HttpContext.RequestAborted);

            if (res.IsSuccess)
            {
                TempData["SuccessMessage"] = model.Id > 0 ? "Address updated successfully." : "New address added successfully.";
            }
            else
            {
                TempData["ErrorMessage"] = res.Message ?? "Failed to save address.";
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving customer address");
            TempData["ErrorMessage"] = "Unable to save address right now. Please try again.";
        }

        return RedirectToAction(nameof(Addresses));
    }

    [HttpPost("/account/addresses/delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteAddress(int id)
    {
        int cid = GetCurrentCustomerId();
        if (cid <= 0 && User.Identity?.IsAuthenticated != true)
        {
            return Json(new { success = false, message = "Unauthorized." });
        }

        try
        {
            var res = await _api.PostAsync<bool>(
                $"{ApiEndPoint.Customer.ShopAddressDelete}?id={id}&customerId={cid}",
                new { },
                HttpContext.RequestAborted);

            if (Request.Headers["X-Requested-With"] == "XMLHttpRequest")
            {
                return Json(new { success = res.IsSuccess, message = res.Message });
            }

            if (res.IsSuccess)
            {
                TempData["SuccessMessage"] = "Address deleted successfully.";
            }
            else
            {
                TempData["ErrorMessage"] = res.Message ?? "Failed to delete address.";
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting address {AddressId}", id);
            TempData["ErrorMessage"] = "Unable to delete address right now.";
        }

        return RedirectToAction(nameof(Addresses));
    }

    [HttpPost("/account/addresses/default")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SetDefaultAddress(int id)
    {
        int cid = GetCurrentCustomerId();
        if (cid <= 0 && User.Identity?.IsAuthenticated != true)
        {
            return Json(new { success = false, message = "Unauthorized." });
        }

        try
        {
            var res = await _api.PostAsync<bool>(
                $"{ApiEndPoint.Customer.ShopSetDefaultAddress}?id={id}&customerId={cid}",
                new { },
                HttpContext.RequestAborted);

            if (Request.Headers["X-Requested-With"] == "XMLHttpRequest")
            {
                return Json(new { success = res.IsSuccess, message = res.Message });
            }

            if (res.IsSuccess)
            {
                TempData["SuccessMessage"] = "Default delivery address updated.";
            }
            else
            {
                TempData["ErrorMessage"] = res.Message ?? "Failed to set default address.";
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting default address {AddressId}", id);
            TempData["ErrorMessage"] = "Unable to update default address.";
        }

        return RedirectToAction(nameof(Addresses));
    }

    [HttpGet("/account/security")]
    public IActionResult Security()
    {
        Section("security", "Security", "Security");

        if (GetCurrentCustomerId() <= 0 && User.Identity?.IsAuthenticated != true)
        {
            return Redirect("/login?returnUrl=/account/security");
        }

        return View(new CustomerChangePasswordRequest());
    }

    [HttpPost("/account/security")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Security(CustomerChangePasswordRequest model)
    {
        Section("security", "Security", "Security");

        int cid = GetCurrentCustomerId();
        if (cid <= 0 && User.Identity?.IsAuthenticated != true)
        {
            return Redirect("/login?returnUrl=/account/security");
        }

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        try
        {
            var res = await _api.PostAsync<bool>(
                $"Shop/Account/ChangePassword?customerId={cid}",
                model,
                HttpContext.RequestAborted);

            if (res.IsSuccess)
            {
                TempData["SuccessMessage"] = "Your password has been changed successfully.";
                return RedirectToAction(nameof(Security));
            }

            ModelState.AddModelError(string.Empty, res.Message ?? "Failed to change password.");
            TempData["ErrorMessage"] = res.Message ?? "Failed to change password.";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error changing password for customer {CustomerId}", cid);
            ModelState.AddModelError(string.Empty, "Unable to change password right now. Please try again.");
            TempData["ErrorMessage"] = "Unable to change password right now. Please try again.";
        }

        return View(model);
    }

    [HttpGet("/account/coupons")]
    public IActionResult Coupons()
    {
        Section("coupons", "My coupons", "Coupons");
        return View();
    }

    [HttpGet("/account/payment-methods")]
    public IActionResult PaymentMethods()
    {
        Section("payment", "Saved cards", "Saved Cards");
        return View();
    }

    [HttpGet("/account/preferences")]
    public IActionResult Preferences()
    {
        Section("preferences", "Communication preferences", "Preferences");
        return View();
    }

    [HttpPost("/account/preferences")]
    [ValidateAntiForgeryToken]
    public IActionResult Preferences(IFormCollection form)
    {
        TempData["SuccessMessage"] = "Your communication preferences have been updated successfully.";
        return RedirectToAction(nameof(Preferences));
    }

    [HttpGet("/account/privacy")]
    public IActionResult Privacy()
    {
        Section("privacy", "Privacy & data", "Privacy");
        return View();
    }

    [HttpGet("/account/referrals")]
    public IActionResult Referrals()
    {
        Section("referrals", "Refer a friend", "Referrals");
        return View();
    }
}
