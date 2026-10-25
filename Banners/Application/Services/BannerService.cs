using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.Extensions.Logging;
using Banners.Domain.IServices;

namespace Banners.Application.Services;

public class BannerService : IBannerService
{
    private readonly IBannerRepository _repository;
    private readonly ILogger<BannerService> _logger;

    public BannerService(IBannerRepository repository, ILogger<BannerService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<BannerViewModel>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, ct);
            return ResponseViewModel<PagedResult<BannerViewModel>>.Success(data, "Banners retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving banner grid.");
            return ResponseViewModel<PagedResult<BannerViewModel>>.Fail("An error occurred while retrieving banners.");
        }
    }

    public async Task<ResponseViewModel<BannerSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetByIdAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<BannerSaveRequest>.Fail("Banner not found.");
            }
            return ResponseViewModel<BannerSaveRequest>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving banner with ID {Id}.", id);
            return ResponseViewModel<BannerSaveRequest>.Fail("An error occurred while retrieving banner details.");
        }
    }

    public async Task<ResponseViewModel<BannerViewModel>> GetDetailAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetDetailAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<BannerViewModel>.Fail("Banner not found.");
            }
            return ResponseViewModel<BannerViewModel>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving banner details with ID {Id}.", id);
            return ResponseViewModel<BannerViewModel>.Fail("An error occurred while retrieving banner details.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(BannerSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var newId = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<int>.Success(newId, "Banner saved successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<int>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving banner.");
            return ResponseViewModel<int>.Fail("An unexpected error occurred while saving banner.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Banner deleted successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting banner ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An unexpected error occurred while deleting banner.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.UpdateStatusAsync(request, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Banner status updated successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating status for banner ID {Id}.", request.Id);
            return ResponseViewModel<bool>.Fail("An unexpected error occurred while updating banner status.");
        }
    }

    public async Task<ResponseViewModel<List<BannerViewModel>>> GetByPlacementAsync(int placement, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetByPlacementAsync(placement, ct);
            return ResponseViewModel<List<BannerViewModel>>.Success(data, "Banners retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving banners for placement {Placement}.", placement);
            return ResponseViewModel<List<BannerViewModel>>.Fail("An error occurred while retrieving banners.");
        }
    }
}
