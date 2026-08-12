using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Comment moderation queue. Read-only — these records are created by the system, not an operator.</summary>
public class BlogCommentController : AdminListController<BlogCommentGridItem>
{
    public BlogCommentController(IAdminClient client) : base(client) { }

    protected override string Module => "BlogComment";
}
