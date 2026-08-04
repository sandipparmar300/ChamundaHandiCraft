using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Platform settings hub. Settings are sections of one record rather than a list,
/// so this controller has no grid or Add action.
/// </summary>
public class SettingsController : Controller
{
    public IActionResult Index() => View();

    public IActionResult History() => View();
}
