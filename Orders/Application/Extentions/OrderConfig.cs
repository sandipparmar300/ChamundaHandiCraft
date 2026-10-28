using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Orders.Application.Services;
using Orders.Domain.IServices;
using Orders.Infrastructure.Repositories;

namespace Orders.Application.Extentions;

public static class OrderConfig
{
    public static IServiceCollection AddOrdersModule(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("AppDbConnection")
            ?? throw new InvalidOperationException("Connection string 'AppDbConnection' not found in configuration.");

        services.AddScoped<IOrderRepository>(_ => new OrderRepository(connectionString));
        services.AddScoped<IOrderService, OrderService>();

        return services;
    }
}
