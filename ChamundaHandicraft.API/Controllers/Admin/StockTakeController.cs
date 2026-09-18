using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Inventory.Domain.IServices;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class StockTakeController : ControllerBase
{
    private readonly IStockTakeService _stockTakeService;

    public StockTakeController(IStockTakeService stockTakeService)
    {
        _stockTakeService = stockTakeService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<StockTakeGridItem>>>> GridList([FromBody] DataTableRequest request, [FromQuery] int? warehouseId, [FromQuery] string? status, CancellationToken ct)
    {
        var response = await _stockTakeService.GetGridAsync(request, warehouseId, status, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<StockTakeGridItem>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _stockTakeService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] StockTakeGridItem request, CancellationToken ct)
    {
        var response = await _stockTakeService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _stockTakeService.DeleteAsync(id, null, ct);
        return Ok(response);
    }

    [HttpPost("UpdateStatus")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateStatus([FromBody] UpdateStatusRequest request, CancellationToken ct)
    {
        var response = await _stockTakeService.UpdateStatusAsync(request, null, ct);
        return Ok(response);
    }
}
