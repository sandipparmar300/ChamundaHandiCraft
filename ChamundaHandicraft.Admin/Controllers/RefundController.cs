using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Money going back to customers.</summary>
public class RefundController : AdminCrudController<RefundGridItem, RefundGridItem>
{
    public RefundController(IAdminClient client) : base(client) { }

    protected override string Module => "Refund";
}
