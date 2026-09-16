using Catalog.Domain.IServices;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.Extensions.Logging;

namespace Catalog.Application.Services;

public class AttributeService : IAttributeService
{
    private readonly IAttributeRepository _repository;
    private readonly ILogger<AttributeService> _logger;

    public AttributeService(IAttributeRepository repository, ILogger<AttributeService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<AttributeGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, ct);
            return ResponseViewModel<PagedResult<AttributeGridItem>>.Success(data, "Attributes retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving attribute grid.");
            return ResponseViewModel<PagedResult<AttributeGridItem>>.Fail("An error occurred while retrieving attributes.");
        }
    }

    public async Task<ResponseViewModel<AttributeSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var attribute = await _repository.GetByIdAsync(id, ct);
            if (attribute == null)
            {
                return ResponseViewModel<AttributeSaveRequest>.Fail("Attribute not found.", ApiStatusCode.NotFound);
            }
            return ResponseViewModel<AttributeSaveRequest>.Success(attribute);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching attribute ID {AttributeId}", id);
            return ResponseViewModel<AttributeSaveRequest>.Fail("An error occurred while fetching the attribute.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(AttributeSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.AttributeName))
            {
                return ResponseViewModel<int>.Fail("Attribute name is required.", ApiStatusCode.ValidationFailed);
            }

            int id = await _repository.SaveAsync(request, adminUserId, ct);
            string message = request.Id > 0 ? "Attribute updated successfully." : "Attribute created successfully.";
            return ResponseViewModel<int>.Success(id, message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving attribute: {AttributeName}", request.AttributeName);
            return ResponseViewModel<int>.Fail("An error occurred while saving the attribute.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            bool success = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, "Attribute deleted successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting attribute ID {AttributeId}", id);
            return ResponseViewModel<bool>.Fail("An error occurred while deleting the attribute.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            bool isActive = request.Status > 0;
            bool success = await _repository.UpdateStatusAsync(request.Id, isActive, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, $"Attribute status changed to {(isActive ? "Active" : "Inactive")}.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating attribute status for ID {AttributeId}", request.Id);
            return ResponseViewModel<bool>.Fail("An error occurred while updating the attribute status.");
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
            _logger.LogError(ex, "Error retrieving attribute lookups.");
            return ResponseViewModel<List<IdNamePair>>.Fail("An error occurred while fetching attribute options.");
        }
    }
}
