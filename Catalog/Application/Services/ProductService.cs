using Catalog.Domain.IServices;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.Extensions.Logging;

namespace Catalog.Application.Services;

public class ProductService : IProductService
{
    private readonly IProductRepository _repository;
    private readonly ILogger<ProductService> _logger;

    public ProductService(IProductRepository repository, ILogger<ProductService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<ProductGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, ct);
            return ResponseViewModel<PagedResult<ProductGridItem>>.Success(data, "Products retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving product grid.");
            return ResponseViewModel<PagedResult<ProductGridItem>>.Fail("An error occurred while retrieving products.");
        }
    }

    public async Task<ResponseViewModel<ProductSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var product = await _repository.GetByIdAsync(id, ct);
            if (product == null)
            {
                return ResponseViewModel<ProductSaveRequest>.Fail("Product not found.", ApiStatusCode.NotFound);
            }
            return ResponseViewModel<ProductSaveRequest>.Success(product);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching product ID {ProductId}", id);
            return ResponseViewModel<ProductSaveRequest>.Fail("An error occurred while fetching the product.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(ProductSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.Name))
            {
                return ResponseViewModel<int>.Fail("Product name is required.", ApiStatusCode.ValidationFailed);
            }
            if (string.IsNullOrWhiteSpace(request.Sku))
            {
                return ResponseViewModel<int>.Fail("SKU is required.", ApiStatusCode.ValidationFailed);
            }
            if (request.CategoryId <= 0)
            {
                return ResponseViewModel<int>.Fail("Please select a valid Category.", ApiStatusCode.ValidationFailed);
            }
            if (request.Price < 0)
            {
                return ResponseViewModel<int>.Fail("Price cannot be negative.", ApiStatusCode.ValidationFailed);
            }
            if (request.Mrp.HasValue && request.Mrp.Value < request.Price)
            {
                return ResponseViewModel<int>.Fail("MRP cannot be lower than the selling price.", ApiStatusCode.ValidationFailed);
            }

            int id = await _repository.SaveAsync(request, adminUserId, ct);
            string message = request.Id > 0 ? "Product updated successfully." : "Product created successfully.";
            return ResponseViewModel<int>.Success(id, message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving product: {ProductName}", request.Name);
            return ResponseViewModel<int>.Fail("An error occurred while saving the product.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            bool success = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, "Product deleted successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting product ID {ProductId}", id);
            return ResponseViewModel<bool>.Fail("An error occurred while deleting the product.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            byte status = (byte)(request.Status > 0 ? 1 : 2); // 1 = Published, 2 = Unpublished
            bool success = await _repository.UpdateStatusAsync(request.Id, status, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, $"Product status updated to {(request.Status > 0 ? "Published" : "Unpublished")}.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating product status for ID {ProductId}", request.Id);
            return ResponseViewModel<bool>.Fail("An error occurred while updating the product status.");
        }
    }

    public async Task<ResponseViewModel<ProductLookupsViewModel>> GetLookupsAsync(CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetLookupsAsync(ct);
            return ResponseViewModel<ProductLookupsViewModel>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving product lookups.");
            return ResponseViewModel<ProductLookupsViewModel>.Fail("An error occurred while fetching product lookups.");
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
            _logger.LogError(ex, "Error retrieving product lookup.");
            return ResponseViewModel<List<IdNamePair>>.Fail("An error occurred while fetching product list.");
        }
    }

    public async Task<ResponseViewModel<List<IdNamePair>>> GetVariantsLookupAsync(int? productId = null, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetVariantsLookupAsync(productId, ct);
            return ResponseViewModel<List<IdNamePair>>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving product variants lookup.");
            return ResponseViewModel<List<IdNamePair>>.Fail("An error occurred while fetching product variants.");
        }
    }
}
