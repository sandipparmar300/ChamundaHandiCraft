/* =============================================================================
   09_Promotions.sql — Coupons, Offers, FlashSales, Combos
   -----------------------------------------------------------------------------
   IsPublic = 0 keeps a coupon out of "My Coupons" — it must be typed.
   Offers.EndsOn is server time and is what the storefront countdown renders from:
   the band disappears at zero rather than restarting. A front end that invents an
   end time is a fake countdown.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.Coupons', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Coupons
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        Code                VARCHAR(64)     NOT NULL,
        /* Shown verbatim on the storefront coupon card. */
        Title               NVARCHAR(200)   NOT NULL,
        Description         NVARCHAR(1000)  NULL,

        /* DiscountType: 0 Percentage, 1 FixedAmount, 2 FreeShipping, 3 BuyXGetY */
        DiscountType        TINYINT         NOT NULL CONSTRAINT DF_Coupons_DiscountType DEFAULT (0),
        DiscountValue       DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Coupons_DiscountValue DEFAULT (0),
        /* Caps a percentage discount. Null means uncapped. */
        MaxDiscount         DECIMAL(18,2)   NULL,
        MinimumOrderValue   DECIMAL(18,2)   NULL,

        /* BuyXGetY parameters, used only when DiscountType = 3. */
        BuyQuantity         INT             NULL,
        GetQuantity         INT             NULL,

        StartsOn            DATETIME2(3)    NOT NULL,
        ExpiresOn           DATETIME2(3)    NULL,

        TotalUsageLimit     INT             NULL,
        PerCustomerLimit    INT             NULL CONSTRAINT DF_Coupons_PerCustomerLimit DEFAULT (1),
        UsageCount          INT             NOT NULL CONSTRAINT DF_Coupons_UsageCount DEFAULT (0),
        TotalDiscountGiven  DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Coupons_TotalDiscountGiven DEFAULT (0),

        /* Hidden coupons never appear in "My Coupons" — they must be typed. */
        IsPublic            BIT             NOT NULL CONSTRAINT DF_Coupons_IsPublic DEFAULT (1),
        /* Restricts to first-time buyers. */
        FirstOrderOnly      BIT             NOT NULL CONSTRAINT DF_Coupons_FirstOrderOnly DEFAULT (0),
        /* Can be combined with an active offer rather than being exclusive. */
        IsStackable         BIT             NOT NULL CONSTRAINT DF_Coupons_IsStackable DEFAULT (0),

        /* CouponStatus: 0 Draft, 1 Active, 2 Paused, 3 Expired, 4 Exhausted */
        Status              TINYINT         NOT NULL CONSTRAINT DF_Coupons_Status DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Coupons_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Coupons_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Coupons_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Coupons PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT CK_Coupons_Window CHECK (ExpiresOn IS NULL OR ExpiresOn > StartsOn)
    );

    CREATE UNIQUE INDEX UX_Coupons_Code ON dbo.Coupons (Code) WHERE IsDeleted = 0;
    CREATE INDEX IX_Coupons_Status ON dbo.Coupons (Status, StartsOn, ExpiresOn) WHERE IsDeleted = 0;
END
GO

/* Scope tables. No rows for a scope means "applies to everything". */
IF OBJECT_ID(N'dbo.CouponProducts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CouponProducts
    (
        Id          BIGINT  IDENTITY(1,1) NOT NULL,
        CouponId    INT     NOT NULL,
        ProductId   INT     NOT NULL,
        /* Exclusions are how "everything except clearance" is expressed. */
        IsExcluded  BIT     NOT NULL CONSTRAINT DF_CouponProducts_IsExcluded DEFAULT (0),

        CONSTRAINT PK_CouponProducts PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_CouponProducts UNIQUE (CouponId, ProductId),
        CONSTRAINT FK_CouponProducts_Coupons  FOREIGN KEY (CouponId)  REFERENCES dbo.Coupons (Id),
        CONSTRAINT FK_CouponProducts_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.CouponCategories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CouponCategories
    (
        Id          BIGINT  IDENTITY(1,1) NOT NULL,
        CouponId    INT     NOT NULL,
        CategoryId  INT     NOT NULL,
        IsExcluded  BIT     NOT NULL CONSTRAINT DF_CouponCategories_IsExcluded DEFAULT (0),

        CONSTRAINT PK_CouponCategories PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_CouponCategories UNIQUE (CouponId, CategoryId),
        CONSTRAINT FK_CouponCategories_Coupons    FOREIGN KEY (CouponId)   REFERENCES dbo.Coupons (Id),
        CONSTRAINT FK_CouponCategories_Categories FOREIGN KEY (CategoryId) REFERENCES dbo.Categories (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.CouponSegments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CouponSegments
    (
        Id          BIGINT  IDENTITY(1,1) NOT NULL,
        CouponId    INT     NOT NULL,
        SegmentId   INT     NOT NULL,

        CONSTRAINT PK_CouponSegments PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_CouponSegments UNIQUE (CouponId, SegmentId),
        CONSTRAINT FK_CouponSegments_Coupons  FOREIGN KEY (CouponId)  REFERENCES dbo.Coupons (Id),
        CONSTRAINT FK_CouponSegments_Segments FOREIGN KEY (SegmentId) REFERENCES dbo.CustomerSegments (Id)
    );
END
GO

/* One row per successful application. This is what PerCustomerLimit is counted
   against, and what the "coupon performance" report sums. */
IF OBJECT_ID(N'dbo.CouponRedemptions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CouponRedemptions
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        CouponId        INT             NOT NULL,
        CustomerId      INT             NULL,
        OrderId         INT             NULL,          -- FK added in 11_Orders.sql
        OrderNumber     VARCHAR(32)     NULL,
        DiscountAmount  DECIMAL(18,2)   NOT NULL,
        OrderTotal      DECIMAL(18,2)   NOT NULL CONSTRAINT DF_CouponRedemptions_OrderTotal DEFAULT (0),
        RedeemedAt      DATETIME2(3)    NOT NULL CONSTRAINT DF_CouponRedemptions_RedeemedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_CouponRedemptions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_CouponRedemptions_Coupons   FOREIGN KEY (CouponId)   REFERENCES dbo.Coupons (Id),
        CONSTRAINT FK_CouponRedemptions_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id)
    );

    CREATE INDEX IX_CouponRedemptions_Coupon   ON dbo.CouponRedemptions (CouponId, RedeemedAt DESC);
    CREATE INDEX IX_CouponRedemptions_Customer ON dbo.CouponRedemptions (CustomerId, CouponId);
END
GO

/* ---------------------------------------------------------------------------
   Offers — flash sales, category sales and combos. Automatic: no code is typed,
   the price simply reflects it.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Offers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Offers
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        Name                NVARCHAR(200)   NOT NULL,
        /* Flash Sale | Category Sale | Combo | Bundle | Clearance */
        OfferType           VARCHAR(48)     NOT NULL CONSTRAINT DF_Offers_OfferType DEFAULT ('Flash Sale'),
        Description         NVARCHAR(1000)  NULL,

        /* DiscountType: 0 Percentage, 1 FixedAmount, 2 FreeShipping, 3 BuyXGetY */
        DiscountType        TINYINT         NOT NULL CONSTRAINT DF_Offers_DiscountType DEFAULT (0),
        DiscountPercent     INT             NOT NULL CONSTRAINT DF_Offers_DiscountPercent DEFAULT (0),
        DiscountAmount      DECIMAL(18,2)   NULL,
        /* Fixed combo price, used when OfferType = Combo. */
        ComboPrice          DECIMAL(18,2)   NULL,

        /* Server time. The storefront countdown renders from EndsOn and removes
           the band at zero — it never restarts and never invents an end time. */
        StartsOn            DATETIME2(3)    NOT NULL,
        EndsOn              DATETIME2(3)    NOT NULL,

        BannerMediaId       INT             NULL,
        SortOrder           INT             NOT NULL CONSTRAINT DF_Offers_SortOrder DEFAULT (0),

        /* Performance, maintained as orders complete. */
        OrdersInfluenced    INT             NOT NULL CONSTRAINT DF_Offers_OrdersInfluenced DEFAULT (0),
        RevenueInfluenced   DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Offers_RevenueInfluenced DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Offers_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Offers_IsActive  DEFAULT (0),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Offers_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Offers PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Offers_BannerMedia FOREIGN KEY (BannerMediaId) REFERENCES dbo.MediaAssets (Id),
        CONSTRAINT CK_Offers_Window CHECK (EndsOn > StartsOn)
    );

    CREATE INDEX IX_Offers_Live ON dbo.Offers (IsActive, StartsOn, EndsOn) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.OfferProducts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OfferProducts
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        OfferId         INT             NOT NULL,
        ProductId       INT             NOT NULL,
        VariantId       INT             NULL,
        /* An explicit sale price for this product, overriding the offer percent. */
        OverridePrice   DECIMAL(18,2)   NULL,
        /* Caps how many units may sell at the offer price. */
        QuantityLimit   INT             NULL,
        QuantitySold    INT             NOT NULL CONSTRAINT DF_OfferProducts_QuantitySold DEFAULT (0),

        CONSTRAINT PK_OfferProducts PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_OfferProducts UNIQUE (OfferId, ProductId, VariantId),
        CONSTRAINT FK_OfferProducts_Offers   FOREIGN KEY (OfferId)   REFERENCES dbo.Offers (Id),
        CONSTRAINT FK_OfferProducts_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products (Id),
        CONSTRAINT FK_OfferProducts_Variants FOREIGN KEY (VariantId) REFERENCES dbo.ProductVariants (Id)
    );

    CREATE INDEX IX_OfferProducts_Product ON dbo.OfferProducts (ProductId);
END
GO

IF OBJECT_ID(N'dbo.OfferCategories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OfferCategories
    (
        Id          BIGINT  IDENTITY(1,1) NOT NULL,
        OfferId     INT     NOT NULL,
        CategoryId  INT     NOT NULL,

        CONSTRAINT PK_OfferCategories PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_OfferCategories UNIQUE (OfferId, CategoryId),
        CONSTRAINT FK_OfferCategories_Offers     FOREIGN KEY (OfferId)    REFERENCES dbo.Offers (Id),
        CONSTRAINT FK_OfferCategories_Categories FOREIGN KEY (CategoryId) REFERENCES dbo.Categories (Id)
    );
END
GO
