using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Bylines shown on articles.</summary>
public class BlogAuthorController : AdminCrudController<BlogAuthorGridItem, BlogAuthorGridItem>
{
    public BlogAuthorController(IAdminClient client) : base(client) { }

    protected override string Module => "BlogAuthor";
}
