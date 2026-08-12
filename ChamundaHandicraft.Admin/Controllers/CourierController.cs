using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Delivery partners and their capabilities.</summary>
public class CourierController : AdminCrudController<CourierGridItem, CourierGridItem>
{
    public CourierController(IAdminClient client) : base(client) { }

    protected override string Module => "Courier";
}
