using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;
using Promotions.Domain.IServices;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class OfferController : ControllerBase
{
    private readonly IOfferService _offerService;

    public OfferController(IOfferService offerService)
    {
        _offerService = offerService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<OfferGridItem>>>> GridList([FromBody] DataTableRequest request, CancellationToken ct)
    {
        var response = await _offerService.GetGridAsync(request, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<FlashSaleSaveRequest>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _offerService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpGet("Details")]
    public async Task<ActionResult<ResponseViewModel<OfferGridItem>>> Details([FromQuery] int id, CancellationToken ct)
    {
        var response = await _offerService.GetDetailAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] FlashSaleSaveRequest request, CancellationToken ct)
    {
        var response = await _offerService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _offerService.DeleteAsync(id, null, ct);
        return Ok(response);
    }

    [HttpPost("UpdateStatus")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateStatus([FromBody] UpdateStatusRequest request, CancellationToken ct)
    {
        var response = await _offerService.UpdateStatusAsync(request, null, ct);
        return Ok(response);
    }
}
