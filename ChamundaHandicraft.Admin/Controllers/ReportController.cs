using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Saved and scheduled reports — sales, inventory, tax.</summary>
public class ReportController : AdminListController<SavedReportGridItem>
{
    public ReportController(IAdminClient client) : base(client) { }

    protected override string Module => "Report";
}
