using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Banners.Application.Services;
using Banners.Domain.IServices;
using Banners.Infrastructure.Repositories;

namespace Banners.Application.Extentions;

public static class BannersConfig
{
    public static IServiceCollection AddBannersModule(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("AppDbConnection")
            ?? throw new InvalidOperationException("Connection string 'AppDbConnection' not found in configuration.");

        services.AddScoped<IBannerRepository>(_ => new BannerRepository(connectionString));
        services.AddScoped<IBannerService, BannerService>();

        return services;
    }
}
