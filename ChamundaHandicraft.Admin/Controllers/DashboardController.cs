using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// View shell for the Dashboard screens. Each action renders markup only —
/// the ApiService calls and view models arrive with the API wiring.
/// </summary>
public class DashboardController : Controller
{
    public IActionResult Index() => View();
}

