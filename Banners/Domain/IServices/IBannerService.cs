using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Banners.Domain.IServices;

public interface IBannerService
{
    Task<ResponseViewModel<PagedResult<BannerViewModel>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<ResponseViewModel<BannerSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<BannerViewModel>> GetDetailAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveAsync(BannerSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<List<BannerViewModel>>> GetByPlacementAsync(int placement, CancellationToken ct = default);
}
