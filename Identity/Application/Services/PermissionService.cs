using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Identity.Domain.IServices;

namespace Identity.Application.Services;

public class PermissionService : IPermissionService
{
    private readonly IPermissionRepository _permissionRepository;

    public PermissionService(IPermissionRepository permissionRepository)
    {
        _permissionRepository = permissionRepository;
    }

    public async Task<ResponseViewModel<List<PermissionMatrixItem>>> GetMatrixAsync(int? roleId = null, CancellationToken ct = default)
    {
        try
        {
            var list = await _permissionRepository.GetMatrixAsync(roleId, ct);
            return ResponseViewModel<List<PermissionMatrixItem>>.Success(list, "Permissions retrieved successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<List<PermissionMatrixItem>>.Fail(
                $"Failed to retrieve permissions: {ex.Message}", ApiStatusCode.ServerError);
        }
    }

    public async Task<ResponseViewModel<bool>> SaveRolePermissionsAsync(int roleId, List<int> permissionIds, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var success = await _permissionRepository.SaveRolePermissionsAsync(roleId, permissionIds, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, "Role permissions saved successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message, ApiStatusCode.BadRequest);
        }
    }
}
