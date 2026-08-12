using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Stock moving between warehouses.</summary>
public class StockTransferController : AdminCrudController<StockTransferGridItem, StockTransferGridItem>
{
    public StockTransferController(IAdminClient client) : base(client) { }

    protected override string Module => "StockTransfer";
}
