using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Categories.Domain.IServices;

public interface ICategoryService
{
    Task<ResponseViewModel<List<CategoryViewModel>>> GetTreeAsync(CancellationToken ct = default);
    Task<ResponseViewModel<PagedResult<CategoryGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<ResponseViewModel<CategorySaveRequest>> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveAsync(CategorySaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<List<IdNamePair>>> GetLookupAsync(CancellationToken ct = default);
}
