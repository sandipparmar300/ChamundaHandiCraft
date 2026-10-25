using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Testimonials.Application.Services;
using Testimonials.Domain.IServices;
using Testimonials.Infrastructure.Repositories;

namespace Testimonials.Application.Extentions;

public static class TestimonialsConfig
{
    public static IServiceCollection AddTestimonialsModule(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("AppDbConnection")
            ?? throw new InvalidOperationException("Connection string 'AppDbConnection' not found in configuration.");

        services.AddScoped<ITestimonialRepository>(_ => new TestimonialRepository(connectionString));
        services.AddScoped<ITestimonialService, TestimonialService>();

        return services;
    }
}
