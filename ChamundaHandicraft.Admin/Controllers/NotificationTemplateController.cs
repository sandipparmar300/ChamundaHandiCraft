using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>The messages order events send.</summary>
public class NotificationTemplateController : AdminCrudController<NotificationTemplateGridItem, NotificationTemplateGridItem>
{
    public NotificationTemplateController(IAdminClient client) : base(client) { }

    protected override string Module => "NotificationTemplate";
}
