using Catalog.Application.Services;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Customer;

[ApiController]
[Route("api/customer/search")]
public class CustomerSearchController : ControllerBase
{
    private readonly ICustomerProductService _customerProductService;

    public CustomerSearchController(ICustomerProductService customerProductService)
    {
        _customerProductService = customerProductService;
    }

    [HttpGet("query")]
    public async Task<ActionResult<ResponseViewModel<ProductListingViewModel>>> Query(
        [FromQuery] string? q,
        [FromQuery] string? sort,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var result = await _customerProductService.GetListingAsync(
            categorySlug: null,
            subCategorySlug: null,
            search: q,
            minPrice: null,
            maxPrice: null,
            material: null,
            craft: null,
            inStockOnly: null,
            rating: null,
            sort: sort ?? "relevance",
            page: page,
            pageSize: pageSize,
            ct: ct);

        return Ok(result);
    }

    [HttpGet("suggestions")]
    public async Task<ActionResult<ResponseViewModel<ProductSearchResultViewModel>>> Suggestions(
        [FromQuery] string? q,
        [FromQuery] int limit = 8,
        CancellationToken ct = default)
    {
        var result = await _customerProductService.SearchAsync(q ?? string.Empty, limit, ct);
        return Ok(result);
    }
}
