using Catalog.Application.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class ArtisanController : ControllerBase
{
    private readonly IArtisanService _artisanService;

    public ArtisanController(IArtisanService artisanService)
    {
        _artisanService = artisanService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<ArtisanGridItem>>>> GridList([FromBody] DataTableRequest request, CancellationToken ct)
    {
        var response = await _artisanService.GetGridAsync(request, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<ArtisanSaveRequest>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _artisanService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] ArtisanSaveRequest request, CancellationToken ct)
    {
        var response = await _artisanService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _artisanService.DeleteAsync(id, null, ct);
        return Ok(response);
    }

    [HttpPost("UpdateStatus")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateStatus([FromBody] UpdateStatusRequest request, CancellationToken ct)
    {
        var response = await _artisanService.UpdateStatusAsync(request, null, ct);
        return Ok(response);
    }

    [HttpGet("Lookup")]
    public async Task<ActionResult<ResponseViewModel<List<IdNamePair>>>> Lookup(CancellationToken ct)
    {
        var response = await _artisanService.GetLookupAsync(ct);
        return Ok(response);
    }
}
