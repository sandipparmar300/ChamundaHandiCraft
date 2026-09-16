using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Categories.Domain.IServices;

public interface IMenuRepository
{
    Task<PagedResult<MenuGridItem>> GetGridAsync(DataTableRequest request, string? location = null, CancellationToken ct = default);
    Task<MenuGridItem?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(MenuGridItem request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<List<IdNamePair>> GetLookupAsync(string? location = null, CancellationToken ct = default);
}
