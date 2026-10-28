using System.Security.Claims;
using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 08 · Checkout and Module 09 · Payment.
/// Single-page frictionless checkout supporting authenticated patrons and guest patrons.
/// </summary>
public class CheckoutController : StorefrontController
{
    public CheckoutController(IStorefrontClient client) : base(client) { }

    [HttpGet("/checkout")]
    public async Task<IActionResult> Index(bool guest = false, CancellationToken ct = default)
    {
        MinimalChrome();
        Page("Checkout");

        bool isGuest = guest || !Shell.IsSignedIn;
        var response = await Client.GetCheckoutAsync(isGuest, ct);
        var vm = response?.Data ?? new CheckoutViewModel();

        if (vm.Lines == null || vm.Lines.Count == 0)
        {
            return RedirectToAction("Index", "Cart");
        }

        vm.IsGuest = isGuest;

        if (Shell.IsSignedIn)
        {
            vm.ContactEmail = User.FindFirst(ClaimTypes.Email)?.Value
                           ?? User.FindFirst("Email")?.Value
                           ?? vm.ContactEmail;

            vm.ContactPhone = User.FindFirst(ClaimTypes.MobilePhone)?.Value
                           ?? User.FindFirst("Phone")?.Value
                           ?? vm.ContactPhone;
        }

        return View(vm);
    }

    [HttpPost("/checkout/place-order")]
    public async Task<IActionResult> PlaceOrder([FromBody] PlaceOrderRequest request, CancellationToken ct = default)
    {
        if (request == null)
        {
            return Json(new { success = false, message = "Invalid order submission." });
        }

        if (string.IsNullOrWhiteSpace(request.GuestToken) &&
            Request.Cookies.TryGetValue(SessionKeys.GuestTokenCookie, out var guestCookie))
        {
            request.GuestToken = guestCookie;
        }

        var response = await Client.PlaceOrderAsync(request, ct);

        if (response.IsSuccess && response.Data != null && response.Data.Success)
        {
            return Json(new
            {
                success = true,
                orderNumber = response.Data.OrderNumber,
                redirectUrl = $"/checkout/success/{response.Data.OrderNumber}",
                message = response.Data.Message
            });
        }

        return Json(new
        {
            success = false,
            message = response.Data?.Message ?? response.Message ?? "Failed to place order. Please review your details and try again."
        });
    }

    [HttpGet("/checkout/success/{orderNumber}")]
    public async Task<IActionResult> Success(string orderNumber, CancellationToken ct = default)
    {
        MinimalChrome();
        Page("Order confirmed");
        ViewData["OrderNumber"] = orderNumber;

        var response = await Client.GetOrderAsync(orderNumber, ct);
        var order = response?.Data ?? new OrderDetailViewModel
        {
            Header = new OrderSummaryCardViewModel
            {
                OrderNumber = orderNumber,
                PlacedOn = DateTime.UtcNow
            }
        };

        return View(order);
    }

    [HttpGet("/checkout/failed")]
    public IActionResult Failed(string? reason)
    {
        MinimalChrome();
        Page("Payment didn't go through");
        ViewData["Reason"] = reason ?? "Your bank declined the transaction.";
        return View();
    }
}
