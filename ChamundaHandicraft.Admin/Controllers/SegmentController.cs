using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Customer segments — the audiences campaigns and coupons target.
///
/// The detail screen carries what the edit form cannot: how many customers matched and
/// when the rule was last evaluated. Both are results of the rule, not part of it.
/// </summary>
public class SegmentController : AdminCrudController<SegmentGridItem, SegmentGridItem>
{
    public SegmentController(IAdminClient client) : base(client) { }

    protected override string Module => "Segment";
}
