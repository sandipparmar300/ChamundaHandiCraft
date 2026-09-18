using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Inventory.Domain.IServices;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class StockAdjustmentController : ControllerBase
{
    private readonly IStockAdjustmentService _adjustmentService;

    public StockAdjustmentController(IStockAdjustmentService adjustmentService)
    {
        _adjustmentService = adjustmentService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<StockAdjustmentGridItem>>>> GridList([FromBody] DataTableRequest request, [FromQuery] int? warehouseId, [FromQuery] int? reasonCodeId, CancellationToken ct)
    {
        var response = await _adjustmentService.GetGridAsync(request, warehouseId, reasonCodeId, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<StockAdjustmentDetailViewModel>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _adjustmentService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] StockAdjustmentSaveRequest request, CancellationToken ct)
    {
        var response = await _adjustmentService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _adjustmentService.DeleteAsync(id, null, ct);
        return Ok(response);
    }
}
