using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Inventory.Domain.IServices;

public interface IPurchaseRepository
{
    Task<PagedResult<PurchaseOrderGridItem>> GetGridAsync(DataTableRequest request, int? supplierId = null, int? warehouseId = null, string? status = null, CancellationToken ct = default);
    Task<PurchaseOrderDetailViewModel?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(PurchaseOrderSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(int id, string status, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> ReceiveStockAsync(int id, int? adminUserId = null, CancellationToken ct = default);
}

public interface IPurchaseService
{
    Task<ResponseViewModel<PagedResult<PurchaseOrderGridItem>>> GetGridAsync(DataTableRequest request, int? supplierId = null, int? warehouseId = null, string? status = null, CancellationToken ct = default);
    Task<ResponseViewModel<PurchaseOrderDetailViewModel>> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveAsync(PurchaseOrderSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> UpdateStatusAsync(int id, string status, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> ReceiveStockAsync(int id, int? adminUserId = null, CancellationToken ct = default);
}
