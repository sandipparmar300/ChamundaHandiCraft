using Catalog.Domain.IServices;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Catalog.Application.Services;

public class CustomerProductService : ICustomerProductService
{
    private readonly ICustomerProductRepository _repository;

    public CustomerProductService(ICustomerProductRepository repository)
    {
        _repository = repository;
    }

    public async Task<ResponseViewModel<ProductListingViewModel>> GetListingAsync(
        string? categorySlug,
        string? subCategorySlug,
        string? search,
        decimal? minPrice,
        decimal? maxPrice,
        string? material,
        string? craft,
        bool? inStockOnly,
        int? rating,
        string? sort,
        int page,
        int pageSize,
        CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.GetListingAsync(
                categorySlug,
                subCategorySlug,
                search,
                minPrice,
                maxPrice,
                material,
                craft,
                inStockOnly,
                rating,
                sort,
                page,
                pageSize,
                ct);

            return ResponseViewModel<ProductListingViewModel>.Success(result, "Products retrieved successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<ProductListingViewModel>.Fail($"Error fetching product listing: {ex.Message}");
        }
    }

    public async Task<ResponseViewModel<ProductDetailViewModel>> GetDetailAsync(string slug, CancellationToken ct = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(slug))
            {
                return ResponseViewModel<ProductDetailViewModel>.Fail("Product slug is required.");
            }

            var result = await _repository.GetDetailAsync(slug, ct);
            if (result == null)
            {
                return ResponseViewModel<ProductDetailViewModel>.Fail("Product not found.");
            }

            return ResponseViewModel<ProductDetailViewModel>.Success(result, "Product detail retrieved successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<ProductDetailViewModel>.Fail($"Error fetching product detail: {ex.Message}");
        }
    }

    public async Task<ResponseViewModel<List<ProductCardViewModel>>> GetRailAsync(string railKey, string? contextSlug, int count, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.GetRailAsync(railKey, contextSlug, count, ct);
            return ResponseViewModel<List<ProductCardViewModel>>.Success(result, "Product rail retrieved successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<List<ProductCardViewModel>>.Fail($"Error fetching product rail: {ex.Message}");
        }
    }

    public async Task<ResponseViewModel<ProductSearchResultViewModel>> SearchAsync(string query, int limit, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.SearchAsync(query, limit, ct);
            return ResponseViewModel<ProductSearchResultViewModel>.Success(result, "Search results retrieved successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<ProductSearchResultViewModel>.Fail($"Error executing search: {ex.Message}");
        }
    }
}
