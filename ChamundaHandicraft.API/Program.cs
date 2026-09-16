using System.Text;
using Catalog.Application.Extentions;
using Categories.Application.Extentions;
using Identity.Application.Extentions;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((context, configuration) => configuration
    .ReadFrom.Configuration(context.Configuration)
    .WriteTo.Console());

#region Services

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new ChamundaHandicraft.Helper.CommonMethod.SafeDateTimeConverter());
        options.JsonSerializerOptions.Converters.Add(new ChamundaHandicraft.Helper.CommonMethod.SafeNullableDateTimeConverter());
    });
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();
builder.Services.AddHttpContextAccessor();
builder.Services.AddMemoryCache();

// Identity & Infrastructure Services
builder.Services.AddIdentityModule(builder.Configuration);
builder.Services.AddCatalogModule(builder.Configuration);
builder.Services.AddCategoriesModule(builder.Configuration);
builder.Services.AddScoped<ChamundaHandicraft.API.Services.Email.IEmailTemplateService, ChamundaHandicraft.API.Services.Email.EmailTemplateService>();
builder.Services.AddScoped<ChamundaHandicraft.API.Services.Email.IEmailService, ChamundaHandicraft.API.Services.Email.SmtpEmailService>();

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
