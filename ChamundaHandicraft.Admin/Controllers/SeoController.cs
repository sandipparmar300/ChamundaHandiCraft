using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Meta, canonical and structured data per route.</summary>
public class SeoController : AdminCrudController<SeoMetaGridItem, SeoMetaGridItem>
{
    public SeoController(IAdminClient client) : base(client) { }

    protected override string Module => "Seo";
}
