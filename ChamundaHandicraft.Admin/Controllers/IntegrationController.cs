using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Payment, courier and communication providers.</summary>
public class IntegrationController : AdminCrudController<IntegrationGridItem, IntegrationGridItem>
{
    public IntegrationController(IAdminClient client) : base(client) { }

    protected override string Module => "Integration";
}
