using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((context, configuration) => configuration
    .ReadFrom.Configuration(context.Configuration)
    .WriteTo.Console());

#region Services

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();
builder.Services.AddHttpContextAccessor();
builder.Services.AddMemoryCache();

// TODO: builder.Services.AddServiceModule(builder.Configuration);
//       ServiceExtension wires the DbContext, the Dapper SqlConnection, all 25 module
//       registrations and their AutoMapper profiles. See ARCHITECTURE.md.

#endregion

#region Authentication

// JwtKey is empty until an environment secret is supplied. Registering a bearer
// handler with an empty signing key throws at startup, so the scheme is only added
// once a key exists.
var jwtKey = builder.Configuration["Jwt:JwtKey"];

if (!string.IsNullOrWhiteSpace(jwtKey))
{
    builder.Services
        .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = builder.Configuration["Jwt:JwtIssuer"],
                ValidAudience = builder.Configuration["Jwt:JwtAudience"],
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
                ClockSkew = TimeSpan.Zero
            };
        });

    builder.Services.AddAuthorization();
}

#endregion

#region Background jobs

// Each job is registered only when its BackgroundJobs:* flag is true.
// TODO: AddHostedService per job as the services are written.

#endregion

var app = builder.Build();

if (string.IsNullOrWhiteSpace(jwtKey))
{
    app.Logger.LogWarning("Jwt:JwtKey is not configured. Authentication is disabled for this run.");
}

app.UseSerilogRequestLogging();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// TODO: app.UseMiddleware<ExceptionMiddleware>();

if (!string.IsNullOrWhiteSpace(jwtKey))
{
    app.UseAuthentication();
    app.UseAuthorization();
}

app.MapControllers();

// TODO: app.MapHub<...>() for the live dashboard, order and inventory hubs.

app.Run();
