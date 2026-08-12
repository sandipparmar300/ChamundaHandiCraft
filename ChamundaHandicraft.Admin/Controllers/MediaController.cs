using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>The image and video library.</summary>
public class MediaController : AdminCrudController<MediaGridItem, MediaGridItem>
{
    public MediaController(IAdminClient client) : base(client) { }

    protected override string Module => "Media";
}
