using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace ChamundaHandicraft.Customer.Services;

/// <summary>
/// The design-phase implementation. Serves <see cref="DemoContent"/> through the same
/// interface and the same envelope the gateway will use, so the controllers, views and
/// error paths exercised now are the ones that ship.
///
/// Swap it for <see cref="GatewayStorefrontClient"/> in Program.cs once the API
/// controllers exist. Nothing else changes.
/// </summary>
public class DemoStorefrontClient : IStorefrontClient
{
    private static ResponseViewModel<T> Ok<T>(T data) => ResponseViewModel<T>.Success(data);

    public Task<ShellViewModel> GetShellAsync(CancellationToken ct = default) =>
        Task.FromResult(new ShellViewModel
        {
            IsSignedIn = false,
            FirstName = string.Empty,
            CartCount = 0,
            WishlistCount = 0,
            NotificationCount = 0,
            RewardPoints = 0,
            Categories = DemoContent.Categories(),
            Config = new StorefrontConfigViewModel
            {
                SupportPhone = "+91 98765 43210",
                SupportEmail = "care@chamundahandicraft.com",
                SupportWhatsApp = "919876543210",
                SupportHours = "Mon–Sat, 10am–7pm IST",
                Gstin = "08AABCK1234M1Z5",
                LegalName = "Chamunda Handicraft Pvt. Ltd.",
                FreeShippingThreshold = 999m
            }
        });

    public Task<StorefrontConfigViewModel> GetConfigAsync(CancellationToken ct = default) =>
        Task.FromResult(new StorefrontConfigViewModel
        {
            SupportPhone = "+91 98765 43210",
            SupportEmail = "care@chamundahandicraft.com",
            SupportWhatsApp = "919876543210",
            SupportHours = "Mon–Sat, 10am–7pm IST",
            Gstin = "08AABCK1234M1Z5",
            LegalName = "Chamunda Handicraft Pvt. Ltd."
        });

    public Task<ResponseViewModel<ProductListingViewModel>> GetListingAsync(
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
        var products = DemoContent.AllProducts();

        return Task.FromResult(Ok(new ProductListingViewModel
        {
            Heading = categorySlug is null ? "All products" : categorySlug,
            CategorySlug = categorySlug,
            Sort = sort ?? "popularity",
            Products = new PagedResult<ProductCardViewModel>
            {
                Items = products,
                TotalCount = 84,
                Page = paging.Page,
                PageSize = paging.PageSize
            }
        }));
    }

    public Task<ResponseViewModel<ProductSearchResultViewModel>> GetSearchSuggestionsAsync(
        string query, int limit = 8, CancellationToken ct = default)
    {
        var products = DemoContent.AllProducts().Take(limit).ToList();
        var categories = DemoContent.Categories().Take(4).ToList();
        return Task.FromResult(Ok(new ProductSearchResultViewModel
        {
            Products = products,
            Categories = categories
        }));
    }

    public Task<ResponseViewModel<ProductListingViewModel>> SearchAsync(
        string? query, PagedRequest paging, string? sort, CancellationToken ct = default)
    {
        var products = string.IsNullOrWhiteSpace(query) || query.Contains("xyz", StringComparison.OrdinalIgnoreCase)
            ? new List<ProductCardViewModel>()
            : DemoContent.AllProducts();

        return Task.FromResult(Ok(new ProductListingViewModel
        {
            Heading = string.IsNullOrEmpty(query) ? "Search" : $"Results for “{query}”",
            Query = query ?? string.Empty,
            Sort = sort ?? "relevance",
            Products = new PagedResult<ProductCardViewModel>
            {
                Items = products,
                TotalCount = products.Count,
                Page = paging.Page,
                PageSize = paging.PageSize
            }
        }));
    }

    public Task<ResponseViewModel<ProductDetailViewModel>> GetProductAsync(string slug, CancellationToken ct = default) =>
        Task.FromResult(Ok(new ProductDetailViewModel { Card = DemoContent.Product(slug) }));

    public Task<ResponseViewModel<List<ProductCardViewModel>>> GetRailAsync(
        string railKey, int count, string? contextSlug = null, CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Products(count, railKey.Length % 5)));

    public Task<ResponseViewModel<List<CategoryViewModel>>> GetCategoriesAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Categories()));

    public Task<ResponseViewModel<List<CategoryViewModel>>> GetMegaMenuAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Categories()));

    public Task<ResponseViewModel<List<BannerViewModel>>> GetBannersAsync(string placement, CancellationToken ct = default) =>
        Task.FromResult(Ok(new List<BannerViewModel>
        {
            new()
            {
                Eyebrow = "Handmade for Diwali",
                Heading = "Light your home with pieces made by hand",
                SubHeading = "Brass diyas, blue pottery and festive décor from artisans across India.",
                ImageUrl = "/assets/images/placeholders/hero.svg",
                MobileImageUrl = "/assets/images/placeholders/hero-mobile.svg",
                ImageAlt = "Brass diyas glowing in a row on a dark wooden surface",
                PrimaryCtaLabel = "Shop the Collection",
                PrimaryCtaUrl = "/c/festive",
                SecondaryCtaLabel = "Meet the Makers",
                SecondaryCtaUrl = "/artisans"
            }
        }));

    public Task<ResponseViewModel<FlashSaleOfferViewModel?>> GetFlashSaleOfferAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok<FlashSaleOfferViewModel?>(new FlashSaleOfferViewModel
        {
            Id = 1,
            Name = "Diwali Flash Sale",
            OfferType = "Flash Sale",
            DiscountPercent = 20,
            StartsOn = DateTime.Now.Date,
            EndsOn = DateTime.Now.Date.AddDays(2).AddHours(20)
        }));

    public Task<ResponseViewModel<List<ChamundaHandicraft.Helper.ViewModel.Admin.TestimonialGridItem>>> GetTestimonialsAsync(CancellationToken ct = default)
    {
        var reviews = DemoContent.Reviews();
        var items = reviews.Select(r => new ChamundaHandicraft.Helper.ViewModel.Admin.TestimonialGridItem
        {
            CustomerName = r.Author,
            Location = "Jaipur",
            Quote = r.Body,
            Rating = r.Rating,
            ShowOnHome = true
        }).ToList();

        return Task.FromResult(Ok(items));
    }

    public Task<ResponseViewModel<CartViewModel>> GetCartAsync(CancellationToken ct = default)
    {
        var lines = DemoContent.CartLines();

        return Task.FromResult(Ok(new CartViewModel
        {
            Lines = lines,
            Summary = DemoContent.Summary(lines)
        }));
    }

    public Task<ResponseViewModel<CartViewModel>> AddToCartAsync(AddToCartRequest request, CancellationToken ct = default) =>
        GetCartAsync(ct);

    public Task<ResponseViewModel<CartViewModel>> UpdateCartQuantityAsync(UpdateCartQuantityRequest request, CancellationToken ct = default) =>
        GetCartAsync(ct);

    public Task<ResponseViewModel<CartViewModel>> RemoveCartItemAsync(long cartItemId, CancellationToken ct = default) =>
        GetCartAsync(ct);

    public Task<ResponseViewModel<CartViewModel>> ApplyCouponAsync(string couponCode, CancellationToken ct = default) =>
        GetCartAsync(ct);

    public Task<ResponseViewModel<CartViewModel>> RemoveCouponAsync(CancellationToken ct = default) =>
        GetCartAsync(ct);

    public Task<ResponseViewModel<CartViewModel>> MergeGuestCartAsync(string guestToken, CancellationToken ct = default) =>
        GetCartAsync(ct);

    public Task<ResponseViewModel<CheckoutViewModel>> GetCheckoutAsync(bool guest, CancellationToken ct = default)
    {
        var lines = DemoContent.CartLines();

        return Task.FromResult(Ok(new CheckoutViewModel
        {
            Lines = lines,
            Summary = DemoContent.Summary(lines),
            Addresses = DemoContent.Addresses(),
            IsGuest = guest,
            AvailablePoints = 2480
        }));
    }

    public Task<ResponseViewModel<PlaceOrderResult>> PlaceOrderAsync(PlaceOrderRequest request, CancellationToken ct = default)
    {
        var result = new PlaceOrderResult
        {
            Success = true,
            OrderId = 1,
            OrderNumber = "CH-2026-000001",
            GrandTotal = 2499.00m,
            ResultCode = 0,
            Message = "Order placed successfully.",
            RedirectUrl = "/checkout/success/CH-2026-000001"
        };
        return Task.FromResult(Ok(result));
    }

    public Task<ResponseViewModel<List<OrderSummaryCardViewModel>>> GetOrdersAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Orders()));

    public Task<ResponseViewModel<OrderDetailViewModel>> GetOrderAsync(string orderNumber, CancellationToken ct = default)
    {
        var header = DemoContent.Orders().FirstOrDefault(o => o.OrderNumber == orderNumber) ?? DemoContent.Orders()[0];
        var lines = DemoContent.CartLines();

        return Task.FromResult(Ok(new OrderDetailViewModel
        {
            Header = header,
            Lines = lines,
            Summary = DemoContent.Summary(lines),
            ShippingAddress = DemoContent.Addresses().First(a => a.IsDefault),
            Timeline = DemoContent.Timeline()
        }));
    }

    public Task<ResponseViewModel<List<OrderTimelineStep>>> GetTrackingAsync(string orderNumber, CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Timeline()));

    public Task<ResponseViewModel<List<AddressViewModel>>> GetAddressesAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Addresses()));

    public Task<ResponseViewModel<List<ProductCardViewModel>>> GetWishlistAsync(CancellationToken ct = default)
    {
        var products = DemoContent.Products(6);
        products.ForEach(p => p.IsWishlisted = true);
        return Task.FromResult(Ok(products));
    }

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

    public Task<ResponseViewModel<List<ArticleCardViewModel>>> GetArticlesAsync(int count, CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Articles().Take(count).ToList()));

    public Task<ResponseViewModel<ArticleCardViewModel>> GetArticleAsync(string slug, CancellationToken ct = default)
    {
        var article = DemoContent.Articles().FirstOrDefault(a => a.Slug == slug);

        return Task.FromResult(article is null
            ? ResponseViewModel<ArticleCardViewModel>.Fail("We couldn't find that story.", Helper.Enums.ApiStatusCode.NotFound)
            : Ok(article));
    }

    public Task<ResponseViewModel<StaticPageViewModel>> GetPageAsync(string slug, CancellationToken ct = default) =>
        Task.FromResult(Ok(new StaticPageViewModel { Slug = slug, Faqs = DemoContent.ShippingFaqs() }));

    public Task<ResponseViewModel<List<ArtisanSummary>>> GetArtisansAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.Artisans()));

    public Task<ResponseViewModel<ArtisanSummary>> GetArtisanAsync(string slug, CancellationToken ct = default)
    {
        var artisan = DemoContent.Artisans().FirstOrDefault(a => a.Slug == slug);

        return Task.FromResult(artisan is null
            ? ResponseViewModel<ArtisanSummary>.Fail("We couldn't find that artisan.", Helper.Enums.ApiStatusCode.NotFound)
            : Ok(artisan));
    }

    public Task<ResponseViewModel<ReviewSummaryViewModel>> GetProductReviewsAsync(string slug, CancellationToken ct = default) =>
        Task.FromResult(Ok(new ReviewSummaryViewModel
        {
            AverageRating = 4.6m,
            TotalCount = 128,
            Distribution = new Dictionary<int, int> { [5] = 92, [4] = 24, [3] = 8, [2] = 3, [1] = 1 },
            SubRatings = new Dictionary<string, decimal> { ["Quality"] = 4.8m, ["Value"] = 4.3m, ["As pictured"] = 4.7m },
            AiSummary = "Customers love the colour depth and the visible hand-painted detail. "
                        + "Several mention it is smaller than expected — check the dimensions before ordering.",
            PositiveThemes = new List<string> { "colour (42)", "craftsmanship (38)", "packing (21)" },
            CriticalThemes = new List<string> { "size (12)", "delivery time (6)" },
            Recent = DemoContent.Reviews()
        }));

    public Task<ResponseViewModel<List<FaqItem>>> GetFaqsAsync(string topic, CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoContent.ShippingFaqs()));
}
