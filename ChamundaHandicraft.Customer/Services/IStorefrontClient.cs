using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace ChamundaHandicraft.Customer.Services;

/// <summary>
/// Everything the storefront needs from the platform, in one seam.
///
/// Two implementations exist:
///   <see cref="DemoStorefrontClient"/>    design phase — serves <see cref="DemoContent"/>
///   <see cref="GatewayStorefrontClient"/> production   — calls the gateway via IApiService
///
/// Controllers depend on this interface only, so moving the site onto live data is a
/// one-line change in Program.cs rather than a rewrite of twenty-four controllers.
/// Every method returns the envelope, so a controller handles a gateway outage the
/// same way it handles a 404.
/// </summary>
public interface IStorefrontClient
{
    // ---- Shell -------------------------------------------------------------
    Task<ShellViewModel> GetShellAsync(CancellationToken ct = default);
    Task<StorefrontConfigViewModel> GetConfigAsync(CancellationToken ct = default);

    // ---- Catalogue ---------------------------------------------------------
    Task<ResponseViewModel<ProductListingViewModel>> GetListingAsync(
        string? categorySlug, string? subCategorySlug, PagedRequest paging, string? sort, CancellationToken ct = default);

    Task<ResponseViewModel<ProductListingViewModel>> SearchAsync(
        string? query, PagedRequest paging, string? sort, CancellationToken ct = default);

    Task<ResponseViewModel<ProductDetailViewModel>> GetProductAsync(string slug, CancellationToken ct = default);

    Task<ResponseViewModel<List<ProductCardViewModel>>> GetRailAsync(
        string railKey, int count, string? contextSlug = null, CancellationToken ct = default);

    Task<ResponseViewModel<List<CategoryViewModel>>> GetCategoriesAsync(CancellationToken ct = default);
    Task<ResponseViewModel<List<BannerViewModel>>> GetBannersAsync(string placement, CancellationToken ct = default);

    // ---- Cart & checkout ---------------------------------------------------
    Task<ResponseViewModel<CartViewModel>> GetCartAsync(CancellationToken ct = default);
    Task<ResponseViewModel<CheckoutViewModel>> GetCheckoutAsync(bool guest, CancellationToken ct = default);

    // ---- Account -----------------------------------------------------------
    Task<ResponseViewModel<List<OrderSummaryCardViewModel>>> GetOrdersAsync(CancellationToken ct = default);
    Task<ResponseViewModel<OrderDetailViewModel>> GetOrderAsync(string orderNumber, CancellationToken ct = default);
    Task<ResponseViewModel<List<OrderTimelineStep>>> GetTrackingAsync(string orderNumber, CancellationToken ct = default);
    Task<ResponseViewModel<List<AddressViewModel>>> GetAddressesAsync(CancellationToken ct = default);
    Task<ResponseViewModel<List<ProductCardViewModel>>> GetWishlistAsync(CancellationToken ct = default);
    Task<ResponseViewModel<List<CouponViewModel>>> GetMyCouponsAsync(CancellationToken ct = default);
    Task<ResponseViewModel<RewardBalanceViewModel>> GetRewardsAsync(CancellationToken ct = default);
    Task<ResponseViewModel<List<NotificationViewModel>>> GetNotificationsAsync(CancellationToken ct = default);

    // ---- Content -----------------------------------------------------------
    Task<ResponseViewModel<List<ArticleCardViewModel>>> GetArticlesAsync(int count, CancellationToken ct = default);
    Task<ResponseViewModel<ArticleCardViewModel>> GetArticleAsync(string slug, CancellationToken ct = default);
    Task<ResponseViewModel<StaticPageViewModel>> GetPageAsync(string slug, CancellationToken ct = default);
    Task<ResponseViewModel<List<ArtisanSummary>>> GetArtisansAsync(CancellationToken ct = default);
    Task<ResponseViewModel<ArtisanSummary>> GetArtisanAsync(string slug, CancellationToken ct = default);
    Task<ResponseViewModel<ReviewSummaryViewModel>> GetProductReviewsAsync(string slug, CancellationToken ct = default);
    Task<ResponseViewModel<List<FaqItem>>> GetFaqsAsync(string topic, CancellationToken ct = default);
}
