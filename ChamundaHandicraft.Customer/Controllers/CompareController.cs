using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>Module 05 · Compare — SL-09, first column sticky, differences highlighted.</summary>
public class CompareController : StorefrontController
{
    public CompareController(IStorefrontClient client) : base(client) { }

    [HttpGet("/compare")]
    public IActionResult Index()
    {
        ActiveNav("shop");
        Page("Compare products", "Compare handmade pieces side by side — material, dimensions, craft, price and delivery.");
        Crumbs(("Home", "/"), ("Compare", null));

        return View(DemoContent.Products(4));
    }
}
