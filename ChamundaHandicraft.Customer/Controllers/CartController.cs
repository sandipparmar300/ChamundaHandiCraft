using ChamundaHandicraft.Customer.Models;
using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 07 · Cart — docs/ui-ux-storefront/13-Modules-07-08-09-Cart-Checkout-Payment.md §7.
/// Every cost appears here. Nothing new is allowed to appear after payment
/// selection (CX principle 7).
/// </summary>
public class CartController : StorefrontController
{
    private readonly ILogger<CartController> _logger;

    public CartController(IStorefrontClient client, ILogger<CartController> logger) : base(client)
    {
        _logger = logger;
    }

    [HttpGet("/cart")]
    public async Task<IActionResult> Index(bool empty = false)
    {
        ActiveNav("cart");
        Page("Your cart");
        Crumbs(("Home", "/"), ("Cart", null));

        var cartResp = await Client.GetCartAsync(HttpContext.RequestAborted);
        var cart = cartResp.IsSuccess && cartResp.Data is not null ? cartResp.Data : new CartViewModel();

        var lines = empty ? new List<CartLineViewModel>() : (cart.Lines ?? new List<CartLineViewModel>());
        var summary = cart.Summary ?? new OrderSummaryViewModel();

        return View(new CartPageViewModel
        {
            Lines = lines,
            Summary = summary,
            SavedForLater = new List<ProductCardViewModel>()
        });
    }

    [HttpPost("/cart/add")]
    public async Task<IActionResult> AddItem([FromBody] AddToCartRequest req)
    {
        if (req is null || (req.ProductId <= 0 && string.IsNullOrWhiteSpace(req.Slug)))
        {
            return Json(ResponseViewModel<CartViewModel>.Fail("Invalid product selected for cart."));
        }

        if (req.Quantity <= 0) req.Quantity = 1;

        var result = await Client.AddToCartAsync(req, HttpContext.RequestAborted);
        return Json(result);
    }

    [HttpPost("/cart/update-qty")]
    public async Task<IActionResult> UpdateQuantity([FromBody] UpdateCartQuantityRequest req)
    {
        if (req is null || req.CartItemId <= 0)
        {
            return Json(ResponseViewModel<CartViewModel>.Fail("Invalid cart item."));
        }

        var result = await Client.UpdateCartQuantityAsync(req, HttpContext.RequestAborted);
        return Json(result);
    }

    [HttpPost("/cart/remove")]
    public async Task<IActionResult> RemoveItem([FromBody] RemoveCartItemRequest req)
    {
        if (req is null || req.CartItemId <= 0)
        {
            return Json(ResponseViewModel<CartViewModel>.Fail("Invalid cart item."));
        }

        var result = await Client.RemoveCartItemAsync(req.CartItemId, HttpContext.RequestAborted);
        return Json(result);
    }

    [HttpPost("/cart/apply-coupon")]
    public async Task<IActionResult> ApplyCoupon([FromBody] ApplyCouponRequest req)
    {
        var code = req?.CouponCode ?? req?.Code;
        if (string.IsNullOrWhiteSpace(code))
        {
            return Json(ResponseViewModel<CartViewModel>.Fail("Please enter a valid coupon code."));
        }

        var result = await Client.ApplyCouponAsync(code.Trim(), HttpContext.RequestAborted);
        return Json(result);
    }

    [HttpPost("/cart/remove-coupon")]
    public async Task<IActionResult> RemoveCoupon()
    {
        var result = await Client.RemoveCouponAsync(HttpContext.RequestAborted);
        return Json(result);
    }

    [HttpGet("/cart/mini-partial")]
    public async Task<IActionResult> MiniCartPartial()
    {
        var cartResp = await Client.GetCartAsync(HttpContext.RequestAborted);
        var cart = cartResp.IsSuccess && cartResp.Data is not null ? cartResp.Data : new CartViewModel();
        return PartialView("_MiniCart", cart);
    }

    [HttpGet("/cart/data")]
    public async Task<IActionResult> GetCartJson()
    {
        var cartResp = await Client.GetCartAsync(HttpContext.RequestAborted);
        return Json(cartResp);
    }
}
