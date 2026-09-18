using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Inventory.Domain.IServices;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class StockTransferController : ControllerBase
{
    private readonly IStockTransferService _transferService;

    public StockTransferController(IStockTransferService transferService)
    {
        _transferService = transferService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<StockTransferGridItem>>>> GridList([FromBody] DataTableRequest request, [FromQuery] int? fromWarehouseId, [FromQuery] int? toWarehouseId, [FromQuery] string? status, CancellationToken ct)
    {
        var response = await _transferService.GetGridAsync(request, fromWarehouseId, toWarehouseId, status, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<StockTransferDetailViewModel>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _transferService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] StockTransferSaveRequest request, CancellationToken ct)
    {
        var response = await _transferService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpPost("UpdateStatus")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateStatus([FromBody] UpdateStatusRequest request, CancellationToken ct)
    {
        var statusStr = request.Status switch
        {
            1 => "In Transit",
            2 => "Received",
            3 => "Cancelled",
            _ => request.Reason ?? "Draft"
        };

        var response = await _transferService.UpdateStatusAsync(request.Id, statusStr, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _transferService.DeleteAsync(id, null, ct);
        return Ok(response);
    }
}
