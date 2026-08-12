using ChamundaHandicraft.Helper.CommonMethod;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace ChamundaHandicraft.Helper.ViewModel.Customer;

/// <summary>
/// The artisan credited on a product. A first-class entity, not a metadata field —
/// the Admin Artisan screens write it and it surfaces on cards, PDP, cart lines,
/// order detail and the invoice.
/// </summary>
public class ArtisanSummary
{
    public int Id { get; set; }
    public string Slug { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Craft { get; set; } = string.Empty;
    public string Cluster { get; set; } = string.Empty;
    public string PhotoUrl { get; set; } = string.Empty;
    public string Url => $"/artisans/{Slug}";
}

/// <summary>
/// One product as a listing card. Returned by <c>Shop/Product/List</c>,
/// <c>Shop/Search/Query</c> and every rail endpoint.
///
/// Everything here is derived server-side from what the Admin published. The
/// storefront renders it and computes nothing about price or stock itself.
/// </summary>
public class ProductCardViewModel
{
    public int Id { get; set; }
    public string Slug { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;

    public string CategoryName { get; set; } = string.Empty;
    public string CategorySlug { get; set; } = string.Empty;

    public string ImageUrl { get; set; } = string.Empty;
    public string? HoverImageUrl { get; set; }

    /// <summary>Descriptive and product-specific — never "product image" (§10.3).</summary>
    public string ImageAlt { get; set; } = string.Empty;

    public decimal Price { get; set; }
    public decimal? Mrp { get; set; }

    public decimal Rating { get; set; }
    public int ReviewCount { get; set; }

    public ArtisanSummary? Artisan { get; set; }
    public List<ProductBadge> Badges { get; set; } = new();

    public StockState Stock { get; set; } = StockState.InStock;

    /// <summary>
    /// Only sent when the true figure is 5 or fewer, so "Only 2 left" can never be
    /// manufactured by the front end (CX principle 3).
    /// </summary>
    public int? StockCount { get; set; }

    public bool IsWishlisted { get; set; }
    public bool IsHandmade { get; set; } = true;

    /// <summary>When true, Add to Cart opens Quick View rather than adding blind.</summary>
    public bool RequiresOptions { get; set; }

    public string ShortDescription { get; set; } = string.Empty;
    public string Material { get; set; } = string.Empty;
    public string Dimensions { get; set; } = string.Empty;

    public int DiscountPercent => Money.DiscountPercent(Price, Mrp);
    public decimal Savings => Mrp is > 0 && Mrp > Price ? Mrp.Value - Price : 0;
    public bool IsOnSale => DiscountPercent > 0;
    public string Url => $"/p/{Slug}";
}

/// <summary>The PDP payload. Extends the card with everything the buy box and tabs need.</summary>
public class ProductDetailViewModel
{
    public ProductCardViewModel Card { get; set; } = new();

    public string FullDescription { get; set; } = string.Empty;

    /// <summary>The handmade story. Editorial copy written on the Admin product screen.</summary>
    public string? CraftStory { get; set; }

    public string? CareInstructions { get; set; }

    public List<MediaViewModel> Media { get; set; } = new();
    public List<ProductOptionGroup> Options { get; set; } = new();
    public List<ProductVariantViewModel> Variants { get; set; } = new();
    public List<SpecificationGroup> Specifications { get; set; } = new();
    public List<FaqItem> Faqs { get; set; } = new();

    public ReviewSummaryViewModel Reviews { get; set; } = new();
    public DeliveryEstimateViewModel Delivery { get; set; } = new();

    public SeoViewModel Seo { get; set; } = new();
    public List<BreadcrumbItem> Breadcrumbs { get; set; } = new();

    /// <summary>Real figure or omitted entirely. Never a fabricated "12 people viewing".</summary>
    public int? SoldLastSevenDays { get; set; }

    public bool ShowVariationNotice => Card.IsHandmade;
}

public class ProductOptionGroup
{
    public string Name { get; set; } = string.Empty;
    public string DisplayType { get; set; } = "Pill";
    public bool IsRequired { get; set; } = true;
    public List<ProductOptionValue> Values { get; set; } = new();
}

public class ProductOptionValue
{
    public int Id { get; set; }
    public string Label { get; set; } = string.Empty;

    /// <summary>A11Y-05 / CU rule: a swatch always carries its colour name as text too.</summary>
    public string? ColourHex { get; set; }

    public string? ImageUrl { get; set; }
    public bool IsSelected { get; set; }
    public bool IsAvailable { get; set; } = true;
}

public class ProductVariantViewModel
{
    public int Id { get; set; }
    public string Sku { get; set; } = string.Empty;
    public string VariantSummary { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal? Mrp { get; set; }
    public StockState Stock { get; set; }
    public int? StockCount { get; set; }
    public List<int> OptionValueIds { get; set; } = new();
}

public class SpecificationGroup
{
    public string Title { get; set; } = string.Empty;
    public List<SpecificationRow> Rows { get; set; } = new();
}

public class SpecificationRow
{
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public string? HelpText { get; set; }
}

public class FaqItem
{
    public string Question { get; set; } = string.Empty;
    public string Answer { get; set; } = string.Empty;
}

/// <summary>
/// CMP-PRD-DeliveryEstimate. The PIN is remembered for 30 days and reused on PDP,
/// cart, checkout and search cards.
/// </summary>
public class DeliveryEstimateViewModel
{
    public string? Pincode { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public bool IsServiceable { get; set; }
    public DateTime? DeliverBy { get; set; }
    public DateTime? DeliverByLatest { get; set; }
    public string? CourierName { get; set; }
    public bool CodAvailable { get; set; }
    public decimal ShippingCost { get; set; }

    /// <summary>Shown when not serviceable, so the shopper knows why rather than guessing.</summary>
    public string? UnavailableReason { get; set; }
}

/// <summary>Category tile and mega-menu node. Written by the Admin Category module.</summary>
public class CategoryViewModel
{
    public int Id { get; set; }
    public string Slug { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string? IntroCopy { get; set; }
    public int ProductCount { get; set; }
    public int? ParentId { get; set; }
    public List<CategoryViewModel> Children { get; set; } = new();
    public string Url => $"/c/{Slug}";
}

/// <summary>One filter group on the PLP rail and the mobile filter sheet.</summary>
public class FacetGroupViewModel
{
    public string Key { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string Type { get; set; } = "Checkbox";
    public bool IsExpandedByDefault { get; set; }
    public List<FacetValueViewModel> Values { get; set; } = new();
}

public class FacetValueViewModel
{
    public string Value { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string? ColourHex { get; set; }
    public int Count { get; set; }
    public bool IsSelected { get; set; }

    /// <summary>FL-02: a zero-result option is disabled and dimmed, never removed.</summary>
    public bool IsDisabled => Count == 0 && !IsSelected;
}

/// <summary>Everything a PLP or search-results page needs in one response.</summary>
public class ProductListingViewModel
{
    public string Heading { get; set; } = string.Empty;
    public string IntroCopy { get; set; } = string.Empty;
    public string? CategorySlug { get; set; }
    public string? Query { get; set; }
    public string? CorrectedFrom { get; set; }

    public PagedResult<ProductCardViewModel> Products { get; set; } = new();
    public List<FacetGroupViewModel> Facets { get; set; } = new();
    public List<CategoryViewModel> SubCategories { get; set; } = new();
    public List<CategoryViewModel> RelatedCategories { get; set; } = new();

    public string Sort { get; set; } = "popularity";
    public string View { get; set; } = "grid";

    public SeoViewModel Seo { get; set; } = new();
    public List<BreadcrumbItem> Breadcrumbs { get; set; } = new();

    public bool IsSearch => Query is not null;
}
