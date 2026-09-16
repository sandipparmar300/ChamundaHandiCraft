using Catalog.Application.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class AttributeController : ControllerBase
{
    private readonly IAttributeService _attributeService;

    public AttributeController(IAttributeService attributeService)
    {
        _attributeService = attributeService;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<AttributeGridItem>>>> GridList([FromBody] DataTableRequest request, CancellationToken ct)
    {
        var response = await _attributeService.GetGridAsync(request, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<AttributeSaveRequest>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _attributeService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] AttributeSaveRequest request, CancellationToken ct)
    {
        var response = await _attributeService.SaveAsync(request, null, ct);
        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _attributeService.DeleteAsync(id, null, ct);
        return Ok(response);
    }

    [HttpPost("UpdateStatus")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateStatus([FromBody] UpdateStatusRequest request, CancellationToken ct)
    {
        var response = await _attributeService.UpdateStatusAsync(request, null, ct);
        return Ok(response);
    }

    [HttpGet("Lookup")]
    public async Task<ActionResult<ResponseViewModel<List<IdNamePair>>>> Lookup(CancellationToken ct)
    {
        var response = await _attributeService.GetLookupAsync(ct);
        return Ok(response);
    }
}
