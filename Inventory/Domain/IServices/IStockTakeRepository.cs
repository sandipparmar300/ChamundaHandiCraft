using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Inventory.Domain.IServices;

public interface IStockTakeRepository
{
    Task<PagedResult<StockTakeGridItem>> GetGridAsync(DataTableRequest request, int? warehouseId = null, string? status = null, CancellationToken ct = default);
    Task<StockTakeGridItem?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(StockTakeGridItem request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
}
