using Catalog.Domain.IServices;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.Extensions.Logging;

namespace Catalog.Application.Services;

public class ArtisanService : IArtisanService
{
    private readonly IArtisanRepository _repository;
    private readonly ILogger<ArtisanService> _logger;

    public ArtisanService(IArtisanRepository repository, ILogger<ArtisanService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<ArtisanGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, ct);
            return ResponseViewModel<PagedResult<ArtisanGridItem>>.Success(data, "Artisans retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving artisan grid.");
            return ResponseViewModel<PagedResult<ArtisanGridItem>>.Fail("An error occurred while retrieving artisans.");
        }
    }

    public async Task<ResponseViewModel<ArtisanSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var artisan = await _repository.GetByIdAsync(id, ct);
            if (artisan == null)
            {
                return ResponseViewModel<ArtisanSaveRequest>.Fail("Artisan not found.", ApiStatusCode.NotFound);
            }
            return ResponseViewModel<ArtisanSaveRequest>.Success(artisan);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching artisan ID {ArtisanId}", id);
            return ResponseViewModel<ArtisanSaveRequest>.Fail("An error occurred while fetching the artisan.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(ArtisanSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.Name))
            {
                return ResponseViewModel<int>.Fail("Artisan name is required.", ApiStatusCode.ValidationFailed);
            }
            if (string.IsNullOrWhiteSpace(request.Craft))
            {
                return ResponseViewModel<int>.Fail("Craft technique is required.", ApiStatusCode.ValidationFailed);
            }
            if (string.IsNullOrWhiteSpace(request.Cluster))
            {
                return ResponseViewModel<int>.Fail("Cluster/region is required.", ApiStatusCode.ValidationFailed);
            }

            int id = await _repository.SaveAsync(request, adminUserId, ct);
            string message = request.Id > 0 ? "Artisan profile updated successfully." : "Artisan profile created successfully.";
            return ResponseViewModel<int>.Success(id, message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving artisan: {ArtisanName}", request.Name);
            return ResponseViewModel<int>.Fail("An error occurred while saving the artisan.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            bool success = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, "Artisan deleted successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting artisan ID {ArtisanId}", id);
            return ResponseViewModel<bool>.Fail("An error occurred while deleting the artisan.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            bool isActive = request.Status > 0;
            bool success = await _repository.UpdateStatusAsync(request.Id, isActive, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, $"Artisan status changed to {(isActive ? "Active" : "Inactive")}.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating artisan status for ID {ArtisanId}", request.Id);
            return ResponseViewModel<bool>.Fail("An error occurred while updating the artisan status.");
        }
    }

    public async Task<ResponseViewModel<List<IdNamePair>>> GetLookupAsync(CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetLookupAsync(ct);
            return ResponseViewModel<List<IdNamePair>>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving artisan lookups.");
            return ResponseViewModel<List<IdNamePair>>.Fail("An error occurred while fetching artisan options.");
        }
    }
}
