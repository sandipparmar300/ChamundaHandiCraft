using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Reference data behind address entry and GST place of supply.</summary>
public class StateController : AdminCrudController<StateGridItem, StateGridItem>
{
    public StateController(IAdminClient client) : base(client) { }

    protected override string Module => "State";
}
