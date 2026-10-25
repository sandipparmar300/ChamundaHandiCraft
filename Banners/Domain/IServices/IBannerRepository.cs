using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Banners.Domain.IServices;

public interface IBannerRepository
{
    Task<PagedResult<BannerViewModel>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<BannerSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<BannerViewModel?> GetDetailAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(BannerSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<List<BannerViewModel>> GetByPlacementAsync(int placement, CancellationToken ct = default);
}
