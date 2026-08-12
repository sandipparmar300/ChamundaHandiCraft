using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Gateway payouts reaching the bank account. Read-only — these records are created by the system, not an operator.</summary>
public class SettlementController : AdminListController<SettlementGridItem>
{
    public SettlementController(IAdminClient client) : base(client) { }

    protected override string Module => "Settlement";
}
