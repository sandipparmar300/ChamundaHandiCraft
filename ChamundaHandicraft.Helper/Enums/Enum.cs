namespace ChamundaHandicraft.Helper.Enums;

/// <summary>
/// Every platform enum in one place, so the Admin panel, the API and the Customer
/// site cannot drift apart on the meaning of a status.
///
/// Numeric values are persisted. Never renumber an existing member — append.
/// </summary>

#region Catalog

/// <summary>
/// The publish gate. Only <see cref="Published"/> products appear on the storefront;
/// every other value is admin-visible only. Set on the Admin product screen.
/// </summary>
public enum ProductStatus
{
    Draft = 0,
    Published = 1,
    Unpublished = 2,
    Archived = 3
}

/// <summary>
/// Second gate, independent of status. A product can be Published but hidden from
/// listings (reachable only by direct link) — used for exclusive drops.
/// </summary>
public enum ProductVisibility
{
    Everywhere = 0,
    SearchOnly = 1,
    CatalogOnly = 2,
    Hidden = 3
}

/// <summary>What the storefront stock indicator renders (CMP-PRD-Stock).</summary>
public enum StockState
{
    InStock = 0,
    LowStock = 1,
    OutOfStock = 2,
    MadeToOrder = 3,
    PreOrder = 4,
    Backorder = 5
}

/// <summary>
/// Merchandising badges. Priority order on a card is Sale &gt; Bestseller &gt; New &gt;
/// Handmade &gt; Limited, capped at two (CU-07).
/// </summary>
public enum ProductBadge
{
    Sale = 0,
    Bestseller = 1,
    New = 2,
    Handmade = 3,
    Limited = 4,
    Eco = 5,
    GiTagged = 6,
    Sponsored = 7,
    BackInStock = 8,
    PreOrder = 9
}

public enum ProductMediaType
{
    Image = 0,
    Video = 1,
    Spin360 = 2
}

#endregion

#region Orders

/// <summary>
/// The order lifecycle from docs/Admin Flows/Orders.txt §2. The Admin moves an order
/// through these; the Customer sees the same value rendered as a status chip and a
/// tracking timeline.
/// </summary>
public enum OrderStatus
{
    Placed = 0,
    PaymentPending = 1,
    Processing = 2,
    Packed = 3,
    Shipped = 4,
    InTransit = 5,
    OutForDelivery = 6,
    Delivered = 7,
    Completed = 8,
    Cancelled = 9,
    ReturnRequested = 10,
    ReturnApproved = 11,
    ReturnPickedUp = 12,
    Refunded = 13,
    PaymentFailed = 14,
    Closed = 15
}

public enum PaymentStatus
{
    Pending = 0,
    Authorised = 1,
    Paid = 2,
    Failed = 3,
    Refunded = 4,
    PartiallyRefunded = 5,
    CodPending = 6
}

public enum PaymentMethod
{
    Upi = 0,
    Card = 1,
    NetBanking = 2,
    Wallet = 3,
    CashOnDelivery = 4,
    StoreCredit = 5
}

public enum ReturnReason
{
    DamagedOrBroken = 0,
    WrongItem = 1,
    NotAsDescribed = 2,
    QualityBelowExpectation = 3,
    SizeUnsuitable = 4,
    ChangedMind = 5
}

/// <summary>What the shopper asked for on the return form.</summary>
public enum ReturnResolution
{
    Refund = 0,
    Replacement = 1,
    StoreCredit = 2
}

public enum ShipmentStatus
{
    NotShipped = 0,
    LabelGenerated = 1,
    PickedUp = 2,
    InTransit = 3,
    OutForDelivery = 4,
    Delivered = 5,
    Failed = 6,
    Rto = 7
}

#endregion

#region Promotions

public enum DiscountType
{
    Percentage = 0,
    FixedAmount = 1,
    FreeShipping = 2,
    BuyXGetY = 3
}

public enum CouponStatus
{
    Draft = 0,
    Active = 1,
    Paused = 2,
    Expired = 3,
    Exhausted = 4
}

#endregion

#region Content

/// <summary>
/// Shared by blog posts, CMS pages, banners and testimonials. Only
/// <see cref="Published"/> reaches the storefront.
/// </summary>
public enum ContentStatus
{
    Draft = 0,
    Scheduled = 1,
    Published = 2,
    Unpublished = 3,
    Archived = 4
}

/// <summary>
/// Reviews and blog comments. The storefront renders only <see cref="Approved"/>,
/// and only from verified purchases.
/// </summary>
public enum ModerationStatus
{
    Pending = 0,
    Approved = 1,
    Rejected = 2,
    Spam = 3
}

public enum BannerPlacement
{
    HomeHero = 0,
    HomeBand = 1,
    CategoryTop = 2,
    PlpInjection = 3,
    CartUpsell = 4,
    AnnouncementBar = 5
}

#endregion

#region Support & customers

public enum TicketStatus
{
    Open = 0,
    AwaitingCustomer = 1,
    AwaitingAgent = 2,
    Resolved = 3,
    Closed = 4
}

public enum CustomerStatus
{
    Active = 0,
    Inactive = 1,
    Blocked = 2,
    Deleted = 3
}

public enum AddressType
{
    Home = 0,
    Work = 1,
    Other = 2
}

public enum NotificationChannel
{
    Email = 0,
    Sms = 1,
    WhatsApp = 2,
    Push = 3,
    InApp = 4
}

public enum RewardLedgerType
{
    Earned = 0,
    Redeemed = 1,
    Expired = 2,
    Reversed = 3,
    Adjusted = 4
}

#endregion

#region Platform

public enum ApiStatusCode
{
    Success = 200,
    Created = 201,
    BadRequest = 400,
    Unauthorized = 401,
    Forbidden = 403,
    NotFound = 404,
    Conflict = 409,
    ValidationFailed = 422,
    ServerError = 500
}

/// <summary>Which gateway prefix a call goes through.</summary>
public enum ApiAudience
{
    Admin = 0,
    Shop = 1,
    Public = 2
}

#endregion
