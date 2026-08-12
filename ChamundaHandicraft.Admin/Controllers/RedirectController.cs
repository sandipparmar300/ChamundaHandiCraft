using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>301s that keep old links working after a slug change.</summary>
public class RedirectController : AdminCrudController<RedirectGridItem, RedirectGridItem>
{
    public RedirectController(IAdminClient client) : base(client) { }

    protected override string Module => "Redirect";
}
