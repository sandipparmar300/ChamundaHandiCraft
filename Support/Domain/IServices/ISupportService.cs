using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Support.Domain.IServices;

public interface ISupportService
{
    Task<ResponseViewModel<PagedResult<SupportTicketGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<ResponseViewModel<SupportTicketGridItem>> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveAsync(SupportTicketGridItem request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
}
