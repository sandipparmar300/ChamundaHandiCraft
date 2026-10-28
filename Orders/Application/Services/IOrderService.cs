using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Orders.Application.Services;

public interface IOrderService
{
    Task<PlaceOrderResult> PlaceOrderAsync(PlaceOrderRequest request, CancellationToken ct = default);
    Task<OrderDetailViewModel?> GetOrderDetailAsync(string orderNumber, int? customerId = null, CancellationToken ct = default);
    Task<OrderDetailViewModel?> GetOrderDetailByIdAsync(int orderId, int? customerId = null, CancellationToken ct = default);
}
