using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Inventory.Domain.IServices;

public interface IInventoryRepository
{
    Task<PagedResult<StockGridItem>> GetGridAsync(DataTableRequest request, int? warehouseId = null, string? stockStatus = null, CancellationToken ct = default);
    Task<StockSaveRequest?> GetByIdAsync(long id, CancellationToken ct = default);
    Task<InventoryDetailViewModel?> GetDetailAsync(long id, CancellationToken ct = default);
    Task<long> SaveAsync(StockSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(long id, int? adminUserId = null, CancellationToken ct = default);
    Task<InventoryKpiSummaryViewModel> GetKpisAsync(CancellationToken ct = default);
    Task<List<InventoryTransactionViewModel>> GetLedgerAsync(int? productId = null, int? warehouseId = null, int maxRows = 100, CancellationToken ct = default);
}

public interface IInventoryService
{
    Task<ResponseViewModel<PagedResult<StockGridItem>>> GetGridAsync(DataTableRequest request, int? warehouseId = null, string? stockStatus = null, CancellationToken ct = default);
    Task<ResponseViewModel<StockSaveRequest>> GetByIdAsync(long id, CancellationToken ct = default);
    Task<ResponseViewModel<InventoryDetailViewModel>> GetDetailAsync(long id, CancellationToken ct = default);
    Task<ResponseViewModel<long>> SaveAsync(StockSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(long id, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<InventoryKpiSummaryViewModel>> GetKpisAsync(CancellationToken ct = default);
    Task<ResponseViewModel<List<InventoryTransactionViewModel>>> GetLedgerAsync(int? productId = null, int? warehouseId = null, int maxRows = 100, CancellationToken ct = default);
}
