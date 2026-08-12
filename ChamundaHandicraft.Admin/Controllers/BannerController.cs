using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Home hero and injected placements.</summary>
public class BannerController : AdminCrudController<BannerViewModel, BannerSaveRequest>
{
    public BannerController(IAdminClient client) : base(client) { }

    protected override string Module => "Banner";
}
