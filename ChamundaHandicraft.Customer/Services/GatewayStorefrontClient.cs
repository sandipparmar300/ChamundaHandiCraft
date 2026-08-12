using ChamundaHandicraft.Helper.ApiService;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace ChamundaHandicraft.Customer.Services;

/// <summary>
/// The production implementation: every method is one call to a constant from
/// <see cref="ApiEndPoint"/> through the gateway. No URL is built by hand and no
/// response is unwrapped twice.
///
/// This class is complete and correct against the contract; what it needs to start
/// returning data is the matching controller on <c>ChamundaHandicraft.API</c>. Until
/// those exist, <c>Program.cs</c> registers <see cref="DemoStorefrontClient"/> instead
/// and every call here is exercised only by the integration tests.
/// </summary>
public class GatewayStorefrontClient : IStorefrontClient
{
    private readonly IApiService _api;

    public GatewayStorefrontClient(IApiService api) => _api = api;

    public async Task<ShellViewModel> GetShellAsync(CancellationToken ct = default)
    {
        var response = await _api.GetAsync<ShellViewModel>(ApiEndPoint.Customer.ShopDashboard, null, ct);

        // The shell renders on every page, so a gateway hiccup must degrade to an
        // anonymous header rather than take the whole page down.
        return response.IsSuccess && response.Data is not null ? response.Data : new ShellViewModel();
    }

    public async Task<StorefrontConfigViewModel> GetConfigAsync(CancellationToken ct = default)
    {
        var response = await _api.GetAsync<StorefrontConfigViewModel>(ApiEndPoint.Settings.ShopStorefrontConfig, null, ct);
        return response.IsSuccess && response.Data is not null ? response.Data : new StorefrontConfigViewModel();
    }

    public Task<ResponseViewModel<ProductListingViewModel>> GetListingAsync(
        string? categorySlug, string? subCategorySlug, PagedRequest paging, string? sort, CancellationToken ct = default) =>
        _api.GetAsync<ProductListingViewModel>(ApiEndPoint.Product.ShopList, new Dictionary<string, string?>
        {
            ["category"] = categorySlug,
            ["subCategory"] = subCategorySlug,
            ["page"] = paging.Page.ToString(),
            ["pageSize"] = paging.PageSize.ToString(),
            ["sort"] = sort
        }, ct);

    public Task<ResponseViewModel<ProductListingViewModel>> SearchAsync(
        string? query, PagedRequest paging, string? sort, CancellationToken ct = default) =>
        _api.GetAsync<ProductListingViewModel>(ApiEndPoint.Search.ShopQuery, new Dictionary<string, string?>
        {
            ["q"] = query,
            ["page"] = paging.Page.ToString(),
            ["pageSize"] = paging.PageSize.ToString(),
            ["sort"] = sort
        }, ct);

    public Task<ResponseViewModel<ProductDetailViewModel>> GetProductAsync(string slug, CancellationToken ct = default) =>
        _api.GetAsync<ProductDetailViewModel>(ApiEndPoint.Product.ShopDetail,
            new Dictionary<string, string?> { ["slug"] = slug }, ct);

    public Task<ResponseViewModel<List<ProductCardViewModel>>> GetRailAsync(
        string railKey, int count, string? contextSlug = null, CancellationToken ct = default)
    {
        // One endpoint per rail semantic, so the API can rank each differently rather
        // than the storefront asking for "some products" and hoping.
        var endpoint = railKey switch
        {
            "related" => ApiEndPoint.Product.ShopRelated,
            "complete-the-look" => ApiEndPoint.Product.ShopCompleteTheLook,
            "recently-viewed" => ApiEndPoint.Product.ShopRecentlyViewed,
            "recommended" => ApiEndPoint.Product.ShopRecommended,
            _ => ApiEndPoint.Product.ShopList
        };

        return _api.GetAsync<List<ProductCardViewModel>>(endpoint, new Dictionary<string, string?>
        {
            ["rail"] = railKey,
            ["count"] = count.ToString(),
            ["slug"] = contextSlug
        }, ct);
    }

    public Task<ResponseViewModel<List<CategoryViewModel>>> GetCategoriesAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<CategoryViewModel>>(ApiEndPoint.Category.ShopFeatured, null, ct);

    public Task<ResponseViewModel<List<BannerViewModel>>> GetBannersAsync(string placement, CancellationToken ct = default) =>
        _api.GetAsync<List<BannerViewModel>>(ApiEndPoint.Banner.ShopByPlacement,
            new Dictionary<string, string?> { ["placement"] = placement }, ct);

    public Task<ResponseViewModel<CartViewModel>> GetCartAsync(CancellationToken ct = default) =>
        _api.GetAsync<CartViewModel>(ApiEndPoint.Cart.ShopGet, null, ct);

    public Task<ResponseViewModel<CheckoutViewModel>> GetCheckoutAsync(bool guest, CancellationToken ct = default) =>
        _api.GetAsync<CheckoutViewModel>(ApiEndPoint.Order.ShopCheckoutInit,
            new Dictionary<string, string?> { ["guest"] = guest.ToString() }, ct);

    public Task<ResponseViewModel<List<OrderSummaryCardViewModel>>> GetOrdersAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<OrderSummaryCardViewModel>>(ApiEndPoint.Order.ShopMyOrders, null, ct);

    public Task<ResponseViewModel<OrderDetailViewModel>> GetOrderAsync(string orderNumber, CancellationToken ct = default) =>
        _api.GetAsync<OrderDetailViewModel>(ApiEndPoint.Order.ShopOrderDetail,
            new Dictionary<string, string?> { ["orderNumber"] = orderNumber }, ct);

    public Task<ResponseViewModel<List<OrderTimelineStep>>> GetTrackingAsync(string orderNumber, CancellationToken ct = default) =>
        _api.GetAsync<List<OrderTimelineStep>>(ApiEndPoint.Shipping.ShopTrack,
            new Dictionary<string, string?> { ["orderNumber"] = orderNumber }, ct);

    public Task<ResponseViewModel<List<AddressViewModel>>> GetAddressesAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<AddressViewModel>>(ApiEndPoint.Customer.ShopAddressList, null, ct);

    public Task<ResponseViewModel<List<ProductCardViewModel>>> GetWishlistAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<ProductCardViewModel>>(ApiEndPoint.Wishlist.ShopGet, null, ct);

    public Task<ResponseViewModel<List<CouponViewModel>>> GetMyCouponsAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<CouponViewModel>>(ApiEndPoint.Promotion.ShopMyCoupons, null, ct);

    public Task<ResponseViewModel<RewardBalanceViewModel>> GetRewardsAsync(CancellationToken ct = default) =>
        _api.GetAsync<RewardBalanceViewModel>(ApiEndPoint.Rewards.ShopBalance, null, ct);

    public Task<ResponseViewModel<List<NotificationViewModel>>> GetNotificationsAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<NotificationViewModel>>(ApiEndPoint.Notification.ShopList, null, ct);

    public Task<ResponseViewModel<List<ArticleCardViewModel>>> GetArticlesAsync(int count, CancellationToken ct = default) =>
        _api.GetAsync<List<ArticleCardViewModel>>(ApiEndPoint.Content.ShopBlogList,
            new Dictionary<string, string?> { ["count"] = count.ToString() }, ct);

    public Task<ResponseViewModel<ArticleCardViewModel>> GetArticleAsync(string slug, CancellationToken ct = default) =>
        _api.GetAsync<ArticleCardViewModel>(ApiEndPoint.Content.ShopBlogDetail,
            new Dictionary<string, string?> { ["slug"] = slug }, ct);

    public Task<ResponseViewModel<StaticPageViewModel>> GetPageAsync(string slug, CancellationToken ct = default) =>
        _api.GetAsync<StaticPageViewModel>(ApiEndPoint.Content.ShopPage,
            new Dictionary<string, string?> { ["slug"] = slug }, ct);

    public Task<ResponseViewModel<List<ArtisanSummary>>> GetArtisansAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<ArtisanSummary>>(ApiEndPoint.Content.ShopArtisanList, null, ct);

    public Task<ResponseViewModel<ArtisanSummary>> GetArtisanAsync(string slug, CancellationToken ct = default) =>
        _api.GetAsync<ArtisanSummary>(ApiEndPoint.Content.ShopArtisanDetail,
            new Dictionary<string, string?> { ["slug"] = slug }, ct);

    public Task<ResponseViewModel<ReviewSummaryViewModel>> GetProductReviewsAsync(string slug, CancellationToken ct = default) =>
        _api.GetAsync<ReviewSummaryViewModel>(ApiEndPoint.Review.ShopSummary,
            new Dictionary<string, string?> { ["slug"] = slug }, ct);

    public Task<ResponseViewModel<List<FaqItem>>> GetFaqsAsync(string topic, CancellationToken ct = default) =>
        _api.GetAsync<List<FaqItem>>(ApiEndPoint.Content.ShopFaqs,
            new Dictionary<string, string?> { ["topic"] = topic }, ct);
}
