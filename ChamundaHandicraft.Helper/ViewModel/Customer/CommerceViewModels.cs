using ChamundaHandicraft.Helper.Enums;

namespace ChamundaHandicraft.Helper.ViewModel.Customer;

/// <summary>One line in the cart, the mini cart, checkout and the order confirmation.</summary>
public class CartLineViewModel
{
    public int Id { get; set; }
    public int ProductId { get; set; }
    public int? VariantId { get; set; }
    public string Slug { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public string ImageAlt { get; set; } = string.Empty;
    public string VariantSummary { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;

    public decimal Price { get; set; }
    public decimal? Mrp { get; set; }
    public int Quantity { get; set; } = 1;

    /// <summary>Live from Inventory, capped by any per-order limit set in Admin.</summary>
    public int MaxQuantity { get; set; } = 10;

    public StockState Stock { get; set; } = StockState.InStock;
    public int? StockCount { get; set; }

    /// <summary>Drives the mandatory compact variation notice on the line (CX principle 4).</summary>
    public bool IsHandmade { get; set; } = true;

    public ArtisanSummary? Artisan { get; set; }
    public DateTime? DeliveryBy { get; set; }

    public decimal LineTotal => Price * Quantity;
    public string Url => $"/p/{Slug}";
}

/// <summary>
/// The complete cost breakdown. Every charge the shopper will ever pay appears here,
/// from the cart onwards — nothing new may appear after payment selection
/// (CX principle 7, and the anti-dark-pattern table in §8.1).
/// </summary>
public class OrderSummaryViewModel
{
    public decimal Subtotal { get; set; }
    public decimal MrpTotal { get; set; }
    public decimal CouponDiscount { get; set; }
    public string? CouponCode { get; set; }
    public decimal Shipping { get; set; }
    public decimal CodFee { get; set; }
    public decimal GiftWrap { get; set; }
    public decimal PointsApplied { get; set; }
    public decimal TaxTotal { get; set; }
    public bool TaxInclusive { get; set; } = true;
    public int ItemCount { get; set; }

    /// <summary>From Settings/StorefrontConfig — never hard-coded in a view.</summary>
    public decimal FreeShippingThreshold { get; set; } = 999m;

    public decimal ProductSavings => MrpTotal > Subtotal ? MrpTotal - Subtotal : 0;
    public decimal TotalSavings => ProductSavings + CouponDiscount + PointsApplied;
    public decimal Total => Subtotal - CouponDiscount - PointsApplied + Shipping + CodFee + GiftWrap;

    public bool QualifiesForFreeShipping => Subtotal >= FreeShippingThreshold;
    public decimal AmountToFreeShipping => Math.Max(0, FreeShippingThreshold - Subtotal);

    public int FreeShippingProgressPercent => FreeShippingThreshold <= 0
        ? 100
        : (int)Math.Min(100, Math.Round(Subtotal / FreeShippingThreshold * 100));
}

public class CartViewModel
{
    public List<CartLineViewModel> Lines { get; set; } = new();
    public List<CartLineViewModel> SavedForLater { get; set; } = new();
    public OrderSummaryViewModel Summary { get; set; } = new();
    public bool GiftWrapSelected { get; set; }
    public string? GiftMessage { get; set; }
    public bool IsEmpty => Lines.Count == 0;
}

public class AddressViewModel
{
    public int Id { get; set; }
    public AddressType Label { get; set; } = AddressType.Home;
    public string FullName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Line1 { get; set; } = string.Empty;
    public string? Line2 { get; set; }
    public string Landmark { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string Pincode { get; set; } = string.Empty;
    public string Country { get; set; } = "India";
    public bool IsDefault { get; set; }

    public string OneLine =>
        string.Join(", ", new[] { Line1, Line2, Landmark, City, State, Pincode }
            .Where(p => !string.IsNullOrWhiteSpace(p)));
}

public class DeliveryMethodViewModel
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Cost { get; set; }
    public DateTime DeliverBy { get; set; }
    public string? CourierName { get; set; }
    public bool IsSelected { get; set; }
}

public class PaymentMethodViewModel
{
    public PaymentMethod Method { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;

    /// <summary>Any surcharge, stated on the option itself rather than revealed later.</summary>
    public decimal ExtraFee { get; set; }

    public bool IsAvailable { get; set; } = true;

    /// <summary>Why it is unavailable — a disabled option must never leave the shopper guessing.</summary>
    public string? UnavailableReason { get; set; }

    public string? OfferText { get; set; }
    public bool IsRecommended { get; set; }
}

public class CheckoutViewModel
{
    public List<CartLineViewModel> Lines { get; set; } = new();
    public OrderSummaryViewModel Summary { get; set; } = new();
    public List<AddressViewModel> Addresses { get; set; } = new();
    public List<DeliveryMethodViewModel> DeliveryMethods { get; set; } = new();
    public List<PaymentMethodViewModel> PaymentMethods { get; set; } = new();
    public bool IsGuest { get; set; }
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
    public int AvailablePoints { get; set; }
    public decimal PointsToCurrencyRate { get; set; } = 1m;
}

public class CouponViewModel
{
    public string Code { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Detail { get; set; } = string.Empty;
    public DiscountType DiscountType { get; set; }
    public decimal DiscountValue { get; set; }
    public decimal? MaxDiscount { get; set; }
    public decimal? MinimumOrderValue { get; set; }
    public DateTime? ExpiresOn { get; set; }
    public bool IsEligible { get; set; }

    /// <summary>"Add ₹4,710 more to use this" — states the gap rather than just refusing.</summary>
    public string? IneligibleReason { get; set; }
}

#region Orders

public class OrderTimelineStep
{
    public string Title { get; set; } = string.Empty;
    public string? Meta { get; set; }
    public string? Location { get; set; }
    public DateTime? At { get; set; }
    public string Icon { get; set; } = "i-package";

    /// <summary>done | current | upcoming</summary>
    public string State { get; set; } = "upcoming";
}

/// <summary>An order as it appears in the customer's order list and account dashboard.</summary>
public class OrderSummaryCardViewModel
{
    public int Id { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public DateTime PlacedOn { get; set; }
    public OrderStatus Status { get; set; }
    public PaymentStatus PaymentStatus { get; set; }
    public decimal Total { get; set; }
    public int ItemCount { get; set; }
    public List<string> Thumbnails { get; set; } = new();
    public string PrimaryItemName { get; set; } = string.Empty;
    public DateTime? DeliveryBy { get; set; }
    public DateTime? DeliveredOn { get; set; }
    public string? Courier { get; set; }
    public string? TrackingNumber { get; set; }

    /// <summary>
    /// Computed by the API from status and the return window in Settings — never by the
    /// view, so the storefront and the admin agree on what is still possible.
    /// </summary>
    public bool CanReview { get; set; }
    public bool CanReturn { get; set; }
    public bool CanCancel { get; set; }
    public bool CanTrack { get; set; }

    public string Url => $"/account/orders/{OrderNumber}";

    public string StatusLabel => Status switch
    {
        OrderStatus.Placed => "Order placed",
        OrderStatus.PaymentPending => "Payment pending",
        OrderStatus.Processing => "Processing",
        OrderStatus.Packed => "Packed",
        OrderStatus.Shipped or OrderStatus.InTransit => "In transit",
        OrderStatus.OutForDelivery => "Out for delivery",
        OrderStatus.Delivered or OrderStatus.Completed => "Delivered",
        OrderStatus.Cancelled => "Cancelled",
        OrderStatus.ReturnRequested or OrderStatus.ReturnApproved or OrderStatus.ReturnPickedUp => "Return in progress",
        OrderStatus.Refunded => "Refunded",
        OrderStatus.PaymentFailed => "Payment failed",
        _ => Status.ToString()
    };

    /// <summary>Maps to the <c>status-chip--*</c> CSS modifier.</summary>
    public string StatusModifier => Status switch
    {
        OrderStatus.Placed or OrderStatus.PaymentPending or OrderStatus.Processing => "placed",
        OrderStatus.Packed => "packed",
        OrderStatus.Shipped or OrderStatus.InTransit or OrderStatus.OutForDelivery => "shipped",
        OrderStatus.Delivered or OrderStatus.Completed => "delivered",
        OrderStatus.Cancelled => "cancelled",
        OrderStatus.ReturnRequested or OrderStatus.ReturnApproved or OrderStatus.ReturnPickedUp => "return",
        OrderStatus.Refunded => "refunded",
        OrderStatus.PaymentFailed => "failed",
        _ => "placed"
    };

    public string StatusIcon => Status switch
    {
        OrderStatus.Placed or OrderStatus.Processing => "i-circle-check",
        OrderStatus.PaymentPending => "i-clock",
        OrderStatus.Packed => "i-package-check",
        OrderStatus.Shipped or OrderStatus.InTransit => "i-truck",
        OrderStatus.OutForDelivery => "i-bike",
        OrderStatus.Delivered or OrderStatus.Completed => "i-home",
        OrderStatus.Cancelled => "i-circle-x",
        OrderStatus.ReturnRequested or OrderStatus.ReturnApproved or OrderStatus.ReturnPickedUp => "i-undo",
        OrderStatus.Refunded => "i-banknote",
        OrderStatus.PaymentFailed => "i-circle-alert",
        _ => "i-package"
    };
}

public class OrderDetailViewModel
{
    public OrderSummaryCardViewModel Header { get; set; } = new();
    public List<CartLineViewModel> Lines { get; set; } = new();
    public OrderSummaryViewModel Summary { get; set; } = new();
    public AddressViewModel ShippingAddress { get; set; } = new();
    public AddressViewModel? BillingAddress { get; set; }
    public List<OrderTimelineStep> Timeline { get; set; } = new();
    public PaymentMethod PaymentMethod { get; set; }
    public string? PaymentReference { get; set; }
    public string? InvoiceUrl { get; set; }
    public int PointsEarned { get; set; }
}

#endregion

#region Reviews, rewards, notifications

public class ReviewViewModel
{
    public int Id { get; set; }
    public string Author { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public int Rating { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public DateTime PostedOn { get; set; }

    /// <summary>Always true on the storefront — only verified purchases are published.</summary>
    public bool VerifiedPurchase { get; set; } = true;

    public int HelpfulCount { get; set; }
    public List<string> Photos { get; set; } = new();
    public string? VariantPurchased { get; set; }

    /// <summary>Admin's public reply, shown beneath the review.</summary>
    public string? MerchantReply { get; set; }
    public DateTime? MerchantRepliedOn { get; set; }
}

public class ReviewSummaryViewModel
{
    public decimal AverageRating { get; set; }
    public int TotalCount { get; set; }

    /// <summary>Star value (1–5) → count, for the distribution bars.</summary>
    public Dictionary<int, int> Distribution { get; set; } = new();

    public Dictionary<string, decimal> SubRatings { get; set; } = new();

    /// <summary>AI-generated and labelled as such. Balanced — never only the positives.</summary>
    public string? AiSummary { get; set; }

    public List<string> PositiveThemes { get; set; } = new();
    public List<string> CriticalThemes { get; set; } = new();
    public List<string> CustomerPhotos { get; set; } = new();
    public List<ReviewViewModel> Recent { get; set; } = new();
}

public class RewardBalanceViewModel
{
    public int Points { get; set; }
    public decimal CurrencyValue { get; set; }
    public string TierName { get; set; } = "Bronze";
    public string? NextTierName { get; set; }
    public int? NextTierAtPoints { get; set; }
    public int PointsToNextTier => NextTierAtPoints is null ? 0 : Math.Max(0, NextTierAtPoints.Value - Points);
}

public class RewardLedgerEntry
{
    public DateTime On { get; set; }
    public string Activity { get; set; } = string.Empty;
    public RewardLedgerType Type { get; set; }
    public int Delta { get; set; }
    public int Balance { get; set; }
    public string? OrderNumber { get; set; }
}

public class NotificationViewModel
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
    public bool IsRead { get; set; }
    public string Icon { get; set; } = "i-bell";

    /// <summary>Every notification is actionable or it is not sent.</summary>
    public string ActionUrl { get; set; } = "/";
    public string ActionLabel { get; set; } = "View";
}

#endregion

#region Content

public class ArticleCardViewModel
{
    public int Id { get; set; }
    public string Slug { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Excerpt { get; set; } = string.Empty;
    public string CoverUrl { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Author { get; set; } = string.Empty;
    public DateTime PublishedOn { get; set; }
    public int ReadMinutes { get; set; } = 5;
    public string Url => $"/blog/{Slug}";
}

public class StaticPageViewModel
{
    public string Slug { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string BodyHtml { get; set; } = string.Empty;
    public DateTime? UpdatedOn { get; set; }
    public List<FaqItem> Faqs { get; set; } = new();
}

public class BannerViewModel
{
    public int Id { get; set; }
    public BannerPlacement Placement { get; set; }
    public string? Eyebrow { get; set; }
    public string Heading { get; set; } = string.Empty;
    public string? SubHeading { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string? MobileImageUrl { get; set; }
    public string ImageAlt { get; set; } = string.Empty;
    public string? PrimaryCtaLabel { get; set; }
    public string? PrimaryCtaUrl { get; set; }
    public string? SecondaryCtaLabel { get; set; }
    public string? SecondaryCtaUrl { get; set; }
    public int SortOrder { get; set; }
}

/// <summary>
/// Runtime configuration the storefront reads once and caches. Every figure a shopper
/// sees — the free-shipping threshold, the COD fee, the return window, the support
/// hours — originates in Admin Settings rather than a hard-coded string in a view.
/// </summary>
public class StorefrontConfigViewModel
{
    public decimal FreeShippingThreshold { get; set; } = 999m;
    public decimal StandardShippingCost { get; set; } = 79m;
    public decimal CodFee { get; set; } = 49m;
    public decimal GiftWrapCost { get; set; } = 99m;
    public int ReturnWindowDays { get; set; } = 7;
    public int RefundWorkingDays { get; set; } = 5;

    public string SupportPhone { get; set; } = string.Empty;
    public string SupportEmail { get; set; } = string.Empty;
    public string SupportWhatsApp { get; set; } = string.Empty;
    public string SupportHours { get; set; } = string.Empty;

    public string CurrencyCode { get; set; } = "INR";
    public string Gstin { get; set; } = string.Empty;
    public string LegalName { get; set; } = string.Empty;

    public int PointsPerHundredSpent { get; set; } = 1;
    public decimal PointValue { get; set; } = 1m;

    /// <summary>Stays false until launch, so nothing is indexed prematurely.</summary>
    public bool RobotsIndexable { get; set; }
}

#endregion

/// <summary>Header and footer state every storefront page needs.</summary>
public class ShellViewModel
{
    public bool IsSignedIn { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public int CartCount { get; set; }
    public int WishlistCount { get; set; }
    public int NotificationCount { get; set; }
    public int RewardPoints { get; set; }
    public string ActiveNav { get; set; } = string.Empty;

    /// <summary>Full, or Minimal on checkout and payment where navigation costs conversion.</summary>
    public string FooterVariant { get; set; } = "Full";

    public bool ShowAnnouncement { get; set; } = true;
    public bool ShowBottomTabs { get; set; } = true;
}
