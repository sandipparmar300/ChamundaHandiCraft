using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Identity.Domain.IServices;

public interface IRoleRepository
{
    Task<PagedResult<RoleGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<RoleSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(RoleSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(int id, bool isActive, int? adminUserId = null, CancellationToken ct = default);
    Task<List<IdNamePair>> GetLookupAsync(CancellationToken ct = default);
}
