using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Inventory.Domain.IServices;
using Microsoft.Extensions.Logging;

namespace Inventory.Application.Services;

public class StockTransferService : IStockTransferService
{
    private readonly IStockTransferRepository _repository;
    private readonly ILogger<StockTransferService> _logger;

    public StockTransferService(IStockTransferRepository repository, ILogger<StockTransferService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<StockTransferGridItem>>> GetGridAsync(DataTableRequest request, int? fromWarehouseId = null, int? toWarehouseId = null, string? status = null, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, fromWarehouseId, toWarehouseId, status, ct);
            return ResponseViewModel<PagedResult<StockTransferGridItem>>.Success(data, "Stock transfers retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving stock transfer grid.");
            return ResponseViewModel<PagedResult<StockTransferGridItem>>.Fail("An error occurred while retrieving stock transfers.");
        }
    }

    public async Task<ResponseViewModel<StockTransferDetailViewModel>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetByIdAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<StockTransferDetailViewModel>.Fail("Stock transfer not found.");
            }
            return ResponseViewModel<StockTransferDetailViewModel>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving stock transfer ID {Id}.", id);
            return ResponseViewModel<StockTransferDetailViewModel>.Fail("An error occurred while retrieving stock transfer.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(StockTransferSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var newId = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<int>.Success(newId, "Stock transfer saved successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<int>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving stock transfer.");
            return ResponseViewModel<int>.Fail("An unexpected error occurred while saving stock transfer.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(int id, string newStatus, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.UpdateStatusAsync(id, newStatus, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, $"Stock transfer status updated to {newStatus} successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating status for stock transfer ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An error occurred while updating status.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Stock transfer cancelled successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting stock transfer ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An error occurred while deleting stock transfer.");
        }
    }
}
