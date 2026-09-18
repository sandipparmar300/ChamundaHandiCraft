using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Inventory.Domain.IServices;
using Microsoft.Extensions.Logging;

namespace Inventory.Application.Services;

public class SupplierService : ISupplierService
{
    private readonly ISupplierRepository _repository;
    private readonly ILogger<SupplierService> _logger;

    public SupplierService(ISupplierRepository repository, ILogger<SupplierService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<SupplierGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, ct);
            return ResponseViewModel<PagedResult<SupplierGridItem>>.Success(data, "Suppliers retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving supplier grid.");
            return ResponseViewModel<PagedResult<SupplierGridItem>>.Fail("An error occurred while retrieving suppliers.");
        }
    }

    public async Task<ResponseViewModel<SupplierSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetByIdAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<SupplierSaveRequest>.Fail("Supplier not found.");
            }
            return ResponseViewModel<SupplierSaveRequest>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving supplier with ID {Id}.", id);
            return ResponseViewModel<SupplierSaveRequest>.Fail("An error occurred while retrieving supplier details.");
        }
    }

    public async Task<ResponseViewModel<SupplierDetailViewModel>> GetDetailAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetDetailAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<SupplierDetailViewModel>.Fail("Supplier not found.");
            }
            return ResponseViewModel<SupplierDetailViewModel>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving supplier details with ID {Id}.", id);
            return ResponseViewModel<SupplierDetailViewModel>.Fail("An error occurred while retrieving supplier details.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(SupplierSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var newId = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<int>.Success(newId, "Supplier saved successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<int>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving supplier.");
            return ResponseViewModel<int>.Fail("An unexpected error occurred while saving supplier.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Supplier deleted successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting supplier ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An error occurred while deleting supplier.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.UpdateStatusAsync(request, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Supplier status updated successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating status for supplier ID {Id}.", request.Id);
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
            _logger.LogError(ex, "Error retrieving supplier lookup.");
            return ResponseViewModel<List<IdNamePair>>.Fail("An error occurred while retrieving suppliers.");
        }
    }
}
