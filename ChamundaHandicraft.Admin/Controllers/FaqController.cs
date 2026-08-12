using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Help centre and PDP questions.</summary>
public class FaqController : AdminCrudController<FaqGridItem, FaqGridItem>
{
    public FaqController(IAdminClient client) : base(client) { }

    protected override string Module => "Faq";
}
