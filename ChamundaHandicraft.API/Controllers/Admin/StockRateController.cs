using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Inventory.Domain.IServices;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class StockRateController : ControllerBase
{
    private readonly IStockRateService _rateService;

    public StockRateController(IStockRateService rateService)
    {
        _rateService = rateService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<StockRateGridItem>>>> GridList([FromBody] DataTableRequest request, [FromQuery] int? warehouseId, CancellationToken ct)
    {
        var response = await _rateService.GetGridAsync(request, warehouseId, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<StockRateDetailViewModel>>> GetById([FromQuery] int productId, [FromQuery] int? variantId, CancellationToken ct)
    {
        var response = await _rateService.GetByIdAsync(productId, variantId, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Save([FromBody] StockRateSaveRequest request, CancellationToken ct)
    {
        var response = await _rateService.SaveAsync(request, null, ct);
        return Ok(response);
    }
}
