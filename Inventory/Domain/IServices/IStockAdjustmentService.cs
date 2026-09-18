using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Inventory.Domain.IServices;

public interface IStockAdjustmentRepository
{
    Task<PagedResult<StockAdjustmentGridItem>> GetGridAsync(DataTableRequest request, int? warehouseId = null, int? reasonCodeId = null, CancellationToken ct = default);
    Task<StockAdjustmentDetailViewModel?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(StockAdjustmentSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
}

public interface IStockAdjustmentService
{
    Task<ResponseViewModel<PagedResult<StockAdjustmentGridItem>>> GetGridAsync(DataTableRequest request, int? warehouseId = null, int? reasonCodeId = null, CancellationToken ct = default);
    Task<ResponseViewModel<StockAdjustmentDetailViewModel>> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveAsync(StockAdjustmentSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
}
