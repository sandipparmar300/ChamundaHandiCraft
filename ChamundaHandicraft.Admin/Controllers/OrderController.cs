using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Order screens. Orders are created by checkout, never by an admin, so there is
/// no Add action — only listing, detail and the status transitions on the detail.
/// </summary>
public class OrderController : Controller
{
    public IActionResult Index() => View();

    public IActionResult Details(int id) => View();
}
