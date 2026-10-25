using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.Extensions.Logging;
using Support.Domain.IServices;

namespace Support.Application.Services;

public class SupportService : ISupportService
{
    private readonly ISupportRepository _repository;
    private readonly ILogger<SupportService> _logger;

    public SupportService(ISupportRepository repository, ILogger<SupportService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<SupportTicketGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, ct);
            return ResponseViewModel<PagedResult<SupportTicketGridItem>>.Success(data, "Support tickets retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving support tickets grid.");
            return ResponseViewModel<PagedResult<SupportTicketGridItem>>.Fail("An error occurred while retrieving support tickets.");
        }
    }

    public async Task<ResponseViewModel<SupportTicketGridItem>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetByIdAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<SupportTicketGridItem>.Fail("Support ticket not found.");
            }
            return ResponseViewModel<SupportTicketGridItem>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving support ticket with ID {Id}.", id);
            return ResponseViewModel<SupportTicketGridItem>.Fail("An error occurred while retrieving support ticket details.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(SupportTicketGridItem request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var newId = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<int>.Success(newId, "Support ticket saved successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<int>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving support ticket.");
            return ResponseViewModel<int>.Fail("An unexpected error occurred while saving support ticket.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Support ticket deleted successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting support ticket ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An unexpected error occurred while deleting support ticket.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.UpdateStatusAsync(request, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Support ticket status updated successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating status for support ticket ID {Id}.", request.Id);
            return ResponseViewModel<bool>.Fail("An unexpected error occurred while updating support ticket status.");
        }
    }
}
