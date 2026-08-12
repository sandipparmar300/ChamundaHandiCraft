using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Parcels in the courier network.</summary>
public class ShipmentController : AdminCrudController<ShipmentGridItem, ShipmentGridItem>
{
    public ShipmentController(IAdminClient client) : base(client) { }

    protected override string Module => "Shipment";
}
