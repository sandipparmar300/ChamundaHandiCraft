using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;
using Testimonials.Domain.IServices;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class TestimonialController : ControllerBase
{
    private readonly ITestimonialService _testimonialService;

    public TestimonialController(ITestimonialService testimonialService)
    {
        _testimonialService = testimonialService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<TestimonialGridItem>>>> GridList([FromBody] DataTableRequest request, CancellationToken ct)
    {
        var response = await _testimonialService.GetGridAsync(request, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<TestimonialSaveRequest>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _testimonialService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpGet("Details")]
    public async Task<ActionResult<ResponseViewModel<TestimonialGridItem>>> Details([FromQuery] int id, CancellationToken ct)
    {
        var response = await _testimonialService.GetDetailAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] TestimonialSaveRequest request, CancellationToken ct)
    {
        var response = await _testimonialService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _testimonialService.DeleteAsync(id, null, ct);
        return Ok(response);
    }

    [HttpPost("UpdateStatus")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateStatus([FromBody] UpdateStatusRequest request, CancellationToken ct)
    {
        var response = await _testimonialService.UpdateStatusAsync(request, null, ct);
        return Ok(response);
    }
}
