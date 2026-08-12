using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using ChamundaHandicraft.Customer.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>Module 18 · Blog — SL-08 editorial layout, article content column max 680px.</summary>
public class BlogController : StorefrontController
{
    public BlogController(IStorefrontClient client) : base(client) { }

    [HttpGet("/blog")]
    public IActionResult Index()
    {
        ActiveNav("blog");
        Page("Stories from the workshop", "How things are made, and who makes them. Craft journalism from the studios we buy from.");
        Crumbs(("Home", "/"), ("Stories", null));
        return View(DemoContent.Articles());
    }

    [HttpGet("/blog/{slug}")]
    public IActionResult Article(string slug)
    {
        ActiveNav("blog");

        var article = DemoContent.Articles().FirstOrDefault(a => a.Slug == slug) ?? DemoContent.Articles()[0];

        Page(article.Title, article.Excerpt);
        Crumbs(("Home", "/"), ("Stories", "/blog"), (article.Category, $"/blog?category={article.Category}"),
            (article.Title.Length > 40 ? article.Title[..40] + "…" : article.Title, null));

        return View(article);
    }
}
