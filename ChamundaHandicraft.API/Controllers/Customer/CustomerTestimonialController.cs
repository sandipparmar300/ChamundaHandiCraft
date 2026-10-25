using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;
using Testimonials.Domain.IServices;

namespace ChamundaHandicraft.API.Controllers.Customer;

[ApiController]
[Route("api/customer/testimonial")]
public class CustomerTestimonialController : ControllerBase
{
    private readonly ITestimonialService _testimonialService;

    public CustomerTestimonialController(ITestimonialService testimonialService)
    {
        _testimonialService = testimonialService;
    }

    [HttpGet("List")]
    [HttpGet("Featured")]
    public async Task<ActionResult<ResponseViewModel<List<TestimonialGridItem>>>> GetFeatured([FromQuery] int count = 10, CancellationToken ct = default)
    {
        var response = await _testimonialService.GetFeaturedAsync(count, ct);
        return Ok(response);
    }
}
