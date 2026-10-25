using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;
using Promotions.Domain.IServices;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class CouponController : ControllerBase
{
    private readonly ICouponService _couponService;

    public CouponController(ICouponService couponService)
    {
        _couponService = couponService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<CouponGridItem>>>> GridList([FromBody] DataTableRequest request, CancellationToken ct)
    {
        var response = await _couponService.GetGridAsync(request, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<CouponSaveRequest>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _couponService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpGet("Details")]
    public async Task<ActionResult<ResponseViewModel<CouponGridItem>>> Details([FromQuery] int id, CancellationToken ct)
    {
        var response = await _couponService.GetDetailAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] CouponSaveRequest request, CancellationToken ct)
    {
        var response = await _couponService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _couponService.DeleteAsync(id, null, ct);
        return Ok(response);
    }

    [HttpPost("UpdateStatus")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateStatus([FromBody] UpdateStatusRequest request, CancellationToken ct)
    {
        var response = await _couponService.UpdateStatusAsync(request, null, ct);
        return Ok(response);
    }
}
