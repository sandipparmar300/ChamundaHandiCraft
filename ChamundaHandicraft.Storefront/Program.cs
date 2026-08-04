using Microsoft.AspNetCore.Authentication.Cookies;

var builder = WebApplication.CreateBuilder(args);

var mvc = builder.Services.AddControllersWithViews();

if (builder.Environment.IsDevelopment())
{
    mvc.AddRazorRuntimeCompilation();
}

// No database access — everything goes through the gateway. See ARCHITECTURE.md.
builder.Services.AddHttpClient();
builder.Services.AddHttpContextAccessor();

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

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseSession();
app.UseAuthentication();
app.UseAuthorization();

// Customer-facing routes are slug-based and come verbatim from
// docs/ui-ux-storefront/00-Master-Index.md §0.4.3. They are mapped as the
// controllers are written; this default keeps the host runnable meanwhile.
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
