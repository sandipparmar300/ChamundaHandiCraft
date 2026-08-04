using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// View shell for the Notification Templates screens. Each action renders markup only â€”
/// the ApiService calls and view models arrive with the API wiring.
/// </summary>
public class NotificationTemplateController : Controller
{
    public IActionResult Index() => View();

    public IActionResult Add() => View("Create");

    public IActionResult Edit(int id) => View("Create");

    public IActionResult Details(int id) => View();
}
