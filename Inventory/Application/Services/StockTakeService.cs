using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Inventory.Domain.IServices;
using Microsoft.Extensions.Logging;

namespace Inventory.Application.Services;

public class StockTakeService : IStockTakeService
{
    private readonly IStockTakeRepository _repository;
    private readonly ILogger<StockTakeService> _logger;

    public StockTakeService(IStockTakeRepository repository, ILogger<StockTakeService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<StockTakeGridItem>>> GetGridAsync(DataTableRequest request, int? warehouseId = null, string? status = null, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, warehouseId, status, ct);
            return ResponseViewModel<PagedResult<StockTakeGridItem>>.Success(data, "Stock takes retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving stock takes grid.");
            return ResponseViewModel<PagedResult<StockTakeGridItem>>.Fail("An error occurred while retrieving stock takes.");
        }
    }

    public async Task<ResponseViewModel<StockTakeGridItem>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetByIdAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<StockTakeGridItem>.Fail("Stock take not found.");
            }
            return ResponseViewModel<StockTakeGridItem>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving stock take ID {Id}.", id);
            return ResponseViewModel<StockTakeGridItem>.Fail("An error occurred while retrieving stock take.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(StockTakeGridItem request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var newId = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<int>.Success(newId, "Stock take saved successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<int>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving stock take.");
            return ResponseViewModel<int>.Fail("An unexpected error occurred while saving stock take.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Stock take deleted successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting stock take ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An error occurred while deleting stock take.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.UpdateStatusAsync(request, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Stock take status updated successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating stock take status ID {Id}.", request.Id);
            return ResponseViewModel<bool>.Fail("An error occurred while updating stock take status.");
        }
    }
}
