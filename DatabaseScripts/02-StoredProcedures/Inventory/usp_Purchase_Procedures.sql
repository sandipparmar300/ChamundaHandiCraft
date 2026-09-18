/* =============================================================================
   usp_Purchase_Procedures.sql
   Stored procedures for Purchase Management:
     1. dbo.usp_Purchase_GridList
     2. dbo.usp_Purchase_GetById
     3. dbo.usp_Purchase_Save
     4. dbo.usp_Purchase_Delete
     5. dbo.usp_Purchase_UpdateStatus
     6. dbo.usp_Purchase_ReceiveStock
   ============================================================================= */

SET NOCOUNT ON;
GO

/* 1. GridList */
CREATE OR ALTER PROCEDURE dbo.usp_Purchase_GridList
    @SearchText           NVARCHAR(200)   = NULL,
    @SupplierId           INT             = NULL,
    @WarehouseId          INT             = NULL,
    @Status               VARCHAR(32)     = NULL, -- Draft, Sent, PartiallyReceived, Received, Cancelled
    @SortColumn           VARCHAR(64)     = 'OrderedOn',
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

    SELECT @TotalRecords = COUNT(*) FROM dbo.PurchaseOrders po WHERE po.IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT
            po.Id,
            po.PoNumber,
            po.SupplierId,
            SupplierName = ISNULL(s.SupplierName, '—'),
            po.WarehouseId,
            WarehouseName = ISNULL(w.WarehouseName, '—'),
            po.OrderedOn,
            po.ExpectedOn,
            po.ReceivedOn,
            po.Status,
            po.SubTotal,
            po.TaxAmount,
            po.ShippingCost,
            po.TotalValue,
            po.QuantityOrdered,
            po.QuantityReceived,
            po.SupplierInvoiceNo,
            po.CreatedAt,
            LineCount = (SELECT COUNT(*) FROM dbo.PurchaseOrderLines pol WHERE pol.PurchaseOrderId = po.Id)
        FROM dbo.PurchaseOrders po
        JOIN dbo.Suppliers s ON po.SupplierId = s.Id
        JOIN dbo.Warehouses w ON po.WarehouseId = w.Id
        WHERE po.IsDeleted = 0
          AND (@SupplierId IS NULL OR po.SupplierId = @SupplierId)
          AND (@WarehouseId IS NULL OR po.WarehouseId = @WarehouseId)
          AND (@Status IS NULL OR po.Status = @Status)
          AND (@SearchText IS NULL
               OR po.PoNumber LIKE N'%' + @SearchText + N'%'
               OR s.SupplierName LIKE N'%' + @SearchText + N'%'
               OR ISNULL(po.SupplierInvoiceNo, '') LIKE N'%' + @SearchText + N'%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT
            po.Id,
            po.PoNumber,
            po.SupplierId,
            SupplierName = ISNULL(s.SupplierName, '—'),
            po.WarehouseId,
            WarehouseName = ISNULL(w.WarehouseName, '—'),
            po.OrderedOn,
            po.ExpectedOn,
            po.ReceivedOn,
            po.Status,
            po.SubTotal,
            po.TaxAmount,
            po.ShippingCost,
            po.TotalValue,
            po.QuantityOrdered,
            po.QuantityReceived,
            po.SupplierInvoiceNo,
            po.CreatedAt,
            LineCount = (SELECT COUNT(*) FROM dbo.PurchaseOrderLines pol WHERE pol.PurchaseOrderId = po.Id)
        FROM dbo.PurchaseOrders po
        JOIN dbo.Suppliers s ON po.SupplierId = s.Id
        JOIN dbo.Warehouses w ON po.WarehouseId = w.Id
        WHERE po.IsDeleted = 0
          AND (@SupplierId IS NULL OR po.SupplierId = @SupplierId)
          AND (@WarehouseId IS NULL OR po.WarehouseId = @WarehouseId)
          AND (@Status IS NULL OR po.Status = @Status)
          AND (@SearchText IS NULL
               OR po.PoNumber LIKE N'%' + @SearchText + N'%'
               OR s.SupplierName LIKE N'%' + @SearchText + N'%'
               OR ISNULL(po.SupplierInvoiceNo, '') LIKE N'%' + @SearchText + N'%')
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'PoNumber'     THEN PoNumber END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'PoNumber'     THEN PoNumber END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'SupplierName' THEN SupplierName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'SupplierName' THEN SupplierName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'TotalValue'   THEN TotalValue END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'TotalValue'   THEN TotalValue END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Status'       THEN Status END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Status'       THEN Status END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'OrderedOn'    THEN OrderedOn END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'OrderedOn'    THEN OrderedOn END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

/* 2. GetById */
CREATE OR ALTER PROCEDURE dbo.usp_Purchase_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1st result set: Header
    SELECT
        po.Id,
        po.PoNumber,
        po.SupplierId,
        SupplierName = s.SupplierName,
        SupplierContact = s.ContactPerson,
        SupplierPhone = s.Phone,
        SupplierEmail = s.Email,
        SupplierGstin = s.Gstin,
        po.WarehouseId,
        WarehouseName = w.WarehouseName,
        WarehouseCode = w.Code,
        po.OrderedOn,
        po.ExpectedOn,
        po.ReceivedOn,
        po.Status,
        po.SubTotal,
        po.TaxAmount,
        po.ShippingCost,
        po.TotalValue,
        po.QuantityOrdered,
        po.QuantityReceived,
        po.SupplierInvoiceNo,
        po.Note,
        po.IsActive,
        po.CreatedAt,
        po.UpdatedAt
    FROM dbo.PurchaseOrders po
    JOIN dbo.Suppliers s ON po.SupplierId = s.Id
    JOIN dbo.Warehouses w ON po.WarehouseId = w.Id
    WHERE po.Id = @Id AND po.IsDeleted = 0;

    -- 2nd result set: Line Items
    SELECT
        pol.Id,
        pol.PurchaseOrderId,
        pol.ProductId,
        pol.VariantId,
        pol.Sku,
        pol.ProductName,
        pol.QuantityOrdered,
        pol.QuantityReceived,
        pol.UnitCost,
        pol.TaxPercent,
        pol.LineTotal,
        CurrentOnHand = ISNULL(st.OnHand, 0)
    FROM dbo.PurchaseOrderLines pol
    JOIN dbo.PurchaseOrders po ON pol.PurchaseOrderId = po.Id
    LEFT JOIN dbo.InventoryStocks st ON pol.ProductId = st.ProductId
        AND (pol.VariantId = st.VariantId OR (pol.VariantId IS NULL AND st.VariantId IS NULL))
        AND st.WarehouseId = po.WarehouseId AND st.IsDeleted = 0
    WHERE pol.PurchaseOrderId = @Id
    ORDER BY pol.Id ASC;
END
GO

/* 3. Save (Insert / Update with JSON line items) */
CREATE OR ALTER PROCEDURE dbo.usp_Purchase_Save
    @Id                INT             = 0,
    @PoNumber          VARCHAR(32)     = NULL,
    @SupplierId        INT,
    @WarehouseId       INT,
    @OrderedOn         DATETIME2(3)    = NULL,
    @ExpectedOn        DATETIME2(3)    = NULL,
    @SupplierInvoiceNo NVARCHAR(64)    = NULL,
    @ShippingCost      DECIMAL(18,2)   = 0,
    @Note              NVARCHAR(1000)  = NULL,
    @Status            VARCHAR(32)     = 'Draft',
    @LinesJson         NVARCHAR(MAX),  -- JSON array of [{ProductId, VariantId, Sku, ProductName, QuantityOrdered, UnitCost, TaxPercent}]
    @LoggedInUserId    INT             = NULL,
    @NewId             INT             OUTPUT,
    @ErrorMessage      NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    IF @SupplierId IS NULL OR @SupplierId <= 0
    BEGIN
        SET @ErrorMessage = N'Supplier is required.';
        RETURN;
    END

    IF @WarehouseId IS NULL OR @WarehouseId <= 0
    BEGIN
        SET @ErrorMessage = N'Warehouse is required.';
        RETURN;
    END

    IF @OrderedOn IS NULL SET @OrderedOn = SYSUTCDATETIME();

    -- Generate PoNumber if not provided
    IF ISNULL(@PoNumber, '') = ''
    BEGIN
        IF @Id = 0
        BEGIN
            DECLARE @NextNum INT = ISNULL((SELECT MAX(Id) FROM dbo.PurchaseOrders), 0) + 1;
            SET @PoNumber = 'PO-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) + '-' + RIGHT('0000' + CAST(@NextNum AS VARCHAR(10)), 4);
        END
        ELSE
        BEGIN
            SELECT @PoNumber = PoNumber FROM dbo.PurchaseOrders WHERE Id = @Id;
        END
    END

    -- Parse lines into temp table
    CREATE TABLE #Lines
    (
        ProductId       INT,
        VariantId       INT NULL,
        Sku             VARCHAR(64),
        ProductName     NVARCHAR(300),
        QuantityOrdered INT,
        UnitCost        DECIMAL(18,2),
        TaxPercent      DECIMAL(18,4),
        LineTotal       AS CAST(QuantityOrdered * UnitCost * (1.0 + (TaxPercent / 100.0)) AS DECIMAL(18,2))
    );

    IF ISNULL(@LinesJson, '') <> '' AND ISJSON(@LinesJson) = 1
    BEGIN
        INSERT INTO #Lines (ProductId, VariantId, Sku, ProductName, QuantityOrdered, UnitCost, TaxPercent)
        SELECT
            ProductId,
            NULLIF(VariantId, 0),
            ISNULL(Sku, 'SKU'),
            ISNULL(ProductName, 'Product'),
            ISNULL(QuantityOrdered, 1),
            ISNULL(UnitCost, 0),
            ISNULL(TaxPercent, 0)
        FROM OPENJSON(@LinesJson)
        WITH
        (
            ProductId       INT,
            VariantId       INT,
            Sku             VARCHAR(64),
            ProductName     NVARCHAR(300),
            QuantityOrdered INT,
            UnitCost        DECIMAL(18,2),
            TaxPercent      DECIMAL(18,4)
        );
    END

    IF NOT EXISTS (SELECT 1 FROM #Lines)
    BEGIN
        SET @ErrorMessage = N'Purchase order must have at least one product line item.';
        DROP TABLE #Lines;
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM #Lines WHERE QuantityOrdered <= 0)
    BEGIN
        SET @ErrorMessage = N'Quantity ordered must be greater than 0 for all line items.';
        DROP TABLE #Lines;
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM #Lines WHERE UnitCost <= 0)
    BEGIN
        SET @ErrorMessage = N'Unit cost must be greater than 0 for all line items.';
        DROP TABLE #Lines;
        RETURN;
    END

    -- Calculate totals
    DECLARE @SubTotal DECIMAL(18,2) = ISNULL((SELECT SUM(QuantityOrdered * UnitCost) FROM #Lines), 0);
    DECLARE @TaxAmount DECIMAL(18,2) = ISNULL((SELECT SUM(QuantityOrdered * UnitCost * (TaxPercent / 100.0)) FROM #Lines), 0);
    DECLARE @TotalQuantity INT = ISNULL((SELECT SUM(QuantityOrdered) FROM #Lines), 0);
    DECLARE @TotalValue DECIMAL(18,2) = @SubTotal + @TaxAmount + ISNULL(@ShippingCost, 0);

    IF @Id = 0
    BEGIN
        INSERT INTO dbo.PurchaseOrders
        (
            PoNumber, SupplierId, WarehouseId, OrderedOn, ExpectedOn, Status,
            SubTotal, TaxAmount, ShippingCost, TotalValue, QuantityOrdered,
            QuantityReceived, SupplierInvoiceNo, Note, IsActive, CreatedAt, CreatedBy
        )
        VALUES
        (
            @PoNumber, @SupplierId, @WarehouseId, @OrderedOn, @ExpectedOn, ISNULL(@Status, 'Draft'),
            @SubTotal, @TaxAmount, ISNULL(@ShippingCost, 0), @TotalValue, @TotalQuantity,
            0, @SupplierInvoiceNo, @Note, 1, SYSUTCDATETIME(), @LoggedInUserId
        );

        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        -- If already received, prevent overwriting items
        IF EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE Id = @Id AND Status IN ('Received','PartiallyReceived'))
        BEGIN
            UPDATE dbo.PurchaseOrders
            SET
                ExpectedOn = @ExpectedOn,
                SupplierInvoiceNo = @SupplierInvoiceNo,
                Note = @Note,
                UpdatedAt = SYSUTCDATETIME(),
                UpdatedBy = @LoggedInUserId
            WHERE Id = @Id;

            SET @NewId = @Id;
            DROP TABLE #Lines;
            RETURN;
        END

        UPDATE dbo.PurchaseOrders
        SET
            SupplierId = @SupplierId,
            WarehouseId = @WarehouseId,
            ExpectedOn = @ExpectedOn,
            SupplierInvoiceNo = @SupplierInvoiceNo,
            ShippingCost = ISNULL(@ShippingCost, 0),
            Note = @Note,
            Status = ISNULL(@Status, Status),
            SubTotal = @SubTotal,
            TaxAmount = @TaxAmount,
            TotalValue = @TotalValue,
            QuantityOrdered = @TotalQuantity,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE Id = @Id;

        SET @NewId = @Id;

        -- Remove old lines
        DELETE FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @Id;
    END

    -- Insert lines
    INSERT INTO dbo.PurchaseOrderLines
    (
        PurchaseOrderId, ProductId, VariantId, Sku, ProductName,
        QuantityOrdered, QuantityReceived, UnitCost, TaxPercent, LineTotal
    )
    SELECT
        @NewId, ProductId, VariantId, Sku, ProductName,
        QuantityOrdered, 0, UnitCost, TaxPercent, LineTotal
    FROM #Lines;

    DROP TABLE #Lines;
END
GO

/* 4. Delete */
CREATE OR ALTER PROCEDURE dbo.usp_Purchase_Delete
    @Id             INT,
    @LoggedInUserId INT           = NULL,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    IF EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE Id = @Id AND Status IN ('Received','PartiallyReceived'))
    BEGIN
        SET @ErrorMessage = N'Cannot delete a purchase order that has already received stock.';
        RETURN;
    END

    UPDATE dbo.PurchaseOrders
    SET
        IsDeleted = 1,
        Status = 'Cancelled',
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id;
END
GO

/* 5. UpdateStatus */
CREATE OR ALTER PROCEDURE dbo.usp_Purchase_UpdateStatus
    @Id             INT,
    @Status         VARCHAR(32),
    @LoggedInUserId INT           = NULL,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    UPDATE dbo.PurchaseOrders
    SET
        Status = @Status,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id AND IsDeleted = 0;
END
GO

/* 6. ReceiveStock (Increments stock & records ledger) */
CREATE OR ALTER PROCEDURE dbo.usp_Purchase_ReceiveStock
    @PurchaseOrderId  INT,
    @LoggedInUserId   INT           = NULL,
    @ErrorMessage     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    DECLARE @Status VARCHAR(32), @WarehouseId INT, @SupplierId INT, @PoNumber VARCHAR(32), @TotalValue DECIMAL(18,2);

    SELECT
        @Status = Status,
        @WarehouseId = WarehouseId,
        @SupplierId = SupplierId,
        @PoNumber = PoNumber,
        @TotalValue = TotalValue
    FROM dbo.PurchaseOrders
    WHERE Id = @PurchaseOrderId AND IsDeleted = 0;

    IF @Status IS NULL
    BEGIN
        SET @ErrorMessage = N'Purchase order not found.';
        RETURN;
    END

    IF @Status = 'Received'
    BEGIN
        SET @ErrorMessage = N'This purchase order has already been fully received.';
        RETURN;
    END

    IF @Status = 'Cancelled'
    BEGIN
        SET @ErrorMessage = N'Cannot receive stock for a cancelled purchase order.';
        RETURN;
    END

    -- Cursor over lines
    DECLARE @LineId BIGINT, @ProductId INT, @VariantId INT, @QtyOrdered INT, @QtyReceived INT, @UnitCost DECIMAL(18,2);

    DECLARE line_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT Id, ProductId, VariantId, QuantityOrdered, QuantityReceived, UnitCost
    FROM dbo.PurchaseOrderLines
    WHERE PurchaseOrderId = @PurchaseOrderId;

    OPEN line_cursor;
    FETCH NEXT FROM line_cursor INTO @LineId, @ProductId, @VariantId, @QtyOrdered, @QtyReceived, @UnitCost;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @ToReceive INT = @QtyOrdered - @QtyReceived;
        IF @ToReceive > 0
        BEGIN
            -- Ensure stock record exists
            IF NOT EXISTS (
                SELECT 1 FROM dbo.InventoryStocks
                WHERE ProductId = @ProductId
                  AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL))
                  AND WarehouseId = @WarehouseId
                  AND IsDeleted = 0
            )
            BEGIN
                INSERT INTO dbo.InventoryStocks
                (
                    ProductId, VariantId, WarehouseId, OnHand, Reserved, Incoming,
                    LowStockThreshold, IsActive, CreatedAt, CreatedBy
                )
                VALUES
                (
                    @ProductId, @VariantId, @WarehouseId, 0, 0, 0,
                    5, 1, SYSUTCDATETIME(), @LoggedInUserId
                );
            END

            -- Increment OnHand
            UPDATE dbo.InventoryStocks
            SET
                OnHand = OnHand + @ToReceive,
                UpdatedAt = SYSUTCDATETIME(),
                UpdatedBy = @LoggedInUserId
            WHERE ProductId = @ProductId
              AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL))
              AND WarehouseId = @WarehouseId
              AND IsDeleted = 0;

            DECLARE @NewOnHand INT = (
                SELECT OnHand FROM dbo.InventoryStocks
                WHERE ProductId = @ProductId
                  AND (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL))
                  AND WarehouseId = @WarehouseId
                  AND IsDeleted = 0
            );

            -- Record ledger transaction
            INSERT INTO dbo.InventoryTransactions
            (
                ProductId, VariantId, WarehouseId, TransactionType,
                QuantityChange, QuantityAfter, ReferenceType, ReferenceId, ReferenceNumber,
                UnitCost, Note, CreatedAt, CreatedBy
            )
            VALUES
            (
                @ProductId, @VariantId, @WarehouseId, 'Purchase',
                @ToReceive, @NewOnHand, 'PurchaseOrder', @PurchaseOrderId, @PoNumber,
                @UnitCost, N'Stock received from PO ' + @PoNumber, SYSUTCDATETIME(), @LoggedInUserId
            );

            -- Update line received qty
            UPDATE dbo.PurchaseOrderLines
            SET QuantityReceived = @QtyOrdered
            WHERE Id = @LineId;
        END

        FETCH NEXT FROM line_cursor INTO @LineId, @ProductId, @VariantId, @QtyOrdered, @QtyReceived, @UnitCost;
    END

    CLOSE line_cursor;
    DEALLOCATE line_cursor;

    -- Update PO header
    UPDATE dbo.PurchaseOrders
    SET
        Status = 'Received',
        ReceivedOn = SYSUTCDATETIME(),
        QuantityReceived = QuantityOrdered,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @PurchaseOrderId;

    -- Update Supplier outstanding amount
    UPDATE dbo.Suppliers
    SET
        OutstandingAmount = OutstandingAmount + @TotalValue,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @SupplierId;
END
GO
