using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Inventory.Domain.IServices;
using Microsoft.Extensions.Logging;

namespace Inventory.Application.Services;

public class InventoryService : IInventoryService
{
    private readonly IInventoryRepository _repository;
    private readonly ILogger<InventoryService> _logger;

    public InventoryService(IInventoryRepository repository, ILogger<InventoryService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<StockGridItem>>> GetGridAsync(DataTableRequest request, int? warehouseId = null, string? stockStatus = null, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, warehouseId, stockStatus, ct);
            return ResponseViewModel<PagedResult<StockGridItem>>.Success(data, "Inventory stock retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inventory grid.");
            return ResponseViewModel<PagedResult<StockGridItem>>.Fail("An error occurred while retrieving inventory stock.");
        }
    }

    public async Task<ResponseViewModel<StockSaveRequest>> GetByIdAsync(long id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetByIdAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<StockSaveRequest>.Fail("Stock record not found.");
            }
            return ResponseViewModel<StockSaveRequest>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving stock record ID {Id}.", id);
            return ResponseViewModel<StockSaveRequest>.Fail("An error occurred while retrieving stock record.");
        }
    }

    public async Task<ResponseViewModel<InventoryDetailViewModel>> GetDetailAsync(long id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetDetailAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<InventoryDetailViewModel>.Fail("Stock record not found.");
            }
            return ResponseViewModel<InventoryDetailViewModel>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving stock detail for ID {Id}.", id);
            return ResponseViewModel<InventoryDetailViewModel>.Fail("An error occurred while retrieving stock details.");
        }
    }

    public async Task<ResponseViewModel<long>> SaveAsync(StockSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var newId = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<long>.Success(newId, "Stock saved successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<long>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving stock record.");
            return ResponseViewModel<long>.Fail("An unexpected error occurred while saving stock record.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(long id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Stock record deleted successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting stock record ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An error occurred while deleting stock record.");
        }
    }

    public async Task<ResponseViewModel<InventoryKpiSummaryViewModel>> GetKpisAsync(CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetKpisAsync(ct);
            return ResponseViewModel<InventoryKpiSummaryViewModel>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inventory KPIs.");
            return ResponseViewModel<InventoryKpiSummaryViewModel>.Fail("An error occurred while retrieving inventory summary KPIs.");
        }
    }

    public async Task<ResponseViewModel<List<InventoryTransactionViewModel>>> GetLedgerAsync(int? productId = null, int? warehouseId = null, int maxRows = 100, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetLedgerAsync(productId, warehouseId, maxRows, ct);
            return ResponseViewModel<List<InventoryTransactionViewModel>>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inventory transaction ledger.");
            return ResponseViewModel<List<InventoryTransactionViewModel>>.Fail("An error occurred while retrieving transaction ledger.");
        }
    }
}
