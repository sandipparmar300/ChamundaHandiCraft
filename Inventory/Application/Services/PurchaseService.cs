using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Inventory.Domain.IServices;
using Microsoft.Extensions.Logging;

namespace Inventory.Application.Services;

public class PurchaseService : IPurchaseService
{
    private readonly IPurchaseRepository _repository;
    private readonly ILogger<PurchaseService> _logger;

    public PurchaseService(IPurchaseRepository repository, ILogger<PurchaseService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<PurchaseOrderGridItem>>> GetGridAsync(DataTableRequest request, int? supplierId = null, int? warehouseId = null, string? status = null, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, supplierId, warehouseId, status, ct);
            return ResponseViewModel<PagedResult<PurchaseOrderGridItem>>.Success(data, "Purchase orders retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving purchase order grid.");
            return ResponseViewModel<PagedResult<PurchaseOrderGridItem>>.Fail("An error occurred while retrieving purchase orders.");
        }
    }

    public async Task<ResponseViewModel<PurchaseOrderDetailViewModel>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetByIdAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<PurchaseOrderDetailViewModel>.Fail("Purchase order not found.");
            }
            return ResponseViewModel<PurchaseOrderDetailViewModel>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving purchase order ID {Id}.", id);
            return ResponseViewModel<PurchaseOrderDetailViewModel>.Fail("An error occurred while retrieving purchase order.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(PurchaseOrderSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var newId = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<int>.Success(newId, "Purchase order saved successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<int>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving purchase order.");
            return ResponseViewModel<int>.Fail("An unexpected error occurred while saving purchase order.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Purchase order deleted successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting purchase order ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An error occurred while deleting purchase order.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(int id, string status, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.UpdateStatusAsync(id, status, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Purchase order status updated successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating status for purchase order ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An error occurred while updating status.");
        }
    }

    public async Task<ResponseViewModel<bool>> ReceiveStockAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.ReceiveStockAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Purchase order stock received and inventory updated successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error receiving stock for purchase order ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An error occurred while receiving purchase order stock.");
        }
    }
}
