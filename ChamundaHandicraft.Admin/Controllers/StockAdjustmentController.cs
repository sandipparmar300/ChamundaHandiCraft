using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Manual stock corrections, each with a stated reason.</summary>
public class StockAdjustmentController : AdminCrudController<StockAdjustmentGridItem, StockAdjustmentGridItem>
{
    public StockAdjustmentController(IAdminClient client) : base(client) { }

    protected override string Module => "StockAdjustment";
}
