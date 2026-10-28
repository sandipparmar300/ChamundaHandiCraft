using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Cart.Application.Services;

public interface ICustomerCartService
{
    Task<ResponseViewModel<CartViewModel>> GetCartAsync(
        int? customerId,
        string? guestToken,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default);

    Task<ResponseViewModel<CartViewModel>> AddItemAsync(
        int? customerId,
        string? guestToken,
        int productId,
        int? variantId,
        int quantity,
        string? note = null,
        string? slug = null,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default);

    Task<ResponseViewModel<CartViewModel>> UpdateQuantityAsync(
        int? customerId,
        string? guestToken,
        long cartItemId,
        int quantity,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default);

    Task<ResponseViewModel<CartViewModel>> RemoveItemAsync(
        int? customerId,
        string? guestToken,
        long cartItemId,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default);

    Task<ResponseViewModel<CartViewModel>> ApplyCouponAsync(
        int? customerId,
        string? guestToken,
        string couponCode,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default);

    Task<ResponseViewModel<CartViewModel>> RemoveCouponAsync(
        int? customerId,
        string? guestToken,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default);

    Task<ResponseViewModel<CartViewModel>> MergeGuestCartAsync(
        int customerId,
        string guestToken,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default);
}
