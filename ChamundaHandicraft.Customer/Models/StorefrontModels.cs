using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace ChamundaHandicraft.Customer.Models;

/// <summary>
/// Presentation-only concerns for the storefront.
///
/// The data shapes themselves live in <c>ChamundaHandicraft.Helper.ViewModel.Customer</c>
/// because the API returns them and the Admin panel writes them. What stays here is
/// purely how this project paints them — CSS class names, icon ids and the small
/// view-composition models a Razor partial needs.
/// </summary>

/// <summary>
/// Badge presentation. Every badge pairs colour with a word and an icon, so colour is
/// never the sole carrier of meaning (A11Y-05).
/// </summary>
public static class BadgeStyle
{
    public static (string Css, string Label, string? Icon) For(ProductBadge badge, int discountPercent = 0) => badge switch
    {
        ProductBadge.Sale => ("badge-sale", discountPercent > 0 ? $"{discountPercent}% OFF" : "SALE", null),
        ProductBadge.Bestseller => ("badge-bestseller", "BESTSELLER", "i-award"),
        ProductBadge.New => ("badge-new", "NEW", "i-badge-plus"),
        ProductBadge.Handmade => ("badge-handmade", "HANDMADE", "i-hand-heart"),
        ProductBadge.Limited => ("badge-limited", "LIMITED", "i-gem"),
        ProductBadge.Eco => ("badge-eco", "SUSTAINABLE", "i-leaf"),
        ProductBadge.GiTagged => ("badge-limited", "GI TAGGED", "i-badge-check"),
        ProductBadge.Sponsored => ("badge-sponsored", "SPONSORED", null),
        ProductBadge.BackInStock => ("badge-new", "BACK IN STOCK", null),
        ProductBadge.PreOrder => ("badge-new", "PRE-ORDER", null),
        _ => ("badge-sponsored", badge.ToString().ToUpperInvariant(), null)
    };
}

/// <summary>
/// Stock presentation. "Only {n} left" renders only when the API actually sent a count
/// of five or fewer — the front end never invents scarcity (CX principle 3).
/// </summary>
public static class StockStyle
{
    public static (string Css, string Label, string Icon)? For(StockState state, int? count) => state switch
    {
        StockState.InStock => ("stock--in", "In stock", "i-circle-check"),
        StockState.LowStock when count is > 0 and <= 5 => ("stock--low", $"Only {count} left", "i-triangle-alert"),
        StockState.LowStock => ("stock--in", "In stock", "i-circle-check"),
        StockState.OutOfStock => ("stock--out", "Out of stock", "i-circle-x"),
        StockState.MadeToOrder => ("stock--made", "Made to order · ships in 10 days", "i-clock"),
        StockState.PreOrder => ("stock--made", "Pre-order", "i-calendar"),
        StockState.Backorder => ("stock--made", "On backorder", "i-clock"),
        _ => null
    };
}

/// <summary>Address label presentation — icon per type.</summary>
public static class AddressStyle
{
    public static string Icon(AddressType type) => type switch
    {
        AddressType.Home => "i-home",
        AddressType.Work => "i-store",
        _ => "i-map-pin"
    };
}

/// <summary>CMP-PRD-Rail — heading, optional "View all", and a horizontally scrolling row.</summary>
public class ProductRailViewModel
{
    public string Heading { get; set; } = "";
    public string? Eyebrow { get; set; }
    public string? SubHeading { get; set; }
    public string? ViewAllUrl { get; set; }
    public string ViewAllLabel { get; set; } = "View all";
    public List<ProductCardViewModel> Products { get; set; } = new();
    public bool Compact { get; set; }
}

/// <summary>
/// What the cart page renders. A thin wrapper over the shared
/// <see cref="CartViewModel"/> so the view can also show the recommendation rails.
/// </summary>
public class CartPageViewModel
{
    public List<CartLineViewModel> Lines { get; set; } = new();
    public OrderSummaryViewModel Summary { get; set; } = new();
    public List<ProductCardViewModel> SavedForLater { get; set; } = new();
}

/// <summary>
/// The PLP and search-results view model. Both surfaces use the same listing pattern
/// (P-01), which is why they share one shape.
/// </summary>
public class ListingViewModel
{
    public string Heading { get; set; } = "";
    public string Intro { get; set; } = "";
    public string? CategorySlug { get; set; }
    public string Sort { get; set; } = "popularity";
    public string View { get; set; } = "grid";
    public List<ProductCardViewModel> Products { get; set; } = new();
    public int TotalCount { get; set; }

    /// <summary>Search-only: the query, and the spelling we corrected from.</summary>
    public string? Query { get; set; }
    public string? CorrectedFrom { get; set; }
    public bool IsSearch => Query is not null;
}
