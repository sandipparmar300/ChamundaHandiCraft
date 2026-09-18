using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Inventory.Domain.IServices;

public interface ISupplierRepository
{
    Task<PagedResult<SupplierGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<SupplierSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<SupplierDetailViewModel?> GetDetailAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(SupplierSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<List<IdNamePair>> GetLookupAsync(CancellationToken ct = default);
}

public interface ISupplierService
{
    Task<ResponseViewModel<PagedResult<SupplierGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<ResponseViewModel<SupplierSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<SupplierDetailViewModel>> GetDetailAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveAsync(SupplierSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<List<IdNamePair>>> GetLookupAsync(CancellationToken ct = default);
}
