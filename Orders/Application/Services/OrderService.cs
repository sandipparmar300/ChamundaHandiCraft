using ChamundaHandicraft.Helper.ViewModel.Customer;
using Orders.Domain.IServices;

namespace Orders.Application.Services;

public class OrderService : IOrderService
{
    private readonly IOrderRepository _orderRepository;

    public OrderService(IOrderRepository orderRepository)
    {
        _orderRepository = orderRepository ?? throw new ArgumentNullException(nameof(orderRepository));
    }

    public Task<PlaceOrderResult> PlaceOrderAsync(PlaceOrderRequest request, CancellationToken ct = default)
    {
        return _orderRepository.CreateOrderFromCartAsync(request, ct);
    }

    public Task<OrderDetailViewModel?> GetOrderDetailAsync(string orderNumber, int? customerId = null, CancellationToken ct = default)
    {
        return _orderRepository.GetOrderByIdOrNumberAsync(null, orderNumber, customerId, ct);
    }

    public Task<OrderDetailViewModel?> GetOrderDetailByIdAsync(int orderId, int? customerId = null, CancellationToken ct = default)
    {
        return _orderRepository.GetOrderByIdOrNumberAsync(orderId, null, customerId, ct);
    }
}
