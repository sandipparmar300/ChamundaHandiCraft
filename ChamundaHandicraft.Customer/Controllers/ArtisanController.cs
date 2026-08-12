using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Artisan storytelling surfaces (modules 03/04). The artisan is a first-class
/// storefront entity, not a metadata field.
/// </summary>
public class ArtisanController : StorefrontController
{
    public ArtisanController(IStorefrontClient client) : base(client) { }

    [HttpGet("/artisans")]
    public IActionResult Index()
    {
        ActiveNav("artisans");
        Page("Meet the makers", "The 240 artisans we buy from, across 18 craft clusters. Every product page names one of them.");
        Crumbs(("Home", "/"), ("Artisans", null));
        return View(DemoContent.Artisans());
    }

    [HttpGet("/artisans/{slug}")]
    public IActionResult Details(string slug)
    {
        ActiveNav("artisans");

        var artisan = DemoContent.Artisans().FirstOrDefault(a => a.Slug == slug) ?? DemoContent.Artisans()[0];

        Page(artisan.Name, $"{artisan.Name} makes {artisan.Craft.ToLowerInvariant()} in {artisan.Cluster}. Read the story and shop the work.");
        Crumbs(("Home", "/"), ("Artisans", "/artisans"), (artisan.Name, null));

        return View(artisan);
    }
}
