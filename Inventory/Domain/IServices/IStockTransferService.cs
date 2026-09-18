using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Inventory.Domain.IServices;

public interface IStockTransferRepository
{
    Task<PagedResult<StockTransferGridItem>> GetGridAsync(DataTableRequest request, int? fromWarehouseId = null, int? toWarehouseId = null, string? status = null, CancellationToken ct = default);
    Task<StockTransferDetailViewModel?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(StockTransferSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(int id, string newStatus, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
}

public interface IStockTransferService
{
    Task<ResponseViewModel<PagedResult<StockTransferGridItem>>> GetGridAsync(DataTableRequest request, int? fromWarehouseId = null, int? toWarehouseId = null, string? status = null, CancellationToken ct = default);
    Task<ResponseViewModel<StockTransferDetailViewModel>> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveAsync(StockTransferSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> UpdateStatusAsync(int id, string newStatus, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
}
