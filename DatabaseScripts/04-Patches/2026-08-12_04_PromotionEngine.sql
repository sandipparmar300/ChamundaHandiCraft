/* =============================================================================
   2026-08-12_04_PromotionEngine.sql
   -----------------------------------------------------------------------------
   Brings dbo.Offers up to what Offer.txt actually specifies, and closes the
   parity gap with dbo.Coupons.

   Why this was missing
   --------------------
   Coupons and Offers are siblings: both are promotions, both have a lifecycle,
   eligibility rules, usage limits and a redemption history. dbo.Coupons had all
   of that. dbo.Offers had a name, a discount, a date window and two counters.

   Everything below is an explicit clause in Offer.txt that had no column:

     §6C  Buy X Get Y      "Buy Product, Buy Quantity, Get Product, Get Quantity,
                            Discount, Maximum Redemption"
     §7   Offer Rules      "Minimum Order Amount, Maximum Order Amount, Order
                            Quantity, Payment Method, First Order, Repeat Customer"
     §8   Offer Schedule   "Status: Draft | Scheduled | Active | Expired |
                            Disabled | Archived"
     §9   Offer Priority   "Resolve conflicts between multiple active offers.
                            Lower number = Higher Priority"
     §12  Customer Eligibility  "All | New | Existing | VIP | Selected Customers"
     §13  Usage Limits     "Unlimited | Total | Per Customer | Daily | Weekly | Monthly"
     §21  Business rule    "Every offer application is recorded in the audit log."
     §6B  Combo Offer      "Products Included ... Quantity Rules"
     §21  Business rule    "Combo offers require all configured products to be
                            present in the cart."

   Without these the automatic offer engine in §10 could not run: it has to pick
   between competing offers (needs Priority), check the shopper qualifies (needs
   eligibility), and stop when a cap is reached (needs limits + redemptions).

   Two smaller gaps on dbo.Coupons are closed at the same time:
     Coupon.txt §6  "Maximum Order Amount"
     Coupon.txt §9  "Order Eligibility ... Payment Method"

   Note on Offers.SortOrder: it already existed and stays. It is DISPLAY order
   (which banner shows first). Priority added below is CONFLICT-RESOLUTION order
   (which discount wins). Offer.txt §9 is explicit that these are different
   concerns, and collapsing them would make a merchandiser unable to feature a
   low-priority offer at the top of a page.
   ============================================================================= */

SET NOCOUNT ON;
GO

/* =============================================================================
   PART A - dbo.Offers: lifecycle, priority, rules, limits
   ============================================================================= */

/* Offer.txt §8 - the six-state lifecycle, mirroring CouponStatus exactly so the
   two promotion types behave the same way in the admin UI.
   0 Draft, 1 Scheduled, 2 Active, 3 Expired, 4 Disabled, 5 Archived */
IF COL_LENGTH(N'dbo.Offers', N'Status') IS NULL
BEGIN
    ALTER TABLE dbo.Offers ADD Status TINYINT NOT NULL
        CONSTRAINT DF_Offers_Status DEFAULT (0);
END
GO

/* Backfill from the pre-existing IsActive bit so nothing silently changes
   meaning. IsActive stays as the generic soft-disable used everywhere else. */
UPDATE dbo.Offers
SET    Status = CASE
                  WHEN IsDeleted = 1                     THEN 5   -- Archived
                  WHEN EndsOn   <= SYSUTCDATETIME()      THEN 3   -- Expired
                  WHEN IsActive = 0                      THEN 4   -- Disabled
                  WHEN StartsOn >  SYSUTCDATETIME()      THEN 1   -- Scheduled
                  ELSE 2                                          -- Active
                END
WHERE  Status = 0;
GO

IF OBJECT_ID(N'CK_Offers_Status', N'C') IS NULL
    ALTER TABLE dbo.Offers ADD CONSTRAINT CK_Offers_Status CHECK (Status BETWEEN 0 AND 5);
GO

/* Offer.txt §9 - conflict resolution. Lower wins. */
IF COL_LENGTH(N'dbo.Offers', N'Priority') IS NULL
    ALTER TABLE dbo.Offers ADD Priority INT NOT NULL CONSTRAINT DF_Offers_Priority DEFAULT (100);
GO

/* Offer.txt §6C - Buy X Get Y. Mirrors dbo.Coupons.BuyQuantity / GetQuantity,
   plus GetProductId because an offer can give a DIFFERENT product free, which a
   coupon cannot. */
IF COL_LENGTH(N'dbo.Offers', N'BuyQuantity') IS NULL
    ALTER TABLE dbo.Offers ADD BuyQuantity INT NULL;
GO
IF COL_LENGTH(N'dbo.Offers', N'GetQuantity') IS NULL
    ALTER TABLE dbo.Offers ADD GetQuantity INT NULL;
GO
IF COL_LENGTH(N'dbo.Offers', N'GetProductId') IS NULL
BEGIN
    ALTER TABLE dbo.Offers ADD GetProductId INT NULL;
    ALTER TABLE dbo.Offers ADD CONSTRAINT FK_Offers_GetProduct
        FOREIGN KEY (GetProductId) REFERENCES dbo.Products (Id);
END
GO

/* Offer.txt §7 - order-level rules. */
IF COL_LENGTH(N'dbo.Offers', N'MinimumOrderValue') IS NULL
    ALTER TABLE dbo.Offers ADD MinimumOrderValue DECIMAL(18,2) NULL;
GO
IF COL_LENGTH(N'dbo.Offers', N'MaximumOrderValue') IS NULL
    ALTER TABLE dbo.Offers ADD MaximumOrderValue DECIMAL(18,2) NULL;
GO
IF COL_LENGTH(N'dbo.Offers', N'MinimumOrderQuantity') IS NULL
    ALTER TABLE dbo.Offers ADD MinimumOrderQuantity INT NULL;
GO
IF COL_LENGTH(N'dbo.Offers', N'MaxDiscount') IS NULL
    ALTER TABLE dbo.Offers ADD MaxDiscount DECIMAL(18,2) NULL;
GO

/* Offer.txt §7 / §12 - customer eligibility.
   0 AllCustomers, 1 NewCustomers, 2 ExistingCustomers, 3 SelectedSegments */
IF COL_LENGTH(N'dbo.Offers', N'CustomerEligibility') IS NULL
    ALTER TABLE dbo.Offers ADD CustomerEligibility TINYINT NOT NULL
        CONSTRAINT DF_Offers_CustomerEligibility DEFAULT (0);
GO
IF COL_LENGTH(N'dbo.Offers', N'FirstOrderOnly') IS NULL
    ALTER TABLE dbo.Offers ADD FirstOrderOnly BIT NOT NULL
        CONSTRAINT DF_Offers_FirstOrderOnly DEFAULT (0);
GO

/* Offer.txt §7 - "Payment Method". Comma-separated PaymentMethod enum values
   (0 Upi, 1 Card, 2 NetBanking, 3 Wallet, 4 CashOnDelivery, 5 StoreCredit).
   NULL means every method qualifies. A child table would be three rows of
   overhead per offer for a list that is never queried independently. */
IF COL_LENGTH(N'dbo.Offers', N'AllowedPaymentMethods') IS NULL
    ALTER TABLE dbo.Offers ADD AllowedPaymentMethods VARCHAR(32) NULL;
GO

/* Offer.txt §13 - usage limits, and §21's stacking rule. */
IF COL_LENGTH(N'dbo.Offers', N'TotalUsageLimit') IS NULL
    ALTER TABLE dbo.Offers ADD TotalUsageLimit INT NULL;
GO
IF COL_LENGTH(N'dbo.Offers', N'PerCustomerLimit') IS NULL
    ALTER TABLE dbo.Offers ADD PerCustomerLimit INT NULL;
GO
IF COL_LENGTH(N'dbo.Offers', N'UsageCount') IS NULL
    ALTER TABLE dbo.Offers ADD UsageCount INT NOT NULL
        CONSTRAINT DF_Offers_UsageCount DEFAULT (0);
GO
IF COL_LENGTH(N'dbo.Offers', N'TotalDiscountGiven') IS NULL
    ALTER TABLE dbo.Offers ADD TotalDiscountGiven DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_Offers_TotalDiscountGiven DEFAULT (0);
GO
IF COL_LENGTH(N'dbo.Offers', N'IsStackable') IS NULL
    ALTER TABLE dbo.Offers ADD IsStackable BIT NOT NULL
        CONSTRAINT DF_Offers_IsStackable DEFAULT (0);
GO

/* Same atomic-counter guard the coupon engine uses, for the same reason:
   Offer.txt §21 "Automatic offers cannot exceed configured discount limits."
   The write path uses a conditional UPDATE; this is the backstop. */
IF OBJECT_ID(N'CK_Offers_WithinUsageLimit', N'C') IS NULL
    ALTER TABLE dbo.Offers ADD CONSTRAINT CK_Offers_WithinUsageLimit
        CHECK (TotalUsageLimit IS NULL OR UsageCount <= TotalUsageLimit);
GO

IF OBJECT_ID(N'CK_Offers_OrderValueRange', N'C') IS NULL
    ALTER TABLE dbo.Offers ADD CONSTRAINT CK_Offers_OrderValueRange
        CHECK (MaximumOrderValue IS NULL OR MinimumOrderValue IS NULL
               OR MaximumOrderValue >= MinimumOrderValue);
GO

/* The offer engine's hot path (§10): every live offer, best priority first. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Offers_Engine' AND object_id=OBJECT_ID(N'dbo.Offers'))
BEGIN
    CREATE INDEX IX_Offers_Engine ON dbo.Offers (Status, Priority, StartsOn, EndsOn)
        INCLUDE (OfferType, DiscountType, DiscountPercent, DiscountAmount,
                 ComboPrice, MinimumOrderValue, MaxDiscount, IsStackable)
        WHERE IsDeleted = 0;
END
GO

/* =============================================================================
   PART B - Combo membership quantities
   ============================================================================= */

/* Offer.txt §6B "Quantity Rules" and §21 "Combo offers require all configured
   products to be present in the cart."

   OfferProducts.QuantityLimit already exists but means something else - it is
   the flash-sale stock allocation (§6D), capping how many units the offer may
   move. RequiredQuantity is how many of this product must be IN THE CART for a
   combo to trigger. "Buy Table + 4 Chairs" needs 1 and 4. */
IF COL_LENGTH(N'dbo.OfferProducts', N'RequiredQuantity') IS NULL
    ALTER TABLE dbo.OfferProducts ADD RequiredQuantity INT NOT NULL
        CONSTRAINT DF_OfferProducts_RequiredQuantity DEFAULT (1);
GO

/* Marks the "get" side of a Buy X Get Y offer where the free item is one of the
   listed products rather than Offers.GetProductId. */
IF COL_LENGTH(N'dbo.OfferProducts', N'IsRewardItem') IS NULL
    ALTER TABLE dbo.OfferProducts ADD IsRewardItem BIT NOT NULL
        CONSTRAINT DF_OfferProducts_IsRewardItem DEFAULT (0);
GO

IF OBJECT_ID(N'CK_OfferProducts_RequiredQuantity', N'C') IS NULL
    ALTER TABLE dbo.OfferProducts ADD CONSTRAINT CK_OfferProducts_RequiredQuantity
        CHECK (RequiredQuantity > 0);
GO

/* =============================================================================
   PART C - Customer eligibility scoping
   ============================================================================= */

/* Offer.txt §12 "Selected Customers". Mirrors dbo.CouponSegments exactly. */
IF OBJECT_ID(N'dbo.OfferSegments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OfferSegments
    (
        Id          BIGINT  IDENTITY(1,1) NOT NULL,
        OfferId     INT     NOT NULL,
        SegmentId   INT     NOT NULL,

        CreatedAt   DATETIME2(3) NOT NULL CONSTRAINT DF_OfferSegments_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy   INT     NULL,

        CONSTRAINT PK_OfferSegments PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_OfferSegments UNIQUE (OfferId, SegmentId),
        CONSTRAINT FK_OfferSegments_Offers   FOREIGN KEY (OfferId)   REFERENCES dbo.Offers (Id),
        CONSTRAINT FK_OfferSegments_Segments FOREIGN KEY (SegmentId) REFERENCES dbo.CustomerSegments (Id)
    );

    CREATE INDEX IX_OfferSegments_Segment ON dbo.OfferSegments (SegmentId);
END
GO

/* Offer.txt §7 - brand-wide promotions. Coupons scope by product and category;
   offers additionally scope by brand ("20% off all Dhokra"). */
IF OBJECT_ID(N'dbo.OfferBrands', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OfferBrands
    (
        Id          BIGINT  IDENTITY(1,1) NOT NULL,
        OfferId     INT     NOT NULL,
        BrandId     INT     NOT NULL,

        CreatedAt   DATETIME2(3) NOT NULL CONSTRAINT DF_OfferBrands_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy   INT     NULL,

        CONSTRAINT PK_OfferBrands PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_OfferBrands UNIQUE (OfferId, BrandId),
        CONSTRAINT FK_OfferBrands_Offers FOREIGN KEY (OfferId) REFERENCES dbo.Offers (Id),
        CONSTRAINT FK_OfferBrands_Brands FOREIGN KEY (BrandId) REFERENCES dbo.Brands (Id)
    );

    CREATE INDEX IX_OfferBrands_Brand ON dbo.OfferBrands (BrandId);
END
GO

/* =============================================================================
   PART D - Redemption history
   ============================================================================= */

/* Offer.txt §21 "Every offer application is recorded in the audit log" and §14
   Offer Analytics (revenue generated, total discount, conversion, best products).

   Mirrors dbo.CouponRedemptions. Append-only - deleting a redemption would
   silently restore a consumed use, exactly as for coupons. */
IF OBJECT_ID(N'dbo.OfferRedemptions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OfferRedemptions
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        OfferId         INT             NOT NULL,
        CustomerId      INT             NULL,          -- null for a guest order
        OrderId         INT             NOT NULL,
        OrderNumber     VARCHAR(32)     NOT NULL,
        /* Which line the offer landed on. Null for a cart-level offer. */
        OrderItemId     BIGINT          NULL,
        ProductId       INT             NULL,
        DiscountAmount  DECIMAL(18,2)   NOT NULL CONSTRAINT DF_OfferRedemptions_DiscountAmount DEFAULT (0),
        OrderTotal      DECIMAL(18,2)   NOT NULL CONSTRAINT DF_OfferRedemptions_OrderTotal DEFAULT (0),
        /* Snapshot: an offer edited or archived later must not restate history. */
        OfferName       NVARCHAR(200)   NOT NULL,
        OfferType       VARCHAR(48)     NOT NULL,
        RedeemedAt      DATETIME2(3)    NOT NULL CONSTRAINT DF_OfferRedemptions_RedeemedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_OfferRedemptions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_OfferRedemptions_Offers     FOREIGN KEY (OfferId)     REFERENCES dbo.Offers (Id),
        CONSTRAINT FK_OfferRedemptions_Customers  FOREIGN KEY (CustomerId)  REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_OfferRedemptions_Orders     FOREIGN KEY (OrderId)     REFERENCES dbo.Orders (Id),
        CONSTRAINT FK_OfferRedemptions_OrderItems FOREIGN KEY (OrderItemId) REFERENCES dbo.OrderItems (Id),
        CONSTRAINT FK_OfferRedemptions_Products   FOREIGN KEY (ProductId)   REFERENCES dbo.Products (Id),
        CONSTRAINT CK_OfferRedemptions_Discount   CHECK (DiscountAmount >= 0)
    );

    /* Per-customer limit check (§13), and the customer's promotion history. */
    CREATE INDEX IX_OfferRedemptions_OfferCustomer
        ON dbo.OfferRedemptions (OfferId, CustomerId);
    /* Offer analytics over a date range (§14). */
    CREATE INDEX IX_OfferRedemptions_OfferDate
        ON dbo.OfferRedemptions (OfferId, RedeemedAt DESC)
        INCLUDE (DiscountAmount, OrderTotal);
    /* "Which offers applied to this order?" - order detail and refund reversal. */
    CREATE INDEX IX_OfferRedemptions_Order ON dbo.OfferRedemptions (OrderId);
END
GO

/* =============================================================================
   PART E - Coupon parity
   ============================================================================= */

/* Coupon.txt §6 "Maximum Order Amount" - caps a coupon so a high-value order
   cannot claim a discount meant for small baskets. */
IF COL_LENGTH(N'dbo.Coupons', N'MaximumOrderValue') IS NULL
    ALTER TABLE dbo.Coupons ADD MaximumOrderValue DECIMAL(18,2) NULL;
GO

/* Coupon.txt §9 "Order Eligibility ... Payment Method", §10 validation rule
   "Payment Method Allowed". Same encoding as Offers.AllowedPaymentMethods. */
IF COL_LENGTH(N'dbo.Coupons', N'AllowedPaymentMethods') IS NULL
    ALTER TABLE dbo.Coupons ADD AllowedPaymentMethods VARCHAR(32) NULL;
GO

IF OBJECT_ID(N'CK_Coupons_OrderValueRange', N'C') IS NULL
    ALTER TABLE dbo.Coupons ADD CONSTRAINT CK_Coupons_OrderValueRange
        CHECK (MaximumOrderValue IS NULL OR MinimumOrderValue IS NULL
               OR MaximumOrderValue >= MinimumOrderValue);
GO

/* Coupon.txt §8 "Per Day Limit". Enforced by counting CouponRedemptions for
   today, which IX_CouponRedemptions_Date below makes cheap. */
IF COL_LENGTH(N'dbo.Coupons', N'PerDayLimit') IS NULL
    ALTER TABLE dbo.Coupons ADD PerDayLimit INT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_CouponRedemptions_Date' AND object_id=OBJECT_ID(N'dbo.CouponRedemptions'))
BEGIN
    CREATE INDEX IX_CouponRedemptions_Date
        ON dbo.CouponRedemptions (CouponId, RedeemedAt DESC)
        INCLUDE (CustomerId, DiscountAmount);
END
GO
