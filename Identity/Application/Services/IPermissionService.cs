using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Identity.Application.Services;

public interface IPermissionService
{
    Task<ResponseViewModel<List<PermissionMatrixItem>>> GetMatrixAsync(int? roleId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> SaveRolePermissionsAsync(int roleId, List<int> permissionIds, int? adminUserId = null, CancellationToken ct = default);
}
