using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Promotions.Application.Services;
using Promotions.Domain.IServices;
using Promotions.Infrastructure.Repositories;

namespace Promotions.Application.Extentions;

public static class PromotionsConfig
{
    public static IServiceCollection AddPromotionsModule(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("AppDbConnection")
            ?? throw new InvalidOperationException("Connection string 'AppDbConnection' not found in configuration.");

        services.AddScoped<ICouponRepository>(_ => new CouponRepository(connectionString));
        services.AddScoped<ICouponService, CouponService>();

        services.AddScoped<IOfferRepository>(_ => new OfferRepository(connectionString));
        services.AddScoped<IOfferService, OfferService>();

        return services;
    }
}
