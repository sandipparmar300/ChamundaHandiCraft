using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Live stock — the only figure the storefront may quote. Read-only — these records are created by the system, not an operator.</summary>
public class InventoryController : AdminListController<StockGridItem>
{
    public InventoryController(IAdminClient client) : base(client) { }

    protected override string Module => "Inventory";
}
