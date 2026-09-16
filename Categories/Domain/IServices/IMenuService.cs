using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Categories.Domain.IServices;

public interface IMenuService
{
    Task<ResponseViewModel<PagedResult<MenuGridItem>>> GetGridAsync(DataTableRequest request, string? location = null, CancellationToken ct = default);
    Task<ResponseViewModel<MenuGridItem>> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveAsync(MenuGridItem request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<List<IdNamePair>>> GetLookupAsync(string? location = null, CancellationToken ct = default);
}
