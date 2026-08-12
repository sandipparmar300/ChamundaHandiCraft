using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ApiService;
using Microsoft.AspNetCore.Authentication.Cookies;

var builder = WebApplication.CreateBuilder(args);

var mvc = builder.Services.AddControllersWithViews();

if (builder.Environment.IsDevelopment())
{
    mvc.AddRazorRuntimeCompilation();
}

// No database access and no module project references — every action calls the
// gateway through ApiService. See ARCHITECTURE.md.
builder.Services.AddHttpContextAccessor();

builder.Services.AddHttpClient<IApiService, ApiService>(client =>
{
    client.BaseAddress = new Uri(
        builder.Configuration["APIGatewayBaseUrl"] ?? "https://localhost:7138/");
    client.Timeout = TimeSpan.FromSeconds(
        builder.Configuration.GetValue("Api:TimeoutSeconds", 60));
});

// The admin panel's data seam, mirroring IStorefrontClient on the customer site.
// Flip Api:UseLiveGateway once ChamundaHandicraft.API exposes the Admin/* controllers.
if (builder.Configuration.GetValue("Api:UseLiveGateway", false))
{
    builder.Services.AddScoped<IAdminClient, GatewayAdminClient>();
}
else
{
    builder.Services.AddScoped<IAdminClient, DemoAdminClient>();
}

builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(
        builder.Configuration.GetValue("Session:IdleTimeoutMinutes", 30));
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

builder.Services
    .AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Auth/Login";
        options.LogoutPath = "/Auth/Logout";
        options.AccessDeniedPath = "/Auth/AccessDenied";
        options.SlidingExpiration = true;
    });

builder.Services.AddAuthorization();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseSession();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Dashboard}/{action=Index}/{id?}");

app.Run();
