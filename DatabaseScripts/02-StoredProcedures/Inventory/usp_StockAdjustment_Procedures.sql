/* =============================================================================
   usp_StockAdjustment_Procedures.sql
   Stored procedures for Stock Adjustment:
     1. dbo.usp_StockAdjustment_GridList
     2. dbo.usp_StockAdjustment_GetById
     3. dbo.usp_StockAdjustment_Save
     4. dbo.usp_StockAdjustment_Delete
   ============================================================================= */

SET NOCOUNT ON;
GO

/* 1. GridList */
CREATE OR ALTER PROCEDURE dbo.usp_StockAdjustment_GridList
    @SearchText           NVARCHAR(200)   = NULL,
    @WarehouseId          INT             = NULL,
    @ReasonCodeId         INT             = NULL,
    @SortColumn           VARCHAR(64)     = 'AdjustedOn',
    @SortOrder            VARCHAR(4)      = 'DESC',
    @PageSize             INT             = 25,
    @PageIndex            INT             = 1,
    @TotalRecords         INT             OUTPUT,
    @TotalFilteredRecords INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageSize  IS NULL OR @PageSize  < 1 SET @PageSize  = 25;
    IF @PageIndex IS NULL OR @PageIndex < 1 SET @PageIndex = 1;
    IF @SortOrder IS NULL OR @SortOrder NOT IN ('ASC','DESC') SET @SortOrder = 'DESC';
    SET @SearchText = NULLIF(LTRIM(RTRIM(ISNULL(@SearchText, N''))), N'');

    SELECT @TotalRecords = COUNT(*) FROM dbo.StockAdjustments sa WHERE sa.IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT
            sa.Id,
            sa.AdjustmentNumber,
            sa.ProductId,
            sa.VariantId,
            ProductName = p.Name + CASE WHEN pv.VariantSummary IS NOT NULL AND pv.VariantSummary <> '' THEN ' (' + pv.VariantSummary + ')' ELSE '' END,
            Sku = ISNULL(pv.Sku, p.Sku),
            sa.WarehouseId,
            WarehouseName = ISNULL(w.WarehouseName, '—'),
            sa.QuantityBefore,
            sa.QuantityChange,
            sa.QuantityAfter,
            sa.ReasonCodeId,
            Reason = ISNULL(rc.Label, 'Manual Adjustment'),
            sa.Note,
            sa.AdjustedOn,
            sa.CreatedAt
        FROM dbo.StockAdjustments sa
        JOIN dbo.Products p ON sa.ProductId = p.Id
        LEFT JOIN dbo.ProductVariants pv ON sa.VariantId = pv.Id
        JOIN dbo.Warehouses w ON sa.WarehouseId = w.Id
        LEFT JOIN dbo.ReasonCodes rc ON sa.ReasonCodeId = rc.Id
        WHERE sa.IsDeleted = 0
          AND (@WarehouseId IS NULL OR sa.WarehouseId = @WarehouseId)
          AND (@ReasonCodeId IS NULL OR sa.ReasonCodeId = @ReasonCodeId)
          AND (@SearchText IS NULL
               OR sa.AdjustmentNumber LIKE N'%' + @SearchText + N'%'
               OR p.Name LIKE N'%' + @SearchText + N'%'
               OR ISNULL(pv.Sku, p.Sku) LIKE N'%' + @SearchText + N'%'
               OR ISNULL(sa.Note, '') LIKE N'%' + @SearchText + N'%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT
            sa.Id,
            sa.AdjustmentNumber,
            sa.ProductId,
            sa.VariantId,
            ProductName = p.Name + CASE WHEN pv.VariantSummary IS NOT NULL AND pv.VariantSummary <> '' THEN ' (' + pv.VariantSummary + ')' ELSE '' END,
            Sku = ISNULL(pv.Sku, p.Sku),
            sa.WarehouseId,
            WarehouseName = ISNULL(w.WarehouseName, '—'),
            sa.QuantityBefore,
            sa.QuantityChange,
            sa.QuantityAfter,
            sa.ReasonCodeId,
            Reason = ISNULL(rc.Label, 'Manual Adjustment'),
            sa.Note,
            sa.AdjustedOn,
            sa.CreatedAt
        FROM dbo.StockAdjustments sa
        JOIN dbo.Products p ON sa.ProductId = p.Id
        LEFT JOIN dbo.ProductVariants pv ON sa.VariantId = pv.Id
        JOIN dbo.Warehouses w ON sa.WarehouseId = w.Id
        LEFT JOIN dbo.ReasonCodes rc ON sa.ReasonCodeId = rc.Id
        WHERE sa.IsDeleted = 0
          AND (@WarehouseId IS NULL OR sa.WarehouseId = @WarehouseId)
          AND (@ReasonCodeId IS NULL OR sa.ReasonCodeId = @ReasonCodeId)
          AND (@SearchText IS NULL
               OR sa.AdjustmentNumber LIKE N'%' + @SearchText + N'%'
               OR p.Name LIKE N'%' + @SearchText + N'%'
               OR ISNULL(pv.Sku, p.Sku) LIKE N'%' + @SearchText + N'%'
               OR ISNULL(sa.Note, '') LIKE N'%' + @SearchText + N'%')
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'AdjustmentNumber' THEN AdjustmentNumber END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'AdjustmentNumber' THEN AdjustmentNumber END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'ProductName'      THEN ProductName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'ProductName'      THEN ProductName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'WarehouseName'    THEN WarehouseName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'WarehouseName'    THEN WarehouseName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'QuantityChange'   THEN QuantityChange END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'QuantityChange'   THEN QuantityChange END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'AdjustedOn'        THEN AdjustedOn END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'AdjustedOn'        THEN AdjustedOn END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

/* 2. GetById */
CREATE OR ALTER PROCEDURE dbo.usp_StockAdjustment_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        sa.Id,
        sa.AdjustmentNumber,
        sa.ProductId,
        sa.VariantId,
        ProductName = p.Name + CASE WHEN pv.VariantSummary IS NOT NULL AND pv.VariantSummary <> '' THEN ' (' + pv.VariantSummary + ')' ELSE '' END,
        Sku = ISNULL(pv.Sku, p.Sku),
        sa.WarehouseId,
        WarehouseName = ISNULL(w.WarehouseName, '—'),
        sa.QuantityBefore,
        sa.QuantityChange,
        sa.QuantityAfter,
        sa.ReasonCodeId,
        Reason = ISNULL(rc.Label, 'Manual Adjustment'),
        sa.Note,
        sa.AdjustedOn,
        sa.CreatedAt,
        CreatedByName = ISNULL(u.FullName, 'Admin')
    FROM dbo.StockAdjustments sa
    JOIN dbo.Products p ON sa.ProductId = p.Id
    LEFT JOIN dbo.ProductVariants pv ON sa.VariantId = pv.Id
    JOIN dbo.Warehouses w ON sa.WarehouseId = w.Id
    LEFT JOIN dbo.ReasonCodes rc ON sa.ReasonCodeId = rc.Id
    LEFT JOIN dbo.AdminUsers u ON sa.CreatedBy = u.Id
    WHERE sa.Id = @Id AND sa.IsDeleted = 0;
END
GO

/* 3. Save */
CREATE OR ALTER PROCEDURE dbo.usp_StockAdjustment_Save
    @Id              INT             = 0,
    @ProductId       INT,
    @VariantId       INT             = NULL,
    @WarehouseId     INT,
    @QuantityChange  INT,            -- e.g. +5 or -3
    @ReasonCodeId    INT,
    @Note            NVARCHAR(1000)  = NULL,
    @LoggedInUserId  INT             = NULL,
    @NewId           INT             OUTPUT,
    @ErrorMessage    NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    IF @ProductId IS NULL OR @ProductId <= 0
    BEGIN
        SET @ErrorMessage = N'Product is required.';
        RETURN;
    END

    IF @WarehouseId IS NULL OR @WarehouseId <= 0
    BEGIN
        SET @ErrorMessage = N'Warehouse is required.';
        RETURN;
    END

    IF @QuantityChange IS NULL OR @QuantityChange = 0
    BEGIN
        SET @ErrorMessage = N'Quantity change cannot be zero.';
        RETURN;
    END

    IF @ReasonCodeId IS NULL OR @ReasonCodeId <= 0
    BEGIN
        SET @ErrorMessage = N'Reason code is mandatory for stock adjustment.';
        RETURN;
    END

    IF @Id > 0
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.StockAdjustments WHERE Id = @Id AND IsDeleted = 0)
        BEGIN
            SET @ErrorMessage = N'Stock adjustment not found.';
            RETURN;
        END

        DECLARE @OldChange INT, @OldProductId INT, @OldVariantId INT, @OldWarehouseId INT;
        SELECT @OldChange = QuantityChange, @OldProductId = ProductId, @OldVariantId = VariantId, @OldWarehouseId = WarehouseId
        FROM dbo.StockAdjustments WHERE Id = @Id;

        -- Reconcile inventory difference if quantity changed
        DECLARE @Diff INT = @QuantityChange - ISNULL(@OldChange, 0);
        IF @Diff <> 0
        BEGIN
            UPDATE dbo.InventoryStocks
            SET OnHand = OnHand + @Diff,
                UpdatedAt = SYSUTCDATETIME(),
                UpdatedBy = @LoggedInUserId
            WHERE ProductId = @ProductId
              AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL))
              AND WarehouseId = @WarehouseId
              AND IsDeleted = 0;
        END

        UPDATE dbo.StockAdjustments
        SET ReasonCodeId = @ReasonCodeId,
            QuantityChange = @QuantityChange,
            QuantityAfter = QuantityBefore + @QuantityChange,
            Note = @Note,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE Id = @Id;

        SET @NewId = @Id;
        RETURN;
    END

    -- Get current OnHand
    DECLARE @QuantityBefore INT = 0;
    DECLARE @StockExists BIT = 0;

    SELECT TOP 1 @QuantityBefore = OnHand, @StockExists = 1
    FROM dbo.InventoryStocks
    WHERE ProductId = @ProductId
      AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL))
      AND WarehouseId = @WarehouseId
      AND IsDeleted = 0;

    DECLARE @QuantityAfter INT = @QuantityBefore + @QuantityChange;

    IF @QuantityAfter < 0
    BEGIN
        SET @ErrorMessage = N'Insufficient on-hand stock. Current on-hand is ' + CAST(@QuantityBefore AS NVARCHAR(20)) + N', adjustment would make it negative.';
        RETURN;
    END

    -- Generate Adjustment Number
    DECLARE @NextNum INT = ISNULL((SELECT MAX(Id) FROM dbo.StockAdjustments), 0) + 1;
    DECLARE @AdjustmentNumber VARCHAR(32) = 'ADJ-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) + '-' + RIGHT('0000' + CAST(@NextNum AS VARCHAR(10)), 4);

    -- Insert Adjustment Record
    INSERT INTO dbo.StockAdjustments
    (
        AdjustmentNumber, ProductId, VariantId, WarehouseId,
        QuantityBefore, QuantityChange, QuantityAfter, ReasonCodeId,
        Note, AdjustedOn, IsActive, CreatedAt, CreatedBy
    )
    VALUES
    (
        @AdjustmentNumber, @ProductId, @VariantId, @WarehouseId,
        @QuantityBefore, @QuantityChange, @QuantityAfter, @ReasonCodeId,
        @Note, SYSUTCDATETIME(), 1, SYSUTCDATETIME(), @LoggedInUserId
    );

    SET @NewId = SCOPE_IDENTITY();

    -- Update or insert InventoryStocks
    IF @StockExists = 1
    BEGIN
        UPDATE dbo.InventoryStocks
        SET
            OnHand = @QuantityAfter,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE ProductId = @ProductId
          AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL))
          AND WarehouseId = @WarehouseId
          AND IsDeleted = 0;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.InventoryStocks
        (
            ProductId, VariantId, WarehouseId, OnHand, Reserved, Incoming,
            LowStockThreshold, IsActive, CreatedAt, CreatedBy
        )
        VALUES
        (
            @ProductId, @VariantId, @WarehouseId, @QuantityAfter, 0, 0,
            5, 1, SYSUTCDATETIME(), @LoggedInUserId
        );
    END

    -- Record Transaction
    DECLARE @ReasonLabel NVARCHAR(200) = (SELECT Label FROM dbo.ReasonCodes WHERE Id = @ReasonCodeId);
    INSERT INTO dbo.InventoryTransactions
    (
        ProductId, VariantId, WarehouseId, TransactionType,
        QuantityChange, QuantityAfter, ReferenceType, ReferenceId, ReferenceNumber,
        Note, CreatedAt, CreatedBy
    )
    VALUES
    (
        @ProductId, @VariantId, @WarehouseId, 'Adjustment',
        @QuantityChange, @QuantityAfter, 'StockAdjustment', @NewId, @AdjustmentNumber,
        ISNULL(@ReasonLabel, N'Stock Adjustment') + CASE WHEN @Note IS NOT NULL THEN N': ' + @Note ELSE N'' END,
        SYSUTCDATETIME(), @LoggedInUserId
    );
END
GO

/* 4. Delete */
CREATE OR ALTER PROCEDURE dbo.usp_StockAdjustment_Delete
    @Id             INT,
    @LoggedInUserId INT           = NULL,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    UPDATE dbo.StockAdjustments
    SET
        IsDeleted = 1,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id;
END
GO
