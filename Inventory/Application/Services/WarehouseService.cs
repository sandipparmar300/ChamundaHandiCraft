using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Inventory.Domain.IServices;
using Microsoft.Extensions.Logging;

namespace Inventory.Application.Services;

public class WarehouseService : IWarehouseService
{
    private readonly IWarehouseRepository _repository;
    private readonly ILogger<WarehouseService> _logger;

    public WarehouseService(IWarehouseRepository repository, ILogger<WarehouseService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<WarehouseGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, ct);
            return ResponseViewModel<PagedResult<WarehouseGridItem>>.Success(data, "Warehouses retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving warehouse grid.");
            return ResponseViewModel<PagedResult<WarehouseGridItem>>.Fail("An error occurred while retrieving warehouses.");
        }
    }

    public async Task<ResponseViewModel<WarehouseSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetByIdAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<WarehouseSaveRequest>.Fail("Warehouse not found.");
            }
            return ResponseViewModel<WarehouseSaveRequest>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving warehouse with ID {Id}.", id);
            return ResponseViewModel<WarehouseSaveRequest>.Fail("An error occurred while retrieving warehouse details.");
        }
    }

    public async Task<ResponseViewModel<WarehouseDetailViewModel>> GetDetailAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetDetailAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<WarehouseDetailViewModel>.Fail("Warehouse not found.");
            }
            return ResponseViewModel<WarehouseDetailViewModel>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving warehouse details with ID {Id}.", id);
            return ResponseViewModel<WarehouseDetailViewModel>.Fail("An error occurred while retrieving warehouse details.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(WarehouseSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var newId = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<int>.Success(newId, "Warehouse saved successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<int>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving warehouse.");
            return ResponseViewModel<int>.Fail("An unexpected error occurred while saving warehouse.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Warehouse deleted successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting warehouse ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An error occurred while deleting warehouse.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.UpdateStatusAsync(request, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Warehouse status updated successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating status for warehouse ID {Id}.", request.Id);
            return ResponseViewModel<bool>.Fail("An error occurred while updating status.");
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
            _logger.LogError(ex, "Error retrieving warehouse lookup.");
            return ResponseViewModel<List<IdNamePair>>.Fail("An error occurred while retrieving warehouses.");
        }
    }
}
