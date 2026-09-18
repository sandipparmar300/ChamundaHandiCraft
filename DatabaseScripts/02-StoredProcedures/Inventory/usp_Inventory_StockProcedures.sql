/* =============================================================================
   usp_Inventory_StockProcedures.sql
   Stored procedures for Stock & Inventory Management:
     1. dbo.usp_Inventory_GridList
     2. dbo.usp_Inventory_GetById
     3. dbo.usp_Inventory_Save
     4. dbo.usp_Inventory_Delete
     5. dbo.usp_Inventory_GetKpis
     6. dbo.usp_Inventory_GetLedger
   ============================================================================= */

SET NOCOUNT ON;
GO

/* 1. GridList */
CREATE OR ALTER PROCEDURE dbo.usp_Inventory_GridList
    @SearchText           NVARCHAR(200)   = NULL,
    @WarehouseId          INT             = NULL,
    @StockStatus          VARCHAR(32)     = NULL, -- InStock, LowStock, OutOfStock, Reserved
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

    SELECT @TotalRecords = COUNT(*) FROM dbo.InventoryStocks s WHERE s.IsDeleted = 0;

    ;WITH BaseData AS
    (
        SELECT
            s.Id,
            s.ProductId,
            s.VariantId,
            ProductName = p.Name + CASE WHEN pv.VariantSummary IS NOT NULL AND pv.VariantSummary <> '' THEN ' (' + pv.VariantSummary + ')' ELSE '' END,
            Sku = ISNULL(pv.Sku, p.Sku),
            Barcode = ISNULL(pv.Barcode, p.Barcode),
            s.WarehouseId,
            WarehouseName = ISNULL(w.WarehouseName, '—'),
            s.OnHand,
            s.Reserved,
            s.Incoming,
            Available = CASE WHEN (s.OnHand - s.Reserved) < 0 THEN 0 ELSE (s.OnHand - s.Reserved) END,
            s.LowStockThreshold,
            s.BinLocation,
            s.LastCountedOn,
            s.UpdatedAt,
            CostPrice = ISNULL(pv.CostPrice, ISNULL(p.CostPrice, 0)),
            Price = ISNULL(pv.Price, p.Price),
            StockState = CASE
                WHEN (s.OnHand - s.Reserved) <= 0 THEN 'OutOfStock'
                WHEN (s.OnHand - s.Reserved) <= s.LowStockThreshold THEN 'LowStock'
                ELSE 'InStock'
            END
        FROM dbo.InventoryStocks s
        JOIN dbo.Products p ON s.ProductId = p.Id AND p.IsDeleted = 0
        LEFT JOIN dbo.ProductVariants pv ON s.VariantId = pv.Id AND pv.IsDeleted = 0
        LEFT JOIN dbo.Warehouses w ON s.WarehouseId = w.Id AND w.IsDeleted = 0
        WHERE s.IsDeleted = 0
          AND (@WarehouseId IS NULL OR s.WarehouseId = @WarehouseId)
          AND (@SearchText IS NULL
               OR p.Name LIKE N'%' + @SearchText + N'%'
               OR ISNULL(pv.Sku, p.Sku) LIKE N'%' + @SearchText + N'%'
               OR ISNULL(pv.Barcode, p.Barcode) LIKE N'%' + @SearchText + N'%'
               OR ISNULL(s.BinLocation, '') LIKE N'%' + @SearchText + N'%')
    ),
    Filtered AS
    (
        SELECT *
        FROM BaseData
        WHERE (@StockStatus IS NULL
               OR (@StockStatus = 'InStock' AND StockState = 'InStock')
               OR (@StockStatus = 'LowStock' AND StockState = 'LowStock')
               OR (@StockStatus = 'OutOfStock' AND StockState = 'OutOfStock')
               OR (@StockStatus = 'Reserved' AND Reserved > 0))
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH BaseData AS
    (
        SELECT
            s.Id,
            s.ProductId,
            s.VariantId,
            ProductName = p.Name + CASE WHEN pv.VariantSummary IS NOT NULL AND pv.VariantSummary <> '' THEN ' (' + pv.VariantSummary + ')' ELSE '' END,
            Sku = ISNULL(pv.Sku, p.Sku),
            Barcode = ISNULL(pv.Barcode, p.Barcode),
            s.WarehouseId,
            WarehouseName = ISNULL(w.WarehouseName, '—'),
            s.OnHand,
            s.Reserved,
            s.Incoming,
            Available = CASE WHEN (s.OnHand - s.Reserved) < 0 THEN 0 ELSE (s.OnHand - s.Reserved) END,
            s.LowStockThreshold,
            s.BinLocation,
            s.LastCountedOn,
            s.UpdatedAt,
            CostPrice = ISNULL(pv.CostPrice, ISNULL(p.CostPrice, 0)),
            Price = ISNULL(pv.Price, p.Price),
            StockState = CASE
                WHEN (s.OnHand - s.Reserved) <= 0 THEN 'OutOfStock'
                WHEN (s.OnHand - s.Reserved) <= s.LowStockThreshold THEN 'LowStock'
                ELSE 'InStock'
            END
        FROM dbo.InventoryStocks s
        JOIN dbo.Products p ON s.ProductId = p.Id AND p.IsDeleted = 0
        LEFT JOIN dbo.ProductVariants pv ON s.VariantId = pv.Id AND pv.IsDeleted = 0
        LEFT JOIN dbo.Warehouses w ON s.WarehouseId = w.Id AND w.IsDeleted = 0
        WHERE s.IsDeleted = 0
          AND (@WarehouseId IS NULL OR s.WarehouseId = @WarehouseId)
          AND (@SearchText IS NULL
               OR p.Name LIKE N'%' + @SearchText + N'%'
               OR ISNULL(pv.Sku, p.Sku) LIKE N'%' + @SearchText + N'%'
               OR ISNULL(pv.Barcode, p.Barcode) LIKE N'%' + @SearchText + N'%'
               OR ISNULL(s.BinLocation, '') LIKE N'%' + @SearchText + N'%')
    ),
    Filtered AS
    (
        SELECT *
        FROM BaseData
        WHERE (@StockStatus IS NULL
               OR (@StockStatus = 'InStock' AND StockState = 'InStock')
               OR (@StockStatus = 'LowStock' AND StockState = 'LowStock')
               OR (@StockStatus = 'OutOfStock' AND StockState = 'OutOfStock')
               OR (@StockStatus = 'Reserved' AND Reserved > 0))
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'ProductName'   THEN ProductName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'ProductName'   THEN ProductName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Sku'           THEN Sku END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Sku'           THEN Sku END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'WarehouseName' THEN WarehouseName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'WarehouseName' THEN WarehouseName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'OnHand'        THEN OnHand END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'OnHand'        THEN OnHand END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Available'     THEN Available END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Available'     THEN Available END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'UpdatedAt'     THEN UpdatedAt END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'UpdatedAt'     THEN UpdatedAt END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

/* 2. GetById */
CREATE OR ALTER PROCEDURE dbo.usp_Inventory_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.Id,
        s.ProductId,
        s.VariantId,
        ProductName = p.Name + CASE WHEN pv.VariantSummary IS NOT NULL AND pv.VariantSummary <> '' THEN ' (' + pv.VariantSummary + ')' ELSE '' END,
        Sku = ISNULL(pv.Sku, p.Sku),
        Barcode = ISNULL(pv.Barcode, p.Barcode),
        s.WarehouseId,
        WarehouseName = ISNULL(w.WarehouseName, '—'),
        s.OnHand,
        s.Reserved,
        s.Incoming,
        Available = CASE WHEN (s.OnHand - s.Reserved) < 0 THEN 0 ELSE (s.OnHand - s.Reserved) END,
        s.LowStockThreshold,
        s.BinLocation,
        s.LastCountedOn,
        s.CreatedAt,
        s.UpdatedAt,
        CostPrice = ISNULL(pv.CostPrice, ISNULL(p.CostPrice, 0)),
        Price = ISNULL(pv.Price, p.Price),
        InventoryValue = s.OnHand * ISNULL(pv.CostPrice, ISNULL(p.CostPrice, 0))
    FROM dbo.InventoryStocks s
    JOIN dbo.Products p ON s.ProductId = p.Id AND p.IsDeleted = 0
    LEFT JOIN dbo.ProductVariants pv ON s.VariantId = pv.Id AND pv.IsDeleted = 0
    LEFT JOIN dbo.Warehouses w ON s.WarehouseId = w.Id AND w.IsDeleted = 0
    WHERE s.Id = @Id AND s.IsDeleted = 0;
END
GO

/* 3. Save (Insert / Update Stock) */
CREATE OR ALTER PROCEDURE dbo.usp_Inventory_Save
    @Id                BIGINT          = 0,
    @ProductId         INT,
    @VariantId         INT             = NULL,
    @WarehouseId       INT,
    @OnHand            INT             = 0,
    @LowStockThreshold INT             = 5,
    @BinLocation       NVARCHAR(64)    = NULL,
    @LoggedInUserId    INT             = NULL,
    @Note              NVARCHAR(500)   = NULL,
    @NewId             BIGINT          OUTPUT,
    @ErrorMessage      NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    IF @ProductId IS NULL OR @ProductId <= 0
    BEGIN
        SET @ErrorMessage = N'Product is required.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE Id = @ProductId AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Selected product does not exist or has been removed.';
        RETURN;
    END

    IF @WarehouseId IS NULL OR @WarehouseId <= 0
    BEGIN
        SET @ErrorMessage = N'Warehouse is required.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.Warehouses WHERE Id = @WarehouseId AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Selected warehouse does not exist or has been removed.';
        RETURN;
    END

    IF @VariantId IS NOT NULL AND @VariantId > 0 AND NOT EXISTS (SELECT 1 FROM dbo.ProductVariants WHERE Id = @VariantId AND ProductId = @ProductId AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Selected product variant does not exist.';
        RETURN;
    END

    IF @VariantId = 0 SET @VariantId = NULL;

    IF @OnHand < 0
    BEGIN
        SET @ErrorMessage = N'On-hand stock quantity cannot be negative.';
        RETURN;
    END

    IF @LowStockThreshold < 0 SET @LowStockThreshold = 0;

    DECLARE @PreviousOnHand INT = 0;
    DECLARE @StockId BIGINT = @Id;

    -- Check if stock row exists for this combination
    IF @StockId = 0
    BEGIN
        SELECT TOP 1 @StockId = Id, @PreviousOnHand = OnHand
        FROM dbo.InventoryStocks
        WHERE ProductId = @ProductId
          AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL))
          AND WarehouseId = @WarehouseId
        ORDER BY IsDeleted ASC;
    END
    ELSE
    BEGIN
        SELECT @PreviousOnHand = OnHand FROM dbo.InventoryStocks WHERE Id = @StockId;

        -- Prevent duplicate combination on edit
        IF EXISTS (
            SELECT 1 FROM dbo.InventoryStocks
            WHERE ProductId = @ProductId
              AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL))
              AND WarehouseId = @WarehouseId
              AND Id <> @StockId
              AND IsDeleted = 0
        )
        BEGIN
            SET @ErrorMessage = N'A stock record already exists for this product, variant, and warehouse.';
            RETURN;
        END
    END

    IF @StockId > 0
    BEGIN
        -- Update
        UPDATE dbo.InventoryStocks
        SET
            ProductId = @ProductId,
            VariantId = @VariantId,
            WarehouseId = @WarehouseId,
            OnHand = @OnHand,
            LowStockThreshold = @LowStockThreshold,
            BinLocation = @BinLocation,
            IsDeleted = 0,
            IsActive = 1,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE Id = @StockId;

        SET @NewId = @StockId;

        -- Record ledger entry if quantity changed
        DECLARE @Diff INT = @OnHand - @PreviousOnHand;
        IF @Diff <> 0
        BEGIN
            INSERT INTO dbo.InventoryTransactions
            (
                ProductId, VariantId, WarehouseId, TransactionType,
                QuantityChange, QuantityAfter, ReferenceType, ReferenceNumber,
                Note, CreatedAt, CreatedBy
            )
            VALUES
            (
                @ProductId, @VariantId, @WarehouseId, 'Adjustment',
                @Diff, @OnHand, 'Manual', 'STOCK-UPDATE',
                ISNULL(@Note, N'Stock updated directly from Stock management'), SYSUTCDATETIME(), @LoggedInUserId
            );
        END
    END
    ELSE
    BEGIN
        -- Insert new stock position
        INSERT INTO dbo.InventoryStocks
        (
            ProductId, VariantId, WarehouseId, OnHand, Reserved, Incoming,
            LowStockThreshold, BinLocation, IsActive, CreatedAt, CreatedBy
        )
        VALUES
        (
            @ProductId, @VariantId, @WarehouseId, @OnHand, 0, 0,
            @LowStockThreshold, @BinLocation, 1, SYSUTCDATETIME(), @LoggedInUserId
        );

        SET @NewId = SCOPE_IDENTITY();

        IF @OnHand > 0
        BEGIN
            INSERT INTO dbo.InventoryTransactions
            (
                ProductId, VariantId, WarehouseId, TransactionType,
                QuantityChange, QuantityAfter, ReferenceType, ReferenceNumber,
                Note, CreatedAt, CreatedBy
            )
            VALUES
            (
                @ProductId, @VariantId, @WarehouseId, 'Adjustment',
                @OnHand, @OnHand, 'Manual', 'STOCK-INIT',
                ISNULL(@Note, N'Initial stock position added'), SYSUTCDATETIME(), @LoggedInUserId
            );
        END
    END
END
GO

/* 4. Delete */
CREATE OR ALTER PROCEDURE dbo.usp_Inventory_Delete
    @Id             BIGINT,
    @LoggedInUserId INT           = NULL,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    IF NOT EXISTS (SELECT 1 FROM dbo.InventoryStocks WHERE Id = @Id AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Stock record not found or already deleted.';
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.InventoryStocks WHERE Id = @Id AND Reserved > 0)
    BEGIN
        SET @ErrorMessage = N'Cannot delete stock record with reserved units held by active customer orders.';
        RETURN;
    END

    UPDATE dbo.InventoryStocks
    SET
        IsDeleted = 1,
        IsActive = 0,
        OnHand = 0,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id;
END
GO

/* 5. GetKpis */
CREATE OR ALTER PROCEDURE dbo.usp_Inventory_GetKpis
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        TotalProducts = (SELECT COUNT(DISTINCT ProductId) FROM dbo.InventoryStocks WHERE IsDeleted = 0),
        TotalStockQuantity = ISNULL((SELECT SUM(OnHand) FROM dbo.InventoryStocks WHERE IsDeleted = 0), 0),
        TotalReservedQuantity = ISNULL((SELECT SUM(Reserved) FROM dbo.InventoryStocks WHERE IsDeleted = 0), 0),
        TotalInventoryValue = ISNULL((
            SELECT SUM(s.OnHand * ISNULL(pv.CostPrice, ISNULL(p.CostPrice, 0)))
            FROM dbo.InventoryStocks s
            JOIN dbo.Products p ON s.ProductId = p.Id AND p.IsDeleted = 0
            LEFT JOIN dbo.ProductVariants pv ON s.VariantId = pv.Id AND pv.IsDeleted = 0
            WHERE s.IsDeleted = 0
        ), 0),
        LowStockProducts = ISNULL((
            SELECT COUNT(*)
            FROM dbo.InventoryStocks s
            WHERE s.IsDeleted = 0
              AND (s.OnHand - s.Reserved) > 0
              AND (s.OnHand - s.Reserved) <= s.LowStockThreshold
        ), 0),
        OutOfStockProducts = ISNULL((
            SELECT COUNT(*)
            FROM dbo.InventoryStocks s
            WHERE s.IsDeleted = 0
              AND (s.OnHand - s.Reserved) <= 0
        ), 0),
        WarehousesCount = (SELECT COUNT(*) FROM dbo.Warehouses WHERE IsActive = 1 AND IsDeleted = 0),
        SuppliersCount = (SELECT COUNT(*) FROM dbo.Suppliers WHERE IsActive = 1 AND IsDeleted = 0),
        PendingPurchaseCount = (SELECT COUNT(*) FROM dbo.PurchaseOrders WHERE Status IN ('Draft','Sent','PartiallyReceived') AND IsDeleted = 0);
END
GO

/* 6. GetLedger */
CREATE OR ALTER PROCEDURE dbo.usp_Inventory_GetLedger
    @ProductId   INT  = NULL,
    @WarehouseId INT  = NULL,
    @MaxRows     INT  = 100
AS
BEGIN
    SET NOCOUNT ON;
    IF @MaxRows IS NULL OR @MaxRows < 1 SET @MaxRows = 100;

    SELECT TOP (@MaxRows)
        t.Id,
        t.ProductId,
        ProductName = p.Name + CASE WHEN pv.VariantSummary IS NOT NULL AND pv.VariantSummary <> '' THEN ' (' + pv.VariantSummary + ')' ELSE '' END,
        Sku = ISNULL(pv.Sku, p.Sku),
        t.WarehouseId,
        WarehouseName = ISNULL(w.WarehouseName, '—'),
        t.TransactionType,
        t.QuantityChange,
        t.QuantityAfter,
        t.ReferenceType,
        t.ReferenceNumber,
        t.UnitCost,
        t.Note,
        t.CreatedAt,
        CreatedByName = ISNULL(u.FullName, 'System')
    FROM dbo.InventoryTransactions t
    JOIN dbo.Products p ON t.ProductId = p.Id
    LEFT JOIN dbo.ProductVariants pv ON t.VariantId = pv.Id
    LEFT JOIN dbo.Warehouses w ON t.WarehouseId = w.Id
    LEFT JOIN dbo.AdminUsers u ON t.CreatedBy = u.Id
    WHERE (@ProductId IS NULL OR t.ProductId = @ProductId)
      AND (@WarehouseId IS NULL OR t.WarehouseId = @WarehouseId)
    ORDER BY t.CreatedAt DESC;
END
GO
