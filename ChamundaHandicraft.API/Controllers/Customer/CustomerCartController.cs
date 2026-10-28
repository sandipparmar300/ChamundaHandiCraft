using System.Security.Claims;
using Cart.Application.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Customer;

[ApiController]
[Route("api/customer/cart")]
public class CustomerCartController : ControllerBase
{
    private readonly ICustomerCartService _cartService;

    public CustomerCartController(ICustomerCartService cartService)
    {
        _cartService = cartService;
    }

    private (int? CustomerId, string? GuestToken) ResolveIdentity()
    {
        int? customerId = null;
        var claimId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                      ?? User.FindFirst("CustomerId")?.Value;

        if (int.TryParse(claimId, out var id))
        {
            customerId = id;
        }
        else if (Request.Headers.TryGetValue("X-Customer-Id", out var headerId)
                 && int.TryParse(headerId, out var parsedHeaderId))
        {
            customerId = parsedHeaderId;
        }

        string? guestToken = null;
        if (Request.Headers.TryGetValue(SessionKeys.GuestTokenHeader, out var guestHeader)
            && !string.IsNullOrWhiteSpace(guestHeader))
        {
            guestToken = guestHeader.ToString().Trim();
        }
        else if (Request.Query.TryGetValue("guestToken", out var queryToken)
                 && !string.IsNullOrWhiteSpace(queryToken))
        {
            guestToken = queryToken.ToString().Trim();
        }

        return (customerId, guestToken);
    }

    [HttpGet("get")]
    public async Task<ActionResult<ResponseViewModel<CartViewModel>>> GetCart(
        [FromQuery] decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        var (customerId, guestToken) = ResolveIdentity();
        var result = await _cartService.GetCartAsync(customerId, guestToken, freeShippingThreshold, ct);
        return Ok(result);
    }

    [HttpPost("additem")]
    public async Task<ActionResult<ResponseViewModel<CartViewModel>>> AddItem(
        [FromBody] AddToCartRequest request,
        [FromQuery] decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        var (customerId, guestToken) = ResolveIdentity();
        var result = await _cartService.AddItemAsync(
            customerId,
            guestToken,
            request.ProductId,
            request.VariantId,
            request.Quantity,
            request.Note,
            request.Slug,
            freeShippingThreshold,
            ct);

        return Ok(result);
    }

    [HttpPost("updatequantity")]
    public async Task<ActionResult<ResponseViewModel<CartViewModel>>> UpdateQuantity(
        [FromBody] UpdateCartQuantityRequest request,
        [FromQuery] decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        var (customerId, guestToken) = ResolveIdentity();
        var result = await _cartService.UpdateQuantityAsync(
            customerId,
            guestToken,
            request.CartItemId,
            request.Quantity,
            freeShippingThreshold,
            ct);

        return Ok(result);
    }

    [HttpPost("removeitem")]
    public async Task<ActionResult<ResponseViewModel<CartViewModel>>> RemoveItem(
        [FromBody] RemoveCartItemRequest request,
        [FromQuery] decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        var (customerId, guestToken) = ResolveIdentity();
        var result = await _cartService.RemoveItemAsync(
            customerId,
            guestToken,
            request.CartItemId,
            freeShippingThreshold,
            ct);

        return Ok(result);
    }

    [HttpPost("applycoupon")]
    public async Task<ActionResult<ResponseViewModel<CartViewModel>>> ApplyCoupon(
        [FromBody] ApplyCouponRequest request,
        [FromQuery] decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        var (customerId, guestToken) = ResolveIdentity();
        var result = await _cartService.ApplyCouponAsync(
            customerId,
            guestToken,
            request.CouponCode,
            freeShippingThreshold,
            ct);

        return Ok(result);
    }

    [HttpPost("removecoupon")]
    public async Task<ActionResult<ResponseViewModel<CartViewModel>>> RemoveCoupon(
        [FromQuery] decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        var (customerId, guestToken) = ResolveIdentity();
        var result = await _cartService.RemoveCouponAsync(
            customerId,
            guestToken,
            freeShippingThreshold,
            ct);

        return Ok(result);
    }

    [HttpPost("mergeguestcart")]
    public async Task<ActionResult<ResponseViewModel<CartViewModel>>> MergeGuestCart(
        [FromBody] MergeGuestCartRequest request,
        [FromQuery] decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        var (customerId, _) = ResolveIdentity();
        if (!customerId.HasValue)
        {
            return Ok(ResponseViewModel<CartViewModel>.Fail("Customer must be authenticated to merge a guest cart."));
        }

        var result = await _cartService.MergeGuestCartAsync(
            customerId.Value,
            request.GuestToken,
            freeShippingThreshold,
            ct);

        return Ok(result);
    }
}
