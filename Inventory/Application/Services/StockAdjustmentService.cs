using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Inventory.Domain.IServices;
using Microsoft.Extensions.Logging;

namespace Inventory.Application.Services;

public class StockAdjustmentService : IStockAdjustmentService
{
    private readonly IStockAdjustmentRepository _repository;
    private readonly ILogger<StockAdjustmentService> _logger;

    public StockAdjustmentService(IStockAdjustmentRepository repository, ILogger<StockAdjustmentService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<StockAdjustmentGridItem>>> GetGridAsync(DataTableRequest request, int? warehouseId = null, int? reasonCodeId = null, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, warehouseId, reasonCodeId, ct);
            return ResponseViewModel<PagedResult<StockAdjustmentGridItem>>.Success(data, "Stock adjustments retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving stock adjustment grid.");
            return ResponseViewModel<PagedResult<StockAdjustmentGridItem>>.Fail("An error occurred while retrieving stock adjustments.");
        }
    }

    public async Task<ResponseViewModel<StockAdjustmentDetailViewModel>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetByIdAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<StockAdjustmentDetailViewModel>.Fail("Stock adjustment not found.");
            }
            return ResponseViewModel<StockAdjustmentDetailViewModel>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving stock adjustment ID {Id}.", id);
            return ResponseViewModel<StockAdjustmentDetailViewModel>.Fail("An error occurred while retrieving stock adjustment.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(StockAdjustmentSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var newId = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<int>.Success(newId, "Stock adjustment posted and inventory reconciled successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<int>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving stock adjustment.");
            return ResponseViewModel<int>.Fail("An unexpected error occurred while saving stock adjustment.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Stock adjustment deleted successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting stock adjustment ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An error occurred while deleting stock adjustment.");
        }
    }
}
