using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Catalog.Application.Services;

public interface IProductService
{
    Task<ResponseViewModel<PagedResult<ProductGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<ResponseViewModel<ProductSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveAsync(ProductSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<ProductLookupsViewModel>> GetLookupsAsync(CancellationToken ct = default);
}
