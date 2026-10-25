using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Support.Application.Services;
using Support.Domain.IServices;
using Support.Infrastructure.Repositories;

namespace Support.Application.Extentions;

public static class SupportConfig
{
    public static IServiceCollection AddSupportModule(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("AppDbConnection")
            ?? throw new InvalidOperationException("Connection string 'AppDbConnection' not found in configuration.");

        services.AddScoped<ISupportRepository>(_ => new SupportRepository(connectionString));
        services.AddScoped<ISupportService, SupportService>();

        return services;
    }
}
