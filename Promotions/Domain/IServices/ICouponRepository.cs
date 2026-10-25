using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Promotions.Domain.IServices;

public interface ICouponRepository
{
    Task<PagedResult<CouponGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<CouponSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<CouponGridItem?> GetDetailAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(CouponSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
}
