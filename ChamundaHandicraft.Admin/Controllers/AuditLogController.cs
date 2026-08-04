using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// View shell for the Audit Log screens. Each action renders markup only â€”
/// the ApiService calls and view models arrive with the API wiring.
/// </summary>
public class AuditLogController : Controller
{
    public IActionResult Index() => View();

    public IActionResult Details(int id) => View();
}
