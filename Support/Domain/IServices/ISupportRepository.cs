using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Support.Domain.IServices;

public interface ISupportRepository
{
    Task<PagedResult<SupportTicketGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<SupportTicketGridItem?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(SupportTicketGridItem request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
}
