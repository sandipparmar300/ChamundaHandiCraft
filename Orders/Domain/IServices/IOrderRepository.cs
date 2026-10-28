using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Orders.Domain.IServices;

public interface IOrderRepository
{
    Task<PlaceOrderResult> CreateOrderFromCartAsync(PlaceOrderRequest request, CancellationToken ct = default);
    Task<OrderDetailViewModel?> GetOrderByIdOrNumberAsync(int? orderId, string? orderNumber, int? customerId, CancellationToken ct = default);
}
