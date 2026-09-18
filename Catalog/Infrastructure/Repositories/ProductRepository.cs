using System.Data;
using System.Text.Json;
using Catalog.Domain.IServices;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Microsoft.Data.SqlClient;

namespace Catalog.Infrastructure.Repositories;

public class ProductRepository : IProductRepository
{
    private readonly string _connectionString;

    public ProductRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<ProductGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchText", request.Search);
        parameters.Add("@SortColumn", string.IsNullOrWhiteSpace(request.SortBy) ? "CreatedAt" : request.SortBy);
        parameters.Add("@SortOrder", request.SortDescending ? "DESC" : "ASC");
        parameters.Add("@PageSize", request.PageSize <= 0 ? 25 : request.PageSize);
        parameters.Add("@PageIndex", request.Page <= 0 ? 1 : request.Page);
        parameters.Add("@TotalRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@TotalFilteredRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await connection.QueryAsync<ProductGridItem>(
            "dbo.usp_Product_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        int total = parameters.Get<int>("@TotalRecords");
        int totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        foreach (var p in items)
        {
            p.IsLiveOnStorefront = p.Status == ProductStatus.Published;
            p.StorefrontUrl = $"/p/{p.Slug}";
        }

        return new PagedResult<ProductGridItem>
        {
            Items = items,
            TotalCount = totalFiltered,
            Page = request.Page <= 0 ? 1 : request.Page,
            PageSize = request.PageSize <= 0 ? 25 : request.PageSize
        };
    }

    public async Task<ProductSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Product_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        var product = await multi.ReadFirstOrDefaultAsync<ProductSaveRequest>();
        if (product is null) return null;

        var media = (await multi.ReadAsync<MediaViewModel>()).AsList();
        product.Media = media;

        var variants = (await multi.ReadAsync<ProductVariantSaveRequest>()).AsList();
        product.Variants = variants;

        // Result set 4: Related Products
        var relations = (await multi.ReadAsync<ProductRelationItem>()).AsList();
        product.ComplementaryProductIds = relations
            .Where(r => string.Equals(r.RelationType, "Complementary", StringComparison.OrdinalIgnoreCase))
            .Select(r => r.RelatedProductId)
            .ToList();
        product.SimilarProductIds = relations
            .Where(r => string.Equals(r.RelationType, "Alternative", StringComparison.OrdinalIgnoreCase))
            .Select(r => r.RelatedProductId)
            .ToList();

        // Result set 5: SEO
        var seo = await multi.ReadFirstOrDefaultAsync<SeoViewModel>();
        product.Seo = seo ?? new SeoViewModel();

        return product;
    }

    public async Task<int> SaveAsync(ProductSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();

        var mediaJson = request.Media is { Count: > 0 }
            ? JsonSerializer.Serialize(request.Media)
            : null;

        var variantsJson = request.Variants is { Count: > 0 }
            ? JsonSerializer.Serialize(request.Variants)
            : null;

        var relationsList = new List<object>();
        if (request.ComplementaryProductIds is { Count: > 0 })
        {
            for (int i = 0; i < request.ComplementaryProductIds.Count; i++)
            {
                relationsList.Add(new
                {
                    RelatedProductId = request.ComplementaryProductIds[i],
                    RelationType = "Complementary",
                    SortOrder = i
                });
            }
        }
        if (request.SimilarProductIds is { Count: > 0 })
        {
            for (int i = 0; i < request.SimilarProductIds.Count; i++)
            {
                relationsList.Add(new
                {
                    RelatedProductId = request.SimilarProductIds[i],
                    RelationType = "Alternative",
                    SortOrder = i
                });
            }
        }

        var relatedJson = relationsList.Count > 0
            ? JsonSerializer.Serialize(relationsList)
            : null;

        return await connection.ExecuteScalarAsync<int>(
            "dbo.usp_Product_Save",
            new
            {
                request.Id,
                request.Name,
                request.ProductCode,
                request.Sku,
                request.Barcode,
                request.Slug,
                request.ShortDescription,
                request.FullDescription,
                request.ProductStory,
                request.CareInstructions,
                request.WarrantyInformation,
                request.VideoUrl,
                request.CategoryId,
                request.SubCategoryId,
                request.CollectionId,
                request.BrandId,
                request.ArtisanId,
                request.Material,
                request.CraftTechnique,
                request.OriginCluster,
                request.Price,
                request.Mrp,
                request.CostPrice,
                request.TaxClassId,
                request.IsTaxInclusive,
                request.LengthCm,
                request.WidthCm,
                request.HeightCm,
                request.WeightGrams,
                request.TrackInventory,
                request.LowStockThreshold,
                request.MaxQuantityPerOrder,
                request.AllowBackorder,
                request.IsMadeToOrder,
                request.MadeToOrderDays,
                HasVariants = request.HasVariants || (request.Variants is { Count: > 0 }),
                Status = (byte)request.Status,
                Visibility = (byte)request.Visibility,
                request.IsFeatured,
                request.IsBestseller,
                request.IsTrending,
                IsHandmade = true,
                request.PublishOn,
                IsActive = true,
                request.StockQuantity,
                request.Seo?.MetaTitle,
                request.Seo?.MetaDescription,
                request.Seo?.MetaKeywords,
                request.Seo?.CanonicalUrl,
                request.Seo?.OgTitle,
                MediaJson = mediaJson,
                VariantsJson = variantsJson,
                RelatedJson = relatedJson,
                AdminUserId = adminUserId,
                WarehouseId = request.WarehouseId
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Product_Delete",
            new { Id = id, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateStatusAsync(int id, byte status, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Product_UpdateStatus",
            new { Id = id, Status = status, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<ProductLookupsViewModel> GetLookupsAsync(CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Product_GetLookups",
            commandType: CommandType.StoredProcedure);

        var lookups = new ProductLookupsViewModel
        {
            Categories = (await multi.ReadAsync<IdNamePair>()).AsList(),
            Brands = (await multi.ReadAsync<IdNamePair>()).AsList(),
            Artisans = (await multi.ReadAsync<IdNamePair>()).AsList(),
            TaxClasses = (await multi.ReadAsync<IdNamePair>()).AsList(),
            Attributes = (await multi.ReadAsync<IdNamePair>()).AsList(),
            Products = (await multi.ReadAsync<IdNamePair>()).AsList()
        };

        return lookups;
    }

    public async Task<List<IdNamePair>> GetLookupAsync(CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var sql = @"SELECT Id, CONCAT(Name, ' (', ISNULL(Sku, 'No SKU'), ')') AS Name 
                    FROM dbo.Products 
                    WHERE IsDeleted = 0 
                    ORDER BY Name";
        var items = await connection.QueryAsync<IdNamePair>(sql);
        return items.AsList();
    }

    public async Task<List<IdNamePair>> GetVariantsLookupAsync(int? productId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var sql = @"SELECT Id, ProductId AS ParentId, CONCAT(ISNULL(VariantSummary, Sku), ' (', Sku, ')') AS Name 
                    FROM dbo.ProductVariants 
                    WHERE IsDeleted = 0 
                      AND (@ProductId IS NULL OR ProductId = @ProductId)
                    ORDER BY Id";
        var items = await connection.QueryAsync<IdNamePair>(sql, new { ProductId = productId });
        return items.AsList();
    }
}
