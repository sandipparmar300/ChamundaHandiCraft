using Identity.Application.Services;
using Identity.Domain.IServices;
using Identity.Infrastructure.Repositories;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Identity.Application.Extentions;

/// <summary>
/// Service collection extension registering the Identity module components.
/// Called by ChamundaHandicraft.API during startup.
/// </summary>
public static class IdentityConfig
{
    public static IServiceCollection AddIdentityModule(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("AppDbConnection")
            ?? throw new InvalidOperationException("Connection string 'AppDbConnection' not found in configuration.");

        // Repositories
        services.AddScoped<IAdminUserRepository>(_ => new AdminUserRepository(connectionString));
        services.AddScoped<IRoleRepository>(_ => new RoleRepository(connectionString));
        services.AddScoped<IPermissionRepository>(_ => new PermissionRepository(connectionString));
        services.AddScoped<IAdminSessionRepository>(_ => new AdminSessionRepository(connectionString));
        services.AddScoped<IPasswordResetRepository>(_ => new PasswordResetRepository(connectionString));

        // Application Services
        services.AddSingleton<IPasswordHasher, PasswordHasher>();
        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IAdminAuthService, AdminAuthService>();
        services.AddScoped<IAdminUserService, AdminUserService>();
        services.AddScoped<IRoleService, RoleService>();
        services.AddScoped<IPermissionService, PermissionService>();

        return services;
    }
}
