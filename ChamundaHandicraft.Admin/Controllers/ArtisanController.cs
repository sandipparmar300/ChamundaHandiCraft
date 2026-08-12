using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>The makers credited on every product page.</summary>
public class ArtisanController : AdminCrudController<ArtisanGridItem, ArtisanSaveRequest>
{
    public ArtisanController(IAdminClient client) : base(client) { }

    protected override string Module => "Artisan";
}
