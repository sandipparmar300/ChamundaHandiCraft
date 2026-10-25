using Customers.Application.Services;
using Customers.Domain.IServices;
using Customers.Infrastructure.Repositories;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Customers.Application.Extentions;

public static class CustomersConfig
{
    public static IServiceCollection AddCustomersModule(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("AppDbConnection")
            ?? configuration.GetConnectionString("DefaultConnection")
            ?? configuration["ConnectionStrings:AppDbConnection"]
            ?? configuration["ConnectionStrings:DefaultConnection"]
            ?? throw new InvalidOperationException("Connection string 'AppDbConnection' or 'DefaultConnection' not found in configuration.");

        // Repositories
        services.AddScoped<ICustomerAuthRepository>(_ => new CustomerAuthRepository(connectionString));
        services.AddScoped<ICustomerProfileRepository>(_ => new CustomerProfileRepository(connectionString));
        services.AddScoped<ICustomerAddressRepository>(_ => new CustomerAddressRepository(connectionString));

        // Services
        services.AddSingleton<ICustomerPasswordHasher, CustomerPasswordHasher>();
        services.AddScoped<ICustomerTokenService, CustomerTokenService>();
        services.AddScoped<ICustomerAuthService, CustomerAuthService>();
        services.AddScoped<ICustomerProfileService, CustomerProfileService>();
        services.AddScoped<ICustomerAddressService, CustomerAddressService>();

        return services;
    }
}
