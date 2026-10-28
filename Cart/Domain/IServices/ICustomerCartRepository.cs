using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Cart.Domain.IServices;

public interface ICustomerCartRepository
{
    Task<CartViewModel> GetCartAsync(
        int? customerId,
        string? guestToken,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default);

    Task<CartViewModel> AddItemAsync(
        int? customerId,
        string? guestToken,
        int productId,
        int? variantId,
        int quantity,
        string? note = null,
        string? slug = null,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default);

    Task<CartViewModel> UpdateQuantityAsync(
        int? customerId,
        string? guestToken,
        long cartItemId,
        int quantity,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default);

    Task<CartViewModel> RemoveItemAsync(
        int? customerId,
        string? guestToken,
        long cartItemId,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default);

    Task<CartViewModel> ApplyCouponAsync(
        int? customerId,
        string? guestToken,
        string couponCode,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default);

    Task<CartViewModel> RemoveCouponAsync(
        int? customerId,
        string? guestToken,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default);

    Task<CartViewModel> MergeGuestCartAsync(
        int customerId,
        string guestToken,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default);
}
