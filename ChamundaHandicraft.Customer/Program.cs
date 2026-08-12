using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.ApiService;
using Microsoft.AspNetCore.Authentication.Cookies;

var builder = WebApplication.CreateBuilder(args);

var mvc = builder.Services.AddControllersWithViews();

if (builder.Environment.IsDevelopment())
{
    mvc.AddRazorRuntimeCompilation();
}

// No database access — everything goes through the gateway. See ARCHITECTURE.md.
builder.Services.AddHttpContextAccessor();

// The single HTTP path to the gateway. Base address is the Ocelot host, never the API.
builder.Services.AddHttpClient<IApiService, ApiService>(client =>
{
    client.BaseAddress = new Uri(
        builder.Configuration["APIGatewayBaseUrl"] ?? "https://localhost:7138/");
    client.Timeout = TimeSpan.FromSeconds(
        builder.Configuration.GetValue("Api:TimeoutSeconds", 30));
});

// The storefront's data seam.
//
//   DemoStorefrontClient    — design phase, serves DemoContent
//   GatewayStorefrontClient — production, calls the gateway
//
// Both implement IStorefrontClient and return the same envelope, so switching is this
// one registration. Flip it once ChamundaHandicraft.API exposes the Shop/* controllers.
if (builder.Configuration.GetValue("Api:UseLiveGateway", false))
{
    builder.Services.AddScoped<IStorefrontClient, GatewayStorefrontClient>();
}
else
{
    builder.Services.AddScoped<IStorefrontClient, DemoStorefrontClient>();
}

// Long-lived so an anonymous cart survives: CX principle 11, never lose the
// shopper's work.
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(
        builder.Configuration.GetValue("Session:IdleTimeoutMinutes", 1440));
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

builder.Services
    .AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/login";
        options.LogoutPath = "/logout";
        options.AccessDeniedPath = "/login";
        options.SlidingExpiration = true;
    });

builder.Services.AddAuthorization();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

// 404 and 500 re-execute into the storefront error page so the shopper keeps the
// header, footer and a route back into the catalogue (CX principle 12).
app.UseStatusCodePagesWithReExecute("/error", "?code={0}");

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseSession();
app.UseAuthentication();
app.UseAuthorization();

// Customer-facing routes are slug-based and come verbatim from
// docs/ui-ux-storefront/00-Master-Index.md §0.4.3. Each controller declares its
// own routes with [Route] so the slug shape lives next to the action it serves.
app.MapControllers();

// Fallback for anything not attribute-routed.
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
