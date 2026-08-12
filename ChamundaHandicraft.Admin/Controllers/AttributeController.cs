using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Product attributes — these become the PLP facets and PDP option selectors.</summary>
public class AttributeController : AdminCrudController<AttributeGridItem, AttributeGridItem>
{
    public AttributeController(IAdminClient client) : base(client) { }

    protected override string Module => "Attribute";
}
