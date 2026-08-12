/* =============================================================================
   11_Orders.sql — Orders, OrderItems, StatusHistory, Notes, Returns, Exchanges,
                   Invoices
   -----------------------------------------------------------------------------
   One order, one set of numbers. The admin detail screen and the customer's own
   order page read these same rows — there is no separate admin total to
   reconcile against a customer total.

   Every line captures the product name, SKU, image and artisan as they were at
   the moment of purchase. An order from last year must still render correctly
   after the product has been renamed, re-priced or archived.

   This file also closes the deferred order foreign keys from 05, 09 and 10.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Orders
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        OrderNumber         VARCHAR(32)     NOT NULL,
        CustomerId          INT             NULL,          -- null for a guest order
        GuestToken          VARCHAR(64)     NULL,
        CartId              INT             NULL,
        CheckoutSessionId   INT             NULL,

        /* Contact captured at checkout, kept even if the account later changes. */
        CustomerName        NVARCHAR(200)   NOT NULL,
        CustomerEmail       NVARCHAR(256)   NULL,
        CustomerPhone       VARCHAR(24)     NULL,

        PlacedOn            DATETIME2(3)    NOT NULL CONSTRAINT DF_Orders_PlacedOn DEFAULT (SYSUTCDATETIME()),

        /* OrderStatus: 0 Placed, 1 PaymentPending, 2 Processing, 3 Packed,
           4 Shipped, 5 InTransit, 6 OutForDelivery, 7 Delivered, 8 Completed,
           9 Cancelled, 10 ReturnRequested, 11 ReturnApproved, 12 ReturnPickedUp,
           13 Refunded, 14 PaymentFailed, 15 Closed
           Transitions are validated by the API against Orders.txt §2 — the admin
           screen offers only the legal next steps. */
        Status              TINYINT         NOT NULL CONSTRAINT DF_Orders_Status DEFAULT (0),
        /* PaymentStatus: 0 Pending, 1 Authorised, 2 Paid, 3 Failed, 4 Refunded,
           5 PartiallyRefunded, 6 CodPending */
        PaymentStatus       TINYINT         NOT NULL CONSTRAINT DF_Orders_PaymentStatus DEFAULT (0),
        /* PaymentMethod: 0 Upi, 1 Card, 2 NetBanking, 3 Wallet, 4 CashOnDelivery, 5 StoreCredit */
        PaymentMethod       TINYINT         NOT NULL CONSTRAINT DF_Orders_PaymentMethod DEFAULT (4),

        -- Money. Total is stored, not computed, because it is what was charged.
        SubTotal            DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Orders_SubTotal DEFAULT (0),
        MrpTotal            DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Orders_MrpTotal DEFAULT (0),
        CouponId            INT             NULL,
        CouponCode          VARCHAR(64)     NULL,
        CouponDiscount      DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Orders_CouponDiscount DEFAULT (0),
        OfferDiscount       DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Orders_OfferDiscount DEFAULT (0),
        PointsRedeemed      INT             NOT NULL CONSTRAINT DF_Orders_PointsRedeemed DEFAULT (0),
        PointsDiscount      DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Orders_PointsDiscount DEFAULT (0),
        ShippingCost        DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Orders_ShippingCost DEFAULT (0),
        CodFee              DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Orders_CodFee DEFAULT (0),
        GiftWrapCost        DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Orders_GiftWrapCost DEFAULT (0),
        TaxTotal            DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Orders_TaxTotal DEFAULT (0),
        IsTaxInclusive      BIT             NOT NULL CONSTRAINT DF_Orders_IsTaxInclusive DEFAULT (1),
        Total               DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Orders_Total DEFAULT (0),
        RefundedAmount      DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Orders_RefundedAmount DEFAULT (0),
        CurrencyCode        VARCHAR(3)      NOT NULL CONSTRAINT DF_Orders_CurrencyCode DEFAULT ('INR'),

        ItemCount           INT             NOT NULL CONSTRAINT DF_Orders_ItemCount DEFAULT (0),
        PointsEarned        INT             NOT NULL CONSTRAINT DF_Orders_PointsEarned DEFAULT (0),

        GiftWrapSelected    BIT             NOT NULL CONSTRAINT DF_Orders_GiftWrapSelected DEFAULT (0),
        GiftMessage         NVARCHAR(500)   NULL,
        CustomerNote        NVARCHAR(1000)  NULL,

        -- Fulfilment summary, denormalised so the grid needs no joins.
        ShipToCity          NVARCHAR(150)   NULL,
        ShipToPincode       VARCHAR(12)     NULL,
        CourierName         NVARCHAR(200)   NULL,
        TrackingNumber      VARCHAR(64)     NULL,
        /* The promise made to the shopper. IsBreachingSla in the admin grid is
           DeliveryBy < today for an undelivered order. */
        DeliveryBy          DATETIME2(3)    NULL,
        ShippedOn           DATETIME2(3)    NULL,
        DeliveredOn         DATETIME2(3)    NULL,
        CancelledOn         DATETIME2(3)    NULL,
        CancelReasonId      INT             NULL,
        CancelNote          NVARCHAR(1000)  NULL,

        HasReturnRequest    BIT             NOT NULL CONSTRAINT DF_Orders_HasReturnRequest DEFAULT (0),
        InvoiceId           INT             NULL,

        SourceChannel       VARCHAR(32)     NOT NULL CONSTRAINT DF_Orders_SourceChannel DEFAULT ('Web'),
        IpAddress           VARCHAR(64)     NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Orders_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Orders_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Orders_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Orders PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Orders_Number UNIQUE (OrderNumber),
        CONSTRAINT FK_Orders_Customers       FOREIGN KEY (CustomerId)        REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_Orders_Carts           FOREIGN KEY (CartId)            REFERENCES dbo.Carts (Id),
        CONSTRAINT FK_Orders_CheckoutSession FOREIGN KEY (CheckoutSessionId) REFERENCES dbo.CheckoutSessions (Id),
        CONSTRAINT FK_Orders_Coupons         FOREIGN KEY (CouponId)          REFERENCES dbo.Coupons (Id),
        CONSTRAINT FK_Orders_CancelReason    FOREIGN KEY (CancelReasonId)    REFERENCES dbo.ReasonCodes (Id),
        CONSTRAINT CK_Orders_TotalNonNegative CHECK (Total >= 0)
    );

    CREATE INDEX IX_Orders_Customer ON dbo.Orders (CustomerId, PlacedOn DESC) WHERE IsDeleted = 0;
    CREATE INDEX IX_Orders_Status   ON dbo.Orders (Status, PlacedOn DESC)     WHERE IsDeleted = 0;
    CREATE INDEX IX_Orders_PlacedOn ON dbo.Orders (PlacedOn DESC)            WHERE IsDeleted = 0;
    CREATE INDEX IX_Orders_Tracking ON dbo.Orders (TrackingNumber)           WHERE TrackingNumber IS NOT NULL;
END
GO

IF OBJECT_ID(N'dbo.OrderItems', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderItems
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        OrderId             INT             NOT NULL,
        ProductId           INT             NOT NULL,
        VariantId           INT             NULL,

        /* Purchase-time snapshot. These are what the order page, the invoice and
           the packing slip render — never a live join back to Products. */
        ProductName         NVARCHAR(300)   NOT NULL,
        Sku                 VARCHAR(64)     NOT NULL,
        Slug                VARCHAR(300)    NULL,
        VariantSummary      NVARCHAR(300)   NULL,
        ImageUrl            NVARCHAR(1000)  NULL,
        ImageAlt            NVARCHAR(300)   NULL,
        ArtisanId           INT             NULL,
        ArtisanName         NVARCHAR(200)   NULL,
        HsnCode             VARCHAR(16)     NULL,

        Quantity            INT             NOT NULL,
        UnitPrice           DECIMAL(18,2)   NOT NULL,
        UnitMrp             DECIMAL(18,2)   NULL,
        LineDiscount        DECIMAL(18,2)   NOT NULL CONSTRAINT DF_OrderItems_LineDiscount DEFAULT (0),
        TaxPercent          DECIMAL(18,4)   NOT NULL CONSTRAINT DF_OrderItems_TaxPercent DEFAULT (0),
        TaxAmount           DECIMAL(18,2)   NOT NULL CONSTRAINT DF_OrderItems_TaxAmount DEFAULT (0),
        LineTotal           DECIMAL(18,2)   NOT NULL,

        /* Per-line fulfilment, so a partially shipped order reads correctly. */
        QuantityShipped     INT             NOT NULL CONSTRAINT DF_OrderItems_QuantityShipped DEFAULT (0),
        QuantityReturned    INT             NOT NULL CONSTRAINT DF_OrderItems_QuantityReturned DEFAULT (0),
        QuantityCancelled   INT             NOT NULL CONSTRAINT DF_OrderItems_QuantityCancelled DEFAULT (0),
        WarehouseId         INT             NULL,
        /* Set when the post-delivery review request has been sent for this line. */
        ReviewRequestedAt   DATETIME2(3)    NULL,
        ReviewId            INT             NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_OrderItems_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,

        CONSTRAINT PK_OrderItems PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_OrderItems_Orders     FOREIGN KEY (OrderId)     REFERENCES dbo.Orders (Id),
        CONSTRAINT FK_OrderItems_Products   FOREIGN KEY (ProductId)   REFERENCES dbo.Products (Id),
        CONSTRAINT FK_OrderItems_Variants   FOREIGN KEY (VariantId)   REFERENCES dbo.ProductVariants (Id),
        CONSTRAINT FK_OrderItems_Artisans   FOREIGN KEY (ArtisanId)   REFERENCES dbo.Artisans (Id),
        CONSTRAINT FK_OrderItems_Warehouses FOREIGN KEY (WarehouseId) REFERENCES dbo.Warehouses (Id),
        CONSTRAINT CK_OrderItems_Quantity CHECK (Quantity > 0)
    );

    CREATE INDEX IX_OrderItems_Order   ON dbo.OrderItems (OrderId);
    CREATE INDEX IX_OrderItems_Product ON dbo.OrderItems (ProductId);
END
GO

/* Shipping and billing as they were at purchase. Copied, not referenced — an
   edit to the customer's address book must not rewrite a shipped order. */
IF OBJECT_ID(N'dbo.OrderAddresses', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderAddresses
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        OrderId         INT             NOT NULL,
        AddressKind     VARCHAR(16)     NOT NULL,      -- Shipping|Billing
        /* AddressType: 0 Home, 1 Work, 2 Other */
        LabelType       TINYINT         NOT NULL CONSTRAINT DF_OrderAddresses_LabelType DEFAULT (0),
        FullName        NVARCHAR(200)   NOT NULL,
        Phone           VARCHAR(24)     NOT NULL,
        AlternatePhone  VARCHAR(24)     NULL,
        Line1           NVARCHAR(300)   NOT NULL,
        Line2           NVARCHAR(300)   NULL,
        Landmark        NVARCHAR(200)   NULL,
        CityName        NVARCHAR(150)   NOT NULL,
        StateName       NVARCHAR(150)   NOT NULL,
        CountryName     NVARCHAR(150)   NOT NULL CONSTRAINT DF_OrderAddresses_CountryName DEFAULT (N'India'),
        Pincode         VARCHAR(12)     NOT NULL,
        /* Place of supply for GST, taken from the state at the time of the order. */
        GstStateCode    VARCHAR(2)      NULL,
        Gstin           VARCHAR(20)     NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_OrderAddresses_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_OrderAddresses PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_OrderAddresses UNIQUE (OrderId, AddressKind),
        CONSTRAINT FK_OrderAddresses_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders (Id)
    );
END
GO

/* Every transition, with whether the customer was told. Turning the notification
   off silently is what makes a tracking page go stale, so it is recorded. */
IF OBJECT_ID(N'dbo.OrderStatusHistories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderStatusHistories
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        OrderId             INT             NOT NULL,
        FromStatus          TINYINT         NULL,
        ToStatus            TINYINT         NOT NULL,
        Note                NVARCHAR(1000)  NULL,
        Location            NVARCHAR(200)   NULL,
        CourierName         NVARCHAR(200)   NULL,
        TrackingNumber      VARCHAR(64)     NULL,
        EstimatedDelivery   DATETIME2(3)    NULL,
        CustomerNotified    BIT             NOT NULL CONSTRAINT DF_OrderStatusHistories_CustomerNotified DEFAULT (1),
        /* True for courier webhook updates, false for an operator action. */
        IsSystemGenerated   BIT             NOT NULL CONSTRAINT DF_OrderStatusHistories_IsSystem DEFAULT (0),
        ChangedBy           INT             NULL,
        ChangedByName       NVARCHAR(200)   NULL,
        ChangedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_OrderStatusHistories_ChangedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_OrderStatusHistories PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_OrderStatusHistories_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders (Id)
    );

    CREATE INDEX IX_OrderStatusHistories_Order ON dbo.OrderStatusHistories (OrderId, ChangedAt);
END
GO

/* Internal notes never reach the customer's order page. */
IF OBJECT_ID(N'dbo.OrderNotes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderNotes
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        OrderId         INT             NOT NULL,
        Body            NVARCHAR(MAX)   NOT NULL,
        IsInternal      BIT             NOT NULL CONSTRAINT DF_OrderNotes_IsInternal DEFAULT (1),
        AuthorId        INT             NULL,
        AuthorName      NVARCHAR(200)   NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_OrderNotes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_OrderNotes_IsDeleted DEFAULT (0),

        CONSTRAINT PK_OrderNotes PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_OrderNotes_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders (Id)
    );

    CREATE INDEX IX_OrderNotes_Order ON dbo.OrderNotes (OrderId, CreatedAt DESC) WHERE IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Returns. One record, read by both tiers — the storefront return page and the
   admin queue show the same truth.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ReturnRequests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReturnRequests
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        RmaNumber           VARCHAR(32)     NOT NULL,
        OrderId             INT             NOT NULL,
        CustomerId          INT             NULL,
        RequestedOn         DATETIME2(3)    NOT NULL CONSTRAINT DF_ReturnRequests_RequestedOn DEFAULT (SYSUTCDATETIME()),

        /* ReturnReason: 0 DamagedOrBroken, 1 WrongItem, 2 NotAsDescribed,
           3 QualityBelowExpectation, 4 SizeUnsuitable, 5 ChangedMind */
        Reason              TINYINT         NOT NULL,
        ReasonCodeId        INT             NULL,
        /* ReturnResolution: 0 Refund, 1 Replacement, 2 StoreCredit */
        Resolution          TINYINT         NOT NULL CONSTRAINT DF_ReturnRequests_Resolution DEFAULT (0),
        CustomerNote        NVARCHAR(2000)  NULL,

        /* Mirrors the parent order's return statuses:
           10 ReturnRequested, 11 ReturnApproved, 12 ReturnPickedUp, 13 Refunded */
        Status              TINYINT         NOT NULL CONSTRAINT DF_ReturnRequests_Status DEFAULT (10),
        RefundAmount        DECIMAL(18,2)   NOT NULL CONSTRAINT DF_ReturnRequests_RefundAmount DEFAULT (0),
        /* Shipping is refunded only when the return is our fault. */
        RefundShipping      BIT             NOT NULL CONSTRAINT DF_ReturnRequests_RefundShipping DEFAULT (0),
        PickupScheduledOn   DATETIME2(3)    NULL,
        PickedUpOn          DATETIME2(3)    NULL,
        ReceivedOn          DATETIME2(3)    NULL,
        /* Restocked only after inspection passes. */
        IsRestocked         BIT             NOT NULL CONSTRAINT DF_ReturnRequests_IsRestocked DEFAULT (0),
        AdminNote           NVARCHAR(2000)  NULL,
        RejectionReason     NVARCHAR(1000)  NULL,
        /* Set when this return produced a replacement order. */
        ExchangeOrderId     INT             NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_ReturnRequests_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_ReturnRequests_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_ReturnRequests_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ReturnRequests PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ReturnRequests_Rma UNIQUE (RmaNumber),
        CONSTRAINT FK_ReturnRequests_Orders     FOREIGN KEY (OrderId)         REFERENCES dbo.Orders (Id),
        CONSTRAINT FK_ReturnRequests_Customers  FOREIGN KEY (CustomerId)      REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_ReturnRequests_ReasonCode FOREIGN KEY (ReasonCodeId)    REFERENCES dbo.ReasonCodes (Id),
        CONSTRAINT FK_ReturnRequests_Exchange   FOREIGN KEY (ExchangeOrderId) REFERENCES dbo.Orders (Id)
    );

    CREATE INDEX IX_ReturnRequests_Order  ON dbo.ReturnRequests (OrderId)              WHERE IsDeleted = 0;
    CREATE INDEX IX_ReturnRequests_Status ON dbo.ReturnRequests (Status, RequestedOn DESC) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.ReturnLines', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReturnLines
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ReturnRequestId INT             NOT NULL,
        OrderItemId     BIGINT          NOT NULL,
        ProductId       INT             NOT NULL,
        VariantId       INT             NULL,
        ProductName     NVARCHAR(300)   NOT NULL,
        Sku             VARCHAR(64)     NOT NULL,
        ImageUrl        NVARCHAR(1000)  NULL,
        Quantity        INT             NOT NULL,
        LineRefund      DECIMAL(18,2)   NOT NULL CONSTRAINT DF_ReturnLines_LineRefund DEFAULT (0),
        /* Pending|Passed|Failed — a failed inspection is not restocked. */
        InspectionResult VARCHAR(24)    NOT NULL CONSTRAINT DF_ReturnLines_InspectionResult DEFAULT ('Pending'),
        InspectionNote  NVARCHAR(1000)  NULL,

        CONSTRAINT PK_ReturnLines PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ReturnLines_Requests   FOREIGN KEY (ReturnRequestId) REFERENCES dbo.ReturnRequests (Id),
        CONSTRAINT FK_ReturnLines_OrderItems FOREIGN KEY (OrderItemId)     REFERENCES dbo.OrderItems (Id),
        CONSTRAINT FK_ReturnLines_Products   FOREIGN KEY (ProductId)       REFERENCES dbo.Products (Id),
        CONSTRAINT CK_ReturnLines_Quantity CHECK (Quantity > 0)
    );

    CREATE INDEX IX_ReturnLines_Request ON dbo.ReturnLines (ReturnRequestId);
END
GO

/* Photographs the shopper attached. Required for damage and wrong-item reasons. */
IF OBJECT_ID(N'dbo.ReturnMedia', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReturnMedia
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ReturnRequestId INT             NOT NULL,
        MediaId         INT             NULL,
        Url             NVARCHAR(1000)  NOT NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_ReturnMedia_SortOrder DEFAULT (0),
        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ReturnMedia_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_ReturnMedia PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ReturnMedia_Requests FOREIGN KEY (ReturnRequestId) REFERENCES dbo.ReturnRequests (Id),
        CONSTRAINT FK_ReturnMedia_Media    FOREIGN KEY (MediaId)         REFERENCES dbo.MediaAssets (Id)
    );
END
GO

/* ---------------------------------------------------------------------------
   Invoices. Tax-compliant GST document — CGST + SGST when the place of supply
   matches the seller's state, IGST when it does not.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Invoices', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Invoices
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        InvoiceNumber       VARCHAR(32)     NOT NULL,
        OrderId             INT             NOT NULL,
        CustomerName        NVARCHAR(200)   NOT NULL,
        CustomerGstin       VARCHAR(20)     NULL,
        InvoiceDate         DATETIME2(3)    NOT NULL CONSTRAINT DF_Invoices_InvoiceDate DEFAULT (SYSUTCDATETIME()),
        /* State name plus GST code — "24-Gujarat". */
        PlaceOfSupply       NVARCHAR(100)   NOT NULL,
        TaxableValue        DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Invoices_TaxableValue DEFAULT (0),
        Cgst                DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Invoices_Cgst DEFAULT (0),
        Sgst                DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Invoices_Sgst DEFAULT (0),
        Igst                DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Invoices_Igst DEFAULT (0),
        Cess                DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Invoices_Cess DEFAULT (0),
        RoundOff            DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Invoices_RoundOff DEFAULT (0),
        Total               DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Invoices_Total DEFAULT (0),
        PdfUrl              NVARCHAR(1000)  NULL,
        /* Credit notes reference the invoice they reverse. */
        IsCreditNote        BIT             NOT NULL CONSTRAINT DF_Invoices_IsCreditNote DEFAULT (0),
        OriginalInvoiceId   INT             NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Invoices_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Invoices_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Invoices_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Invoices PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Invoices_Number UNIQUE (InvoiceNumber),
        CONSTRAINT FK_Invoices_Orders   FOREIGN KEY (OrderId)           REFERENCES dbo.Orders (Id),
        CONSTRAINT FK_Invoices_Original FOREIGN KEY (OriginalInvoiceId) REFERENCES dbo.Invoices (Id)
    );

    CREATE INDEX IX_Invoices_Order ON dbo.Invoices (OrderId) WHERE IsDeleted = 0;
    CREATE INDEX IX_Invoices_Date  ON dbo.Invoices (InvoiceDate DESC) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.FK_Orders_Invoices', N'F') IS NULL
    ALTER TABLE dbo.Orders
        ADD CONSTRAINT FK_Orders_Invoices FOREIGN KEY (InvoiceId) REFERENCES dbo.Invoices (Id);
GO

/* ---------------------------------------------------------------------------
   Deferred foreign keys from 05_Customers.sql, 09_Promotions.sql and 10_Cart.sql
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.FK_RewardPointLedgers_Orders', N'F') IS NULL
    ALTER TABLE dbo.RewardPointLedgers
        ADD CONSTRAINT FK_RewardPointLedgers_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders (Id);
GO

IF OBJECT_ID(N'dbo.FK_CouponRedemptions_Orders', N'F') IS NULL
    ALTER TABLE dbo.CouponRedemptions
        ADD CONSTRAINT FK_CouponRedemptions_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders (Id);
GO

IF OBJECT_ID(N'dbo.FK_Carts_ConvertedOrder', N'F') IS NULL
    ALTER TABLE dbo.Carts
        ADD CONSTRAINT FK_Carts_ConvertedOrder FOREIGN KEY (ConvertedOrderId) REFERENCES dbo.Orders (Id);
GO

IF OBJECT_ID(N'dbo.FK_CheckoutSessions_Orders', N'F') IS NULL
    ALTER TABLE dbo.CheckoutSessions
        ADD CONSTRAINT FK_CheckoutSessions_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders (Id);
GO
