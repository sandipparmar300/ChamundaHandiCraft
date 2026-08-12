using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Static pages served at /pages/{slug}.</summary>
public class CmsPageController : AdminCrudController<CmsPageGridItem, CmsPageSaveRequest>
{
    public CmsPageController(IAdminClient client) : base(client) { }

    protected override string Module => "CmsPage";
}
