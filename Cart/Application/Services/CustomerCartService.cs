using Cart.Domain.IServices;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.Extensions.Logging;

namespace Cart.Application.Services;

public class CustomerCartService : ICustomerCartService
{
    private readonly ICustomerCartRepository _cartRepository;
    private readonly ILogger<CustomerCartService> _logger;

    public CustomerCartService(
        ICustomerCartRepository cartRepository,
        ILogger<CustomerCartService> logger)
    {
        _cartRepository = cartRepository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<CartViewModel>> GetCartAsync(
        int? customerId,
        string? guestToken,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        try
        {
            var cart = await _cartRepository.GetCartAsync(customerId, guestToken, freeShippingThreshold, ct);
            return ResponseViewModel<CartViewModel>.Success(cart);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting cart for customer {CustomerId} / guest {GuestToken}", customerId, guestToken);
            return ResponseViewModel<CartViewModel>.Fail("Failed to retrieve your cart.");
        }
    }

    public async Task<ResponseViewModel<CartViewModel>> AddItemAsync(
        int? customerId,
        string? guestToken,
        int productId,
        int? variantId,
        int quantity,
        string? note = null,
        string? slug = null,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        try
        {
            var cart = await _cartRepository.AddItemAsync(customerId, guestToken, productId, variantId, quantity, note, slug, freeShippingThreshold, ct);
            return ResponseViewModel<CartViewModel>.Success(cart, "Item added to cart successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error adding item to cart for customer {CustomerId} / guest {GuestToken}", customerId, guestToken);
            return ResponseViewModel<CartViewModel>.Fail(ex.Message);
        }
    }

    public async Task<ResponseViewModel<CartViewModel>> UpdateQuantityAsync(
        int? customerId,
        string? guestToken,
        long cartItemId,
        int quantity,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        try
        {
            var cart = await _cartRepository.UpdateQuantityAsync(customerId, guestToken, cartItemId, quantity, freeShippingThreshold, ct);
            return ResponseViewModel<CartViewModel>.Success(cart, "Cart quantity updated.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating cart item {CartItemId} quantity", cartItemId);
            return ResponseViewModel<CartViewModel>.Fail(ex.Message);
        }
    }

    public async Task<ResponseViewModel<CartViewModel>> RemoveItemAsync(
        int? customerId,
        string? guestToken,
        long cartItemId,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        try
        {
            var cart = await _cartRepository.RemoveItemAsync(customerId, guestToken, cartItemId, freeShippingThreshold, ct);
            return ResponseViewModel<CartViewModel>.Success(cart, "Item removed from cart.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error removing cart item {CartItemId}", cartItemId);
            return ResponseViewModel<CartViewModel>.Fail(ex.Message);
        }
    }

    public async Task<ResponseViewModel<CartViewModel>> ApplyCouponAsync(
        int? customerId,
        string? guestToken,
        string couponCode,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        try
        {
            var cart = await _cartRepository.ApplyCouponAsync(customerId, guestToken, couponCode, freeShippingThreshold, ct);
            return ResponseViewModel<CartViewModel>.Success(cart, $"Coupon '{couponCode}' applied successfully!");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to apply coupon {CouponCode}", couponCode);
            return ResponseViewModel<CartViewModel>.Fail(ex.Message);
        }
    }

    public async Task<ResponseViewModel<CartViewModel>> RemoveCouponAsync(
        int? customerId,
        string? guestToken,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        try
        {
            var cart = await _cartRepository.RemoveCouponAsync(customerId, guestToken, freeShippingThreshold, ct);
            return ResponseViewModel<CartViewModel>.Success(cart, "Coupon removed.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error removing coupon");
            return ResponseViewModel<CartViewModel>.Fail(ex.Message);
        }
    }

    public async Task<ResponseViewModel<CartViewModel>> MergeGuestCartAsync(
        int customerId,
        string guestToken,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        try
        {
            var cart = await _cartRepository.MergeGuestCartAsync(customerId, guestToken, freeShippingThreshold, ct);
            return ResponseViewModel<CartViewModel>.Success(cart, "Cart synchronized.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error merging guest cart {GuestToken} for customer {CustomerId}", guestToken, customerId);
            return ResponseViewModel<CartViewModel>.Fail(ex.Message);
        }
    }
}
