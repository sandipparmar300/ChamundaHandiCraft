using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Money coming in. Read-only — these records are created by the system, not an operator.</summary>
public class PaymentController : AdminListController<PaymentGridItem>
{
    public PaymentController(IAdminClient client) : base(client) { }

    protected override string Module => "Payment";
}
