using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Promotions.Domain.IServices;

public interface IOfferRepository
{
    Task<PagedResult<OfferGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<FlashSaleSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<OfferGridItem?> GetDetailAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(FlashSaleSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<FlashSaleOfferViewModel?> GetFlashSaleOfferAsync(CancellationToken ct = default);
}
