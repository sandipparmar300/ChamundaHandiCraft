using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 19 · Static Pages. Two shapes only: an editorial page (About,
/// Sustainability) and a policy page (SL-07 centred wide, long-form text with a
/// table of contents). Everything routes through <c>/pages/{slug}</c>.
/// </summary>
public class PageController : StorefrontController
{
    public PageController(IStorefrontClient client) : base(client) { }

    private static readonly HashSet<string> Editorial = new(StringComparer.OrdinalIgnoreCase)
    {
        "about", "sustainability", "careers", "press", "bulk-orders"
    };

    [HttpGet("/pages/{slug}")]
    public IActionResult Index(string slug)
    {
        var title = Titleise(slug);

        Page(title);
        Crumbs(("Home", "/"), (title, null));
        ViewData["Slug"] = slug;

        if (string.Equals(slug, "contact", StringComparison.OrdinalIgnoreCase))
        {
            return View("Contact");
        }

        return Editorial.Contains(slug) ? View("About") : View("Policy");
    }

    private static string Titleise(string slug) => slug.ToLowerInvariant() switch
    {
        "about" => "Our story",
        "sustainability" => "Sustainability",
        "careers" => "Careers",
        "press" => "Press",
        "bulk-orders" => "Bulk & corporate orders",
        "contact" => "Contact us",
        "privacy-policy" => "Privacy policy",
        "terms" => "Terms & conditions",
        "shipping-policy" => "Shipping policy",
        "return-policy" => "Return policy",
        "refund-policy" => "Refund policy",
        "cookie-policy" => "Cookie policy",
        "shipping" => "Shipping information",
        "returns" => "Returns",
        _ => string.Join(' ', slug.Split('-').Select(w => w.Length == 0 ? w : char.ToUpperInvariant(w[0]) + w[1..]))
    };
}
