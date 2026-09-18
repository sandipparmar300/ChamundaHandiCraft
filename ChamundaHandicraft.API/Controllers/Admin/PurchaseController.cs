using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Inventory.Domain.IServices;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class PurchaseController : ControllerBase
{
    private readonly IPurchaseService _purchaseService;

    public PurchaseController(IPurchaseService purchaseService)
    {
        _purchaseService = purchaseService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<PurchaseOrderGridItem>>>> GridList([FromBody] DataTableRequest request, [FromQuery] int? supplierId, [FromQuery] int? warehouseId, [FromQuery] string? status, CancellationToken ct)
    {
        var response = await _purchaseService.GetGridAsync(request, supplierId, warehouseId, status, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<PurchaseOrderDetailViewModel>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _purchaseService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] PurchaseOrderSaveRequest request, CancellationToken ct)
    {
        var response = await _purchaseService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _purchaseService.DeleteAsync(id, null, ct);
        return Ok(response);
    }

    [HttpPost("UpdateStatus")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateStatus([FromBody] UpdateStatusRequest request, CancellationToken ct)
    {
        var statusStr = request.Status switch
        {
            1 => "Ordered",
            2 => "PartiallyReceived",
            3 => "Received",
            4 => "Cancelled",
            _ => request.Reason ?? "Draft"
        };

        var response = await _purchaseService.UpdateStatusAsync(request.Id, statusStr, null, ct);
        return Ok(response);
    }

    [HttpPost("ReceiveStock")]
    public async Task<ActionResult<ResponseViewModel<bool>>> ReceiveStock([FromQuery] int id, CancellationToken ct)
    {
        var response = await _purchaseService.ReceiveStockAsync(id, null, ct);
        return Ok(response);
    }
}
