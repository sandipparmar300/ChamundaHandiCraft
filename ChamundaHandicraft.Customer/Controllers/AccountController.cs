using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 10 · My Account — docs/ui-ux-storefront/14-Modules-10-11-12-Account-Orders-Tracking.md.
/// SL-05: sidebar 3 / content 9 on desktop; a drill-down menu list on mobile.
/// </summary>
public class AccountController : StorefrontController
{
    public AccountController(IStorefrontClient client) : base(client) { }

    private void Section(string key, string title, string crumb)
    {
        ActiveNav("account");
        Page(title);
        Crumbs(("Home", "/"), ("My Account", "/account"), (crumb, null));
        ViewData["AccountSection"] = key;
    }

    [HttpGet("/account")]
    public IActionResult Index()
    {
        ActiveNav("account");
        Page("My account");
        Crumbs(("Home", "/"), ("My Account", null));
        ViewData["AccountSection"] = "dashboard";
        return View();
    }

    [HttpGet("/account/profile")]
    public IActionResult Profile()
    {
        Section("profile", "Profile", "Profile");
        return View();
    }

    [HttpGet("/account/addresses")]
    public IActionResult Addresses()
    {
        Section("addresses", "Addresses", "Addresses");
        return View(DemoContent.Addresses());
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

    [HttpGet("/account/security")]
    public IActionResult Security()
    {
        Section("security", "Security", "Security");
        return View();
    }

    [HttpGet("/account/preferences")]
    public IActionResult Preferences()
    {
        Section("preferences", "Communication preferences", "Preferences");
        return View();
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
