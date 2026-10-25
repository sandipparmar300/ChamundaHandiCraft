using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Promotions.Domain.IServices;

public interface IOfferService
{
    Task<ResponseViewModel<PagedResult<OfferGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<ResponseViewModel<FlashSaleSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<OfferGridItem>> GetDetailAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveAsync(FlashSaleSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<FlashSaleOfferViewModel?>> GetFlashSaleOfferAsync(CancellationToken ct = default);
}
