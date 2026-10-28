using Catalog.Application.Services;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Customer;

[ApiController]
[Route("api/customer/product")]
public class CustomerProductController : ControllerBase
{
    private readonly ICustomerProductService _customerProductService;

    public CustomerProductController(ICustomerProductService customerProductService)
    {
        _customerProductService = customerProductService;
    }

    [HttpGet("list")]
    public async Task<ActionResult<ResponseViewModel<ProductListingViewModel>>> GetList(
        [FromQuery] string? category,
        [FromQuery] string? subCategory,
        [FromQuery] string? search,
        [FromQuery] decimal? minPrice,
        [FromQuery] decimal? maxPrice,
        [FromQuery] string? material,
        [FromQuery] string? craft,
        [FromQuery] bool? inStockOnly,
        [FromQuery] int? rating,
        [FromQuery] string? sort,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var result = await _customerProductService.GetListingAsync(
            category,
            subCategory,
            search,
            minPrice,
            maxPrice,
            material,
            craft,
            inStockOnly,
            rating,
            sort,
            page,
            pageSize,
            ct);

        return Ok(result);
    }

    [HttpGet("detail")]
    public async Task<ActionResult<ResponseViewModel<ProductDetailViewModel>>> GetDetail(
        [FromQuery] string slug,
        CancellationToken ct = default)
    {
        var result = await _customerProductService.GetDetailAsync(slug, ct);
        return Ok(result);
    }

    [HttpGet("quickview")]
    public async Task<ActionResult<ResponseViewModel<ProductDetailViewModel>>> GetQuickView(
        [FromQuery] string slug,
        CancellationToken ct = default)
    {
        var result = await _customerProductService.GetDetailAsync(slug, ct);
        return Ok(result);
    }

    [HttpGet("rail")]
    public async Task<ActionResult<ResponseViewModel<List<ProductCardViewModel>>>> GetRail(
        [FromQuery] string rail = "new-arrivals",
        [FromQuery] string? contextSlug = null,
        [FromQuery] int count = 8,
        CancellationToken ct = default)
    {
        var result = await _customerProductService.GetRailAsync(rail, contextSlug, count, ct);
        return Ok(result);
    }

    [HttpGet("related")]
    public async Task<ActionResult<ResponseViewModel<List<ProductCardViewModel>>>> GetRelated(
        [FromQuery] string? slug = null,
        [FromQuery] int count = 4,
        CancellationToken ct = default)
    {
        var result = await _customerProductService.GetRailAsync("related", slug, count, ct);
        return Ok(result);
    }
}
