using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.Extensions.Logging;
using Promotions.Domain.IServices;

namespace Promotions.Application.Services;

public class OfferService : IOfferService
{
    private readonly IOfferRepository _repository;
    private readonly ILogger<OfferService> _logger;

    public OfferService(IOfferRepository repository, ILogger<OfferService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<OfferGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, ct);
            return ResponseViewModel<PagedResult<OfferGridItem>>.Success(data, "Offers retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving offer grid.");
            return ResponseViewModel<PagedResult<OfferGridItem>>.Fail("An error occurred while retrieving offers.");
        }
    }

    public async Task<ResponseViewModel<FlashSaleSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetByIdAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<FlashSaleSaveRequest>.Fail("Offer not found.");
            }
            return ResponseViewModel<FlashSaleSaveRequest>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving offer with ID {Id}.", id);
            return ResponseViewModel<FlashSaleSaveRequest>.Fail("An error occurred while retrieving offer details.");
        }
    }

    public async Task<ResponseViewModel<OfferGridItem>> GetDetailAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetDetailAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<OfferGridItem>.Fail("Offer not found.");
            }
            return ResponseViewModel<OfferGridItem>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving offer details with ID {Id}.", id);
            return ResponseViewModel<OfferGridItem>.Fail("An error occurred while retrieving offer details.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(FlashSaleSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var newId = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<int>.Success(newId, "Offer saved successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<int>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving offer.");
            return ResponseViewModel<int>.Fail("An unexpected error occurred while saving offer.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Offer deleted successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting offer ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An unexpected error occurred while deleting offer.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.UpdateStatusAsync(request, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Offer status updated successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating status for offer ID {Id}.", request.Id);
            return ResponseViewModel<bool>.Fail("An unexpected error occurred while updating offer status.");
        }
    }

    public async Task<ResponseViewModel<FlashSaleOfferViewModel?>> GetFlashSaleOfferAsync(CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetFlashSaleOfferAsync(ct);
            return ResponseViewModel<FlashSaleOfferViewModel?>.Success(data, "Flash sale offer retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving flash sale offer.");
            return ResponseViewModel<FlashSaleOfferViewModel?>.Fail("An error occurred while retrieving flash sale offer.");
        }
    }
}
