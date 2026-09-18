/* =============================================================================
   usp_StockTransfer_Procedures.sql
   Stored procedures for Stock Transfer:
     1. dbo.usp_StockTransfer_GridList
     2. dbo.usp_StockTransfer_GetById
     3. dbo.usp_StockTransfer_Save
     4. dbo.usp_StockTransfer_UpdateStatus
     5. dbo.usp_StockTransfer_Delete
   ============================================================================= */

SET NOCOUNT ON;
GO

/* 1. GridList */
CREATE OR ALTER PROCEDURE dbo.usp_StockTransfer_GridList
    @SearchText           NVARCHAR(200)   = NULL,
    @FromWarehouseId      INT             = NULL,
    @ToWarehouseId        INT             = NULL,
    @Status               VARCHAR(32)     = NULL, -- Draft, In Transit, Received, Cancelled
    @SortColumn           VARCHAR(64)     = 'InitiatedOn',
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

    SELECT @TotalRecords = COUNT(*) FROM dbo.StockTransfers st WHERE st.IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT
            st.Id,
            st.TransferNumber,
            st.FromWarehouseId,
            FromWarehouse = ISNULL(fw.WarehouseName, '—'),
            st.ToWarehouseId,
            ToWarehouse = ISNULL(tw.WarehouseName, '—'),
            st.InitiatedOn,
            st.DispatchedOn,
            st.ReceivedOn,
            st.Status,
            st.TotalQuantity,
            st.Note,
            st.CreatedAt,
            SkuCount = (SELECT COUNT(*) FROM dbo.StockTransferLines stl WHERE stl.StockTransferId = st.Id)
        FROM dbo.StockTransfers st
        JOIN dbo.Warehouses fw ON st.FromWarehouseId = fw.Id
        JOIN dbo.Warehouses tw ON st.ToWarehouseId = tw.Id
        WHERE st.IsDeleted = 0
          AND (@FromWarehouseId IS NULL OR st.FromWarehouseId = @FromWarehouseId)
          AND (@ToWarehouseId IS NULL OR st.ToWarehouseId = @ToWarehouseId)
          AND (@Status IS NULL OR st.Status = @Status)
          AND (@SearchText IS NULL
               OR st.TransferNumber LIKE N'%' + @SearchText + N'%'
               OR fw.WarehouseName LIKE N'%' + @SearchText + N'%'
               OR tw.WarehouseName LIKE N'%' + @SearchText + N'%'
               OR ISNULL(st.Note, '') LIKE N'%' + @SearchText + N'%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT
            st.Id,
            st.TransferNumber,
            st.FromWarehouseId,
            FromWarehouse = ISNULL(fw.WarehouseName, '—'),
            st.ToWarehouseId,
            ToWarehouse = ISNULL(tw.WarehouseName, '—'),
            st.InitiatedOn,
            st.DispatchedOn,
            st.ReceivedOn,
            st.Status,
            st.TotalQuantity,
            st.Note,
            st.CreatedAt,
            SkuCount = (SELECT COUNT(*) FROM dbo.StockTransferLines stl WHERE stl.StockTransferId = st.Id)
        FROM dbo.StockTransfers st
        JOIN dbo.Warehouses fw ON st.FromWarehouseId = fw.Id
        JOIN dbo.Warehouses tw ON st.ToWarehouseId = tw.Id
        WHERE st.IsDeleted = 0
          AND (@FromWarehouseId IS NULL OR st.FromWarehouseId = @FromWarehouseId)
          AND (@ToWarehouseId IS NULL OR st.ToWarehouseId = @ToWarehouseId)
          AND (@Status IS NULL OR st.Status = @Status)
          AND (@SearchText IS NULL
               OR st.TransferNumber LIKE N'%' + @SearchText + N'%'
               OR fw.WarehouseName LIKE N'%' + @SearchText + N'%'
               OR tw.WarehouseName LIKE N'%' + @SearchText + N'%'
               OR ISNULL(st.Note, '') LIKE N'%' + @SearchText + N'%')
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'TransferNumber' THEN TransferNumber END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'TransferNumber' THEN TransferNumber END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'FromWarehouse'  THEN FromWarehouse END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'FromWarehouse'  THEN FromWarehouse END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'ToWarehouse'    THEN ToWarehouse END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'ToWarehouse'    THEN ToWarehouse END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'TotalQuantity'  THEN TotalQuantity END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'TotalQuantity'  THEN TotalQuantity END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Status'         THEN Status END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Status'         THEN Status END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'InitiatedOn'    THEN InitiatedOn END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'InitiatedOn'    THEN InitiatedOn END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

/* 2. GetById */
CREATE OR ALTER PROCEDURE dbo.usp_StockTransfer_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1st result set: Header
    SELECT
        st.Id,
        st.TransferNumber,
        st.FromWarehouseId,
        FromWarehouseName = fw.WarehouseName,
        FromWarehouseCode = fw.Code,
        st.ToWarehouseId,
        ToWarehouseName = tw.WarehouseName,
        ToWarehouseCode = tw.Code,
        st.InitiatedOn,
        st.DispatchedOn,
        st.ReceivedOn,
        st.Status,
        st.TotalQuantity,
        st.Note,
        st.IsActive,
        st.CreatedAt,
        st.UpdatedAt,
        CreatedByName = ISNULL(u.FullName, 'Admin')
    FROM dbo.StockTransfers st
    JOIN dbo.Warehouses fw ON st.FromWarehouseId = fw.Id
    JOIN dbo.Warehouses tw ON st.ToWarehouseId = tw.Id
    LEFT JOIN dbo.AdminUsers u ON st.CreatedBy = u.Id
    WHERE st.Id = @Id AND st.IsDeleted = 0;

    -- 2nd result set: Line items
    SELECT
        stl.Id,
        stl.StockTransferId,
        stl.ProductId,
        stl.VariantId,
        stl.Sku,
        ProductName = p.Name + CASE WHEN pv.VariantSummary IS NOT NULL AND pv.VariantSummary <> '' THEN ' (' + pv.VariantSummary + ')' ELSE '' END,
        stl.QuantitySent,
        stl.QuantityReceived,
        SourceAvailable = ISNULL(stk.OnHand - stk.Reserved, 0)
    FROM dbo.StockTransferLines stl
    JOIN dbo.StockTransfers st ON stl.StockTransferId = st.Id
    JOIN dbo.Products p ON stl.ProductId = p.Id
    LEFT JOIN dbo.ProductVariants pv ON stl.VariantId = pv.Id
    LEFT JOIN dbo.InventoryStocks stk ON stl.ProductId = stk.ProductId
        AND (stl.VariantId = stk.VariantId OR (stl.VariantId IS NULL AND stk.VariantId IS NULL))
        AND stk.WarehouseId = st.FromWarehouseId AND stk.IsDeleted = 0
    WHERE stl.StockTransferId = @Id
    ORDER BY stl.Id ASC;
END
GO

/* 3. Save */
CREATE OR ALTER PROCEDURE dbo.usp_StockTransfer_Save
    @Id               INT             = 0,
    @FromWarehouseId  INT,
    @ToWarehouseId    INT,
    @Note             NVARCHAR(1000)  = NULL,
    @LinesJson        NVARCHAR(MAX),  -- JSON: [{ProductId, VariantId, Sku, QuantitySent}]
    @LoggedInUserId   INT             = NULL,
    @NewId            INT             OUTPUT,
    @ErrorMessage     NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    IF @FromWarehouseId IS NULL OR @FromWarehouseId <= 0
    BEGIN
        SET @ErrorMessage = N'Source warehouse is required.';
        RETURN;
    END

    IF @ToWarehouseId IS NULL OR @ToWarehouseId <= 0
    BEGIN
        SET @ErrorMessage = N'Destination warehouse is required.';
        RETURN;
    END

    IF @FromWarehouseId = @ToWarehouseId
    BEGIN
        SET @ErrorMessage = N'Source and Destination warehouses cannot be the same.';
        RETURN;
    END

    -- Parse lines into temp table
    CREATE TABLE #Lines
    (
        ProductId    INT,
        VariantId    INT NULL,
        Sku          VARCHAR(64),
        QuantitySent INT
    );

    IF ISNULL(@LinesJson, '') <> '' AND ISJSON(@LinesJson) = 1
    BEGIN
        INSERT INTO #Lines (ProductId, VariantId, Sku, QuantitySent)
        SELECT
            ProductId,
            NULLIF(VariantId, 0),
            ISNULL(Sku, 'SKU'),
            ISNULL(QuantitySent, 1)
        FROM OPENJSON(@LinesJson)
        WITH
        (
            ProductId    INT,
            VariantId    INT,
            Sku          VARCHAR(64),
            QuantitySent INT
        );
    END

    IF NOT EXISTS (SELECT 1 FROM #Lines)
    BEGIN
        SET @ErrorMessage = N'Stock transfer must have at least one product item.';
        DROP TABLE #Lines;
        RETURN;
    END

    -- Verify stock availability at source warehouse
    IF EXISTS (
        SELECT 1
        FROM #Lines l
        LEFT JOIN dbo.InventoryStocks s ON l.ProductId = s.ProductId
            AND (l.VariantId = s.VariantId OR (l.VariantId IS NULL AND s.VariantId IS NULL))
            AND s.WarehouseId = @FromWarehouseId AND s.IsDeleted = 0
        WHERE l.QuantitySent > ISNULL(s.OnHand - s.Reserved, 0)
    )
    BEGIN
        SET @ErrorMessage = N'One or more items exceed available stock at the source warehouse.';
        DROP TABLE #Lines;
        RETURN;
    END

    DECLARE @TotalQuantity INT = ISNULL((SELECT SUM(QuantitySent) FROM #Lines), 0);

    IF @Id = 0
    BEGIN
        DECLARE @NextNum INT = ISNULL((SELECT MAX(Id) FROM dbo.StockTransfers), 0) + 1;
        DECLARE @TransferNumber VARCHAR(32) = 'TRF-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) + '-' + RIGHT('0000' + CAST(@NextNum AS VARCHAR(10)), 4);

        INSERT INTO dbo.StockTransfers
        (
            TransferNumber, FromWarehouseId, ToWarehouseId, InitiatedOn,
            Status, TotalQuantity, Note, IsActive, CreatedAt, CreatedBy
        )
        VALUES
        (
            @TransferNumber, @FromWarehouseId, @ToWarehouseId, SYSUTCDATETIME(),
            'Draft', @TotalQuantity, @Note, 1, SYSUTCDATETIME(), @LoggedInUserId
        );

        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.StockTransfers WHERE Id = @Id AND Status IN ('In Transit', 'Received'))
        BEGIN
            UPDATE dbo.StockTransfers
            SET Note = @Note, UpdatedAt = SYSUTCDATETIME(), UpdatedBy = @LoggedInUserId
            WHERE Id = @Id;

            SET @NewId = @Id;
            DROP TABLE #Lines;
            RETURN;
        END

        UPDATE dbo.StockTransfers
        SET
            FromWarehouseId = @FromWarehouseId,
            ToWarehouseId = @ToWarehouseId,
            TotalQuantity = @TotalQuantity,
            Note = @Note,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE Id = @Id;

        SET @NewId = @Id;
        DELETE FROM dbo.StockTransferLines WHERE StockTransferId = @Id;
    END

    INSERT INTO dbo.StockTransferLines
    (
        StockTransferId, ProductId, VariantId, Sku, QuantitySent, QuantityReceived
    )
    SELECT
        @NewId, ProductId, VariantId, Sku, QuantitySent, 0
    FROM #Lines;

    DROP TABLE #Lines;
END
GO

/* 4. UpdateStatus (Dispatch, Receive, Cancel workflow) */
CREATE OR ALTER PROCEDURE dbo.usp_StockTransfer_UpdateStatus
    @Id             INT,
    @NewStatus      VARCHAR(32), -- 'In Transit', 'Received', 'Cancelled'
    @LoggedInUserId INT           = NULL,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    DECLARE @CurrentStatus VARCHAR(32), @FromWarehouseId INT, @ToWarehouseId INT, @TransferNumber VARCHAR(32);

    SELECT
        @CurrentStatus = Status,
        @FromWarehouseId = FromWarehouseId,
        @ToWarehouseId = ToWarehouseId,
        @TransferNumber = TransferNumber
    FROM dbo.StockTransfers
    WHERE Id = @Id AND IsDeleted = 0;

    IF @CurrentStatus IS NULL
    BEGIN
        SET @ErrorMessage = N'Stock transfer not found.';
        RETURN;
    END

    -- Dispatch: Draft -> In Transit
    IF @NewStatus = 'In Transit' AND @CurrentStatus = 'Draft'
    BEGIN
        -- Deduct from source warehouse
        DECLARE @ProductId INT, @VariantId INT, @QtySent INT;

        DECLARE cur_dispatch CURSOR LOCAL FAST_FORWARD FOR
        SELECT ProductId, VariantId, QuantitySent FROM dbo.StockTransferLines WHERE StockTransferId = @Id;

        OPEN cur_dispatch;
        FETCH NEXT FROM cur_dispatch INTO @ProductId, @VariantId, @QtySent;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            UPDATE dbo.InventoryStocks
            SET
                OnHand = OnHand - @QtySent,
                UpdatedAt = SYSUTCDATETIME(),
                UpdatedBy = @LoggedInUserId
            WHERE ProductId = @ProductId
              AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL))
              AND WarehouseId = @FromWarehouseId
              AND IsDeleted = 0;

            DECLARE @AfterQty INT = (SELECT OnHand FROM dbo.InventoryStocks WHERE ProductId = @ProductId AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL)) AND WarehouseId = @FromWarehouseId AND IsDeleted = 0);

            INSERT INTO dbo.InventoryTransactions
            (
                ProductId, VariantId, WarehouseId, TransactionType,
                QuantityChange, QuantityAfter, ReferenceType, ReferenceId, ReferenceNumber,
                Note, CreatedAt, CreatedBy
            )
            VALUES
            (
                @ProductId, @VariantId, @FromWarehouseId, 'Transfer',
                -@QtySent, @AfterQty, 'StockTransfer', @Id, @TransferNumber,
                N'Stock dispatched on transfer ' + @TransferNumber, SYSUTCDATETIME(), @LoggedInUserId
            );

            FETCH NEXT FROM cur_dispatch INTO @ProductId, @VariantId, @QtySent;
        END

        CLOSE cur_dispatch;
        DEALLOCATE cur_dispatch;

        UPDATE dbo.StockTransfers
        SET
            Status = 'In Transit',
            DispatchedOn = SYSUTCDATETIME(),
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE Id = @Id;
        RETURN;
    END

    -- Receive: In Transit -> Received
    IF @NewStatus = 'Received' AND @CurrentStatus = 'In Transit'
    BEGIN
        DECLARE cur_receive CURSOR LOCAL FAST_FORWARD FOR
        SELECT ProductId, VariantId, QuantitySent FROM dbo.StockTransferLines WHERE StockTransferId = @Id;

        OPEN cur_receive;
        FETCH NEXT FROM cur_receive INTO @ProductId, @VariantId, @QtySent;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Ensure record at destination
            IF NOT EXISTS (
                SELECT 1 FROM dbo.InventoryStocks
                WHERE ProductId = @ProductId
                  AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL))
                  AND WarehouseId = @ToWarehouseId AND IsDeleted = 0
            )
            BEGIN
                INSERT INTO dbo.InventoryStocks
                (
                    ProductId, VariantId, WarehouseId, OnHand, Reserved, Incoming,
                    LowStockThreshold, IsActive, CreatedAt, CreatedBy
                )
                VALUES
                (
                    @ProductId, @VariantId, @ToWarehouseId, 0, 0, 0,
                    5, 1, SYSUTCDATETIME(), @LoggedInUserId
                );
            END

            UPDATE dbo.InventoryStocks
            SET
                OnHand = OnHand + @QtySent,
                UpdatedAt = SYSUTCDATETIME(),
                UpdatedBy = @LoggedInUserId
            WHERE ProductId = @ProductId
              AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL))
              AND WarehouseId = @ToWarehouseId AND IsDeleted = 0;

            DECLARE @DestAfterQty INT = (SELECT OnHand FROM dbo.InventoryStocks WHERE ProductId = @ProductId AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL)) AND WarehouseId = @ToWarehouseId AND IsDeleted = 0);

            INSERT INTO dbo.InventoryTransactions
            (
                ProductId, VariantId, WarehouseId, TransactionType,
                QuantityChange, QuantityAfter, ReferenceType, ReferenceId, ReferenceNumber,
                Note, CreatedAt, CreatedBy
            )
            VALUES
            (
                @ProductId, @VariantId, @ToWarehouseId, 'Transfer',
                @QtySent, @DestAfterQty, 'StockTransfer', @Id, @TransferNumber,
                N'Stock received from transfer ' + @TransferNumber, SYSUTCDATETIME(), @LoggedInUserId
            );

            UPDATE dbo.StockTransferLines
            SET QuantityReceived = @QtySent
            WHERE StockTransferId = @Id AND ProductId = @ProductId AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL));

            FETCH NEXT FROM cur_receive INTO @ProductId, @VariantId, @QtySent;
        END

        CLOSE cur_receive;
        DEALLOCATE cur_receive;

        UPDATE dbo.StockTransfers
        SET
            Status = 'Received',
            ReceivedOn = SYSUTCDATETIME(),
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE Id = @Id;
        RETURN;
    END

    -- Cancel: Draft -> Cancelled (or In Transit -> Cancelled restores source stock)
    IF @NewStatus = 'Cancelled'
    BEGIN
        IF @CurrentStatus = 'In Transit'
        BEGIN
            -- Restore stock to source
            DECLARE cur_restore CURSOR LOCAL FAST_FORWARD FOR
            SELECT ProductId, VariantId, QuantitySent FROM dbo.StockTransferLines WHERE StockTransferId = @Id;

            OPEN cur_restore;
            FETCH NEXT FROM cur_restore INTO @ProductId, @VariantId, @QtySent;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                UPDATE dbo.InventoryStocks
                SET OnHand = OnHand + @QtySent, UpdatedAt = SYSUTCDATETIME(), UpdatedBy = @LoggedInUserId
                WHERE ProductId = @ProductId AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL)) AND WarehouseId = @FromWarehouseId AND IsDeleted = 0;

                DECLARE @RestoreAfterQty INT = (SELECT OnHand FROM dbo.InventoryStocks WHERE ProductId = @ProductId AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL)) AND WarehouseId = @FromWarehouseId AND IsDeleted = 0);

                INSERT INTO dbo.InventoryTransactions
                (
                    ProductId, VariantId, WarehouseId, TransactionType,
                    QuantityChange, QuantityAfter, ReferenceType, ReferenceId, ReferenceNumber,
                    Note, CreatedAt, CreatedBy
                )
                VALUES
                (
                    @ProductId, @VariantId, @FromWarehouseId, 'Transfer',
                    @QtySent, @RestoreAfterQty, 'StockTransfer', @Id, @TransferNumber,
                    N'Transfer cancelled - stock restored to source', SYSUTCDATETIME(), @LoggedInUserId
                );

                FETCH NEXT FROM cur_restore INTO @ProductId, @VariantId, @QtySent;
            END

            CLOSE cur_restore;
            DEALLOCATE cur_restore;
        END

        UPDATE dbo.StockTransfers
        SET
            Status = 'Cancelled',
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE Id = @Id;
        RETURN;
    END

    SET @ErrorMessage = N'Invalid status transition from ' + @CurrentStatus + N' to ' + @NewStatus;
END
GO

/* 5. Delete */
CREATE OR ALTER PROCEDURE dbo.usp_StockTransfer_Delete
    @Id             INT,
    @LoggedInUserId INT           = NULL,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    IF EXISTS (SELECT 1 FROM dbo.StockTransfers WHERE Id = @Id AND Status = 'In Transit')
    BEGIN
        SET @ErrorMessage = N'Cannot delete transfer that is in transit. Cancel it first to restore stock.';
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.StockTransfers WHERE Id = @Id AND Status = 'Received')
    BEGIN
        SET @ErrorMessage = N'Cannot delete a completed stock transfer.';
        RETURN;
    END

    UPDATE dbo.StockTransfers
    SET
        IsDeleted = 1,
        Status = 'Cancelled',
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id;
END
GO
