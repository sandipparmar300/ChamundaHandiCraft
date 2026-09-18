using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Inventory.Domain.IServices;

public interface IWarehouseRepository
{
    Task<PagedResult<WarehouseGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<WarehouseSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<WarehouseDetailViewModel?> GetDetailAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(WarehouseSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<List<IdNamePair>> GetLookupAsync(CancellationToken ct = default);
}

public interface IWarehouseService
{
    Task<ResponseViewModel<PagedResult<WarehouseGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<ResponseViewModel<WarehouseSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<WarehouseDetailViewModel>> GetDetailAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveAsync(WarehouseSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<List<IdNamePair>>> GetLookupAsync(CancellationToken ct = default);
}
