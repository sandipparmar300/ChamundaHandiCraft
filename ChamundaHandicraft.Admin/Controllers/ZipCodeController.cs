using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Serviceability — what the PDP PIN check answers.</summary>
public class ZipCodeController : AdminCrudController<ZipCodeGridItem, ZipCodeGridItem>
{
    public ZipCodeController(IAdminClient client) : base(client) { }

    protected override string Module => "ZipCode";
}
