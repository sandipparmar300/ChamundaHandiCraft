using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Quotes shown on the home page.</summary>
public class TestimonialController : AdminCrudController<TestimonialGridItem, TestimonialSaveRequest>
{
    public TestimonialController(IAdminClient client) : base(client) { }

    protected override string Module => "Testimonial";
}
