using Catalog.Application.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class ProductController : ControllerBase
{
    private readonly IProductService _productService;

    public ProductController(IProductService productService)
    {
        _productService = productService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<ProductGridItem>>>> GridList([FromBody] DataTableRequest request, CancellationToken ct)
    {
        var response = await _productService.GetGridAsync(request, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<ProductSaveRequest>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _productService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] ProductSaveRequest request, CancellationToken ct)
    {
        var response = await _productService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _productService.DeleteAsync(id, null, ct);
        return Ok(response);
    }

    [HttpPost("UpdateStatus")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateStatus([FromBody] UpdateStatusRequest request, CancellationToken ct)
    {
        var response = await _productService.UpdateStatusAsync(request, null, ct);
        return Ok(response);
    }

    [HttpGet("Lookups")]
    public async Task<ActionResult<ResponseViewModel<ProductLookupsViewModel>>> Lookups(CancellationToken ct)
    {
        var response = await _productService.GetLookupsAsync(ct);
        return Ok(response);
    }

    [HttpGet("Lookup")]
    public async Task<ActionResult<ResponseViewModel<List<IdNamePair>>>> Lookup(CancellationToken ct)
    {
        var response = await _productService.GetLookupAsync(ct);
        return Ok(response);
    }

    [HttpGet("VariantLookup")]
    public async Task<ActionResult<ResponseViewModel<List<IdNamePair>>>> VariantLookup([FromQuery] int? productId, CancellationToken ct)
    {
        var response = await _productService.GetVariantsLookupAsync(productId, ct);
        return Ok(response);
    }
}
