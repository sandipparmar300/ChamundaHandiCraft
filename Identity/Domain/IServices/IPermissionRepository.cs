using ChamundaHandicraft.Helper.ViewModel.Admin;

namespace Identity.Domain.IServices;

public interface IPermissionRepository
{
    Task<List<PermissionMatrixItem>> GetMatrixAsync(int? roleId = null, CancellationToken ct = default);
    Task<bool> SaveRolePermissionsAsync(int roleId, List<int> permissionIds, int? adminUserId = null, CancellationToken ct = default);
}
