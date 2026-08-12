using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Return requests raised from the customer order page.</summary>
public class ReturnController : AdminCrudController<ReturnRequestViewModel, ReturnRequestViewModel>
{
    public ReturnController(IAdminClient client) : base(client) { }

    protected override string Module => "Return";
}
