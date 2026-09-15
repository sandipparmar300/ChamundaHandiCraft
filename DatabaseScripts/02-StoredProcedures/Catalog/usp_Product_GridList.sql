/* =============================================================================
   usp_Product_GridList
   -----------------------------------------------------------------------------
   Server-side grid for Module 03 - Product Management.

   Specs:
     Product.txt §3   the column list the grid renders
     Product.txt §10  search by name / SKU / barcode / product code / category /
                      brand, and the advanced filter set
     DatabaseScripts/README.md  the GridList_<Entity> contract:
                      @SortColumn, @SortOrder, @PageSize, @PageIndex, @SearchText
                      plus module filters; OUTPUT @TotalRecords and
                      @TotalFilteredRecords.

   Naming note: the README documents this family as GridList_<Entity>. The prompt
   asks for usp_<Module>_<Action>. Both names are provided - usp_Product_GridList
   is the implementation and GridList_Product is a thin synonym at the end of this
   file - so existing repository code and the new convention both resolve.

   No SELECT *. No dynamic SQL: sorting is resolved with a CASE expression so the
   procedure cannot be injected through @SortColumn.
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Product_GridList
    @SearchText             NVARCHAR(300)   = NULL,
    @CategoryId             INT             = NULL,
    @BrandId                INT             = NULL,
    @ArtisanId              INT             = NULL,
    @MaterialId             INT             = NULL,
    @Status                 TINYINT         = NULL,   -- 0 Draft, 1 Published, 2 Unpublished, 3 Archived
    @StockState             VARCHAR(16)     = NULL,   -- InStock | LowStock | OutOfStock
    @IsFeatured             BIT             = NULL,
    @IsBestseller           BIT             = NULL,
    @IsTrending             BIT             = NULL,
    @MinPrice               DECIMAL(18,2)   = NULL,
    @MaxPrice               DECIMAL(18,2)   = NULL,
    @CreatedFrom            DATETIME2(3)    = NULL,
    @CreatedTo              DATETIME2(3)    = NULL,
    @SortColumn             VARCHAR(64)     = 'CreatedAt',
    @SortOrder              VARCHAR(4)      = 'DESC',
    @PageSize               INT             = 25,
    @PageIndex              INT             = 1,
    @TotalRecords           INT             OUTPUT,
    @TotalFilteredRecords   INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageSize  IS NULL OR @PageSize  < 1 SET @PageSize  = 25;
    IF @PageIndex IS NULL OR @PageIndex < 1 SET @PageIndex = 1;
    IF @SortOrder IS NULL OR @SortOrder NOT IN ('ASC','DESC') SET @SortOrder = 'DESC';

    SET @SearchText = NULLIF(LTRIM(RTRIM(ISNULL(@SearchText, N''))), N'');

    /* Unfiltered denominator for the "showing x of y" caption. */
    SELECT @TotalRecords = COUNT(*)
    FROM   dbo.Products
    WHERE  IsDeleted = 0;

    /* Stock is summed across warehouses once, then joined - cheaper than a
       correlated subquery per row and it lets the stock filter be sargable. */
    ;WITH Stock AS
    (
        SELECT  s.ProductId,
                OnHand    = SUM(s.OnHand),
                Reserved  = SUM(s.Reserved),
                Available = SUM(s.OnHand - s.Reserved),
                LowStockThreshold = MAX(s.LowStockThreshold)
        FROM    dbo.InventoryStocks AS s
        WHERE   s.IsDeleted = 0
        GROUP   BY s.ProductId
    ),
    Filtered AS
    (
        SELECT  p.Id,
                p.Name,
                p.Sku,
                p.ProductCode,
                p.Barcode,
                p.Slug,
                p.Price,
                p.Mrp,
                p.CostPrice,
                p.Status,
                p.Visibility,
                p.IsFeatured,
                p.IsBestseller,
                p.IsTrending,
                p.AverageRating,
                p.ReviewCount,
                p.SoldCount,
                p.CreatedAt,
                p.UpdatedAt,
                p.CategoryId,
                p.BrandId,
                p.ArtisanId,
                CategoryName = c.Name,
                BrandName    = b.BrandName,
                ArtisanName  = a.Name,
                OnHand       = ISNULL(st.OnHand, 0),
                Reserved     = ISNULL(st.Reserved, 0),
                Available    = ISNULL(st.Available, 0),
                LowStockThreshold = ISNULL(st.LowStockThreshold, p.LowStockThreshold),
                ImageUrl     = pm.Url,
                ImageAlt     = pm.AltText,
                DiscountPercent = CASE WHEN p.Mrp IS NOT NULL AND p.Mrp > 0
                                       THEN CAST(ROUND(100.0 * (p.Mrp - p.Price) / p.Mrp, 0) AS INT)
                                       ELSE 0 END
        FROM    dbo.Products AS p
        LEFT JOIN dbo.Categories AS c ON c.Id = p.CategoryId
        LEFT JOIN dbo.Brands     AS b ON b.Id = p.BrandId
        LEFT JOIN dbo.Artisans   AS a ON a.Id = p.ArtisanId
        LEFT JOIN Stock          AS st ON st.ProductId = p.Id
        /* The primary image only - OUTER APPLY keeps it to one row per product. */
        OUTER APPLY (
            SELECT TOP (1) m.Url, m.AltText
            FROM   dbo.ProductMedia AS m
            WHERE  m.ProductId = p.Id
              AND  m.IsDeleted = 0
              AND  m.MediaType = 0
            ORDER  BY m.IsPrimary DESC, m.SortOrder, m.Id
        ) AS pm
        WHERE   p.IsDeleted = 0
          AND  (@Status       IS NULL OR p.Status      = @Status)
          AND  (@BrandId      IS NULL OR p.BrandId     = @BrandId)
          AND  (@ArtisanId    IS NULL OR p.ArtisanId   = @ArtisanId)
          AND  (@MaterialId   IS NULL OR p.MaterialId  = @MaterialId)
          AND  (@IsFeatured   IS NULL OR p.IsFeatured  = @IsFeatured)
          AND  (@IsBestseller IS NULL OR p.IsBestseller= @IsBestseller)
          AND  (@IsTrending   IS NULL OR p.IsTrending  = @IsTrending)
          AND  (@MinPrice     IS NULL OR p.Price      >= @MinPrice)
          AND  (@MaxPrice     IS NULL OR p.Price      <= @MaxPrice)
          AND  (@CreatedFrom  IS NULL OR p.CreatedAt  >= @CreatedFrom)
          AND  (@CreatedTo    IS NULL OR p.CreatedAt  <  DATEADD(DAY, 1, @CreatedTo))
          /* A product may sit in several categories; match either the primary
             column or any ProductCategories row. */
          AND  (@CategoryId   IS NULL
                OR p.CategoryId = @CategoryId
                OR EXISTS (SELECT 1 FROM dbo.ProductCategories AS pc
                           WHERE pc.ProductId = p.Id AND pc.CategoryId = @CategoryId))
          AND  (@SearchText   IS NULL
                OR p.Name        LIKE N'%' + @SearchText + N'%'
                OR p.Sku         LIKE       @SearchText + N'%'
                OR p.ProductCode LIKE       @SearchText + N'%'
                OR p.Barcode     =          @SearchText)
          AND  (@StockState IS NULL
                OR (@StockState = 'OutOfStock' AND ISNULL(st.Available, 0) <= 0)
                OR (@StockState = 'LowStock'
                    AND ISNULL(st.Available, 0) > 0
                    AND ISNULL(st.Available, 0) <= ISNULL(st.LowStockThreshold, p.LowStockThreshold))
                OR (@StockState = 'InStock'
                    AND ISNULL(st.Available, 0) > ISNULL(st.LowStockThreshold, p.LowStockThreshold)))
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    /* Recompute rather than materialise: the CTE above is only in scope for the
       statement that follows it, and repeating it lets the optimiser push the
       paging predicate down. */
    ;WITH Stock AS
    (
        SELECT  s.ProductId,
                OnHand    = SUM(s.OnHand),
                Reserved  = SUM(s.Reserved),
                Available = SUM(s.OnHand - s.Reserved),
                LowStockThreshold = MAX(s.LowStockThreshold)
        FROM    dbo.InventoryStocks AS s
        WHERE   s.IsDeleted = 0
        GROUP   BY s.ProductId
    ),
    Filtered AS
    (
        SELECT  p.Id,
                p.Name,
                p.Sku,
                p.ProductCode,
                p.Barcode,
                p.Slug,
                p.Price,
                p.Mrp,
                p.CostPrice,
                p.Status,
                p.Visibility,
                p.IsFeatured,
                p.IsBestseller,
                p.IsTrending,
                p.AverageRating,
                p.ReviewCount,
                p.SoldCount,
                p.CreatedAt,
                p.UpdatedAt,
                CategoryName = c.Name,
                BrandName    = b.BrandName,
                ArtisanName  = a.Name,
                OnHand       = ISNULL(st.OnHand, 0),
                Reserved     = ISNULL(st.Reserved, 0),
                Available    = ISNULL(st.Available, 0),
                LowStockThreshold = ISNULL(st.LowStockThreshold, p.LowStockThreshold),
                ImageUrl     = pm.Url,
                ImageAlt     = pm.AltText,
                DiscountPercent = CASE WHEN p.Mrp IS NOT NULL AND p.Mrp > 0
                                       THEN CAST(ROUND(100.0 * (p.Mrp - p.Price) / p.Mrp, 0) AS INT)
                                       ELSE 0 END
        FROM    dbo.Products AS p
        LEFT JOIN dbo.Categories AS c ON c.Id = p.CategoryId
        LEFT JOIN dbo.Brands     AS b ON b.Id = p.BrandId
        LEFT JOIN dbo.Artisans   AS a ON a.Id = p.ArtisanId
        LEFT JOIN Stock          AS st ON st.ProductId = p.Id
        OUTER APPLY (
            SELECT TOP (1) m.Url, m.AltText
            FROM   dbo.ProductMedia AS m
            WHERE  m.ProductId = p.Id
              AND  m.IsDeleted = 0
              AND  m.MediaType = 0
            ORDER  BY m.IsPrimary DESC, m.SortOrder, m.Id
        ) AS pm
        WHERE   p.IsDeleted = 0
          AND  (@Status       IS NULL OR p.Status      = @Status)
          AND  (@BrandId      IS NULL OR p.BrandId     = @BrandId)
          AND  (@ArtisanId    IS NULL OR p.ArtisanId   = @ArtisanId)
          AND  (@MaterialId   IS NULL OR p.MaterialId  = @MaterialId)
          AND  (@IsFeatured   IS NULL OR p.IsFeatured  = @IsFeatured)
          AND  (@IsBestseller IS NULL OR p.IsBestseller= @IsBestseller)
          AND  (@IsTrending   IS NULL OR p.IsTrending  = @IsTrending)
          AND  (@MinPrice     IS NULL OR p.Price      >= @MinPrice)
          AND  (@MaxPrice     IS NULL OR p.Price      <= @MaxPrice)
          AND  (@CreatedFrom  IS NULL OR p.CreatedAt  >= @CreatedFrom)
          AND  (@CreatedTo    IS NULL OR p.CreatedAt  <  DATEADD(DAY, 1, @CreatedTo))
          AND  (@CategoryId   IS NULL
                OR p.CategoryId = @CategoryId
                OR EXISTS (SELECT 1 FROM dbo.ProductCategories AS pc
                           WHERE pc.ProductId = p.Id AND pc.CategoryId = @CategoryId))
          AND  (@SearchText   IS NULL
                OR p.Name        LIKE N'%' + @SearchText + N'%'
                OR p.Sku         LIKE       @SearchText + N'%'
                OR p.ProductCode LIKE       @SearchText + N'%'
                OR p.Barcode     =          @SearchText)
          AND  (@StockState IS NULL
                OR (@StockState = 'OutOfStock' AND ISNULL(st.Available, 0) <= 0)
                OR (@StockState = 'LowStock'
                    AND ISNULL(st.Available, 0) > 0
                    AND ISNULL(st.Available, 0) <= ISNULL(st.LowStockThreshold, p.LowStockThreshold))
                OR (@StockState = 'InStock'
                    AND ISNULL(st.Available, 0) > ISNULL(st.LowStockThreshold, p.LowStockThreshold)))
    )
    SELECT
        Id, Name, Sku, ProductCode, Barcode, Slug,
        Price, Mrp, CostPrice, DiscountPercent,
        Status, Visibility, IsFeatured, IsBestseller, IsTrending,
        AverageRating, ReviewCount, SoldCount,
        CategoryName, BrandName, ArtisanName,
        OnHand, Reserved, Available, LowStockThreshold,
        ImageUrl, ImageAlt,
        CreatedAt, UpdatedAt
    FROM Filtered
    /* Whitelisted sort. @SortColumn never reaches the engine as text. */
    ORDER BY
        CASE WHEN @SortOrder = 'ASC' THEN
            CASE @SortColumn
                WHEN 'Name'       THEN Name
                WHEN 'Sku'        THEN Sku
                ELSE NULL
            END
        END ASC,
        CASE WHEN @SortOrder = 'DESC' THEN
            CASE @SortColumn
                WHEN 'Name'       THEN Name
                WHEN 'Sku'        THEN Sku
                ELSE NULL
            END
        END DESC,
        CASE WHEN @SortOrder = 'ASC' THEN
            CASE @SortColumn
                WHEN 'Price'      THEN Price
                WHEN 'Available'  THEN CAST(Available AS DECIMAL(18,2))
                WHEN 'SoldCount'  THEN CAST(SoldCount AS DECIMAL(18,2))
                WHEN 'Rating'     THEN AverageRating
                ELSE NULL
            END
        END ASC,
        CASE WHEN @SortOrder = 'DESC' THEN
            CASE @SortColumn
                WHEN 'Price'      THEN Price
                WHEN 'Available'  THEN CAST(Available AS DECIMAL(18,2))
                WHEN 'SoldCount'  THEN CAST(SoldCount AS DECIMAL(18,2))
                WHEN 'Rating'     THEN AverageRating
                ELSE NULL
            END
        END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'UpdatedAt' THEN UpdatedAt END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'UpdatedAt' THEN UpdatedAt END DESC,
        CASE WHEN @SortOrder = 'ASC'  THEN CreatedAt END ASC,
        CASE WHEN @SortOrder = 'DESC' THEN CreatedAt END DESC,
        Id DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO


/* -----------------------------------------------------------------------------
   Repository-convention synonym. DatabaseScripts/README.md documents the family
   as GridList_<Entity>; the existing repository contract in ARCHITECTURE.md §6
   calls it by that name. It forwards, so there is only one implementation.
   ----------------------------------------------------------------------------- */
GO

CREATE OR ALTER PROCEDURE dbo.GridList_Product
    @SearchText             NVARCHAR(300)   = NULL,
    @CategoryId             INT             = NULL,
    @BrandId                INT             = NULL,
    @ArtisanId              INT             = NULL,
    @MaterialId             INT             = NULL,
    @Status                 TINYINT         = NULL,
    @StockState             VARCHAR(16)     = NULL,
    @IsFeatured             BIT             = NULL,
    @IsBestseller           BIT             = NULL,
    @IsTrending             BIT             = NULL,
    @MinPrice               DECIMAL(18,2)   = NULL,
    @MaxPrice               DECIMAL(18,2)   = NULL,
    @CreatedFrom            DATETIME2(3)    = NULL,
    @CreatedTo              DATETIME2(3)    = NULL,
    @SortColumn             VARCHAR(64)     = 'CreatedAt',
    @SortOrder              VARCHAR(4)      = 'DESC',
    @PageSize               INT             = 25,
    @PageIndex              INT             = 1,
    @TotalRecords           INT             OUTPUT,
    @TotalFilteredRecords   INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.usp_Product_GridList
        @SearchText           = @SearchText,
        @CategoryId           = @CategoryId,
        @BrandId              = @BrandId,
        @ArtisanId            = @ArtisanId,
        @MaterialId           = @MaterialId,
        @Status               = @Status,
        @StockState           = @StockState,
        @IsFeatured           = @IsFeatured,
        @IsBestseller         = @IsBestseller,
        @IsTrending           = @IsTrending,
        @MinPrice             = @MinPrice,
        @MaxPrice             = @MaxPrice,
        @CreatedFrom          = @CreatedFrom,
        @CreatedTo            = @CreatedTo,
        @SortColumn           = @SortColumn,
        @SortOrder            = @SortOrder,
        @PageSize             = @PageSize,
        @PageIndex            = @PageIndex,
        @TotalRecords         = @TotalRecords         OUTPUT,
        @TotalFilteredRecords = @TotalFilteredRecords OUTPUT;
END
GO
