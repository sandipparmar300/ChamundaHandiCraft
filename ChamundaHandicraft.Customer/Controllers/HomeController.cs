using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>Module 02 · Home — docs/ui-ux-storefront/10-Modules-01-02-Auth-Home.md §2.</summary>
public class HomeController : StorefrontController
{
    public HomeController(IStorefrontClient client) : base(client) { }

    [HttpGet("/")]
    public async Task<IActionResult> Index(CancellationToken ct = default)
    {
        ActiveNav("home");
        Page("Handmade by Indian artisans",
            "Brass diyas, blue pottery, kantha textiles and jewellery bought direct from named artisans. "
            + "Free delivery above ₹999, 7-day returns, secure payments.");

        var heroBannersResp = await Client.GetBannersAsync("HomeHero", ct);
        var categoriesResp = await Client.GetCategoriesAsync(ct);
        var flashSaleResp = await Client.GetFlashSaleOfferAsync(ct);
        var testimonialsResp = await Client.GetTestimonialsAsync(ct);
        var config = await Client.GetConfigAsync(ct);

        var allProducts = DemoContent.AllProducts();

        var model = new HomeIndexViewModel
        {
            HeroBanners = heroBannersResp.IsSuccess && heroBannersResp.Data != null && heroBannersResp.Data.Count > 0
                ? heroBannersResp.Data
                : new List<BannerViewModel>(),
            FeaturedCategories = categoriesResp.IsSuccess && categoriesResp.Data != null && categoriesResp.Data.Count > 0
                ? categoriesResp.Data
                : DemoContent.Categories(),
            FlashSaleOffer = flashSaleResp.IsSuccess ? flashSaleResp.Data : null,
            Testimonials = testimonialsResp.IsSuccess && testimonialsResp.Data != null && testimonialsResp.Data.Count > 0
                ? testimonialsResp.Data
                : DemoContent.Reviews().Select(r => new TestimonialGridItem
                {
                    CustomerName = r.Author,
                    Location = "Verified Buyer",
                    Quote = r.Body,
                    Rating = r.Rating,
                    ShowOnHome = true
                }).ToList(),
            Config = config,
            FlashSaleProducts = allProducts.Where(p => p.IsOnSale).Take(6).ToList(),
            NewArrivals = allProducts.Skip(4).Take(6).ToList(),
            Bestsellers = allProducts.Take(6).ToList(),
            Artisans = DemoContent.Artisans(),
            Articles = DemoContent.Articles()
        };

        return View(model);
    }

    [HttpGet("/error")]
    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error(int? code)
    {
        ViewData["StatusCode"] = code ?? 500;
        Response.StatusCode = code ?? 500;
        return View("Error");
    }
}
