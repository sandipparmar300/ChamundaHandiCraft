using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Workshops and studio lines.</summary>
public class BrandController : AdminCrudController<BrandGridItem, BrandGridItem>
{
    public BrandController(IAdminClient client) : base(client) { }

    protected override string Module => "Brand";
}
