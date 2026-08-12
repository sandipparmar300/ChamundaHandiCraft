using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Storefront navigation.</summary>
public class MenuController : AdminCrudController<MenuGridItem, MenuGridItem>
{
    public MenuController(IAdminClient client) : base(client) { }

    protected override string Module => "Menu";
}
