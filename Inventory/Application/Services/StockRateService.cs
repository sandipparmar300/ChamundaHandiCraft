using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Inventory.Domain.IServices;
using Microsoft.Extensions.Logging;

namespace Inventory.Application.Services;

public class StockRateService : IStockRateService
{
    private readonly IStockRateRepository _repository;
    private readonly ILogger<StockRateService> _logger;

    public StockRateService(IStockRateRepository repository, ILogger<StockRateService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<StockRateGridItem>>> GetGridAsync(DataTableRequest request, int? warehouseId = null, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, warehouseId, ct);
            return ResponseViewModel<PagedResult<StockRateGridItem>>.Success(data, "Stock rates retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving stock rate grid.");
            return ResponseViewModel<PagedResult<StockRateGridItem>>.Fail("An error occurred while retrieving stock rates.");
        }
    }

    public async Task<ResponseViewModel<StockRateDetailViewModel>> GetByIdAsync(int productId, int? variantId = null, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetByIdAsync(productId, variantId, ct);
            if (data == null)
            {
                return ResponseViewModel<StockRateDetailViewModel>.Fail("Product stock rate not found.");
            }
            return ResponseViewModel<StockRateDetailViewModel>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving stock rate for Product {ProductId}, Variant {VariantId}.", productId, variantId);
            return ResponseViewModel<StockRateDetailViewModel>.Fail("An error occurred while retrieving stock rate details.");
        }
    }

    public async Task<ResponseViewModel<bool>> SaveAsync(StockRateSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Stock rate updated successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving stock rate.");
            return ResponseViewModel<bool>.Fail("An error occurred while updating stock rate.");
        }
    }
}
