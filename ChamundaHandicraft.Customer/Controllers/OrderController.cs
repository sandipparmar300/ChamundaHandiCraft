using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 11 · Orders — docs/ui-ux-storefront/14-Modules-10-11-12-Account-Orders-Tracking.md §11.
/// Every order screen answers "where is it" before anything else.
/// </summary>
public class OrderController : StorefrontController
{
    public OrderController(IStorefrontClient client) : base(client) { }

    private void Section(string title, params (string Label, string? Url)[] crumbs)
    {
        ActiveNav("account");
        Page(title);
        Crumbs(crumbs);
        ViewData["AccountSection"] = "orders";
    }

    [HttpGet("/account/orders")]
    public IActionResult Index()
    {
        Section("My orders", ("Home", "/"), ("My Account", "/account"), ("Orders", null));
        return View(DemoContent.Orders());
    }

    [HttpGet("/account/orders/{orderNumber}")]
    public IActionResult Details(string orderNumber)
    {
        Section($"Order {orderNumber}",
            ("Home", "/"), ("My Account", "/account"), ("Orders", "/account/orders"), (orderNumber, null));

        ViewData["OrderNumber"] = orderNumber;
        return View(DemoContent.Orders().FirstOrDefault(o => o.OrderNumber == orderNumber) ?? DemoContent.Orders()[0]);
    }

    [HttpGet("/account/orders/{orderNumber}/return")]
    public IActionResult Return(string orderNumber)
    {
        Section("Return or replace",
            ("Home", "/"), ("My Account", "/account"), ("Orders", "/account/orders"),
            (orderNumber, $"/account/orders/{orderNumber}"), ("Return", null));

        ViewData["OrderNumber"] = orderNumber;
        return View();
    }

    [HttpGet("/account/returns")]
    public IActionResult Returns()
    {
        Section("Returns & refunds", ("Home", "/"), ("My Account", "/account"), ("Returns", null));
        ViewData["AccountSection"] = "returns";
        return View();
    }
}
