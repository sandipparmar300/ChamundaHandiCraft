using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Who changed what, and when. Read-only — these records are created by the system, not an operator.</summary>
public class AuditLogController : AdminListController<AuditLogGridItem>
{
    public AuditLogController(IAdminClient client) : base(client) { }

    protected override string Module => "AuditLog";
}
