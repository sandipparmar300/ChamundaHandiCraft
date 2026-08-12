using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Permission sets granted to team members.</summary>
public class RoleController : AdminCrudController<RoleGridItem, RoleGridItem>
{
    public RoleController(IAdminClient client) : base(client) { }

    protected override string Module => "Role";
}
