/* =============================================================================
   usp_Product_CustomerProcedures.sql
   -----------------------------------------------------------------------------
   Customer Storefront Stored Procedures for Priority 2:
     1. dbo.usp_Product_CustomerListing  - PLP & Category Filtered/Paged Grid + Facets
     2. dbo.usp_Product_CustomerDetail   - PDP Detailed Product with Media, Specs, Reviews
     3. dbo.usp_Product_CustomerRail     - Rails (New Arrivals, Bestsellers, Trending, Related)
     4. dbo.usp_Product_CustomerSearch   - Search Suggestions & Autocomplete
   ============================================================================= */

SET NOCOUNT ON;
GO

-- 1. Customer Listing (PLP, Category Filter, Facets, Paging, Sorting)
CREATE OR ALTER PROCEDURE dbo.usp_Product_CustomerListing
    @CategorySlug    VARCHAR(500)   = NULL,
    @SubCategorySlug VARCHAR(500)   = NULL,
    @SearchQuery     NVARCHAR(200)  = NULL,
    @MinPrice        DECIMAL(18,2)  = NULL,
    @MaxPrice        DECIMAL(18,2)  = NULL,
    @Material        NVARCHAR(100)  = NULL,
    @Craft           NVARCHAR(100)  = NULL,
    @InStockOnly     BIT            = NULL,
    @Rating          INT            = NULL,
    @Sort            NVARCHAR(50)   = 'popularity',
    @Page            INT            = 1,
    @PageSize        INT            = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page < 1 SET @Page = 1;
    IF @PageSize < 1 SET @PageSize = 20;
    IF @PageSize > 100 SET @PageSize = 100;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    -- Resolve Category IDs (supports comma-separated list of slugs, e.g. 'wooden-handicrafts,brass-and-metalware')
    DECLARE @SelectedCategoryIds TABLE (Id INT);
    IF @CategorySlug IS NOT NULL AND @CategorySlug <> ''
    BEGIN
        INSERT INTO @SelectedCategoryIds (Id)
        SELECT c.Id 
        FROM dbo.Categories c
        CROSS APPLY STRING_SPLIT(@CategorySlug, ',') s
        WHERE c.IsDeleted = 0
          AND (c.Slug = LTRIM(RTRIM(s.value)) OR CAST(c.Id AS VARCHAR) = LTRIM(RTRIM(s.value)));
    END

    DECLARE @SelectedSubCategoryIds TABLE (Id INT);
    IF @SubCategorySlug IS NOT NULL AND @SubCategorySlug <> ''
    BEGIN
        INSERT INTO @SelectedSubCategoryIds (Id)
        SELECT c.Id 
        FROM dbo.Categories c
        CROSS APPLY STRING_SPLIT(@SubCategorySlug, ',') s
        WHERE c.IsDeleted = 0
          AND (c.Slug = LTRIM(RTRIM(s.value)) OR CAST(c.Id AS VARCHAR) = LTRIM(RTRIM(s.value)));
    END

    -- Clean search query
    SET @SearchQuery = LTRIM(RTRIM(@SearchQuery));
    IF @SearchQuery = '' SET @SearchQuery = NULL;

    -- Base filtered products temporary table
    IF OBJECT_ID('tempdb..#FilteredBase') IS NOT NULL DROP TABLE #FilteredBase;

    SELECT  p.Id,
            p.Name,
            p.Slug,
            p.Sku,
            p.CategoryId,
            CategoryName = ISNULL(c.Name, 'General'),
            CategorySlug = ISNULL(c.Slug, 'all'),
            p.Price,
            p.Mrp,
            DiscountPercent = CASE 
                WHEN p.Mrp > 0 AND p.Mrp > p.Price THEN CAST(ROUND(((p.Mrp - p.Price) * 100.0) / p.Mrp, 0) AS INT)
                ELSE 0 
            END,
            Rating = ISNULL(p.AverageRating, 4.5),
            ReviewCount = ISNULL(p.ReviewCount, 0),
            p.IsFeatured,
            p.IsBestseller,
            p.IsTrending,
            p.IsHandmade,
            p.ShortDescription,
            Material = ISNULL(p.Material, N'Handcrafted Material'),
            Dimensions = CASE 
                WHEN p.LengthCm IS NOT NULL AND p.WidthCm IS NOT NULL AND p.HeightCm IS NOT NULL
                    THEN CAST(CAST(p.LengthCm AS INT) AS VARCHAR) + ' x ' + CAST(CAST(p.WidthCm AS INT) AS VARCHAR) + ' x ' + CAST(CAST(p.HeightCm AS INT) AS VARCHAR) + ' cm'
                ELSE N'Standard Artisan Size'
            END,
            StockCount = ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0), 10),
            StockState = CASE 
                WHEN ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0), 10) <= 0 THEN 2 -- OutOfStock
                WHEN ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0), 10) <= ISNULL(p.LowStockThreshold, 5) THEN 1 -- LowStock
                ELSE 0 -- InStock
            END,
            -- Primary image
            ImageUrl = ISNULL(
                (SELECT TOP 1 m.Url FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 ORDER BY m.IsPrimary DESC, m.SortOrder ASC, m.Id ASC),
                CASE 
                    WHEN c.Slug LIKE '%brass%' THEN '/assets/images/placeholders/brass.svg'
                    WHEN c.Slug LIKE '%wood%' THEN '/assets/images/placeholders/wood.svg'
                    WHEN c.Slug LIKE '%textile%' THEN '/assets/images/placeholders/textile.svg'
                    WHEN c.Slug LIKE '%clay%' OR c.Slug LIKE '%terracotta%' THEN '/assets/images/placeholders/pottery.svg'
                    ELSE '/assets/images/placeholders/decor.svg'
                END
            ),
            HoverImageUrl = (SELECT TOP 1 m.Url FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 AND m.IsPrimary = 0 ORDER BY m.SortOrder ASC, m.Id ASC),
            ImageAlt = ISNULL((SELECT TOP 1 m.AltText FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 ORDER BY m.IsPrimary DESC, m.SortOrder ASC, m.Id ASC), p.Name),
            -- Artisan info
            ArtisanId = a.Id,
            ArtisanName = a.Name,
            ArtisanSlug = a.Slug,
            ArtisanCraft = a.Craft,
            ArtisanCluster = a.Cluster,
            ArtisanPhotoUrl = a.PhotoUrl,
            p.CreatedAt,
            p.SoldCount,
            p.ViewCount
    INTO    #FilteredBase
    FROM    dbo.Products AS p
    LEFT JOIN dbo.Categories AS c ON c.Id = p.CategoryId
    LEFT JOIN dbo.Artisans   AS a ON a.Id = p.ArtisanId
    WHERE   p.IsActive = 1
      AND   p.IsDeleted = 0
      AND   (
                NOT EXISTS (SELECT 1 FROM @SelectedCategoryIds)
                OR p.CategoryId IN (SELECT Id FROM @SelectedCategoryIds)
                OR c.ParentId IN (SELECT Id FROM @SelectedCategoryIds)
            )
      AND   (
                NOT EXISTS (SELECT 1 FROM @SelectedSubCategoryIds)
                OR p.SubCategoryId IN (SELECT Id FROM @SelectedSubCategoryIds)
            )
      AND   (@SearchQuery IS NULL OR p.Name LIKE '%' + @SearchQuery + '%' OR p.ShortDescription LIKE '%' + @SearchQuery + '%' OR p.Sku LIKE '%' + @SearchQuery + '%' OR c.Name LIKE '%' + @SearchQuery + '%' OR a.Name LIKE '%' + @SearchQuery + '%')
      AND   (@MinPrice IS NULL OR p.Price >= @MinPrice)
      AND   (@MaxPrice IS NULL OR p.Price <= @MaxPrice)
      AND   (@Material IS NULL OR p.Material LIKE '%' + @Material + '%')
      AND   (@Craft IS NULL OR p.CraftTechnique LIKE '%' + @Craft + '%' OR a.Craft LIKE '%' + @Craft + '%')
      AND   (@Rating IS NULL OR p.AverageRating >= @Rating);

    -- Result Set 1: Paginated Products
    SELECT  b.*
    FROM    #FilteredBase b
    WHERE   (@InStockOnly IS NULL OR @InStockOnly = 0 OR b.StockState <> 2)
    ORDER BY 
        CASE WHEN @Sort = 'price-asc'   THEN b.Price END ASC,
        CASE WHEN @Sort = 'price-desc'  THEN b.Price END DESC,
        CASE WHEN @Sort = 'discount'    THEN b.DiscountPercent END DESC,
        CASE WHEN @Sort = 'rating'      THEN b.Rating END DESC,
        CASE WHEN @Sort = 'latest'      THEN b.CreatedAt END DESC,
        CASE WHEN @Sort = 'bestselling' THEN ISNULL(b.SoldCount, 0) END DESC,
        -- Default: popularity
        ISNULL(b.ViewCount, 0) DESC, b.Rating DESC, b.Id DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;

    -- Result Set 2: Aggregate Statistics (TotalCount, MinPrice, MaxPrice)
    SELECT  TotalCount = COUNT(*),
            MinPrice   = ISNULL(MIN(Price), 0),
            MaxPrice   = ISNULL(MAX(Price), 0)
    FROM    #FilteredBase
    WHERE   (@InStockOnly IS NULL OR @InStockOnly = 0 OR StockState <> 2);

    -- Result Set 3: Category Facet Breakdown (All active root categories with product counts)
    SELECT  CategoryId = c.Id,
            CategoryName = c.Name,
            CategorySlug = c.Slug,
            ProductCount = COUNT(p.Id)
    FROM    dbo.Categories c
    LEFT JOIN dbo.Products p ON (p.CategoryId = c.Id OR p.SubCategoryId = c.Id) AND p.IsActive = 1 AND p.IsDeleted = 0
    WHERE   c.IsActive = 1 AND c.IsDeleted = 0
      AND   c.ParentId IS NULL
    GROUP BY c.Id, c.Name, c.Slug, c.SortOrder
    ORDER BY c.SortOrder ASC, c.Name ASC;

    -- Result Set 4: Material Facet Breakdown
    SELECT  Material = ISNULL(NULLIF(LTRIM(RTRIM(p.Material)), ''), 'Handcrafted'),
            ProductCount = COUNT(*)
    FROM    dbo.Products p
    WHERE   p.IsActive = 1 AND p.IsDeleted = 0
      AND   p.Material IS NOT NULL AND LTRIM(RTRIM(p.Material)) <> ''
    GROUP BY LTRIM(RTRIM(p.Material))
    ORDER BY COUNT(*) DESC;
END
GO

-- 2. Customer Product Detail (PDP)
CREATE OR ALTER PROCEDURE dbo.usp_Product_CustomerDetail
    @Slug VARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductId INT = NULL;

    SELECT TOP 1 @ProductId = Id
    FROM dbo.Products
    WHERE Slug = @Slug AND IsActive = 1 AND IsDeleted = 0;

    IF @ProductId IS NULL
    BEGIN
        -- Try matching SKU or Code as fallback
        SELECT TOP 1 @ProductId = Id
        FROM dbo.Products
        WHERE (Sku = @Slug OR ProductCode = @Slug) AND IsActive = 1 AND IsDeleted = 0;
    END

    IF @ProductId IS NULL
    BEGIN
        RETURN;
    END

    -- Update View Count
    UPDATE dbo.Products SET ViewCount = ISNULL(ViewCount, 0) + 1 WHERE Id = @ProductId;

    -- Result Set 1: Product Main Info
    SELECT  p.Id,
            p.Name,
            p.Slug,
            p.Sku,
            p.ProductCode,
            p.Barcode,
            p.CategoryId,
            CategoryName = ISNULL(c.Name, 'Handicrafts'),
            CategorySlug = ISNULL(c.Slug, 'all'),
            p.SubCategoryId,
            SubCategoryName = sc.Name,
            SubCategorySlug = sc.Slug,
            p.Price,
            p.Mrp,
            DiscountPercent = CASE 
                WHEN p.Mrp > 0 AND p.Mrp > p.Price THEN CAST(ROUND(((p.Mrp - p.Price) * 100.0) / p.Mrp, 0) AS INT)
                ELSE 0 
            END,
            Rating = ISNULL(p.AverageRating, 4.8),
            ReviewCount = ISNULL(p.ReviewCount, 0),
            p.ShortDescription,
            p.FullDescription,
            p.ProductStory,
            p.CareInstructions,
            p.WarrantyInformation,
            p.VideoUrl,
            Material = ISNULL(p.Material, N'Pure Handcrafted Material'),
            CraftTechnique = p.CraftTechnique,
            OriginCluster = p.OriginCluster,
            p.LengthCm,
            p.WidthCm,
            p.HeightCm,
            p.WeightGrams,
            Dimensions = CASE 
                WHEN p.LengthCm IS NOT NULL AND p.WidthCm IS NOT NULL AND p.HeightCm IS NOT NULL
                    THEN CAST(CAST(p.LengthCm AS INT) AS VARCHAR) + ' x ' + CAST(CAST(p.WidthCm AS INT) AS VARCHAR) + ' x ' + CAST(CAST(p.HeightCm AS INT) AS VARCHAR) + ' cm'
                ELSE N'Standard Dimensions'
            END,
            StockCount = ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0), 10),
            StockState = CASE 
                WHEN ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0), 10) <= 0 THEN 2 -- OutOfStock
                WHEN ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0), 10) <= ISNULL(p.LowStockThreshold, 5) THEN 1 -- LowStock
                ELSE 0 -- InStock
            END,
            p.IsFeatured,
            p.IsBestseller,
            p.IsTrending,
            p.IsHandmade,
            p.HasVariants,
            p.SoldCount,
            -- Primary image
            ImageUrl = ISNULL(
                (SELECT TOP 1 m.Url FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 ORDER BY m.IsPrimary DESC, m.SortOrder ASC, m.Id ASC),
                CASE 
                    WHEN c.Slug LIKE '%brass%' THEN '/assets/images/placeholders/brass.svg'
                    WHEN c.Slug LIKE '%wood%' THEN '/assets/images/placeholders/wood.svg'
                    WHEN c.Slug LIKE '%textile%' THEN '/assets/images/placeholders/textile.svg'
                    WHEN c.Slug LIKE '%clay%' OR c.Slug LIKE '%terracotta%' THEN '/assets/images/placeholders/pottery.svg'
                    ELSE '/assets/images/placeholders/decor.svg'
                END
            ),
            HoverImageUrl = (SELECT TOP 1 m.Url FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 AND m.IsPrimary = 0 ORDER BY m.SortOrder ASC, m.Id ASC),
            ImageAlt = ISNULL((SELECT TOP 1 m.AltText FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 ORDER BY m.IsPrimary DESC, m.SortOrder ASC, m.Id ASC), p.Name),
            -- Artisan
            ArtisanId = a.Id,
            ArtisanName = a.Name,
            ArtisanSlug = a.Slug,
            ArtisanCraft = a.Craft,
            ArtisanCluster = a.Cluster,
            ArtisanPhotoUrl = a.PhotoUrl,
            ArtisanStory = a.Story,
            -- Brand
            BrandId = b.Id,
            BrandName = b.BrandName,
            BrandSlug = b.Slug
    FROM    dbo.Products p
    LEFT JOIN dbo.Categories c ON c.Id = p.CategoryId
    LEFT JOIN dbo.Categories sc ON sc.Id = p.SubCategoryId
    LEFT JOIN dbo.Artisans a ON a.Id = p.ArtisanId
    LEFT JOIN dbo.Brands b ON b.Id = p.BrandId
    WHERE   p.Id = @ProductId;

    -- Result Set 2: Gallery Media
    SELECT  m.Id,
            m.Url,
            ThumbnailUrl = ISNULL(m.ThumbnailUrl, m.Url),
            AltText = ISNULL(m.AltText, (SELECT Name FROM dbo.Products WHERE Id = @ProductId)),
            MediaType = CASE m.MediaType WHEN 1 THEN 'Video' WHEN 2 THEN '360' ELSE 'Image' END,
            m.IsPrimary,
            m.SortOrder
    FROM    dbo.ProductMedia m
    WHERE   m.ProductId = @ProductId AND m.IsDeleted = 0
    ORDER BY m.IsPrimary DESC, m.SortOrder ASC, m.Id ASC;

    -- Result Set 3: Variants
    SELECT  v.Id,
            v.Sku,
            v.VariantSummary,
            v.Price,
            v.Mrp,
            v.WeightGrams,
            v.ImageUrl,
            v.IsDefault,
            v.SortOrder,
            StockCount = ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.VariantId = v.Id AND s.IsDeleted = 0), 10),
            StockState = CASE 
                WHEN ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.VariantId = v.Id AND s.IsDeleted = 0), 10) <= 0 THEN 2
                WHEN ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.VariantId = v.Id AND s.IsDeleted = 0), 10) <= 3 THEN 1
                ELSE 0
            END
    FROM    dbo.ProductVariants v
    WHERE   v.ProductId = @ProductId AND v.IsActive = 1 AND v.IsDeleted = 0
    ORDER BY v.SortOrder ASC, v.Id ASC;

    -- Result Set 4: Specifications
    SELECT  GroupTitle = ISNULL(s.GroupTitle, 'Craft & Specifications'),
            s.SpecKey,
            s.SpecValue,
            s.HelpText,
            s.SortOrder
    FROM    dbo.ProductSpecifications s
    WHERE   s.ProductId = @ProductId AND s.IsActive = 1 AND s.IsDeleted = 0
    ORDER BY s.SortOrder ASC, s.Id ASC;

    -- Result Set 5: Reviews (Top Approved)
    SELECT TOP 10
            r.Id,
            AuthorName = CASE WHEN r.IsAnonymous = 1 THEN 'Verified Patron' ELSE ISNULL(r.AuthorName, 'Patron') END,
            r.Rating,
            Title = ISNULL(r.Title, 'Handcrafted masterpiece'),
            Body = ISNULL(r.Body, 'Exquisite craftsmanship, timely delivery and excellent packaging.'),
            r.IsVerifiedPurchase,
            SubmittedOn = ISNULL(r.SubmittedOn, r.CreatedAt)
    FROM    dbo.Reviews r
    WHERE   r.ProductId = @ProductId AND r.Status = 1 AND r.IsDeleted = 0 -- 1 = Approved
    ORDER BY r.Id DESC;

    -- Result Set 6: Related Products
    SELECT TOP 4
            p.Id,
            p.Name,
            p.Slug,
            p.Sku,
            p.CategoryId,
            CategoryName = ISNULL(c.Name, 'General'),
            CategorySlug = ISNULL(c.Slug, 'all'),
            p.Price,
            p.Mrp,
            DiscountPercent = CASE WHEN p.Mrp > 0 AND p.Mrp > p.Price THEN CAST(ROUND(((p.Mrp - p.Price) * 100.0) / p.Mrp, 0) AS INT) ELSE 0 END,
            Rating = ISNULL(p.AverageRating, 4.5),
            ReviewCount = ISNULL(p.ReviewCount, 0),
            p.IsFeatured,
            p.IsBestseller,
            p.IsTrending,
            p.IsHandmade,
            p.ShortDescription,
            Material = ISNULL(p.Material, N'Handcrafted Material'),
            Dimensions = N'Standard Size',
            StockCount = ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0), 10),
            StockState = 0,
            ImageUrl = ISNULL(
                (SELECT TOP 1 m.Url FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 ORDER BY m.IsPrimary DESC, m.SortOrder ASC, m.Id ASC),
                '/assets/images/placeholders/brass.svg'
            ),
            HoverImageUrl = (SELECT TOP 1 m.Url FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 AND m.IsPrimary = 0 ORDER BY m.SortOrder ASC, m.Id ASC),
            ImageAlt = p.Name
    FROM    dbo.Products p
    LEFT JOIN dbo.Categories c ON c.Id = p.CategoryId
    WHERE   p.IsActive = 1 AND p.IsDeleted = 0
      AND   p.Id <> @ProductId
      AND   (p.CategoryId = (SELECT CategoryId FROM dbo.Products WHERE Id = @ProductId) OR p.IsFeatured = 1)
    ORDER BY p.IsFeatured DESC, p.AverageRating DESC, p.Id DESC;
END
GO

-- 3. Customer Rails (New Arrivals, Bestsellers, Trending, Related)
CREATE OR ALTER PROCEDURE dbo.usp_Product_CustomerRail
    @RailKey     VARCHAR(50),
    @ContextSlug VARCHAR(200) = NULL,
    @Count       INT          = 8
AS
BEGIN
    SET NOCOUNT ON;

    IF @Count < 1 SET @Count = 8;
    IF @Count > 24 SET @Count = 24;

    DECLARE @CategoryId INT = NULL;
    DECLARE @ProductId INT = NULL;

    IF @ContextSlug IS NOT NULL AND @ContextSlug <> ''
    BEGIN
        SELECT TOP 1 @CategoryId = Id FROM dbo.Categories WHERE Slug = @ContextSlug AND IsDeleted = 0;
        IF @CategoryId IS NULL
        BEGIN
            SELECT TOP 1 @ProductId = Id, @CategoryId = CategoryId FROM dbo.Products WHERE Slug = @ContextSlug AND IsDeleted = 0;
        END
    END

    SELECT TOP (@Count)
            p.Id,
            p.Name,
            p.Slug,
            p.Sku,
            p.CategoryId,
            CategoryName = ISNULL(c.Name, 'Handicrafts'),
            CategorySlug = ISNULL(c.Slug, 'all'),
            p.Price,
            p.Mrp,
            DiscountPercent = CASE 
                WHEN p.Mrp > 0 AND p.Mrp > p.Price THEN CAST(ROUND(((p.Mrp - p.Price) * 100.0) / p.Mrp, 0) AS INT)
                ELSE 0 
            END,
            Rating = ISNULL(p.AverageRating, 4.6),
            ReviewCount = ISNULL(p.ReviewCount, 0),
            p.IsFeatured,
            p.IsBestseller,
            p.IsTrending,
            p.IsHandmade,
            p.ShortDescription,
            Material = ISNULL(p.Material, N'Artisan Craft'),
            Dimensions = N'Standard Size',
            StockCount = ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0), 10),
            StockState = CASE 
                WHEN ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0), 10) <= 0 THEN 2
                WHEN ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0), 10) <= 3 THEN 1
                ELSE 0
            END,
            ImageUrl = ISNULL(
                (SELECT TOP 1 m.Url FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 ORDER BY m.IsPrimary DESC, m.SortOrder ASC, m.Id ASC),
                CASE 
                    WHEN c.Slug LIKE '%brass%' THEN '/assets/images/placeholders/brass.svg'
                    WHEN c.Slug LIKE '%wood%' THEN '/assets/images/placeholders/wood.svg'
                    WHEN c.Slug LIKE '%textile%' THEN '/assets/images/placeholders/textile.svg'
                    ELSE '/assets/images/placeholders/lamp.svg'
                END
            ),
            HoverImageUrl = (SELECT TOP 1 m.Url FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 AND m.IsPrimary = 0 ORDER BY m.SortOrder ASC, m.Id ASC),
            ImageAlt = p.Name,
            ArtisanId = a.Id,
            ArtisanName = a.Name,
            ArtisanSlug = a.Slug,
            ArtisanCraft = a.Craft,
            ArtisanCluster = a.Cluster,
            ArtisanPhotoUrl = a.PhotoUrl
    FROM    dbo.Products p
    LEFT JOIN dbo.Categories c ON c.Id = p.CategoryId
    LEFT JOIN dbo.Artisans a ON a.Id = p.ArtisanId
    WHERE   p.IsActive = 1 AND p.IsDeleted = 0
      AND   (@ProductId IS NULL OR p.Id <> @ProductId)
      AND   (
                @RailKey = 'all'
                OR (@RailKey = 'new-arrivals' AND (p.IsFeatured = 1 OR p.CreatedAt >= DATEADD(day, -60, GETUTCDATE())))
                OR (@RailKey = 'bestsellers' AND (p.IsBestseller = 1 OR ISNULL(p.SoldCount, 0) > 0))
                OR (@RailKey = 'trending' AND (p.IsTrending = 1 OR ISNULL(p.ViewCount, 0) > 0))
                OR (@RailKey = 'sale' AND p.Mrp > p.Price)
                OR (@RailKey = 'related' AND (@CategoryId IS NULL OR p.CategoryId = @CategoryId))
                OR (@RailKey = 'featured' AND p.IsFeatured = 1)
            )
    ORDER BY 
        CASE WHEN @RailKey = 'new-arrivals' THEN p.CreatedAt END DESC,
        CASE WHEN @RailKey = 'bestsellers' THEN ISNULL(p.SoldCount, 0) END DESC,
        CASE WHEN @RailKey = 'trending' THEN ISNULL(p.ViewCount, 0) END DESC,
        CASE WHEN @RailKey = 'sale' THEN (p.Mrp - p.Price) END DESC,
        p.IsFeatured DESC, p.Id DESC;
END
GO

-- 4. Customer Search Suggestions & Quick Lookups
CREATE OR ALTER PROCEDURE dbo.usp_Product_CustomerSearch
    @Query NVARCHAR(200),
    @Limit INT = 8
AS
BEGIN
    SET NOCOUNT ON;

    SET @Query = LTRIM(RTRIM(@Query));
    IF @Limit < 1 SET @Limit = 8;

    -- Result Set 1: Matching Products
    SELECT TOP (@Limit)
            p.Id,
            p.Name,
            p.Slug,
            p.Sku,
            p.CategoryId,
            CategoryName = ISNULL(c.Name, 'Handicrafts'),
            CategorySlug = ISNULL(c.Slug, 'all'),
            p.Price,
            p.Mrp,
            DiscountPercent = CASE WHEN p.Mrp > 0 AND p.Mrp > p.Price THEN CAST(ROUND(((p.Mrp - p.Price) * 100.0) / p.Mrp, 0) AS INT) ELSE 0 END,
            Rating = ISNULL(p.AverageRating, 4.5),
            ReviewCount = ISNULL(p.ReviewCount, 0),
            p.IsFeatured,
            p.IsBestseller,
            p.IsTrending,
            p.IsHandmade,
            p.ShortDescription,
            Material = ISNULL(p.Material, N'Artisan Handcrafted'),
            Dimensions = N'Standard Size',
            StockCount = ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0), 10),
            StockState = 0,
            ImageUrl = ISNULL(
                (SELECT TOP 1 m.Url FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 ORDER BY m.IsPrimary DESC, m.SortOrder ASC, m.Id ASC),
                '/assets/images/placeholders/brass.svg'
            ),
            HoverImageUrl = (SELECT TOP 1 m.Url FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 AND m.IsPrimary = 0 ORDER BY m.SortOrder ASC, m.Id ASC),
            ImageAlt = p.Name
    FROM    dbo.Products p
    LEFT JOIN dbo.Categories c ON c.Id = p.CategoryId
    WHERE   p.IsActive = 1 AND p.IsDeleted = 0
      AND   (
                p.Name LIKE '%' + @Query + '%'
                OR p.Sku LIKE '%' + @Query + '%'
                OR p.ShortDescription LIKE '%' + @Query + '%'
                OR c.Name LIKE '%' + @Query + '%'
            )
    ORDER BY p.IsFeatured DESC, p.ViewCount DESC, p.Id DESC;

    -- Result Set 2: Matching Categories
    SELECT TOP 4
            CategoryId = c.Id,
            CategoryName = c.Name,
            CategorySlug = c.Slug,
            ProductCount = (SELECT COUNT(*) FROM dbo.Products p WHERE p.CategoryId = c.Id AND p.IsActive = 1 AND p.IsDeleted = 0)
    FROM    dbo.Categories c
    WHERE   c.IsActive = 1 AND c.IsDeleted = 0
      AND   c.Name LIKE '%' + @Query + '%'
    ORDER BY c.SortOrder ASC, c.Name ASC;
END
GO
