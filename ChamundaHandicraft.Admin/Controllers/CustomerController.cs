using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Shoppers, their orders and their lifetime value. Read-only — these records are created by the system, not an operator.</summary>
public class CustomerController : AdminListController<CustomerGridItem>
{
    public CustomerController(IAdminClient client) : base(client) { }

    protected override string Module => "Customer";
}
