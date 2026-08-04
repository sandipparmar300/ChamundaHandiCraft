using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// View shell for the Customer screens. Each action renders markup only —
/// the ApiService calls and view models arrive with the API wiring.
/// </summary>
public class CustomerController : Controller
{
    public IActionResult Index() => View();

    public IActionResult Details(int id) => View();
}

