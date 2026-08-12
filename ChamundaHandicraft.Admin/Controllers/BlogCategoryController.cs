using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Article grouping and the blog chip nav.</summary>
public class BlogCategoryController : AdminCrudController<BlogCategoryGridItem, BlogCategoryGridItem>
{
    public BlogCategoryController(IAdminClient client) : base(client) { }

    protected override string Module => "BlogCategory";
}
