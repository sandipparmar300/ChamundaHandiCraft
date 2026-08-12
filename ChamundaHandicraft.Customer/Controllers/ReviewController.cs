using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 15 · Reviews. Only verified purchases can post, and that promise is
/// stated wherever reviews appear.
/// </summary>
public class ReviewController : StorefrontController
{
    public ReviewController(IStorefrontClient client) : base(client) { }

    [HttpGet("/reviews/write/{slug}")]
    public IActionResult Write(string slug)
    {
        ActiveNav("account");
        Page("Write a review");
        Crumbs(("Home", "/"), ("My Account", "/account"), ("Write a Review", null));
        ViewData["AccountSection"] = "reviews";
        return View(DemoContent.Product(slug));
    }

    [HttpGet("/account/reviews")]
    public IActionResult Index()
    {
        ActiveNav("account");
        Page("My reviews");
        Crumbs(("Home", "/"), ("My Account", "/account"), ("My Reviews", null));
        ViewData["AccountSection"] = "reviews";
        return View();
    }
}
