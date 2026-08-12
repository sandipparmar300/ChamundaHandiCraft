using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Newsletter list and suppression.</summary>
public class SubscriberController : AdminCrudController<SubscriberGridItem, SubscriberGridItem>
{
    public SubscriberController(IAdminClient client) : base(client) { }

    protected override string Module => "Subscriber";
}
