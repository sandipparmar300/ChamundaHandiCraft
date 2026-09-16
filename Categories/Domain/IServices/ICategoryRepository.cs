using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Categories.Domain.IServices;

public interface ICategoryRepository
{
    Task<List<CategoryViewModel>> GetTreeAsync(CancellationToken ct = default);
    Task<PagedResult<CategoryGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<CategorySaveRequest?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(CategorySaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<List<IdNamePair>> GetLookupAsync(CancellationToken ct = default);
}
