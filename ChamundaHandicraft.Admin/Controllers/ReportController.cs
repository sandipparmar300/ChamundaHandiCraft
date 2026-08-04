using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Report catalogue, saved reports and schedules. Reports are generated, never
/// created as records, so there is no Add action.
/// </summary>
public class ReportController : Controller
{
    public IActionResult Index() => View();

    public IActionResult Details(int id) => View();
}
