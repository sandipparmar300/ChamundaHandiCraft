using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>Module 17 · Notifications. Everything is actionable or it doesn't get sent.</summary>
public class NotificationController : StorefrontController
{
    public NotificationController(IStorefrontClient client) : base(client) { }

    [HttpGet("/account/notifications")]
    public IActionResult Index()
    {
        ActiveNav("account");
        Page("Notifications");
        Crumbs(("Home", "/"), ("My Account", "/account"), ("Notifications", null));
        ViewData["AccountSection"] = "notifications";
        return View();
    }
}
