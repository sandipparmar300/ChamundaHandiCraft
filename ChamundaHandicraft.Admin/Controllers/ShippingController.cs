using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Zones and rate cards — what checkout charges.</summary>
public class ShippingController : AdminCrudController<ShippingZoneGridItem, ShippingZoneGridItem>
{
    public ShippingController(IAdminClient client) : base(client) { }

    protected override string Module => "Shipping";
}
