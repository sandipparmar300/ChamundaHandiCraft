using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Chargebacks — the evidence window is the deadline that matters.</summary>
public class DisputeController : AdminCrudController<DisputeGridItem, DisputeGridItem>
{
    public DisputeController(IAdminClient client) : base(client) { }

    protected override string Module => "Dispute";
}
