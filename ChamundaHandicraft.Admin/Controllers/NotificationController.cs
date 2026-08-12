using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>What was sent, to whom, and whether it arrived. Read-only — these records are created by the system, not an operator.</summary>
public class NotificationController : AdminListController<NotificationLogGridItem>
{
    public NotificationController(IAdminClient client) : base(client) { }

    protected override string Module => "Notification";
}
