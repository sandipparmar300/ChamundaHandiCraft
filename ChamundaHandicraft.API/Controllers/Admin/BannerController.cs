using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;
using Banners.Domain.IServices;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class BannerController : ControllerBase
{
    private readonly IBannerService _bannerService;

    public BannerController(IBannerService bannerService)
    {
        _bannerService = bannerService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<BannerViewModel>>>> GridList([FromBody] DataTableRequest request, CancellationToken ct)
    {
        var response = await _bannerService.GetGridAsync(request, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<BannerSaveRequest>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _bannerService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpGet("Details")]
    public async Task<ActionResult<ResponseViewModel<BannerViewModel>>> Details([FromQuery] int id, CancellationToken ct)
    {
        var response = await _bannerService.GetDetailAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] BannerSaveRequest request, CancellationToken ct)
    {
        var response = await _bannerService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _bannerService.DeleteAsync(id, null, ct);
        return Ok(response);
    }

    [HttpPost("UpdateStatus")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateStatus([FromBody] UpdateStatusRequest request, CancellationToken ct)
    {
        var response = await _bannerService.UpdateStatusAsync(request, null, ct);
        return Ok(response);
    }
}
