using Categories.Domain.IServices;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Customer;

[ApiController]
[Route("api/customer/category")]
public class CustomerCategoryController : ControllerBase
{
    private readonly ICategoryService _categoryService;

    public CustomerCategoryController(ICategoryService categoryService)
    {
        _categoryService = categoryService;
    }

    [HttpGet("MegaMenu")]
    public async Task<ActionResult<ResponseViewModel<List<CategoryViewModel>>>> GetMegaMenu(CancellationToken ct)
    {
        var response = await _categoryService.GetMegaMenuAsync(ct);
        return Ok(response);
    }

    [HttpGet("Featured")]
    public async Task<ActionResult<ResponseViewModel<List<CategoryViewModel>>>> GetFeatured(CancellationToken ct)
    {
        var response = await _categoryService.GetFeaturedAsync(ct);
        return Ok(response);
    }

    [HttpGet("Tree")]
    public async Task<ActionResult<ResponseViewModel<List<CategoryViewModel>>>> GetTree(CancellationToken ct)
    {
        var response = await _categoryService.GetTreeAsync(ct);
        return Ok(response);
    }
}
