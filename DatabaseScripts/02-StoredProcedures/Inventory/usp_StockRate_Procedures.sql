/* =============================================================================
   usp_StockRate_Procedures.sql
   Stored procedures for Stock Rates, Pricing & Valuation Management:
     1. dbo.usp_StockRate_GridList
     2. dbo.usp_StockRate_GetById
     3. dbo.usp_StockRate_Save
   ============================================================================= */

SET NOCOUNT ON;
GO

/* 1. GridList */
CREATE OR ALTER PROCEDURE dbo.usp_StockRate_GridList
    @SearchText           NVARCHAR(200)   = NULL,
    @WarehouseId          INT             = NULL,
    @SortColumn           VARCHAR(64)     = 'ProductName',
    @SortOrder            VARCHAR(4)      = 'ASC',
    @PageSize             INT             = 25,
    @PageIndex            INT             = 1,
    @TotalRecords         INT             OUTPUT,
    @TotalFilteredRecords INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageSize  IS NULL OR @PageSize  < 1 SET @PageSize  = 25;
    IF @PageIndex IS NULL OR @PageIndex < 1 SET @PageIndex = 1;
    IF @SortOrder IS NULL OR @SortOrder NOT IN ('ASC','DESC') SET @SortOrder = 'ASC';
    SET @SearchText = NULLIF(LTRIM(RTRIM(ISNULL(@SearchText, N''))), N'');

    ;WITH ProductItemRows AS
    (
        -- Products without variants
        SELECT
            ProductId        = p.Id,
            VariantId        = CAST(NULL AS INT),
            ItemName         = p.Name,
            Sku              = p.Sku,
            Barcode          = p.Barcode,
            CostPrice        = ISNULL(p.CostPrice, 0),
            Price            = ISNULL(p.Price, 0),
            Mrp              = ISNULL(p.Mrp, 0),
            UpdatedAt        = p.UpdatedAt
        FROM dbo.Products p
        WHERE p.IsDeleted = 0 AND ISNULL(p.HasVariants, 0) = 0

        UNION ALL

        -- Product variants
        SELECT
            ProductId        = pv.ProductId,
            VariantId        = pv.Id,
            ItemName         = p.Name + ' (' + ISNULL(pv.VariantSummary, 'Variant') + ')',
            Sku              = ISNULL(pv.Sku, p.Sku),
            Barcode          = pv.Barcode,
            CostPrice        = ISNULL(pv.CostPrice, ISNULL(p.CostPrice, 0)),
            Price            = ISNULL(pv.Price, p.Price),
            Mrp              = ISNULL(pv.Mrp, ISNULL(p.Mrp, 0)),
            UpdatedAt        = ISNULL(pv.UpdatedAt, p.UpdatedAt)
        FROM dbo.ProductVariants pv
        JOIN dbo.Products p ON pv.ProductId = p.Id AND p.IsDeleted = 0
        WHERE pv.IsDeleted = 0
    ),
    AggregatedStock AS
    (
        SELECT
            s.ProductId,
            VariantId = ISNULL(s.VariantId, 0),
            TotalOnHand = SUM(s.OnHand),
            TotalReserved = SUM(s.Reserved),
            TotalAvailable = SUM(CASE WHEN (s.OnHand - s.Reserved) < 0 THEN 0 ELSE (s.OnHand - s.Reserved) END)
        FROM dbo.InventoryStocks s
        WHERE s.IsDeleted = 0
          AND (@WarehouseId IS NULL OR s.WarehouseId = @WarehouseId)
        GROUP BY s.ProductId, ISNULL(s.VariantId, 0)
    ),
    BaseList AS
    (
        SELECT
            r.ProductId,
            VariantId      = ISNULL(r.VariantId, 0),
            ProductName    = r.ItemName,
            r.Sku,
            r.Barcode,
            OnHand         = ISNULL(stk.TotalOnHand, 0),
            Reserved       = ISNULL(stk.TotalReserved, 0),
            Available      = ISNULL(stk.TotalAvailable, 0),
            r.CostPrice,
            r.Price,
            r.Mrp,
            Valuation      = CAST(ISNULL(stk.TotalOnHand, 0) * r.CostPrice AS DECIMAL(18,2)),
            MarginAmount   = CAST(r.Price - r.CostPrice AS DECIMAL(18,2)),
            MarginPercent  = CASE 
                                WHEN r.Price > 0 THEN CAST(((r.Price - r.CostPrice) / r.Price) * 100.0 AS DECIMAL(9,2))
                                ELSE 0.00
                             END,
            r.UpdatedAt
        FROM ProductItemRows r
        LEFT JOIN AggregatedStock stk ON r.ProductId = stk.ProductId AND ISNULL(r.VariantId, 0) = stk.VariantId
        WHERE (@SearchText IS NULL
               OR r.ItemName LIKE N'%' + @SearchText + N'%'
               OR r.Sku LIKE N'%' + @SearchText + N'%'
               OR ISNULL(r.Barcode, '') LIKE N'%' + @SearchText + N'%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM BaseList;

    SELECT @TotalRecords = COUNT(*) 
    FROM (
        SELECT p.Id FROM dbo.Products p WHERE p.IsDeleted = 0 AND ISNULL(p.HasVariants, 0) = 0
        UNION ALL
        SELECT pv.Id FROM dbo.ProductVariants pv JOIN dbo.Products p ON pv.ProductId = p.Id AND p.IsDeleted = 0 WHERE pv.IsDeleted = 0
    ) t;

    ;WITH ProductItemRows AS
    (
        SELECT
            ProductId        = p.Id,
            VariantId        = CAST(NULL AS INT),
            ItemName         = p.Name,
            Sku              = p.Sku,
            Barcode          = p.Barcode,
            CostPrice        = ISNULL(p.CostPrice, 0),
            Price            = ISNULL(p.Price, 0),
            Mrp              = ISNULL(p.Mrp, 0),
            UpdatedAt        = p.UpdatedAt
        FROM dbo.Products p
        WHERE p.IsDeleted = 0 AND ISNULL(p.HasVariants, 0) = 0

        UNION ALL

        SELECT
            ProductId        = pv.ProductId,
            VariantId        = pv.Id,
            ItemName         = p.Name + ' (' + ISNULL(pv.VariantSummary, 'Variant') + ')',
            Sku              = ISNULL(pv.Sku, p.Sku),
            Barcode          = pv.Barcode,
            CostPrice        = ISNULL(pv.CostPrice, ISNULL(p.CostPrice, 0)),
            Price            = ISNULL(pv.Price, p.Price),
            Mrp              = ISNULL(pv.Mrp, ISNULL(p.Mrp, 0)),
            UpdatedAt        = ISNULL(pv.UpdatedAt, p.UpdatedAt)
        FROM dbo.ProductVariants pv
        JOIN dbo.Products p ON pv.ProductId = p.Id AND p.IsDeleted = 0
        WHERE pv.IsDeleted = 0
    ),
    AggregatedStock AS
    (
        SELECT
            s.ProductId,
            VariantId = ISNULL(s.VariantId, 0),
            TotalOnHand = SUM(s.OnHand),
            TotalReserved = SUM(s.Reserved),
            TotalAvailable = SUM(CASE WHEN (s.OnHand - s.Reserved) < 0 THEN 0 ELSE (s.OnHand - s.Reserved) END)
        FROM dbo.InventoryStocks s
        WHERE s.IsDeleted = 0
          AND (@WarehouseId IS NULL OR s.WarehouseId = @WarehouseId)
        GROUP BY s.ProductId, ISNULL(s.VariantId, 0)
    ),
    BaseList AS
    (
        SELECT
            r.ProductId,
            VariantId      = ISNULL(r.VariantId, 0),
            ProductName    = r.ItemName,
            r.Sku,
            r.Barcode,
            OnHand         = ISNULL(stk.TotalOnHand, 0),
            Reserved       = ISNULL(stk.TotalReserved, 0),
            Available      = ISNULL(stk.TotalAvailable, 0),
            r.CostPrice,
            r.Price,
            r.Mrp,
            Valuation      = CAST(ISNULL(stk.TotalOnHand, 0) * r.CostPrice AS DECIMAL(18,2)),
            MarginAmount   = CAST(r.Price - r.CostPrice AS DECIMAL(18,2)),
            MarginPercent  = CASE 
                                WHEN r.Price > 0 THEN CAST(((r.Price - r.CostPrice) / r.Price) * 100.0 AS DECIMAL(9,2))
                                ELSE 0.00
                             END,
            r.UpdatedAt
        FROM ProductItemRows r
        LEFT JOIN AggregatedStock stk ON r.ProductId = stk.ProductId AND ISNULL(r.VariantId, 0) = stk.VariantId
        WHERE (@SearchText IS NULL
               OR r.ItemName LIKE N'%' + @SearchText + N'%'
               OR r.Sku LIKE N'%' + @SearchText + N'%'
               OR ISNULL(r.Barcode, '') LIKE N'%' + @SearchText + N'%')
    )
    SELECT *
    FROM BaseList
    ORDER BY
        CASE WHEN @SortColumn = 'ProductName'   AND @SortOrder = 'ASC'  THEN ProductName END ASC,
        CASE WHEN @SortColumn = 'ProductName'   AND @SortOrder = 'DESC' THEN ProductName END DESC,
        CASE WHEN @SortColumn = 'Sku'           AND @SortOrder = 'ASC'  THEN Sku END ASC,
        CASE WHEN @SortColumn = 'Sku'           AND @SortOrder = 'DESC' THEN Sku END DESC,
        CASE WHEN @SortColumn = 'OnHand'        AND @SortOrder = 'ASC'  THEN OnHand END ASC,
        CASE WHEN @SortColumn = 'OnHand'        AND @SortOrder = 'DESC' THEN OnHand END DESC,
        CASE WHEN @SortColumn = 'CostPrice'     AND @SortOrder = 'ASC'  THEN CostPrice END ASC,
        CASE WHEN @SortColumn = 'CostPrice'     AND @SortOrder = 'DESC' THEN CostPrice END DESC,
        CASE WHEN @SortColumn = 'Price'         AND @SortOrder = 'ASC'  THEN Price END ASC,
        CASE WHEN @SortColumn = 'Price'         AND @SortOrder = 'DESC' THEN Price END DESC,
        CASE WHEN @SortColumn = 'Valuation'     AND @SortOrder = 'ASC'  THEN Valuation END ASC,
        CASE WHEN @SortColumn = 'Valuation'     AND @SortOrder = 'DESC' THEN Valuation END DESC,
        CASE WHEN @SortColumn = 'MarginPercent' AND @SortOrder = 'ASC'  THEN MarginPercent END ASC,
        CASE WHEN @SortColumn = 'MarginPercent' AND @SortOrder = 'DESC' THEN MarginPercent END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO

/* 2. GetById */
CREATE OR ALTER PROCEDURE dbo.usp_StockRate_GetById
    @ProductId INT,
    @VariantId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @VariantId IS NOT NULL AND @VariantId > 0
    BEGIN
        SELECT
            ProductId    = pv.ProductId,
            VariantId    = pv.Id,
            ProductName  = p.Name + ' (' + ISNULL(pv.VariantSummary, 'Variant') + ')',
            Sku          = ISNULL(pv.Sku, p.Sku),
            Barcode      = ISNULL(pv.Barcode, p.Barcode),
            CostPrice    = ISNULL(pv.CostPrice, ISNULL(p.CostPrice, 0)),
            Price        = ISNULL(pv.Price, p.Price),
            Mrp          = ISNULL(pv.Mrp, ISNULL(p.Mrp, 0)),
            TotalOnHand  = ISNULL((SELECT SUM(OnHand) FROM dbo.InventoryStocks WHERE ProductId = p.Id AND VariantId = pv.Id AND IsDeleted = 0), 0)
        FROM dbo.ProductVariants pv
        JOIN dbo.Products p ON pv.ProductId = p.Id
        WHERE pv.Id = @VariantId AND pv.IsDeleted = 0;
    END
    ELSE
    BEGIN
        SELECT
            ProductId    = p.Id,
            VariantId    = 0,
            ProductName  = p.Name,
            Sku          = p.Sku,
            Barcode      = p.Barcode,
            CostPrice    = ISNULL(p.CostPrice, 0),
            Price        = ISNULL(p.Price, 0),
            Mrp          = ISNULL(p.Mrp, 0),
            TotalOnHand  = ISNULL((SELECT SUM(OnHand) FROM dbo.InventoryStocks WHERE ProductId = p.Id AND (VariantId IS NULL OR VariantId = 0) AND IsDeleted = 0), 0)
        FROM dbo.Products p
        WHERE p.Id = @ProductId AND p.IsDeleted = 0;
    END
END;
GO

/* 3. Save */
CREATE OR ALTER PROCEDURE dbo.usp_StockRate_Save
    @ProductId INT,
    @VariantId INT = NULL,
    @CostPrice DECIMAL(18,2),
    @Price     DECIMAL(18,2),
    @Mrp       DECIMAL(18,2),
    @UserId    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @VariantId IS NOT NULL AND @VariantId > 0
        BEGIN
            UPDATE dbo.ProductVariants
            SET CostPrice = @CostPrice,
                Price     = @Price,
                Mrp       = @Mrp,
                UpdatedAt = SYSDATETIME(),
                UpdatedBy = ISNULL(@UserId, UpdatedBy)
            WHERE Id = @VariantId;
        END
        ELSE
        BEGIN
            UPDATE dbo.Products
            SET CostPrice = @CostPrice,
                Price     = @Price,
                Mrp       = @Mrp,
                UpdatedAt = SYSDATETIME(),
                UpdatedBy = ISNULL(@UserId, UpdatedBy)
            WHERE Id = @ProductId;
        END

        COMMIT TRANSACTION;

        SELECT StatusCode = 200, Message = 'Stock rate updated successfully.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
