using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Physical counts and their discrepancies.</summary>
public class StockTakeController : AdminCrudController<StockTakeGridItem, StockTakeGridItem>
{
    public StockTakeController(IAdminClient client) : base(client) { }

    protected override string Module => "StockTake";
}
