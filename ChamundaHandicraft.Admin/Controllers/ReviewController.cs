using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// View shell for the Reviews screens. Each action renders markup only â€”
/// the ApiService calls and view models arrive with the API wiring.
/// </summary>
public class ReviewController : Controller
{
    public IActionResult Index() => View();

    public IActionResult Details(int id) => View();
}
