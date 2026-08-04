using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Inventory hub. Stock is never edited directly — it moves through Purchase,
/// StockAdjustment and StockTransfer, each of which writes a ledger entry.
/// </summary>
public class InventoryController : Controller
{
    public IActionResult Index() => View();

    public IActionResult Details(int id) => View();
}
