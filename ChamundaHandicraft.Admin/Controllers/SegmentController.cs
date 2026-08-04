using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// View shell for the Segment screens. Each action renders markup only —
/// the ApiService calls and view models arrive with the API wiring.
/// </summary>
public class SegmentController : Controller
{
    public IActionResult Index() => View();

    public IActionResult Add() => View("Create");

    public IActionResult Edit(int id) => View("Create");
}

