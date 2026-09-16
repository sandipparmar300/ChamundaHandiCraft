using Catalog.Domain.IServices;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.Extensions.Logging;

namespace Catalog.Application.Services;

public class BrandService : IBrandService
{
    private readonly IBrandRepository _repository;
    private readonly ILogger<BrandService> _logger;

    public BrandService(IBrandRepository repository, ILogger<BrandService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<BrandGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, ct);
            return ResponseViewModel<PagedResult<BrandGridItem>>.Success(data, "Brands retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving brand grid.");
            return ResponseViewModel<PagedResult<BrandGridItem>>.Fail("An error occurred while retrieving brands.");
        }
    }

    public async Task<ResponseViewModel<BrandSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var brand = await _repository.GetByIdAsync(id, ct);
            if (brand == null)
            {
                return ResponseViewModel<BrandSaveRequest>.Fail("Brand not found.", ApiStatusCode.NotFound);
            }
            return ResponseViewModel<BrandSaveRequest>.Success(brand);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching brand ID {BrandId}", id);
            return ResponseViewModel<BrandSaveRequest>.Fail("An error occurred while fetching the brand.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(BrandSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.BrandName))
            {
                return ResponseViewModel<int>.Fail("Brand name is required.", ApiStatusCode.ValidationFailed);
            }

            int id = await _repository.SaveAsync(request, adminUserId, ct);
            string message = request.Id > 0 ? "Brand updated successfully." : "Brand created successfully.";
            return ResponseViewModel<int>.Success(id, message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving brand: {BrandName}", request.BrandName);
            return ResponseViewModel<int>.Fail("An error occurred while saving the brand.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            bool success = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, "Brand deleted successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting brand ID {BrandId}", id);
            return ResponseViewModel<bool>.Fail("An error occurred while deleting the brand.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            bool isActive = request.Status > 0;
            bool success = await _repository.UpdateStatusAsync(request.Id, isActive, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, $"Brand status changed to {(isActive ? "Active" : "Inactive")}.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating brand status for ID {BrandId}", request.Id);
            return ResponseViewModel<bool>.Fail("An error occurred while updating the brand status.");
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
            _logger.LogError(ex, "Error retrieving brand lookups.");
            return ResponseViewModel<List<IdNamePair>>.Fail("An error occurred while fetching brand options.");
        }
    }
}
