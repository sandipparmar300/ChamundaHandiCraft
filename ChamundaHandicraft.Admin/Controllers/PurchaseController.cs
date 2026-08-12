using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Purchase orders raised against suppliers.</summary>
public class PurchaseController : AdminCrudController<PurchaseOrderGridItem, PurchaseOrderGridItem>
{
    public PurchaseController(IAdminClient client) : base(client) { }

    protected override string Module => "Purchase";
}
