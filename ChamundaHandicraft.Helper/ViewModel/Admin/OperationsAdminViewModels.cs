using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace ChamundaHandicraft.Helper.ViewModel.Admin;

#region Orders

/// <summary>One row in the Admin order grid (docs/Admin Flows/Orders.txt §4).</summary>
public class OrderGridItem
{
    public int Id { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public DateTime PlacedOn { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public int CustomerId { get; set; }
    public string? CustomerEmail { get; set; }
    public string? CustomerPhone { get; set; }
    public decimal Total { get; set; }
    public int ItemCount { get; set; }
    public PaymentMethod PaymentMethod { get; set; }
    public PaymentStatus PaymentStatus { get; set; }
    public OrderStatus Status { get; set; }
    public string? Courier { get; set; }
    public string? TrackingNumber { get; set; }
    public DateTime? DeliveryBy { get; set; }
    public string ShipToCity { get; set; } = string.Empty;
    public string ShipToPincode { get; set; } = string.Empty;
    public bool HasReturnRequest { get; set; }

    /// <summary>Flags an order past its promised date, so the grid can surface it first.</summary>
    public bool IsBreachingSla { get; set; }
}

/// <summary>
/// A status transition. The API validates it against the lifecycle in Orders.txt §2 —
/// the Admin panel offers only the legal next steps rather than every value.
/// </summary>
public class OrderStatusUpdateRequest
{
    public int OrderId { get; set; }
    public OrderStatus NewStatus { get; set; }
    public string? Note { get; set; }
    public string? Courier { get; set; }
    public string? TrackingNumber { get; set; }
    public DateTime? EstimatedDelivery { get; set; }

    /// <summary>
    /// Ticked by default. Every transition the shopper can act on triggers the matching
    /// notification template, which is what keeps the tracking page honest.
    /// </summary>
    public bool NotifyCustomer { get; set; } = true;
}

/// <summary>
/// The Admin order detail. Deliberately shares <see cref="CartLineViewModel"/>,
/// <see cref="AddressViewModel"/> and <see cref="OrderSummaryViewModel"/> with the
/// customer's own order page — one order, one set of numbers, no reconciliation.
/// </summary>
public class OrderDetailAdminViewModel
{
    public OrderGridItem Header { get; set; } = new();
    public List<CartLineViewModel> Lines { get; set; } = new();
    public OrderSummaryViewModel Summary { get; set; } = new();
    public AddressViewModel ShippingAddress { get; set; } = new();
    public AddressViewModel? BillingAddress { get; set; }
    public List<OrderTimelineStep> Timeline { get; set; } = new();
    public List<OrderNoteViewModel> Notes { get; set; } = new();
    public List<OrderStatus> AllowedNextStatuses { get; set; } = new();

    /// <summary>The gateway's own reference — what support quotes when a bank queries a charge.</summary>
    public string? PaymentReference { get; set; }

    public string? InvoiceUrl { get; set; }
    public ReturnRequestViewModel? ReturnRequest { get; set; }
}

public class OrderNoteViewModel
{
    public int Id { get; set; }
    public string Body { get; set; } = string.Empty;
    public string Author { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }

    /// <summary>Internal notes never reach the customer's order page.</summary>
    public bool IsInternal { get; set; } = true;
}

/// <summary>
/// A return as the customer submitted it and the admin acts on it. Both tiers read
/// this same record — the storefront return page and the admin queue show one truth.
/// </summary>
public class ReturnRequestViewModel
{
    public int Id { get; set; }
    public string RmaNumber { get; set; } = string.Empty;
    public string OrderNumber { get; set; } = string.Empty;
    public DateTime RequestedOn { get; set; }
    public ReturnReason Reason { get; set; }
    public ReturnResolution Resolution { get; set; }
    public string? CustomerNote { get; set; }
    public List<string> Photos { get; set; } = new();
    public List<ReturnLineViewModel> Lines { get; set; } = new();
    public decimal RefundAmount { get; set; }
    public OrderStatus Status { get; set; }
    public DateTime? PickupScheduledOn { get; set; }
    public string? AdminNote { get; set; }
}

public class ReturnLineViewModel
{
    public int OrderLineId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal LineRefund { get; set; }
}

#endregion

#region Promotions

public class CouponSaveRequest
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;

    /// <summary>Shown verbatim on the storefront coupon card.</summary>
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;

    public DiscountType DiscountType { get; set; }
    public decimal DiscountValue { get; set; }
    public decimal? MaxDiscount { get; set; }
    public decimal? MinimumOrderValue { get; set; }

    public DateTime StartsOn { get; set; }
    public DateTime? ExpiresOn { get; set; }

    public int? TotalUsageLimit { get; set; }
    public int? PerCustomerLimit { get; set; } = 1;

    public List<int> CategoryIds { get; set; } = new();
    public List<int> ProductIds { get; set; } = new();
    public List<int> CustomerSegmentIds { get; set; } = new();

    /// <summary>Hidden coupons never appear in "My Coupons" — they must be typed.</summary>
    public bool IsPublic { get; set; } = true;

    public CouponStatus Status { get; set; } = CouponStatus.Draft;
}

/// <summary>
/// A scheduled sale window. <see cref="EndsOn"/> is server time and is what the
/// storefront countdown renders from — the front end never invents an end time,
/// and the band disappears at zero rather than restarting (CX principle 3).
/// </summary>
public class FlashSaleSaveRequest
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateTime StartsOn { get; set; }
    public DateTime EndsOn { get; set; }
    public int DiscountPercent { get; set; }
    public List<int> ProductIds { get; set; } = new();
    public bool IsActive { get; set; }
}

public class BannerSaveRequest
{
    public int Id { get; set; }
    public BannerPlacement Placement { get; set; }
    public string? Eyebrow { get; set; }
    public string Heading { get; set; } = string.Empty;
    public string? SubHeading { get; set; }

    public string ImageUrl { get; set; } = string.Empty;

    /// <summary>A separate mobile crop. Never a scaled desktop image — see the perf budget.</summary>
    public string? MobileImageUrl { get; set; }

    /// <summary>Required. A banner without alt text cannot be published.</summary>
    public string ImageAlt { get; set; } = string.Empty;

    public string? PrimaryCtaLabel { get; set; }
    public string? PrimaryCtaUrl { get; set; }
    public string? SecondaryCtaLabel { get; set; }
    public string? SecondaryCtaUrl { get; set; }

    public DateTime? StartsOn { get; set; }
    public DateTime? EndsOn { get; set; }
    public int SortOrder { get; set; }
    public ContentStatus Status { get; set; } = ContentStatus.Draft;
}

#endregion

#region Content & moderation

public class BlogPostSaveRequest
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string Excerpt { get; set; } = string.Empty;
    public string BodyHtml { get; set; } = string.Empty;
    public string CoverUrl { get; set; } = string.Empty;
    public string CoverAlt { get; set; } = string.Empty;
    public int? CategoryId { get; set; }
    public int? AuthorId { get; set; }
    public List<int> TagIds { get; set; } = new();

    /// <summary>Links a story to the products it features, driving the "Shop this story" rail.</summary>
    public List<int> FeaturedProductIds { get; set; } = new();

    public int ReadMinutes { get; set; }
    public DateTime? PublishOn { get; set; }
    public ContentStatus Status { get; set; } = ContentStatus.Draft;
    public SeoViewModel Seo { get; set; } = new();
}

public class CmsPageSaveRequest
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string BodyHtml { get; set; } = string.Empty;
    public string Template { get; set; } = "Policy";
    public ContentStatus Status { get; set; } = ContentStatus.Draft;
    public SeoViewModel Seo { get; set; } = new();
}

/// <summary>
/// A review awaiting moderation. Rejecting one keeps it off the storefront; nothing
/// here lets an operator edit the shopper's words or hide a review for being negative.
/// </summary>
public class ReviewModerationItem
{
    public int Id { get; set; }
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string ProductImageUrl { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public List<string> Photos { get; set; } = new();
    public DateTime SubmittedOn { get; set; }
    public bool VerifiedPurchase { get; set; }
    public string? OrderNumber { get; set; }
    public ModerationStatus Status { get; set; }

    /// <summary>Why it was rejected. Shown to the customer, so it must be a real reason.</summary>
    public string? RejectionReason { get; set; }

    public string? MerchantReply { get; set; }
}

public class TestimonialSaveRequest
{
    public int Id { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string? Location { get; set; }
    public string Quote { get; set; } = string.Empty;
    public int Rating { get; set; } = 5;
    public string? PhotoUrl { get; set; }
    public bool ShowOnHome { get; set; }
    public int SortOrder { get; set; }
    public ContentStatus Status { get; set; } = ContentStatus.Draft;
}

#endregion

#region Settings

/// <summary>
/// One section of storefront configuration. Saving it changes what shoppers see —
/// the free-shipping threshold on every cart, the COD fee on every checkout, the
/// return window on every order page. Versioned, with a history screen.
/// </summary>
public class SettingsSectionRequest
{
    public string Section { get; set; } = string.Empty;
    public Dictionary<string, string?> Values { get; set; } = new();
    public string? ChangeNote { get; set; }
}

/// <summary>Section names, so a typo cannot silently create a new one.</summary>
public static class SettingsSection
{
    public const string Storefront = "storefront";
    public const string Shipping = "shipping";
    public const string Payment = "payment";
    public const string Tax = "tax";
    public const string Rewards = "rewards";
    public const string Seo = "seo";
    public const string Contact = "contact";
    public const string Notifications = "notifications";
    public const string Legal = "legal";
}

#endregion

#region Dashboard

/// <summary>The admin dashboard tiles (docs/Admin Flows/Dashboard.txt).</summary>
public class AdminDashboardViewModel
{
    public int TotalOrders { get; set; }
    public int TodaysOrders { get; set; }
    public int PendingOrders { get; set; }
    public int ProcessingOrders { get; set; }
    public int PackedOrders { get; set; }
    public int ShippedOrders { get; set; }
    public int DeliveredOrders { get; set; }
    public int CancelledOrders { get; set; }
    public int ReturnedOrders { get; set; }
    public int RefundPending { get; set; }
    public decimal TotalSales { get; set; }
    public decimal AverageOrderValue { get; set; }

    public int LowStockCount { get; set; }
    public int OutOfStockCount { get; set; }
    public int PendingReviewCount { get; set; }
    public int OpenTicketCount { get; set; }
    public int AbandonedCartCount { get; set; }

    public List<OrderGridItem> RecentOrders { get; set; } = new();
    public List<ProductGridItem> LowStockProducts { get; set; } = new();
}

#endregion
