using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Inventory.Domain.IServices;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class InventoryController : ControllerBase
{
    private readonly IInventoryService _inventoryService;

    public InventoryController(IInventoryService inventoryService)
    {
        _inventoryService = inventoryService;
    }

    [HttpPost("GridList")]
    [HttpPost("StockGridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<StockGridItem>>>> GridList([FromBody] DataTableRequest request, [FromQuery] int? warehouseId, [FromQuery] string? stockStatus, CancellationToken ct)
    {
        var response = await _inventoryService.GetGridAsync(request, warehouseId, stockStatus, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<StockSaveRequest>>> GetById([FromQuery] long id, CancellationToken ct)
    {
        var response = await _inventoryService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpGet("Details")]
    public async Task<ActionResult<ResponseViewModel<InventoryDetailViewModel>>> Details([FromQuery] long id, CancellationToken ct)
    {
        var response = await _inventoryService.GetDetailAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<long>>> Save([FromBody] StockSaveRequest request, CancellationToken ct)
    {
        var response = await _inventoryService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] long id, CancellationToken ct)
    {
        var response = await _inventoryService.DeleteAsync(id, null, ct);
        return Ok(response);
    }

    [HttpGet("Kpis")]
    public async Task<ActionResult<ResponseViewModel<InventoryKpiSummaryViewModel>>> Kpis(CancellationToken ct)
    {
        var response = await _inventoryService.GetKpisAsync(ct);
        return Ok(response);
    }

    [HttpGet("Ledger")]
    [HttpGet("StockLedger")]
    public async Task<ActionResult<ResponseViewModel<List<InventoryTransactionViewModel>>>> Ledger([FromQuery] int? productId, [FromQuery] int? warehouseId, [FromQuery] int maxRows = 100, CancellationToken ct = default)
    {
        var response = await _inventoryService.GetLedgerAsync(productId, warehouseId, maxRows, ct);
        return Ok(response);
    }
}
