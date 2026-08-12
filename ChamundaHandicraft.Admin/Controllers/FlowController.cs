using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Automated sequences — welcome, abandoned cart, review request.</summary>
public class FlowController : AdminCrudController<FlowGridItem, FlowGridItem>
{
    public FlowController(IAdminClient client) : base(client) { }

    protected override string Module => "Flow";
}
