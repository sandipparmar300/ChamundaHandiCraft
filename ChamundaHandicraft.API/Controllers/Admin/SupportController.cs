using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;
using Support.Domain.IServices;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class SupportController : ControllerBase
{
    private readonly ISupportService _supportService;

    public SupportController(ISupportService supportService)
    {
        _supportService = supportService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<SupportTicketGridItem>>>> GridList([FromBody] DataTableRequest request, CancellationToken ct)
    {
        var response = await _supportService.GetGridAsync(request, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<SupportTicketGridItem>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _supportService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpGet("Details")]
    public async Task<ActionResult<ResponseViewModel<SupportTicketGridItem>>> Details([FromQuery] int id, CancellationToken ct)
    {
        var response = await _supportService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] SupportTicketGridItem request, CancellationToken ct)
    {
        var response = await _supportService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _supportService.DeleteAsync(id, null, ct);
        return Ok(response);
    }

    [HttpPost("UpdateStatus")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateStatus([FromBody] UpdateStatusRequest request, CancellationToken ct)
    {
        var response = await _supportService.UpdateStatusAsync(request, null, ct);
        return Ok(response);
    }
}
