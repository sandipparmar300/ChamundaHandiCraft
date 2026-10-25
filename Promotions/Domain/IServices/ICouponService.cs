using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Promotions.Domain.IServices;

public interface ICouponService
{
    Task<ResponseViewModel<PagedResult<CouponGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<ResponseViewModel<CouponSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<CouponGridItem>> GetDetailAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveAsync(CouponSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
}
