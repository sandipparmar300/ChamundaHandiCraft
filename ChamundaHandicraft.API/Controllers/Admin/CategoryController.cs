using Categories.Domain.IServices;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class CategoryController : ControllerBase
{
    private readonly ICategoryService _categoryService;

    public CategoryController(ICategoryService categoryService)
    {
        _categoryService = categoryService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<CategoryGridItem>>>> GridList([FromBody] DataTableRequest request, CancellationToken ct)
    {
        var response = await _categoryService.GetGridAsync(request, ct);
        return Ok(response);
    }

    [HttpGet("Tree")]
    public async Task<ActionResult<ResponseViewModel<List<CategoryViewModel>>>> Tree(CancellationToken ct)
    {
        var response = await _categoryService.GetTreeAsync(ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<CategorySaveRequest>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _categoryService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] CategorySaveRequest request, CancellationToken ct)
    {
        var response = await _categoryService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _categoryService.DeleteAsync(id, null, ct);
        return Ok(response);
    }

    [HttpPost("UpdateStatus")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateStatus([FromBody] UpdateStatusRequest request, CancellationToken ct)
    {
        var response = await _categoryService.UpdateStatusAsync(request, null, ct);
        return Ok(response);
    }

    [HttpGet("Lookup")]
    public async Task<ActionResult<ResponseViewModel<List<IdNamePair>>>> Lookup(CancellationToken ct)
    {
        var response = await _categoryService.GetLookupAsync(ct);
        return Ok(response);
    }
}
