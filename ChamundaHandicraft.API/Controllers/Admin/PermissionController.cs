using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Identity.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class PermissionController : ControllerBase
{
    private readonly IPermissionService _permissionService;

    public PermissionController(IPermissionService permissionService)
    {
        _permissionService = permissionService;
    }

    [HttpGet("Matrix")]
    public async Task<ActionResult<ResponseViewModel<List<PermissionMatrixItem>>>> Matrix([FromQuery] int? roleId, CancellationToken ct)
    {
        var response = await _permissionService.GetMatrixAsync(roleId, ct);
        return Ok(response);
    }

    [HttpPost("SaveRolePermissions")]
    public async Task<ActionResult<ResponseViewModel<bool>>> SaveRolePermissions([FromBody] SaveRolePermissionsRequest request, CancellationToken ct)
    {
        var response = await _permissionService.SaveRolePermissionsAsync(request.RoleId, request.PermissionIds, null, ct);
        return Ok(response);
    }
}

public class SaveRolePermissionsRequest
{
    public int RoleId { get; set; }
    public List<int> PermissionIds { get; set; } = new();
}
