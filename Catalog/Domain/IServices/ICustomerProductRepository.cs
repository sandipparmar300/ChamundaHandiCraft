using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Catalog.Domain.IServices;

/// <summary>
/// Repository contract for Customer Storefront Product operations.
/// </summary>
public interface ICustomerProductRepository
{
    Task<ProductListingViewModel> GetListingAsync(
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
        CancellationToken ct = default);

    Task<ProductDetailViewModel?> GetDetailAsync(string slug, CancellationToken ct = default);

    Task<List<ProductCardViewModel>> GetRailAsync(string railKey, string? contextSlug, int count, CancellationToken ct = default);

    Task<ProductSearchResultViewModel> SearchAsync(string query, int limit, CancellationToken ct = default);
}
