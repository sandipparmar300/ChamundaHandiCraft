using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Requests waiting on a second pair of eyes. Read-only — these records are created by the system, not an operator.</summary>
public class ApprovalController : AdminListController<ApprovalGridItem>
{
    public ApprovalController(IAdminClient client) : base(client) { }

    protected override string Module => "Approval";
}
