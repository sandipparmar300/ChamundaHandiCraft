using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Inventory.Domain.IServices;

public interface IStockTakeService
{
    Task<ResponseViewModel<PagedResult<StockTakeGridItem>>> GetGridAsync(DataTableRequest request, int? warehouseId = null, string? status = null, CancellationToken ct = default);
    Task<ResponseViewModel<StockTakeGridItem>> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveAsync(StockTakeGridItem request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
}
