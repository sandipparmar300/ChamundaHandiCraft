using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Customer tickets — one working day is the promise.</summary>
public class SupportController : AdminCrudController<SupportTicketGridItem, SupportTicketGridItem>
{
    public SupportController(IAdminClient client) : base(client) { }

    protected override string Module => "Support";
}
