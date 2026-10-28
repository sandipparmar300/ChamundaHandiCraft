using System.Data;
using Catalog.Domain.IServices;
using ChamundaHandicraft.Helper.CommonMethod;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Dapper;
using Microsoft.Data.SqlClient;

namespace Catalog.Infrastructure.Repositories;

public class CustomerProductRepository : ICustomerProductRepository
{
    private readonly string _connectionString;

    public CustomerProductRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<ProductListingViewModel> GetListingAsync(
        string? categorySlug,
        string? subCategorySlug,
        string? search,
        decimal? minPrice,
        decimal? maxPrice,
        string? material,
        string? craft,
        bool? inStockOnly,
        int? rating,
        string? sort,
        int page,
        int pageSize,
        CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@CategorySlug", string.IsNullOrWhiteSpace(categorySlug) ? null : categorySlug);
        parameters.Add("@SubCategorySlug", string.IsNullOrWhiteSpace(subCategorySlug) ? null : subCategorySlug);
        parameters.Add("@SearchQuery", string.IsNullOrWhiteSpace(search) ? null : search);
        parameters.Add("@MinPrice", minPrice);
        parameters.Add("@MaxPrice", maxPrice);
        parameters.Add("@Material", string.IsNullOrWhiteSpace(material) ? null : material);
        parameters.Add("@Craft", string.IsNullOrWhiteSpace(craft) ? null : craft);
        parameters.Add("@InStockOnly", inStockOnly);
        parameters.Add("@Rating", rating);
        parameters.Add("@Sort", string.IsNullOrWhiteSpace(sort) ? "popularity" : sort);
        parameters.Add("@Page", page <= 0 ? 1 : page);
        parameters.Add("@PageSize", pageSize <= 0 ? 20 : pageSize);

        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Product_CustomerListing",
            parameters,
            commandType: CommandType.StoredProcedure);

        // Result Set 1: Products
        var rawProducts = (await multi.ReadAsync<CustomerProductListingRow>()).AsList();

        // Result Set 2: Aggregate Statistics
        var totals = await multi.ReadFirstOrDefaultAsync<ListingTotalsRow>() ?? new ListingTotalsRow();

        // Result Set 3: Category Facets
        var categoryFacets = (await multi.ReadAsync<CategoryFacetRow>()).AsList();

        // Result Set 4: Material Facets
        var materialFacets = (await multi.ReadAsync<MaterialFacetRow>()).AsList();

        var productCards = rawProducts.Select(MapToCard).ToList();

        // Build Facet Groups
        var facets = new List<FacetGroupViewModel>();

        if (categoryFacets.Count > 0)
        {
            var selectedSlugs = (categorySlug ?? "")
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

            facets.Add(new FacetGroupViewModel
            {
                Key = "category",
                Label = "Categories",
                Type = "Checkbox",
                IsExpandedByDefault = true,
                Values = categoryFacets.Select(c => new FacetValueViewModel
                {
                    Value = c.CategorySlug,
                    Label = c.CategoryName,
                    Count = c.ProductCount,
                    IsSelected = selectedSlugs.Contains(c.CategorySlug, StringComparer.OrdinalIgnoreCase)
                }).ToList()
            });
        }

        if (materialFacets.Count > 0)
        {
            facets.Add(new FacetGroupViewModel
            {
                Key = "material",
                Label = "Material",
                Type = "Checkbox",
                IsExpandedByDefault = true,
                Values = materialFacets.Select(m => new FacetValueViewModel
                {
                    Value = m.Material,
                    Label = m.Material,
                    Count = m.ProductCount,
                    IsSelected = string.Equals(m.Material, material, StringComparison.OrdinalIgnoreCase)
                }).ToList()
            });
        }

        // Determine Page Heading and Intro
        string heading = "All Handcrafted Collections";
        string intro = "Everything we stock, bought direct from named Indian master artisans across verified craft clusters.";

        if (!string.IsNullOrWhiteSpace(categorySlug))
        {
            var matchedCat = categoryFacets.FirstOrDefault(c => string.Equals(c.CategorySlug, categorySlug, StringComparison.OrdinalIgnoreCase));
            heading = matchedCat != null ? matchedCat.CategoryName : Titleise(categorySlug);
            intro = $"Authentic handcrafted {heading.ToLowerInvariant()} bought direct from Indian artisans. Free delivery above ₹999.";
        }
        else if (!string.IsNullOrWhiteSpace(search))
        {
            heading = $"Search results for “{search}”";
            intro = $"Showing handcrafted pieces matching “{search}”.";
        }

        var breadcrumbs = new List<BreadcrumbItem>
        {
            new() { Label = "Home", Url = "/" },
            new() { Label = "Shop", Url = "/shop" }
        };

        if (!string.IsNullOrWhiteSpace(categorySlug))
        {
            breadcrumbs.Add(new() { Label = heading, Url = $"/c/{categorySlug}" });
        }

        return new ProductListingViewModel
        {
            Heading = heading,
            IntroCopy = intro,
            CategorySlug = categorySlug,
            Query = search,
            Sort = sort ?? "popularity",
            View = "grid",
            Products = new PagedResult<ProductCardViewModel>
            {
                Items = productCards,
                TotalCount = totals.TotalCount,
                Page = page <= 0 ? 1 : page,
                PageSize = pageSize <= 0 ? 20 : pageSize
            },
            Facets = facets,
            SubCategories = categoryFacets.Select(c => new CategoryViewModel
            {
                Id = c.CategoryId,
                Name = c.CategoryName,
                Slug = c.CategorySlug,
                ProductCount = c.ProductCount
            }).ToList(),
            Breadcrumbs = breadcrumbs,
            Seo = new SeoViewModel
            {
                MetaTitle = $"{heading} | Chamunda Handicraft",
                MetaDescription = intro
            }
        };
    }

    public async Task<ProductDetailViewModel?> GetDetailAsync(string slug, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Slug", slug);

        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Product_CustomerDetail",
            parameters,
            commandType: CommandType.StoredProcedure);

        // Result Set 1: Product Main
        var raw = await multi.ReadFirstOrDefaultAsync<CustomerProductDetailRow>();
        if (raw == null) return null;

        // Result Set 2: Gallery Media
        var mediaRows = (await multi.ReadAsync<CustomerMediaRow>()).AsList();

        // Result Set 3: Variants
        var variantRows = (await multi.ReadAsync<CustomerVariantRow>()).AsList();

        // Result Set 4: Specifications
        var specRows = (await multi.ReadAsync<CustomerSpecRow>()).AsList();

        // Result Set 5: Reviews
        var reviewRows = (await multi.ReadAsync<CustomerReviewRow>()).AsList();

        // Result Set 6: Related
        var relatedRows = (await multi.ReadAsync<CustomerProductListingRow>()).AsList();

        var card = MapDetailToCard(raw);

        var media = mediaRows.Select(m => new MediaViewModel
        {
            Id = m.Id,
            Url = m.Url,
            ThumbnailUrl = m.ThumbnailUrl,
            AltText = m.AltText ?? string.Empty,
            MediaType = m.MediaType == "Video" ? ProductMediaType.Video : (m.MediaType == "360" ? ProductMediaType.Spin360 : ProductMediaType.Image),
            IsPrimary = m.IsPrimary,
            SortOrder = m.SortOrder
        }).ToList();

        if (media.Count == 0 && !string.IsNullOrWhiteSpace(raw.ImageUrl))
        {
            media.Add(new MediaViewModel
            {
                Url = raw.ImageUrl,
                AltText = raw.ImageAlt ?? raw.Name ?? string.Empty,
                IsPrimary = true
            });
        }

        var variants = variantRows.Select(v => new ProductVariantViewModel
        {
            Id = v.Id,
            Sku = v.Sku,
            VariantSummary = v.VariantSummary,
            Price = v.Price,
            Mrp = v.Mrp,
            Stock = (StockState)v.StockState,
            StockCount = v.StockCount <= 5 ? v.StockCount : null
        }).ToList();

        var specGroups = specRows
            .GroupBy(s => s.GroupTitle)
            .Select(g => new SpecificationGroup
            {
                Title = g.Key,
                Rows = g.Select(r => new SpecificationRow
                {
                    Key = r.SpecKey,
                    Value = r.SpecValue,
                    HelpText = r.HelpText
                }).ToList()
            }).ToList();

        var reviews = new ReviewSummaryViewModel
        {
            AverageRating = raw.Rating,
            TotalCount = raw.ReviewCount,
            Recent = reviewRows.Select(r => new ReviewViewModel
            {
                Id = r.Id,
                Author = r.AuthorName,
                Rating = r.Rating,
                Title = r.Title,
                Body = r.Body,
                VerifiedPurchase = r.IsVerifiedPurchase,
                PostedOn = r.SubmittedOn
            }).ToList()
        };

        var breadcrumbs = new List<BreadcrumbItem>
        {
            new() { Label = "Home", Url = "/" },
            new() { Label = "Shop", Url = "/shop" }
        };

        if (!string.IsNullOrWhiteSpace(raw.CategorySlug))
        {
            breadcrumbs.Add(new() { Label = raw.CategoryName, Url = $"/c/{raw.CategorySlug}" });
        }

        if (!string.IsNullOrWhiteSpace(raw.SubCategorySlug))
        {
            breadcrumbs.Add(new() { Label = raw.SubCategoryName ?? "", Url = $"/c/{raw.CategorySlug}/{raw.SubCategorySlug}" });
        }

        breadcrumbs.Add(new() { Label = raw.Name ?? string.Empty, Url = $"/p/{raw.Slug}" });

        return new ProductDetailViewModel
        {
            Card = card,
            FullDescription = !string.IsNullOrWhiteSpace(raw.FullDescription) ? raw.FullDescription : (raw.ShortDescription ?? string.Empty),
            CraftStory = !string.IsNullOrWhiteSpace(raw.ProductStory) ? raw.ProductStory : raw.ArtisanStory,
            CareInstructions = raw.CareInstructions,
            Media = media,
            Variants = variants,
            Specifications = specGroups,
            Reviews = reviews,
            RelatedProducts = relatedRows.Select(MapToCard).ToList(),
            Delivery = new DeliveryEstimateViewModel
            {
                IsServiceable = true,
                DeliverBy = DateTime.Today.AddDays(4),
                DeliverByLatest = DateTime.Today.AddDays(7),
                CourierName = "Delhivery Express",
                CodAvailable = true,
                ShippingCost = raw.Price >= 999 ? 0 : 99
            },
            SoldLastSevenDays = raw.SoldCount > 0 ? raw.SoldCount : null,
            Breadcrumbs = breadcrumbs,
            Seo = new SeoViewModel
            {
                MetaTitle = $"{raw.Name} | Chamunda Handicraft",
                MetaDescription = raw.ShortDescription
            }
        };
    }

    public async Task<List<ProductCardViewModel>> GetRailAsync(string railKey, string? contextSlug, int count, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@RailKey", railKey);
        parameters.Add("@ContextSlug", contextSlug);
        parameters.Add("@Count", count <= 0 ? 8 : count);

        var rows = (await connection.QueryAsync<CustomerProductListingRow>(
            "dbo.usp_Product_CustomerRail",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        return rows.Select(MapToCard).ToList();
    }

    public async Task<ProductSearchResultViewModel> SearchAsync(string query, int limit, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Query", query);
        parameters.Add("@Limit", limit <= 0 ? 8 : limit);

        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Product_CustomerSearch",
            parameters,
            commandType: CommandType.StoredProcedure);

        var productRows = (await multi.ReadAsync<CustomerProductListingRow>()).AsList();
        var categoryRows = (await multi.ReadAsync<CategoryFacetRow>()).AsList();

        var products = productRows.Select(MapToCard).ToList();
        var categories = categoryRows.Select(c => new CategoryViewModel
        {
            Id = c.CategoryId,
            Name = c.CategoryName,
            Slug = c.CategorySlug,
            ProductCount = c.ProductCount
        }).ToList();

        return new ProductSearchResultViewModel
        {
            Products = products,
            Categories = categories
        };
    }

    private static ProductCardViewModel MapToCard(CustomerProductListingRow row)
    {
        var badges = new List<ProductBadge>();
        if (row.DiscountPercent > 0) badges.Add(ProductBadge.Sale);
        if (row.IsBestseller) badges.Add(ProductBadge.Bestseller);
        if (row.IsFeatured && badges.Count < 2) badges.Add(ProductBadge.New);
        if (row.IsHandmade && badges.Count < 2) badges.Add(ProductBadge.Handmade);

        return new ProductCardViewModel
        {
            Id = row.Id,
            Slug = row.Slug,
            Name = row.Name,
            Sku = row.Sku,
            CategoryName = row.CategoryName,
            CategorySlug = row.CategorySlug,
            Price = row.Price,
            Mrp = row.Mrp,
            Rating = row.Rating,
            ReviewCount = row.ReviewCount,
            ImageUrl = row.ImageUrl,
            HoverImageUrl = row.HoverImageUrl,
            ImageAlt = row.ImageAlt ?? row.Name,
            ShortDescription = row.ShortDescription ?? string.Empty,
            Material = row.Material ?? "Handcrafted",
            Dimensions = row.Dimensions ?? "Standard Size",
            Stock = (StockState)row.StockState,
            StockCount = row.StockCount <= 5 ? row.StockCount : null,
            IsHandmade = row.IsHandmade,
            Badges = badges.Take(2).ToList(),
            Artisan = row.ArtisanId.HasValue ? new ArtisanSummary
            {
                Id = row.ArtisanId.Value,
                Name = row.ArtisanName ?? string.Empty,
                Slug = row.ArtisanSlug ?? string.Empty,
                Craft = row.ArtisanCraft ?? string.Empty,
                Cluster = row.ArtisanCluster ?? string.Empty,
                PhotoUrl = row.ArtisanPhotoUrl ?? string.Empty
            } : null
        };
    }

    private static ProductCardViewModel MapDetailToCard(CustomerProductDetailRow row)
    {
        var badges = new List<ProductBadge>();
        if (row.DiscountPercent > 0) badges.Add(ProductBadge.Sale);
        if (row.IsBestseller) badges.Add(ProductBadge.Bestseller);
        if (row.IsFeatured && badges.Count < 2) badges.Add(ProductBadge.New);
        if (row.IsHandmade && badges.Count < 2) badges.Add(ProductBadge.Handmade);

        return new ProductCardViewModel
        {
            Id = row.Id,
            Slug = row.Slug,
            Name = row.Name,
            Sku = row.Sku,
            CategoryName = row.CategoryName,
            CategorySlug = row.CategorySlug,
            Price = row.Price,
            Mrp = row.Mrp,
            Rating = row.Rating,
            ReviewCount = row.ReviewCount,
            ImageUrl = row.ImageUrl,
            HoverImageUrl = row.HoverImageUrl,
            ImageAlt = row.ImageAlt ?? row.Name,
            ShortDescription = row.ShortDescription ?? string.Empty,
            Material = row.Material ?? "Handcrafted",
            Dimensions = row.Dimensions ?? "Standard Size",
            Stock = (StockState)row.StockState,
            StockCount = row.StockCount <= 5 ? row.StockCount : null,
            IsHandmade = row.IsHandmade,
            Badges = badges.Take(2).ToList(),
            Artisan = row.ArtisanId.HasValue ? new ArtisanSummary
            {
                Id = row.ArtisanId.Value,
                Name = row.ArtisanName ?? string.Empty,
                Slug = row.ArtisanSlug ?? string.Empty,
                Craft = row.ArtisanCraft ?? string.Empty,
                Cluster = row.ArtisanCluster ?? string.Empty,
                PhotoUrl = row.ArtisanPhotoUrl ?? string.Empty
            } : null
        };
    }

    private static string Titleise(string slug) =>
        string.Join(' ', slug.Split('-')
            .Select(w => w.Length switch
            {
                0 => w,
                _ => char.ToUpperInvariant(w[0]) + w[1..]
            }));

    #region Dapper Row DTOs

    private class CustomerProductListingRow
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Slug { get; set; } = string.Empty;
        public string Sku { get; set; } = string.Empty;
        public int? CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public string CategorySlug { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public decimal? Mrp { get; set; }
        public int DiscountPercent { get; set; }
        public decimal Rating { get; set; }
        public int ReviewCount { get; set; }
        public bool IsFeatured { get; set; }
        public bool IsBestseller { get; set; }
        public bool IsTrending { get; set; }
        public bool IsHandmade { get; set; }
        public string? ShortDescription { get; set; }
        public string? Material { get; set; }
        public string? Dimensions { get; set; }
        public int StockCount { get; set; }
        public int StockState { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public string? HoverImageUrl { get; set; }
        public string? ImageAlt { get; set; }
        public int? ArtisanId { get; set; }
        public string? ArtisanName { get; set; }
        public string? ArtisanSlug { get; set; }
        public string? ArtisanCraft { get; set; }
        public string? ArtisanCluster { get; set; }
        public string? ArtisanPhotoUrl { get; set; }
        public DateTime CreatedAt { get; set; }
        public int? SoldCount { get; set; }
        public int? ViewCount { get; set; }
    }

    private class CustomerProductDetailRow : CustomerProductListingRow
    {
        public string? ProductCode { get; set; }
        public string? Barcode { get; set; }
        public int? SubCategoryId { get; set; }
        public string? SubCategoryName { get; set; }
        public string? SubCategorySlug { get; set; }
        public string? FullDescription { get; set; }
        public string? ProductStory { get; set; }
        public string? CareInstructions { get; set; }
        public string? WarrantyInformation { get; set; }
        public string? VideoUrl { get; set; }
        public string? CraftTechnique { get; set; }
        public string? OriginCluster { get; set; }
        public decimal? LengthCm { get; set; }
        public decimal? WidthCm { get; set; }
        public decimal? HeightCm { get; set; }
        public decimal? WeightGrams { get; set; }
        public bool HasVariants { get; set; }
        public string? ArtisanStory { get; set; }
        public int? BrandId { get; set; }
        public string? BrandName { get; set; }
        public string? BrandSlug { get; set; }
    }

    private class ListingTotalsRow
    {
        public int TotalCount { get; set; }
        public decimal MinPrice { get; set; }
        public decimal MaxPrice { get; set; }
    }

    private class CategoryFacetRow
    {
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public string CategorySlug { get; set; } = string.Empty;
        public int ProductCount { get; set; }
    }

    private class MaterialFacetRow
    {
        public string Material { get; set; } = string.Empty;
        public int ProductCount { get; set; }
    }

    private class CustomerMediaRow
    {
        public int Id { get; set; }
        public string Url { get; set; } = string.Empty;
        public string? ThumbnailUrl { get; set; }
        public string? AltText { get; set; }
        public string? MediaType { get; set; }
        public bool IsPrimary { get; set; }
        public int SortOrder { get; set; }
    }

    private class CustomerVariantRow
    {
        public int Id { get; set; }
        public string Sku { get; set; } = string.Empty;
        public string VariantSummary { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public decimal? Mrp { get; set; }
        public decimal? WeightGrams { get; set; }
        public string? ImageUrl { get; set; }
        public bool IsDefault { get; set; }
        public int SortOrder { get; set; }
        public int StockCount { get; set; }
        public int StockState { get; set; }
    }

    private class CustomerSpecRow
    {
        public string GroupTitle { get; set; } = string.Empty;
        public string SpecKey { get; set; } = string.Empty;
        public string SpecValue { get; set; } = string.Empty;
        public string? HelpText { get; set; }
        public int SortOrder { get; set; }
    }

    private class CustomerReviewRow
    {
        public int Id { get; set; }
        public string AuthorName { get; set; } = string.Empty;
        public int Rating { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public bool IsVerifiedPurchase { get; set; }
        public DateTime SubmittedOn { get; set; }
    }

    #endregion
}
