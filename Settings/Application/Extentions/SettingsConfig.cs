using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Settings.Application.Services;
using Settings.Domain.IServices;
using Settings.Infrastructure.Repositories;

namespace Settings.Application.Extentions;

public static class SettingsConfig
{
    public static IServiceCollection AddSettingsModule(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("DefaultConnection string not found.");

        services.AddScoped<ISettingsRepository>(_ => new SettingsRepository(connectionString));
        services.AddScoped<ISettingsService, SettingsService>();

        return services;
    }
}
