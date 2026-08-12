using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Discount codes the shopper applies in cart.</summary>
public class CouponController : AdminCrudController<CouponGridItem, CouponSaveRequest>
{
    public CouponController(IAdminClient client) : base(client) { }

    protected override string Module => "Coupon";
}
