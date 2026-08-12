using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Team members and their roles.</summary>
public class AdminUserController : AdminCrudController<AdminUserGridItem, AdminUserGridItem>
{
    public AdminUserController(IAdminClient client) : base(client) { }

    protected override string Module => "AdminUser";
}
