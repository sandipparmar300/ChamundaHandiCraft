using Catalog.Application.Services;
using Catalog.Domain.IServices;
using Catalog.Infrastructure.Repositories;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Catalog.Application.Extentions;

/// <summary>
/// Service collection extension registering the Catalog module components.
/// Called by ChamundaHandicraft.API during startup.
/// </summary>
public static class CatalogConfig
{
    public static IServiceCollection AddCatalogModule(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("AppDbConnection")
            ?? throw new InvalidOperationException("Connection string 'AppDbConnection' not found in configuration.");

        // Repositories
        services.AddScoped<IBrandRepository>(_ => new BrandRepository(connectionString));
        services.AddScoped<IArtisanRepository>(_ => new ArtisanRepository(connectionString));
        services.AddScoped<IAttributeRepository>(_ => new AttributeRepository(connectionString));
        services.AddScoped<IProductRepository>(_ => new ProductRepository(connectionString));

        // Application Services
        services.AddScoped<IBrandService, BrandService>();
        services.AddScoped<IArtisanService, ArtisanService>();
        services.AddScoped<IAttributeService, AttributeService>();
        services.AddScoped<IProductService, ProductService>();

        return services;
    }
}
