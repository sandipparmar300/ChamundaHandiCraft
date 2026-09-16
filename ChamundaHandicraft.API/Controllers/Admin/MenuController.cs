using Categories.Domain.IServices;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class MenuController : ControllerBase
{
    private readonly IMenuService _menuService;

    public MenuController(IMenuService menuService)
    {
        _menuService = menuService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<MenuGridItem>>>> GridList([FromBody] DataTableRequest request, [FromQuery] string? location = null, CancellationToken ct = default)
    {
        var response = await _menuService.GetGridAsync(request, location, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<MenuGridItem>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _menuService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] MenuGridItem request, CancellationToken ct)
    {
        var response = await _menuService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _menuService.DeleteAsync(id, null, ct);
        return Ok(response);
    }

    [HttpPost("UpdateStatus")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateStatus([FromBody] UpdateStatusRequest request, CancellationToken ct)
    {
        var response = await _menuService.UpdateStatusAsync(request, null, ct);
        return Ok(response);
    }

    [HttpGet("Lookup")]
    public async Task<ActionResult<ResponseViewModel<List<IdNamePair>>>> Lookup([FromQuery] string? location = null, CancellationToken ct = default)
    {
        var response = await _menuService.GetLookupAsync(location, ct);
        return Ok(response);
    }
}
