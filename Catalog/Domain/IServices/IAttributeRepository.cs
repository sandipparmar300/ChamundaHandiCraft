using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Catalog.Domain.IServices;

public interface IAttributeRepository
{
    Task<PagedResult<AttributeGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<AttributeSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(AttributeSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(int id, bool isActive, int? adminUserId = null, CancellationToken ct = default);
    Task<List<IdNamePair>> GetLookupAsync(CancellationToken ct = default);
}
