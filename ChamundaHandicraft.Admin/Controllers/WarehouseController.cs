using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Stock locations.</summary>
public class WarehouseController : AdminCrudController<WarehouseGridItem, WarehouseGridItem>
{
    public WarehouseController(IAdminClient client) : base(client) { }

    protected override string Module => "Warehouse";
}
