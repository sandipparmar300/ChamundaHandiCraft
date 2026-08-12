using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Craft stories, published to /blog.</summary>
public class BlogController : AdminCrudController<BlogGridItem, BlogPostSaveRequest>
{
    public BlogController(IAdminClient client) : base(client) { }

    protected override string Module => "Blog";
}
