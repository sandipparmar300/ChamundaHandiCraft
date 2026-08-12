using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Reference data behind address entry.</summary>
public class CountryController : AdminCrudController<CountryGridItem, CountryGridItem>
{
    public CountryController(IAdminClient client) : base(client) { }

    protected override string Module => "Country";
}
