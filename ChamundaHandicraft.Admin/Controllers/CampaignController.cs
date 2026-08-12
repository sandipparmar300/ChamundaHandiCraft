using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Email and WhatsApp sends.</summary>
public class CampaignController : AdminCrudController<CampaignGridItem, CampaignGridItem>
{
    public CampaignController(IAdminClient client) : base(client) { }

    protected override string Module => "Campaign";
}
