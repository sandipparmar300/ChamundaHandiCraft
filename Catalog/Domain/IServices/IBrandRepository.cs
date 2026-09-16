using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Catalog.Domain.IServices;

public interface IBrandRepository
{
    Task<PagedResult<BrandGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<BrandSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(BrandSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(int id, bool isActive, int? adminUserId = null, CancellationToken ct = default);
    Task<List<IdNamePair>> GetLookupAsync(CancellationToken ct = default);
}
