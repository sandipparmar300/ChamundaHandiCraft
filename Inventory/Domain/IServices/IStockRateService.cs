using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Inventory.Domain.IServices;

public interface IStockRateRepository
{
    Task<PagedResult<StockRateGridItem>> GetGridAsync(DataTableRequest request, int? warehouseId = null, CancellationToken ct = default);
    Task<StockRateDetailViewModel?> GetByIdAsync(int productId, int? variantId = null, CancellationToken ct = default);
    Task<bool> SaveAsync(StockRateSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
}

public interface IStockRateService
{
    Task<ResponseViewModel<PagedResult<StockRateGridItem>>> GetGridAsync(DataTableRequest request, int? warehouseId = null, CancellationToken ct = default);
    Task<ResponseViewModel<StockRateDetailViewModel>> GetByIdAsync(int productId, int? variantId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> SaveAsync(StockRateSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
}
