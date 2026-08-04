using Ocelot.DependencyInjection;
using Ocelot.Middleware;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddJsonFile("ocelot.json", optional: false, reloadOnChange: true);

// The gateway performs no authentication of its own — JWT validation happens in the
// API so a single implementation governs both web tiers.
const string WebTiersCorsPolicy = "WebTiers";

var allowedOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins")
    .Get<string[]>() ?? Array.Empty<string>();

builder.Services.AddCors(options =>
{
    options.AddPolicy(WebTiersCorsPolicy, policy => policy
        .WithOrigins(allowedOrigins)
        .AllowAnyHeader()
        .AllowAnyMethod()
        .AllowCredentials());
});

builder.Services.AddOcelot(builder.Configuration);

var app = builder.Build();

if (allowedOrigins.Length == 0)
{
    app.Logger.LogWarning(
        "Cors:AllowedOrigins is empty. The Admin and Customer origins must be listed before either tier can call the gateway from a browser.");
}

app.UseCors(WebTiersCorsPolicy);

// Rate limiting is configured per route via RateLimitOptions in ocelot.json —
// tighter on /Public/* and /Webhooks/* than on /Admin/*.
await app.UseOcelot();

app.Run();
