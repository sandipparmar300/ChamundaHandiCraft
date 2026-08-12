using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace ChamundaHandicraft.Helper.ViewModel.Admin;

/// <summary>
/// The write side of the catalogue. Read these next to
/// <c>ViewModel/Customer/CatalogViewModels.cs</c> — what an admin saves here is what a
/// shopper sees there, and <c>docs/INTEGRATION-MAP.md</c> names the screen.
/// </summary>

/// <summary>One row in the Admin product grid (docs/Admin Flows/Product.txt §3).</summary>
public class ProductGridItem : AuditableViewModel
{
    public int Id { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public string ProductCode { get; set; } = string.Empty;
    public string? Barcode { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public string? SubCategoryName { get; set; }
    public string? BrandName { get; set; }
    public decimal Price { get; set; }
    public decimal? Mrp { get; set; }
    public int DiscountPercent { get; set; }
    public int StockQuantity { get; set; }
    public ProductStatus Status { get; set; }
    public ProductVisibility Visibility { get; set; }
    public bool IsFeatured { get; set; }
    public bool IsBestseller { get; set; }
    public bool IsTrending { get; set; }

    /// <summary>
    /// Live on the storefront only when published, visible and in a published category.
    /// The grid shows this as a single unambiguous column rather than making the
    /// operator infer it from three others.
    /// </summary>
    public bool IsLiveOnStorefront { get; set; }

    /// <summary>Deep link to the storefront PDP, so Preview opens exactly what a shopper sees.</summary>
    public string StorefrontUrl { get; set; } = string.Empty;
}

/// <summary>
/// The product create/edit payload. Every field here has a destination on the
/// storefront — nothing is captured that nobody reads.
/// </summary>
public class ProductSaveRequest
{
    public int Id { get; set; }

    // General
    public string Name { get; set; } = string.Empty;
    public string ProductCode { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public string? Barcode { get; set; }

    /// <summary>Drives <c>/p/{slug}</c>. Changing it must create a 301 in the Seo module.</summary>
    public string Slug { get; set; } = string.Empty;

    public string ShortDescription { get; set; } = string.Empty;
    public string FullDescription { get; set; } = string.Empty;

    /// <summary>The handmade story rendered in the PDP craft band.</summary>
    public string? ProductStory { get; set; }

    public string? CareInstructions { get; set; }
    public string? WarrantyInformation { get; set; }

    // Classification
    public int CategoryId { get; set; }
    public int? SubCategoryId { get; set; }
    public int? CollectionId { get; set; }
    public int? BrandId { get; set; }

    /// <summary>Credits the maker on the card, PDP, cart line, order and invoice.</summary>
    public int? ArtisanId { get; set; }

    public string? Material { get; set; }
    public string? CraftTechnique { get; set; }
    public string? OriginCluster { get; set; }
    public List<int> TagIds { get; set; } = new();

    // Pricing
    public decimal Price { get; set; }

    /// <summary>
    /// The genuine list price. Discounts are computed from it, so inflating it to
    /// manufacture a bigger saving is a policy breach, not a merchandising tactic (§8.1).
    /// </summary>
    public decimal? Mrp { get; set; }

    public decimal? CostPrice { get; set; }
    public int? TaxClassId { get; set; }
    public bool IsTaxInclusive { get; set; } = true;

    // Dimensions — feed the PDP spec list and the courier rate calculation
    public decimal? LengthCm { get; set; }
    public decimal? WidthCm { get; set; }
    public decimal? HeightCm { get; set; }
    public decimal? WeightGrams { get; set; }

    // Inventory
    public bool TrackInventory { get; set; } = true;
    public int? LowStockThreshold { get; set; } = 5;
    public int? MaxQuantityPerOrder { get; set; }
    public bool AllowBackorder { get; set; }
    public bool IsMadeToOrder { get; set; }
    public int? MadeToOrderDays { get; set; }

    // Merchandising
    public ProductStatus Status { get; set; } = ProductStatus.Draft;
    public ProductVisibility Visibility { get; set; } = ProductVisibility.Everywhere;
    public bool IsFeatured { get; set; }
    public bool IsBestseller { get; set; }
    public bool IsTrending { get; set; }

    /// <summary>
    /// Only <see cref="ProductBadge.Handmade"/>, Eco, GiTagged and Limited are set
    /// here. Sale, Bestseller and New are computed by the API from price, sales and
    /// publish date so a badge can never claim something untrue.
    /// </summary>
    public List<ProductBadge> ManualBadges { get; set; } = new();

    public DateTime? PublishOn { get; set; }

    public List<MediaViewModel> Media { get; set; } = new();
    public List<ProductVariantSaveRequest> Variants { get; set; } = new();
    public List<ProductSpecificationSaveRequest> Specifications { get; set; } = new();
    public List<ProductFaqSaveRequest> Faqs { get; set; } = new();
    public SeoViewModel Seo { get; set; } = new();
}

public class ProductVariantSaveRequest
{
    public int Id { get; set; }
    public string Sku { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal? Mrp { get; set; }
    public int StockQuantity { get; set; }
    public bool IsDefault { get; set; }
    public Dictionary<string, string> OptionValues { get; set; } = new();
    public string? ImageUrl { get; set; }
}

public class ProductSpecificationSaveRequest
{
    public string GroupTitle { get; set; } = string.Empty;
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public string? HelpText { get; set; }
    public int SortOrder { get; set; }
}

public class ProductFaqSaveRequest
{
    public int Id { get; set; }
    public string Question { get; set; } = string.Empty;
    public string Answer { get; set; } = string.Empty;
    public int SortOrder { get; set; }
}

/// <summary>Category grid row and save payload — one shape, since the form is small.</summary>
public class CategorySaveRequest
{
    public int Id { get; set; }
    public int? ParentId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }

    /// <summary>80–150 words shown above or below the PLP grid, editorially controlled.</summary>
    public string? IntroCopy { get; set; }

    public string? ImageUrl { get; set; }
    public string? IconName { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public bool ShowInMegaMenu { get; set; } = true;
    public bool IsFeaturedOnHome { get; set; }
    public SeoViewModel Seo { get; set; } = new();
}

/// <summary>Artisan profile. Written in Admin, rendered as a first-class storefront page.</summary>
public class ArtisanSaveRequest
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string Craft { get; set; } = string.Empty;
    public string Cluster { get; set; } = string.Empty;
    public string? Story { get; set; }
    public string? PhotoUrl { get; set; }
    public string? CoverUrl { get; set; }
    public string? VideoUrl { get; set; }
    public int? WorkingSinceYear { get; set; }
    public int? PartnerSinceYear { get; set; }
    public int? ApprenticesTrained { get; set; }
    public bool IsGiTagged { get; set; }
    public bool IsActive { get; set; } = true;
    public SeoViewModel Seo { get; set; } = new();
}

/// <summary>Inventory row. The only source the storefront may quote stock from.</summary>
public class StockGridItem
{
    public int ProductId { get; set; }
    public int? VariantId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public string? WarehouseName { get; set; }
    public int OnHand { get; set; }

    /// <summary>Held by carts and unshipped orders — not available to sell.</summary>
    public int Reserved { get; set; }

    public int Available => Math.Max(0, OnHand - Reserved);
    public int LowStockThreshold { get; set; } = 5;

    /// <summary>What the storefront stock indicator will render for this row.</summary>
    public StockState State => Available <= 0
        ? StockState.OutOfStock
        : Available <= LowStockThreshold ? StockState.LowStock : StockState.InStock;
}
