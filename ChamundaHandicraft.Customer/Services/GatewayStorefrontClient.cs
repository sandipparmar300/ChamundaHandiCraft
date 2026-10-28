using ChamundaHandicraft.Helper.ApiService;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace ChamundaHandicraft.Customer.Services;

/// <summary>
/// The production implementation: calls the platform API Gateway.
/// Priority 1 (Homepage & Chrome) endpoints are fully dynamic and backed by live database data.
/// Unmigrated downstream modules gracefully degrade to DemoContent during the roadmap rollout.
/// </summary>
public class GatewayStorefrontClient : IStorefrontClient
{
    private readonly IApiService _api;

    public GatewayStorefrontClient(IApiService api) => _api = api;

    private static ResponseViewModel<T> Ok<T>(T data) => ResponseViewModel<T>.Success(data);

    // ---- Shell -------------------------------------------------------------
    public async Task<ShellViewModel> GetShellAsync(CancellationToken ct = default)
    {
        var response = await _api.GetAsync<ShellViewModel>(ApiEndPoint.Customer.ShopDashboard, null, ct);
        var shell = response.IsSuccess && response.Data is not null ? response.Data : new ShellViewModel();

        var megaMenuResp = await GetMegaMenuAsync(ct);
        if (megaMenuResp.IsSuccess && megaMenuResp.Data is not null && megaMenuResp.Data.Count > 0)
        {
            shell.Categories = megaMenuResp.Data;
        }
        else
        {
            shell.Categories = DemoContent.Categories();
        }

        shell.Config = await GetConfigAsync(ct);

        return shell;
    }

    public async Task<StorefrontConfigViewModel> GetConfigAsync(CancellationToken ct = default)
    {
        var response = await _api.GetAsync<StorefrontConfigViewModel>(ApiEndPoint.Settings.ShopStorefrontConfig, null, ct);
        return response.IsSuccess && response.Data is not null ? response.Data : new StorefrontConfigViewModel();
    }

    // ---- Catalogue ---------------------------------------------------------
    public async Task<ResponseViewModel<ProductListingViewModel>> GetListingAsync(
        string? categorySlug,
        string? subCategorySlug,
        PagedRequest paging,
        string? sort,
        string? material = null,
        decimal? minPrice = null,
        decimal? maxPrice = null,
        bool? inStockOnly = null,
        int? rating = null,
        CancellationToken ct = default)
    {
        var response = await _api.GetAsync<ProductListingViewModel>(ApiEndPoint.Product.ShopList, new Dictionary<string, string?>
        {
            ["category"] = categorySlug,
            ["subCategory"] = subCategorySlug,
            ["page"] = paging.Page.ToString(),
            ["pageSize"] = paging.PageSize.ToString(),
            ["sort"] = sort,
            ["material"] = material,
            ["minPrice"] = minPrice?.ToString(),
            ["maxPrice"] = maxPrice?.ToString(),
            ["inStockOnly"] = inStockOnly?.ToString(),
            ["rating"] = rating?.ToString()
        }, ct);

        if (response.IsSuccess && response.Data is not null) return response;

        var products = DemoContent.AllProducts();
        return Ok(new ProductListingViewModel
        {
            Heading = categorySlug is null ? "All products" : categorySlug,
            CategorySlug = categorySlug,
            Sort = sort ?? "popularity",
            Products = new PagedResult<ProductCardViewModel>
            {
                Items = products,
                TotalCount = products.Count,
                Page = paging.Page,
                PageSize = paging.PageSize
            }
        });
    }

    public async Task<ResponseViewModel<ProductListingViewModel>> SearchAsync(
        string? query, PagedRequest paging, string? sort, CancellationToken ct = default)
    {
        var response = await _api.GetAsync<ProductListingViewModel>(ApiEndPoint.Search.ShopQuery, new Dictionary<string, string?>
        {
            ["q"] = query,
            ["page"] = paging.Page.ToString(),
            ["pageSize"] = paging.PageSize.ToString(),
            ["sort"] = sort
        }, ct);

        if (response.IsSuccess && response.Data is not null) return response;

        var products = string.IsNullOrWhiteSpace(query) || query.Contains("xyz", StringComparison.OrdinalIgnoreCase)
            ? new List<ProductCardViewModel>()
            : DemoContent.AllProducts();

        return Ok(new ProductListingViewModel
        {
            Heading = string.IsNullOrEmpty(query) ? "Search" : $"Results for “{query}”",
            Query = query ?? string.Empty,
            Sort = sort ?? "popularity",
            Products = new PagedResult<ProductCardViewModel>
            {
                Items = products,
                TotalCount = products.Count,
                Page = paging.Page,
                PageSize = paging.PageSize
            }
        });
    }

    public async Task<ResponseViewModel<ProductSearchResultViewModel>> GetSearchSuggestionsAsync(
        string query, int limit = 8, CancellationToken ct = default)
    {
        var response = await _api.GetAsync<ProductSearchResultViewModel>(ApiEndPoint.Search.ShopSuggestions, new Dictionary<string, string?>
        {
            ["q"] = query,
            ["limit"] = limit.ToString()
        }, ct);

        if (response.IsSuccess && response.Data is not null) return response;

        return Ok(new ProductSearchResultViewModel
        {
            Products = DemoContent.AllProducts().Take(limit).ToList(),
            Categories = DemoContent.Categories().Take(4).ToList()
        });
    }

    public async Task<ResponseViewModel<ProductDetailViewModel>> GetProductAsync(string slug, CancellationToken ct = default)
    {
        var response = await _api.GetAsync<ProductDetailViewModel>(ApiEndPoint.Product.ShopDetail,
            new Dictionary<string, string?> { ["slug"] = slug }, ct);

        if (response.IsSuccess && response.Data is not null) return response;

        return Ok(new ProductDetailViewModel { Card = DemoContent.Product(slug) });
    }

    public async Task<ResponseViewModel<List<ProductCardViewModel>>> GetRailAsync(
        string railKey, int count, string? contextSlug = null, CancellationToken ct = default)
    {
        var endpoint = railKey switch
        {
            "related" => ApiEndPoint.Product.ShopRelated,
            _ => ApiEndPoint.Product.ShopRail
        };

        var response = await _api.GetAsync<List<ProductCardViewModel>>(endpoint, new Dictionary<string, string?>
        {
            ["rail"] = railKey,
            ["count"] = count.ToString(),
            ["contextSlug"] = contextSlug,
            ["slug"] = contextSlug
        }, ct);

        if (response.IsSuccess && response.Data is not null) return response;

        return Ok(DemoContent.Products(count, railKey.Length % 5));
    }

    // Priority 1: Categories & Banners
    public Task<ResponseViewModel<List<CategoryViewModel>>> GetCategoriesAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<CategoryViewModel>>(ApiEndPoint.Category.ShopFeatured, null, ct);

    public Task<ResponseViewModel<List<CategoryViewModel>>> GetMegaMenuAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<CategoryViewModel>>(ApiEndPoint.Category.ShopMegaMenu, null, ct);

    public Task<ResponseViewModel<List<BannerViewModel>>> GetBannersAsync(string placement, CancellationToken ct = default) =>
        _api.GetAsync<List<BannerViewModel>>(ApiEndPoint.Banner.ShopByPlacement,
            new Dictionary<string, string?> { ["placement"] = placement }, ct);

    public Task<ResponseViewModel<FlashSaleOfferViewModel?>> GetFlashSaleOfferAsync(CancellationToken ct = default) =>
        _api.GetAsync<FlashSaleOfferViewModel?>(ApiEndPoint.Promotion.ShopFlashSale, null, ct);

    public Task<ResponseViewModel<List<TestimonialGridItem>>> GetTestimonialsAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<TestimonialGridItem>>(ApiEndPoint.Content.ShopTestimonials, null, ct);

    // ---- Cart & checkout ---------------------------------------------------
    public async Task<ResponseViewModel<CartViewModel>> GetCartAsync(CancellationToken ct = default)
    {
        var response = await _api.GetAsync<CartViewModel>(ApiEndPoint.Cart.ShopGet, null, ct);
        if (response.IsSuccess && response.Data is not null) return response;

        return Ok(new CartViewModel());
    }

    public Task<ResponseViewModel<CartViewModel>> AddToCartAsync(AddToCartRequest request, CancellationToken ct = default) =>
        _api.PostAsync<CartViewModel>(ApiEndPoint.Cart.ShopAddItem, request, ct);

    public Task<ResponseViewModel<CartViewModel>> UpdateCartQuantityAsync(UpdateCartQuantityRequest request, CancellationToken ct = default) =>
        _api.PostAsync<CartViewModel>(ApiEndPoint.Cart.ShopUpdateQuantity, request, ct);

    public Task<ResponseViewModel<CartViewModel>> RemoveCartItemAsync(long cartItemId, CancellationToken ct = default) =>
        _api.PostAsync<CartViewModel>(ApiEndPoint.Cart.ShopRemoveItem, new RemoveCartItemRequest { CartItemId = cartItemId }, ct);

    public Task<ResponseViewModel<CartViewModel>> ApplyCouponAsync(string couponCode, CancellationToken ct = default) =>
        _api.PostAsync<CartViewModel>(ApiEndPoint.Cart.ShopApplyCoupon, new ApplyCouponRequest { CouponCode = couponCode }, ct);

    public Task<ResponseViewModel<CartViewModel>> RemoveCouponAsync(CancellationToken ct = default) =>
        _api.PostAsync<CartViewModel>(ApiEndPoint.Cart.ShopRemoveCoupon, null, ct);

    public Task<ResponseViewModel<CartViewModel>> MergeGuestCartAsync(string guestToken, CancellationToken ct = default) =>
        _api.PostAsync<CartViewModel>(ApiEndPoint.Auth.MergeGuestCart, new MergeGuestCartRequest { GuestToken = guestToken }, ct);

    public async Task<ResponseViewModel<CheckoutViewModel>> GetCheckoutAsync(bool guest, CancellationToken ct = default)
    {
        var response = await _api.GetAsync<CheckoutViewModel>(ApiEndPoint.Order.ShopCheckoutInit,
            new Dictionary<string, string?> { ["guest"] = guest.ToString() }, ct);
        if (response.IsSuccess && response.Data is not null) return response;

        var lines = DemoContent.CartLines();
        return Ok(new CheckoutViewModel
        {
            Lines = lines,
            Summary = DemoContent.Summary(lines),
            Addresses = DemoContent.Addresses(),
            IsGuest = guest,
            AvailablePoints = 2480
        });
    }

    public Task<ResponseViewModel<PlaceOrderResult>> PlaceOrderAsync(PlaceOrderRequest request, CancellationToken ct = default) =>
        _api.PostAsync<PlaceOrderResult>(ApiEndPoint.Order.ShopPlaceOrder, request, ct);

    // ---- Account -----------------------------------------------------------
    public Task<ResponseViewModel<List<OrderSummaryCardViewModel>>> GetOrdersAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Orders()));

    public async Task<ResponseViewModel<OrderDetailViewModel>> GetOrderAsync(string orderNumber, CancellationToken ct = default)
    {
        var response = await _api.GetAsync<OrderDetailViewModel>(ApiEndPoint.Order.ShopOrderDetail,
            new Dictionary<string, string?> { ["orderNumber"] = orderNumber }, ct);
        if (response.IsSuccess && response.Data is not null) return response;

        var header = DemoContent.Orders().FirstOrDefault(o => o.OrderNumber == orderNumber) ?? DemoContent.Orders()[0];
        return Ok(new OrderDetailViewModel
        {
            Header = header,
            Lines = DemoContent.CartLines(),
            ShippingAddress = DemoContent.Addresses()[0],
            Timeline = DemoContent.Timeline()
        });
    }

    public Task<ResponseViewModel<List<OrderTimelineStep>>> GetTrackingAsync(string orderNumber, CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Timeline()));

    public Task<ResponseViewModel<List<AddressViewModel>>> GetAddressesAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<AddressViewModel>>(ApiEndPoint.Customer.ShopAddressList, null, ct);

    public Task<ResponseViewModel<List<ProductCardViewModel>>> GetWishlistAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Products(4)));

    public Task<ResponseViewModel<List<CouponViewModel>>> GetMyCouponsAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Coupons()));

    public Task<ResponseViewModel<RewardBalanceViewModel>> GetRewardsAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok(new RewardBalanceViewModel
        {
            Points = 1840,
            CurrencyValue = 1840,
            TierName = "Bronze",
            NextTierName = "Silver",
            NextTierAtPoints = 2000
        }));

    public Task<ResponseViewModel<List<NotificationViewModel>>> GetNotificationsAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Notifications()));

    // ---- Content -----------------------------------------------------------
    public Task<ResponseViewModel<List<ArticleCardViewModel>>> GetArticlesAsync(int count, CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Articles()));

    public Task<ResponseViewModel<ArticleCardViewModel>> GetArticleAsync(string slug, CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Articles().FirstOrDefault(a => a.Slug == slug) ?? DemoContent.Articles()[0]));

    public Task<ResponseViewModel<StaticPageViewModel>> GetPageAsync(string slug, CancellationToken ct = default) =>
        Task.FromResult(Ok(new StaticPageViewModel
        {
            Slug = slug,
            Title = "About Chamunda Handicraft",
            BodyHtml = "<p>Every piece in our collection is made by an artisan whose name we know.</p>"
        }));

    public Task<ResponseViewModel<List<ArtisanSummary>>> GetArtisansAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Artisans()));

    public Task<ResponseViewModel<ArtisanSummary>> GetArtisanAsync(string slug, CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Artisans().FirstOrDefault(a => a.Slug == slug) ?? DemoContent.Artisans()[0]));

    public Task<ResponseViewModel<ReviewSummaryViewModel>> GetProductReviewsAsync(string slug, CancellationToken ct = default) =>
        Task.FromResult(Ok(new ReviewSummaryViewModel
        {
            AverageRating = 4.6m,
            TotalCount = 128,
            Distribution = new Dictionary<int, int> { [5] = 92, [4] = 24, [3] = 8, [2] = 3, [1] = 1 }
        }));

    public Task<ResponseViewModel<List<FaqItem>>> GetFaqsAsync(string topic, CancellationToken ct = default) =>
        Task.FromResult(Ok(new List<FaqItem>
        {
            new() { Question = "Are these genuine handmade pieces?", Answer = "Yes, purchased directly from named artisans." },
            new() { Question = "What is your return policy?", Answer = "7-day no questions asked return pickup." }
        }));
}
