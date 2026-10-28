using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Catalog.Application.Services;

public interface ICustomerProductService
{
    Task<ResponseViewModel<ProductListingViewModel>> GetListingAsync(
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

    Task<ResponseViewModel<ProductDetailViewModel>> GetDetailAsync(string slug, CancellationToken ct = default);

    Task<ResponseViewModel<List<ProductCardViewModel>>> GetRailAsync(string railKey, string? contextSlug, int count, CancellationToken ct = default);

    Task<ResponseViewModel<ProductSearchResultViewModel>> SearchAsync(string query, int limit, CancellationToken ct = default);
}
