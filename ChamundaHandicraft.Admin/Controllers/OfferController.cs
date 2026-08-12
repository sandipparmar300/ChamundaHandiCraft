using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Flash sales and category offers.</summary>
public class OfferController : AdminCrudController<OfferGridItem, FlashSaleSaveRequest>
{
    public OfferController(IAdminClient client) : base(client) { }

    protected override string Module => "Offer";
}
