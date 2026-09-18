using Inventory.Application.Services;
using Inventory.Domain.IServices;
using Inventory.Infrastructure.Repositories;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Inventory.Application.Extentions;

public static class InventoryConfig
{
    public static IServiceCollection AddInventoryModule(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("AppDbConnection")
            ?? throw new InvalidOperationException("Connection string 'AppDbConnection' not found in configuration.");

        // Repositories
        services.AddScoped<IWarehouseRepository>(_ => new WarehouseRepository(connectionString));
        services.AddScoped<ISupplierRepository>(_ => new SupplierRepository(connectionString));
        services.AddScoped<IInventoryRepository>(_ => new InventoryRepository(connectionString));
        services.AddScoped<IPurchaseRepository>(_ => new PurchaseRepository(connectionString));
        services.AddScoped<IStockAdjustmentRepository>(_ => new StockAdjustmentRepository(connectionString));
        services.AddScoped<IStockTransferRepository>(_ => new StockTransferRepository(connectionString));
        services.AddScoped<IStockRateRepository>(_ => new StockRateRepository(connectionString));
        services.AddScoped<IStockTakeRepository>(_ => new StockTakeRepository(connectionString));

        // Services
        services.AddScoped<IWarehouseService, WarehouseService>();
        services.AddScoped<ISupplierService, SupplierService>();
        services.AddScoped<IInventoryService, InventoryService>();
        services.AddScoped<IPurchaseService, PurchaseService>();
        services.AddScoped<IStockAdjustmentService, StockAdjustmentService>();
        services.AddScoped<IStockTransferService, StockTransferService>();
        services.AddScoped<IStockRateService, StockRateService>();
        services.AddScoped<IStockTakeService, StockTakeService>();

        return services;
    }
}
