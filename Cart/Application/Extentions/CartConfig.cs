using Cart.Application.Services;
using Cart.Domain.IServices;
using Cart.Infrastructure.Repositories;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Cart.Application.Extentions;

public static class CartConfig
{
    public static IServiceCollection AddCartModule(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("AppDbConnection")
            ?? throw new InvalidOperationException("Connection string 'AppDbConnection' not found in configuration.");

        services.AddScoped<ICustomerCartRepository>(_ => new CustomerCartRepository(connectionString));
        services.AddScoped<ICustomerCartService, CustomerCartService>();

        return services;
    }
}
