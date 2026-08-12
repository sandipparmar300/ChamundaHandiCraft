using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Generic lookup lists used across the platform.</summary>
public class MasterController : AdminCrudController<MasterGridItem, MasterGridItem>
{
    public MasterController(IAdminClient client) : base(client) { }

    protected override string Module => "Master";
}
