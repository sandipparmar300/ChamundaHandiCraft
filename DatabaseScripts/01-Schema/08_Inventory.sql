/* =============================================================================
   08_Inventory.sql — Warehouses, Suppliers, Stock, Transactions, Purchases,
                      Adjustments, StockTakes, Transfers
   -----------------------------------------------------------------------------
   InventoryStocks is the only table the storefront may quote availability from.

       Available = OnHand - Reserved

   Reserved counts live carts and unshipped orders. A cached list value must never
   drive "Only 2 left" — that is how a shopper gets told something untrue.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.Warehouses', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Warehouses
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        WarehouseName   NVARCHAR(200)   NOT NULL,
        Code            VARCHAR(32)     NOT NULL,
        Line1           NVARCHAR(300)   NULL,
        Line2           NVARCHAR(300)   NULL,
        CityId          INT             NULL,
        StateId         INT             NULL,
        CityName        NVARCHAR(150)   NULL,
        StateName       NVARCHAR(150)   NULL,
        Pincode         VARCHAR(12)     NULL,
        ContactPerson   NVARCHAR(200)   NULL,
        Phone           VARCHAR(24)     NULL,
        Email           NVARCHAR(256)   NULL,
        /* Exactly one default warehouse fulfils single-warehouse operation.
           Multi-warehouse allocation is decision D-01 and is not wired yet. */
        IsDefault       BIT             NOT NULL CONSTRAINT DF_Warehouses_IsDefault DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Warehouses_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Warehouses_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Warehouses_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Warehouses PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Warehouses_Code UNIQUE (Code),
        CONSTRAINT FK_Warehouses_Cities FOREIGN KEY (CityId)  REFERENCES dbo.Cities (Id),
        CONSTRAINT FK_Warehouses_States FOREIGN KEY (StateId) REFERENCES dbo.States (Id)
    );

    CREATE UNIQUE INDEX UX_Warehouses_Default ON dbo.Warehouses (IsDefault)
        WHERE IsDefault = 1 AND IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.Suppliers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Suppliers
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        SupplierName        NVARCHAR(200)   NOT NULL,
        Code                VARCHAR(32)     NOT NULL,
        ContactPerson       NVARCHAR(200)   NULL,
        Phone               VARCHAR(24)     NULL,
        Email               NVARCHAR(256)   NULL,
        Gstin               VARCHAR(20)     NULL,
        Line1               NVARCHAR(300)   NULL,
        CityId              INT             NULL,
        StateId             INT             NULL,
        CityName            NVARCHAR(150)   NULL,
        Pincode             VARCHAR(12)     NULL,
        PaymentTermsDays    INT             NOT NULL CONSTRAINT DF_Suppliers_PaymentTermsDays DEFAULT (30),
        /* Running balance owed, maintained as purchase orders are received and paid. */
        OutstandingAmount   DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Suppliers_OutstandingAmount DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Suppliers_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Suppliers_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Suppliers_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Suppliers PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Suppliers_Code UNIQUE (Code),
        CONSTRAINT FK_Suppliers_Cities FOREIGN KEY (CityId)  REFERENCES dbo.Cities (Id),
        CONSTRAINT FK_Suppliers_States FOREIGN KEY (StateId) REFERENCES dbo.States (Id)
    );
END
GO

/* ---------------------------------------------------------------------------
   The stock ledger's current position. One row per (product, variant, warehouse).
   VariantId is NULL for products without variants; the filtered unique indexes
   below enforce one row per combination in both cases, because a NULL will not
   compare equal inside a plain UNIQUE constraint.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.InventoryStocks', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.InventoryStocks
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        ProductId           INT             NOT NULL,
        VariantId           INT             NULL,
        WarehouseId         INT             NOT NULL,
        OnHand              INT             NOT NULL CONSTRAINT DF_InventoryStocks_OnHand DEFAULT (0),
        /* Held by live carts and unshipped orders. Not available to sell. */
        Reserved            INT             NOT NULL CONSTRAINT DF_InventoryStocks_Reserved DEFAULT (0),
        /* Ordered from the supplier, not yet received. Feeds the restock date. */
        Incoming            INT             NOT NULL CONSTRAINT DF_InventoryStocks_Incoming DEFAULT (0),
        LowStockThreshold   INT             NOT NULL CONSTRAINT DF_InventoryStocks_LowStockThreshold DEFAULT (5),
        BinLocation         NVARCHAR(64)    NULL,
        LastCountedOn       DATETIME2(3)    NULL,
        RestockExpectedOn   DATETIME2(3)    NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_InventoryStocks_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_InventoryStocks_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_InventoryStocks_IsDeleted DEFAULT (0),

        CONSTRAINT PK_InventoryStocks PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_InventoryStocks_Products   FOREIGN KEY (ProductId)   REFERENCES dbo.Products (Id),
        CONSTRAINT FK_InventoryStocks_Variants   FOREIGN KEY (VariantId)   REFERENCES dbo.ProductVariants (Id),
        CONSTRAINT FK_InventoryStocks_Warehouses FOREIGN KEY (WarehouseId) REFERENCES dbo.Warehouses (Id),
        /* Reserved can never exceed what is physically held. */
        CONSTRAINT CK_InventoryStocks_Reserved CHECK (Reserved >= 0 AND Reserved <= OnHand)
    );

    CREATE UNIQUE INDEX UX_InventoryStocks_WithVariant ON dbo.InventoryStocks (ProductId, VariantId, WarehouseId)
        WHERE VariantId IS NOT NULL;
    CREATE UNIQUE INDEX UX_InventoryStocks_NoVariant ON dbo.InventoryStocks (ProductId, WarehouseId)
        WHERE VariantId IS NULL;
    CREATE INDEX IX_InventoryStocks_Product ON dbo.InventoryStocks (ProductId) INCLUDE (OnHand, Reserved, LowStockThreshold);
END
GO

/* Append-only movement log. Every change to OnHand or Reserved writes one row,
   so a discrepancy can always be traced to the document that caused it. */
IF OBJECT_ID(N'dbo.InventoryTransactions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.InventoryTransactions
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        ProductId           INT             NOT NULL,
        VariantId           INT             NULL,
        WarehouseId         INT             NOT NULL,
        /* Purchase|Sale|Return|Adjustment|Transfer|Reservation|ReservationRelease|StockTake */
        TransactionType     VARCHAR(32)     NOT NULL,
        QuantityChange      INT             NOT NULL,      -- signed
        QuantityAfter       INT             NOT NULL,
        /* The document this movement came from — PO, order, adjustment, transfer. */
        ReferenceType       VARCHAR(48)     NULL,
        ReferenceId         INT             NULL,
        ReferenceNumber     NVARCHAR(64)    NULL,
        UnitCost            DECIMAL(18,2)   NULL,
        Note                NVARCHAR(500)   NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_InventoryTransactions_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,

        CONSTRAINT PK_InventoryTransactions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_InventoryTransactions_Products   FOREIGN KEY (ProductId)   REFERENCES dbo.Products (Id),
        CONSTRAINT FK_InventoryTransactions_Variants   FOREIGN KEY (VariantId)   REFERENCES dbo.ProductVariants (Id),
        CONSTRAINT FK_InventoryTransactions_Warehouses FOREIGN KEY (WarehouseId) REFERENCES dbo.Warehouses (Id)
    );

    CREATE INDEX IX_InventoryTransactions_Product ON dbo.InventoryTransactions (ProductId, CreatedAt DESC);
    CREATE INDEX IX_InventoryTransactions_Reference ON dbo.InventoryTransactions (ReferenceType, ReferenceId);
END
GO

IF OBJECT_ID(N'dbo.PurchaseOrders', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PurchaseOrders
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        PoNumber            VARCHAR(32)     NOT NULL,
        SupplierId          INT             NOT NULL,
        WarehouseId         INT             NOT NULL,
        OrderedOn           DATETIME2(3)    NOT NULL CONSTRAINT DF_PurchaseOrders_OrderedOn DEFAULT (SYSUTCDATETIME()),
        ExpectedOn          DATETIME2(3)    NULL,
        ReceivedOn          DATETIME2(3)    NULL,
        /* Draft|Sent|PartiallyReceived|Received|Cancelled */
        Status              VARCHAR(32)     NOT NULL CONSTRAINT DF_PurchaseOrders_Status DEFAULT ('Draft'),
        SubTotal            DECIMAL(18,2)   NOT NULL CONSTRAINT DF_PurchaseOrders_SubTotal DEFAULT (0),
        TaxAmount           DECIMAL(18,2)   NOT NULL CONSTRAINT DF_PurchaseOrders_TaxAmount DEFAULT (0),
        ShippingCost        DECIMAL(18,2)   NOT NULL CONSTRAINT DF_PurchaseOrders_ShippingCost DEFAULT (0),
        TotalValue          DECIMAL(18,2)   NOT NULL CONSTRAINT DF_PurchaseOrders_TotalValue DEFAULT (0),
        QuantityOrdered     INT             NOT NULL CONSTRAINT DF_PurchaseOrders_QuantityOrdered DEFAULT (0),
        QuantityReceived    INT             NOT NULL CONSTRAINT DF_PurchaseOrders_QuantityReceived DEFAULT (0),
        SupplierInvoiceNo   NVARCHAR(64)    NULL,
        Note                NVARCHAR(1000)  NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_PurchaseOrders_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_PurchaseOrders_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_PurchaseOrders_IsDeleted DEFAULT (0),

        CONSTRAINT PK_PurchaseOrders PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_PurchaseOrders_Number UNIQUE (PoNumber),
        CONSTRAINT FK_PurchaseOrders_Suppliers  FOREIGN KEY (SupplierId)  REFERENCES dbo.Suppliers (Id),
        CONSTRAINT FK_PurchaseOrders_Warehouses FOREIGN KEY (WarehouseId) REFERENCES dbo.Warehouses (Id)
    );

    CREATE INDEX IX_PurchaseOrders_Supplier ON dbo.PurchaseOrders (SupplierId, OrderedOn DESC) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.PurchaseOrderLines', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PurchaseOrderLines
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        PurchaseOrderId     INT             NOT NULL,
        ProductId           INT             NOT NULL,
        VariantId           INT             NULL,
        Sku                 VARCHAR(64)     NOT NULL,
        ProductName         NVARCHAR(300)   NOT NULL,
        QuantityOrdered     INT             NOT NULL,
        QuantityReceived    INT             NOT NULL CONSTRAINT DF_PurchaseOrderLines_QuantityReceived DEFAULT (0),
        UnitCost            DECIMAL(18,2)   NOT NULL,
        TaxPercent          DECIMAL(18,4)   NOT NULL CONSTRAINT DF_PurchaseOrderLines_TaxPercent DEFAULT (0),
        LineTotal           DECIMAL(18,2)   NOT NULL CONSTRAINT DF_PurchaseOrderLines_LineTotal DEFAULT (0),

        CONSTRAINT PK_PurchaseOrderLines PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_PurchaseOrderLines_Orders   FOREIGN KEY (PurchaseOrderId) REFERENCES dbo.PurchaseOrders (Id),
        CONSTRAINT FK_PurchaseOrderLines_Products FOREIGN KEY (ProductId)       REFERENCES dbo.Products (Id),
        CONSTRAINT FK_PurchaseOrderLines_Variants FOREIGN KEY (VariantId)       REFERENCES dbo.ProductVariants (Id)
    );

    CREATE INDEX IX_PurchaseOrderLines_Order ON dbo.PurchaseOrderLines (PurchaseOrderId);
END
GO

/* Manual stock corrections. ReasonCodeId is mandatory — an unexplained quantity
   change is how shrinkage hides. */
IF OBJECT_ID(N'dbo.StockAdjustments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.StockAdjustments
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        AdjustmentNumber    VARCHAR(32)     NOT NULL,
        ProductId           INT             NOT NULL,
        VariantId           INT             NULL,
        WarehouseId         INT             NOT NULL,
        QuantityBefore      INT             NOT NULL,
        QuantityChange      INT             NOT NULL,
        QuantityAfter       INT             NOT NULL,
        ReasonCodeId        INT             NOT NULL,
        Note                NVARCHAR(1000)  NULL,
        AdjustedOn          DATETIME2(3)    NOT NULL CONSTRAINT DF_StockAdjustments_AdjustedOn DEFAULT (SYSUTCDATETIME()),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_StockAdjustments_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_StockAdjustments_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_StockAdjustments_IsDeleted DEFAULT (0),

        CONSTRAINT PK_StockAdjustments PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_StockAdjustments_Number UNIQUE (AdjustmentNumber),
        CONSTRAINT FK_StockAdjustments_Products    FOREIGN KEY (ProductId)    REFERENCES dbo.Products (Id),
        CONSTRAINT FK_StockAdjustments_Variants    FOREIGN KEY (VariantId)    REFERENCES dbo.ProductVariants (Id),
        CONSTRAINT FK_StockAdjustments_Warehouses  FOREIGN KEY (WarehouseId)  REFERENCES dbo.Warehouses (Id),
        CONSTRAINT FK_StockAdjustments_ReasonCodes FOREIGN KEY (ReasonCodeId) REFERENCES dbo.ReasonCodes (Id),
        CONSTRAINT CK_StockAdjustments_NonZero CHECK (QuantityChange <> 0)
    );

    CREATE INDEX IX_StockAdjustments_Product ON dbo.StockAdjustments (ProductId, AdjustedOn DESC) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.StockTakes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.StockTakes
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        StockTakeNumber     VARCHAR(32)     NOT NULL,
        WarehouseId         INT             NOT NULL,
        StartedOn           DATETIME2(3)    NOT NULL CONSTRAINT DF_StockTakes_StartedOn DEFAULT (SYSUTCDATETIME()),
        CompletedOn         DATETIME2(3)    NULL,
        /* In Progress|Completed|Cancelled */
        Status              VARCHAR(32)     NOT NULL CONSTRAINT DF_StockTakes_Status DEFAULT ('In Progress'),
        SkusCounted         INT             NOT NULL CONSTRAINT DF_StockTakes_SkusCounted DEFAULT (0),
        DiscrepancyCount    INT             NOT NULL CONSTRAINT DF_StockTakes_DiscrepancyCount DEFAULT (0),
        DiscrepancyValue    DECIMAL(18,2)   NOT NULL CONSTRAINT DF_StockTakes_DiscrepancyValue DEFAULT (0),
        Note                NVARCHAR(1000)  NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_StockTakes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_StockTakes_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_StockTakes_IsDeleted DEFAULT (0),

        CONSTRAINT PK_StockTakes PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_StockTakes_Number UNIQUE (StockTakeNumber),
        CONSTRAINT FK_StockTakes_Warehouses FOREIGN KEY (WarehouseId) REFERENCES dbo.Warehouses (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.StockTakeLines', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.StockTakeLines
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        StockTakeId     INT             NOT NULL,
        ProductId       INT             NOT NULL,
        VariantId       INT             NULL,
        Sku             VARCHAR(64)     NOT NULL,
        SystemQuantity  INT             NOT NULL,
        CountedQuantity INT             NULL,
        Variance        AS (ISNULL(CountedQuantity, SystemQuantity) - SystemQuantity) PERSISTED,
        UnitCost        DECIMAL(18,2)   NULL,
        Note            NVARCHAR(500)   NULL,
        CountedAt       DATETIME2(3)    NULL,
        CountedBy       INT             NULL,

        CONSTRAINT PK_StockTakeLines PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_StockTakeLines_StockTakes FOREIGN KEY (StockTakeId) REFERENCES dbo.StockTakes (Id),
        CONSTRAINT FK_StockTakeLines_Products   FOREIGN KEY (ProductId)   REFERENCES dbo.Products (Id),
        CONSTRAINT FK_StockTakeLines_Variants   FOREIGN KEY (VariantId)   REFERENCES dbo.ProductVariants (Id)
    );

    CREATE INDEX IX_StockTakeLines_StockTake ON dbo.StockTakeLines (StockTakeId);
END
GO

IF OBJECT_ID(N'dbo.StockTransfers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.StockTransfers
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        TransferNumber      VARCHAR(32)     NOT NULL,
        FromWarehouseId     INT             NOT NULL,
        ToWarehouseId       INT             NOT NULL,
        InitiatedOn         DATETIME2(3)    NOT NULL CONSTRAINT DF_StockTransfers_InitiatedOn DEFAULT (SYSUTCDATETIME()),
        DispatchedOn        DATETIME2(3)    NULL,
        ReceivedOn          DATETIME2(3)    NULL,
        /* Draft|In Transit|Received|Cancelled */
        Status              VARCHAR(32)     NOT NULL CONSTRAINT DF_StockTransfers_Status DEFAULT ('Draft'),
        TotalQuantity       INT             NOT NULL CONSTRAINT DF_StockTransfers_TotalQuantity DEFAULT (0),
        Note                NVARCHAR(1000)  NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_StockTransfers_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_StockTransfers_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_StockTransfers_IsDeleted DEFAULT (0),

        CONSTRAINT PK_StockTransfers PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_StockTransfers_Number UNIQUE (TransferNumber),
        CONSTRAINT FK_StockTransfers_FromWarehouse FOREIGN KEY (FromWarehouseId) REFERENCES dbo.Warehouses (Id),
        CONSTRAINT FK_StockTransfers_ToWarehouse   FOREIGN KEY (ToWarehouseId)   REFERENCES dbo.Warehouses (Id),
        CONSTRAINT CK_StockTransfers_DifferentSites CHECK (FromWarehouseId <> ToWarehouseId)
    );
END
GO

IF OBJECT_ID(N'dbo.StockTransferLines', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.StockTransferLines
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        StockTransferId     INT             NOT NULL,
        ProductId           INT             NOT NULL,
        VariantId           INT             NULL,
        Sku                 VARCHAR(64)     NOT NULL,
        QuantitySent        INT             NOT NULL,
        QuantityReceived    INT             NULL,

        CONSTRAINT PK_StockTransferLines PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_StockTransferLines_Transfers FOREIGN KEY (StockTransferId) REFERENCES dbo.StockTransfers (Id),
        CONSTRAINT FK_StockTransferLines_Products  FOREIGN KEY (ProductId)       REFERENCES dbo.Products (Id),
        CONSTRAINT FK_StockTransferLines_Variants  FOREIGN KEY (VariantId)       REFERENCES dbo.ProductVariants (Id)
    );

    CREATE INDEX IX_StockTransferLines_Transfer ON dbo.StockTransferLines (StockTransferId);
END
GO

/* Back-in-stock waiting list. Feeds the BackInStock badge and its notification. */
IF OBJECT_ID(N'dbo.StockNotifyRequests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.StockNotifyRequests
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ProductId       INT             NOT NULL,
        VariantId       INT             NULL,
        CustomerId      INT             NULL,
        Email           NVARCHAR(256)   NULL,
        Phone           VARCHAR(24)     NULL,
        RequestedAt     DATETIME2(3)    NOT NULL CONSTRAINT DF_StockNotifyRequests_RequestedAt DEFAULT (SYSUTCDATETIME()),
        NotifiedAt      DATETIME2(3)    NULL,

        CONSTRAINT PK_StockNotifyRequests PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_StockNotifyRequests_Products  FOREIGN KEY (ProductId)  REFERENCES dbo.Products (Id),
        CONSTRAINT FK_StockNotifyRequests_Variants  FOREIGN KEY (VariantId)  REFERENCES dbo.ProductVariants (Id),
        CONSTRAINT FK_StockNotifyRequests_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id)
    );

    CREATE INDEX IX_StockNotifyRequests_Pending ON dbo.StockNotifyRequests (ProductId, VariantId) WHERE NotifiedAt IS NULL;
END
GO
