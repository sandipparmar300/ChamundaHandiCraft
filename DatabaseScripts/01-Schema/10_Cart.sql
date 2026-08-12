/* =============================================================================
   10_Cart.sql — Carts, CartItems, CheckoutSessions
   -----------------------------------------------------------------------------
   A cart belongs to a customer or to a guest token, never to neither. The
   ch_guest cookie is deliberately long-lived: losing it loses the shopper's work.
   On sign-in the guest cart is folded into the customer's own cart and the guest
   token is retired — MergedIntoCartId records where it went.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.Carts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Carts
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        CustomerId          INT             NULL,
        GuestToken          VARCHAR(64)     NULL,

        /* Applied coupon, revalidated on every read — a cart that sat overnight
           must not quote an expired discount. */
        CouponId            INT             NULL,
        CouponCode          VARCHAR(64)     NULL,

        GiftWrapSelected    BIT             NOT NULL CONSTRAINT DF_Carts_GiftWrapSelected DEFAULT (0),
        GiftMessage         NVARCHAR(500)   NULL,
        PointsApplied       INT             NOT NULL CONSTRAINT DF_Carts_PointsApplied DEFAULT (0),
        /* The PIN remembered for 30 days (ch_pin), reused on PDP, cart and checkout. */
        DeliveryPincode     VARCHAR(12)     NULL,

        /* Where this cart went when the guest signed in. */
        MergedIntoCartId    INT             NULL,
        MergedAt            DATETIME2(3)    NULL,

        /* Set when the abandoned-cart job has picked it up, so a shopper is not
           mailed about the same cart twice. */
        AbandonedAt         DATETIME2(3)    NULL,
        RecoveryEmailSentAt DATETIME2(3)    NULL,
        ConvertedOrderId    INT             NULL,          -- FK added in 11_Orders.sql
        LastActivityAt      DATETIME2(3)    NOT NULL CONSTRAINT DF_Carts_LastActivityAt DEFAULT (SYSUTCDATETIME()),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Carts_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Carts_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Carts_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Carts PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Carts_Customers  FOREIGN KEY (CustomerId)       REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_Carts_Coupons    FOREIGN KEY (CouponId)         REFERENCES dbo.Coupons (Id),
        CONSTRAINT FK_Carts_MergedInto FOREIGN KEY (MergedIntoCartId) REFERENCES dbo.Carts (Id),
        CONSTRAINT CK_Carts_Owner CHECK (CustomerId IS NOT NULL OR GuestToken IS NOT NULL)
    );

    /* One live cart per customer, and one per guest token. */
    CREATE UNIQUE INDEX UX_Carts_Customer ON dbo.Carts (CustomerId)
        WHERE CustomerId IS NOT NULL AND IsDeleted = 0 AND ConvertedOrderId IS NULL AND MergedIntoCartId IS NULL;
    CREATE UNIQUE INDEX UX_Carts_GuestToken ON dbo.Carts (GuestToken)
        WHERE GuestToken IS NOT NULL AND IsDeleted = 0 AND ConvertedOrderId IS NULL AND MergedIntoCartId IS NULL;
    /* Drives the abandoned-cart job. */
    CREATE INDEX IX_Carts_Abandoned ON dbo.Carts (LastActivityAt)
        WHERE IsDeleted = 0 AND ConvertedOrderId IS NULL;
END
GO

IF OBJECT_ID(N'dbo.CartItems', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CartItems
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        CartId          INT             NOT NULL,
        ProductId       INT             NOT NULL,
        VariantId       INT             NULL,
        Quantity        INT             NOT NULL CONSTRAINT DF_CartItems_Quantity DEFAULT (1),

        /* Price captured when the line was added. The cart re-prices on every
           read; this is kept so "the price of an item in your cart changed" can
           be stated rather than silently applied. */
        PriceWhenAdded  DECIMAL(18,2)   NOT NULL,
        Price           DECIMAL(18,2)   NOT NULL,
        Mrp             DECIMAL(18,2)   NULL,

        /* Saved-for-later lines stay on the cart but out of the totals. */
        IsSavedForLater BIT             NOT NULL CONSTRAINT DF_CartItems_IsSavedForLater DEFAULT (0),
        /* The stock hold behind Reserved in InventoryStocks, released on expiry. */
        ReservedUntil   DATETIME2(3)    NULL,
        Note            NVARCHAR(500)   NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_CartItems_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_CartItems_IsDeleted DEFAULT (0),

        CONSTRAINT PK_CartItems PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_CartItems_Carts    FOREIGN KEY (CartId)    REFERENCES dbo.Carts (Id),
        CONSTRAINT FK_CartItems_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products (Id),
        CONSTRAINT FK_CartItems_Variants FOREIGN KEY (VariantId) REFERENCES dbo.ProductVariants (Id),
        CONSTRAINT CK_CartItems_Quantity CHECK (Quantity > 0)
    );

    CREATE INDEX IX_CartItems_Cart ON dbo.CartItems (CartId) WHERE IsDeleted = 0;
    CREATE UNIQUE INDEX UX_CartItems_WithVariant ON dbo.CartItems (CartId, ProductId, VariantId, IsSavedForLater)
        WHERE VariantId IS NOT NULL AND IsDeleted = 0;
    CREATE UNIQUE INDEX UX_CartItems_NoVariant ON dbo.CartItems (CartId, ProductId, IsSavedForLater)
        WHERE VariantId IS NULL AND IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Checkout session. Holds the shopper's in-progress selections between the cart
   and a placed order, and freezes the quoted figures so nothing new can appear
   after payment selection.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.CheckoutSessions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CheckoutSessions
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        SessionToken        VARCHAR(64)     NOT NULL,
        CartId              INT             NOT NULL,
        CustomerId          INT             NULL,
        GuestToken          VARCHAR(64)     NULL,
        IsGuest             BIT             NOT NULL CONSTRAINT DF_CheckoutSessions_IsGuest DEFAULT (0),

        ContactEmail        NVARCHAR(256)   NULL,
        ContactPhone        VARCHAR(24)     NULL,
        ShippingAddressId   INT             NULL,
        BillingAddressId    INT             NULL,
        /* Snapshot of the addresses as entered, so a later edit to the saved
           address book cannot rewrite what this checkout quoted. */
        ShippingAddressJson NVARCHAR(MAX)   NULL,
        BillingAddressJson  NVARCHAR(MAX)   NULL,

        DeliveryMethodCode  VARCHAR(48)     NULL,
        /* PaymentMethod: 0 Upi, 1 Card, 2 NetBanking, 3 Wallet, 4 CashOnDelivery, 5 StoreCredit */
        PaymentMethod       TINYINT         NULL,

        /* The frozen quote. Every charge the shopper will pay appears here. */
        SubTotal            DECIMAL(18,2)   NOT NULL CONSTRAINT DF_CheckoutSessions_SubTotal DEFAULT (0),
        MrpTotal            DECIMAL(18,2)   NOT NULL CONSTRAINT DF_CheckoutSessions_MrpTotal DEFAULT (0),
        CouponDiscount      DECIMAL(18,2)   NOT NULL CONSTRAINT DF_CheckoutSessions_CouponDiscount DEFAULT (0),
        ShippingCost        DECIMAL(18,2)   NOT NULL CONSTRAINT DF_CheckoutSessions_ShippingCost DEFAULT (0),
        CodFee              DECIMAL(18,2)   NOT NULL CONSTRAINT DF_CheckoutSessions_CodFee DEFAULT (0),
        GiftWrapCost        DECIMAL(18,2)   NOT NULL CONSTRAINT DF_CheckoutSessions_GiftWrapCost DEFAULT (0),
        PointsApplied       DECIMAL(18,2)   NOT NULL CONSTRAINT DF_CheckoutSessions_PointsApplied DEFAULT (0),
        TaxTotal            DECIMAL(18,2)   NOT NULL CONSTRAINT DF_CheckoutSessions_TaxTotal DEFAULT (0),
        GrandTotal          DECIMAL(18,2)   NOT NULL CONSTRAINT DF_CheckoutSessions_GrandTotal DEFAULT (0),

        /* Started|AddressCaptured|PaymentPending|Completed|Abandoned|Expired */
        Status              VARCHAR(32)     NOT NULL CONSTRAINT DF_CheckoutSessions_Status DEFAULT ('Started'),
        OrderId             INT             NULL,          -- FK added in 11_Orders.sql
        ExpiresAt           DATETIME2(3)    NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_CheckoutSessions_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_CheckoutSessions_IsDeleted DEFAULT (0),

        CONSTRAINT PK_CheckoutSessions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_CheckoutSessions_Token UNIQUE (SessionToken),
        CONSTRAINT FK_CheckoutSessions_Carts     FOREIGN KEY (CartId)            REFERENCES dbo.Carts (Id),
        CONSTRAINT FK_CheckoutSessions_Customers FOREIGN KEY (CustomerId)        REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_CheckoutSessions_ShipAddr  FOREIGN KEY (ShippingAddressId) REFERENCES dbo.CustomerAddresses (Id),
        CONSTRAINT FK_CheckoutSessions_BillAddr  FOREIGN KEY (BillingAddressId)  REFERENCES dbo.CustomerAddresses (Id)
    );

    CREATE INDEX IX_CheckoutSessions_Cart ON dbo.CheckoutSessions (CartId, Status);
END
GO
