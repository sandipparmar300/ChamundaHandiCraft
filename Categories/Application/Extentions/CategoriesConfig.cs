using Categories.Application.Services;
using Categories.Domain.IServices;
using Categories.Infrastructure.Repositories;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Categories.Application.Extentions;

public static class CategoriesConfig
{
    public static IServiceCollection AddCategoriesModule(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("AppDbConnection")
            ?? throw new InvalidOperationException("Connection string 'AppDbConnection' not found in configuration.");

        // Repositories
        services.AddScoped<ICategoryRepository>(_ => new CategoryRepository(connectionString));
        services.AddScoped<IMenuRepository>(_ => new MenuRepository(connectionString));

        // Services
        services.AddScoped<ICategoryService, CategoryService>();
        services.AddScoped<IMenuService, MenuService>();

        return services;
    }
}
