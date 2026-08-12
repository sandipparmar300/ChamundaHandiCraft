using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>Module 16 · Rewards. No expiry games, no hidden tiers.</summary>
public class RewardsController : StorefrontController
{
    public RewardsController(IStorefrontClient client) : base(client) { }

    [HttpGet("/account/rewards")]
    public IActionResult Index()
    {
        ActiveNav("account");
        Page("Rewards & points");
        Crumbs(("Home", "/"), ("My Account", "/account"), ("Rewards", null));
        ViewData["AccountSection"] = "rewards";
        return View();
    }
}
