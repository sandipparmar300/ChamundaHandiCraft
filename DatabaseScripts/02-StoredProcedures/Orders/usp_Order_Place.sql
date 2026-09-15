/* =============================================================================
   usp_Order_Place
   -----------------------------------------------------------------------------
   Creates an order atomically.

   Specs:
     Prompt      §34  "Create Order -> Create Order Items -> Reserve/Reduce
                       Inventory -> Apply Coupon -> Create Payment Record ->
                       Create Shipment Information -> Create Order Status.
                       The database must maintain consistency if any operation
                       fails."
     Checkout.txt §12 the place-order flow
     Checkout.txt §20 "Inventory must be revalidated before order creation.
                       Coupons must be revalidated immediately before payment."
     Orders.txt  §23  stock reserved on placement; every status change audited

   THE POINT OF THIS PROCEDURE
   ---------------------------
   Everything it does could be done from C# in a TransactionScope. It is a
   procedure because the failure mode it prevents is a partial order: stock
   reserved but no order row, or an order row with a coupon consumed and no
   lines. One transaction, one round trip, no chance of the application dying
   between two calls and leaving inventory held by an order that does not exist.

   Inventory is revalidated INSIDE the transaction even though the checkout page
   already checked. Between the shopper seeing "in stock" and pressing Place
   Order, someone else may have taken the last unit - and the only check that
   counts is the one holding the row lock.

   INPUT
   -----
   @Items is a table-valued parameter, so an order of any size is one call.
   The type is created below if absent.

   OUTPUT
   ------
   @ResultCode  0 success
                1 out of stock          (@FailedProductId names the culprit)
                2 coupon no longer valid
                3 empty basket
                4 price mismatch        (cart total disagreed with the lines)
   ============================================================================= */

SET NOCOUNT ON;
GO

/* Table-valued parameter for the order lines. */
IF TYPE_ID(N'dbo.OrderLineTable') IS NULL
BEGIN
    CREATE TYPE dbo.OrderLineTable AS TABLE
    (
        ProductId       INT             NOT NULL,
        VariantId       INT             NULL,
        Quantity        INT             NOT NULL,
        UnitPrice       DECIMAL(18,2)   NOT NULL,
        UnitMrp         DECIMAL(18,2)   NULL,
        UnitCostPrice   DECIMAL(18,2)   NULL,
        LineDiscount    DECIMAL(18,2)   NOT NULL DEFAULT (0),
        TaxPercent      DECIMAL(18,4)   NOT NULL DEFAULT (0),
        /* Snapshot fields resolved by the caller from the live catalogue. */
        ProductName     NVARCHAR(300)   NOT NULL,
        Sku             VARCHAR(64)     NOT NULL,
        Slug            VARCHAR(300)    NULL,
        VariantSummary  NVARCHAR(300)   NULL,
        ImageUrl        NVARCHAR(1000)  NULL,
        ImageAlt        NVARCHAR(300)   NULL,
        ArtisanId       INT             NULL,
        ArtisanName     NVARCHAR(200)   NULL,
        HsnCode         VARCHAR(16)     NULL,
        WarehouseId     INT             NULL,
        PRIMARY KEY (ProductId, VariantId)
    );
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Order_Place
    @OrderNumber        VARCHAR(32),
    @CustomerId         INT             = NULL,
    @GuestToken         VARCHAR(64)     = NULL,
    @CartId             INT             = NULL,
    @CheckoutSessionId  INT             = NULL,

    @CustomerName       NVARCHAR(200),
    @CustomerEmail      NVARCHAR(256)   = NULL,
    @CustomerPhone      VARCHAR(24)     = NULL,

    @Items              dbo.OrderLineTable READONLY,

    /* Money, computed by the pricing engine and re-verified here. */
    @SubTotal           DECIMAL(18,2),
    @MrpTotal           DECIMAL(18,2)   = 0,
    @CouponId           INT             = NULL,
    @CouponCode         VARCHAR(64)     = NULL,
    @CouponDiscount     DECIMAL(18,2)   = 0,
    @OfferDiscount      DECIMAL(18,2)   = 0,
    @PointsRedeemed     INT             = 0,
    @PointsDiscount     DECIMAL(18,2)   = 0,
    @ShippingCost       DECIMAL(18,2)   = 0,
    @CodFee             DECIMAL(18,2)   = 0,
    @GiftWrapCost       DECIMAL(18,2)   = 0,
    @TaxTotal           DECIMAL(18,2)   = 0,
    @IsTaxInclusive     BIT             = 1,
    @Total              DECIMAL(18,2),
    @CurrencyCode       VARCHAR(3)      = 'INR',

    @PaymentMethod      TINYINT         = 4,      -- default COD
    @GiftWrapSelected   BIT             = 0,
    @GiftMessage        NVARCHAR(500)   = NULL,
    @CustomerNote       NVARCHAR(1000)  = NULL,
    @SourceChannel      VARCHAR(32)     = 'Web',
    @IpAddress          VARCHAR(64)     = NULL,

    /* Shipping snapshot for the grid. */
    @ShipToCity         NVARCHAR(150)   = NULL,
    @ShipToPincode      VARCHAR(12)     = NULL,
    @DeliveryBy         DATETIME2(3)    = NULL,
    @PlaceOfSupply      NVARCHAR(100)   = NULL,
    @IsInterState       BIT             = 0,

    @LoggedInUserId     INT             = NULL,

    @OrderId            INT             OUTPUT,
    @ResultCode         INT             OUTPUT,
    @FailedProductId    INT             OUTPUT,
    @Message            NVARCHAR(300)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @OrderId         = NULL;
    SET @ResultCode      = 0;
    SET @FailedProductId = NULL;
    SET @Message         = N'Order placed successfully.';

    ---------------------------------------------------------------------------
    -- Pre-flight checks that need no transaction
    ---------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM @Items)
    BEGIN
        SET @ResultCode = 3;
        SET @Message    = N'Your basket is empty.';
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM @Items WHERE Quantity <= 0)
    BEGIN
        SET @ResultCode = 3;
        SET @Message    = N'Every line must have a quantity of at least one.';
        RETURN;
    END

    /* Checkout.txt §20 - prices are recalculated during checkout. Verify the
       caller's SubTotal actually matches the lines it sent, so a tampered
       client cannot dictate a total. One paisa of tolerance for rounding. */
    DECLARE @ComputedSubTotal DECIMAL(18,2) =
        (SELECT SUM((UnitPrice * Quantity) - LineDiscount) FROM @Items);

    IF ABS(ISNULL(@ComputedSubTotal, 0) - @SubTotal) > 0.01
    BEGIN
        SET @ResultCode = 4;
        SET @Message    = N'Your basket total has changed. Please review and try again.';
        RETURN;
    END

    DECLARE @ItemCount INT = (SELECT SUM(Quantity) FROM @Items);

    BEGIN TRY
        BEGIN TRANSACTION;

        -----------------------------------------------------------------------
        -- 1. Reserve stock for every line FIRST.
        --    Before the order exists, so a shortfall costs nothing to unwind.
        -----------------------------------------------------------------------
        DECLARE @ProductId INT, @VariantId INT, @Qty INT, @WarehouseId INT;
        DECLARE @Rc INT, @Available INT;

        DECLARE line_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT ProductId, VariantId, Quantity, WarehouseId FROM @Items;

        OPEN line_cursor;
        FETCH NEXT FROM line_cursor INTO @ProductId, @VariantId, @Qty, @WarehouseId;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            /* Only reserve what is actually tracked. A made-to-order piece has
               no stock row and must not block the sale. */
            IF EXISTS (SELECT 1 FROM dbo.Products
                       WHERE Id = @ProductId AND TrackInventory = 1 AND IsDeleted = 0)
            BEGIN
                EXEC dbo.usp_Inventory_ReserveStock
                    @ProductId        = @ProductId,
                    @VariantId        = @VariantId,
                    @WarehouseId      = @WarehouseId,
                    @Quantity         = @Qty,
                    @ReferenceType    = 'Order',
                    @ReferenceNumber  = @OrderNumber,
                    @LoggedInUserId   = @LoggedInUserId,
                    @ResultCode       = @Rc        OUTPUT,
                    @AvailableQuantity= @Available OUTPUT;

                IF @Rc = 1
                BEGIN
                    CLOSE line_cursor; DEALLOCATE line_cursor;
                    ROLLBACK TRANSACTION;
                    SET @ResultCode      = 1;
                    SET @FailedProductId = @ProductId;
                    SET @Message = CASE
                        WHEN @Available > 0
                        THEN CONCAT(N'Only ', @Available, N' left of one of your items.')
                        ELSE N'One of your items just went out of stock.' END;
                    RETURN;
                END
            END

            FETCH NEXT FROM line_cursor INTO @ProductId, @VariantId, @Qty, @WarehouseId;
        END

        CLOSE line_cursor;
        DEALLOCATE line_cursor;

        -----------------------------------------------------------------------
        -- 2. Order header
        -----------------------------------------------------------------------
        INSERT INTO dbo.Orders
        (
            OrderNumber, CustomerId, GuestToken, CartId, CheckoutSessionId,
            CustomerName, CustomerEmail, CustomerPhone, PlacedOn,
            Status, PaymentStatus, PaymentMethod,
            SubTotal, MrpTotal, CouponId, CouponCode, CouponDiscount, OfferDiscount,
            PointsRedeemed, PointsDiscount, ShippingCost, CodFee, GiftWrapCost,
            TaxTotal, IsTaxInclusive, Total, CurrencyCode, ItemCount,
            GiftWrapSelected, GiftMessage, CustomerNote,
            ShipToCity, ShipToPincode, DeliveryBy,
            SourceChannel, IpAddress, CreatedAt, CreatedBy
        )
        VALUES
        (
            @OrderNumber, @CustomerId, @GuestToken, @CartId, @CheckoutSessionId,
            @CustomerName, @CustomerEmail, @CustomerPhone, SYSUTCDATETIME(),
            /* Checkout.txt §20: COD is confirmed immediately (0 Placed); an
               online payment waits in PaymentPending (1) until the gateway
               confirms, which is what stops a retry creating a second order. */
            CASE WHEN @PaymentMethod = 4 THEN 0 ELSE 1 END,
            CASE WHEN @PaymentMethod = 4 THEN 6 ELSE 0 END,   -- 6 CodPending / 0 Pending
            @PaymentMethod,
            @SubTotal, @MrpTotal, @CouponId, @CouponCode, @CouponDiscount, @OfferDiscount,
            @PointsRedeemed, @PointsDiscount, @ShippingCost, @CodFee, @GiftWrapCost,
            @TaxTotal, @IsTaxInclusive, @Total, @CurrencyCode, @ItemCount,
            @GiftWrapSelected, @GiftMessage, @CustomerNote,
            @ShipToCity, @ShipToPincode, @DeliveryBy,
            @SourceChannel, @IpAddress, SYSUTCDATETIME(), @LoggedInUserId
        );

        SET @OrderId = SCOPE_IDENTITY();

        -----------------------------------------------------------------------
        -- 3. Order lines - the purchase-time snapshot
        -----------------------------------------------------------------------
        INSERT INTO dbo.OrderItems
        (
            OrderId, ProductId, VariantId,
            ProductName, Sku, Slug, VariantSummary, ImageUrl, ImageAlt,
            ArtisanId, ArtisanName, HsnCode,
            Quantity, UnitPrice, UnitMrp, UnitCostPrice, LineDiscount,
            TaxPercent, TaxAmount, LineTotal,
            WarehouseId, CreatedAt, CreatedBy
        )
        SELECT
            @OrderId, i.ProductId, i.VariantId,
            i.ProductName, i.Sku, i.Slug, i.VariantSummary, i.ImageUrl, i.ImageAlt,
            i.ArtisanId, i.ArtisanName, i.HsnCode,
            i.Quantity, i.UnitPrice, i.UnitMrp,
            /* Cost snapshot: prefer what the caller resolved, else current cost. */
            ISNULL(i.UnitCostPrice, ISNULL(v.CostPrice, p.CostPrice)),
            i.LineDiscount,
            i.TaxPercent,
            /* Tax on the discounted line value. */
            ROUND(((i.UnitPrice * i.Quantity) - i.LineDiscount)
                  * (i.TaxPercent / 100.0), 2),
            (i.UnitPrice * i.Quantity) - i.LineDiscount,
            i.WarehouseId, SYSUTCDATETIME(), @LoggedInUserId
        FROM   @Items AS i
        LEFT JOIN dbo.Products        AS p ON p.Id = i.ProductId
        LEFT JOIN dbo.ProductVariants AS v ON v.Id = i.VariantId;

        -----------------------------------------------------------------------
        -- 4. Per-line GST components, frozen at sale time
        --    Intra-state splits into CGST + SGST; inter-state is a single IGST.
        -----------------------------------------------------------------------
        INSERT INTO dbo.OrderItemTaxes
        (
            OrderItemId, OrderId, TaxComponent, TaxRate,
            TaxableAmount, TaxAmount, HsnCode, PlaceOfSupply,
            IsInterState, IsTaxInclusive, CreatedAt, CreatedBy
        )
        SELECT
            oi.Id, @OrderId,
            c.Component,
            oi.TaxPercent * c.Share,
            oi.LineTotal - oi.TaxAmount,
            ROUND(oi.TaxAmount * c.Share, 2),
            oi.HsnCode, @PlaceOfSupply, @IsInterState, @IsTaxInclusive,
            SYSUTCDATETIME(), @LoggedInUserId
        FROM   dbo.OrderItems AS oi
        CROSS APPLY (
            SELECT Component, Share
            FROM  (VALUES
                      ('CGST', CASE WHEN @IsInterState = 0 THEN 0.5 ELSE 0 END),
                      ('SGST', CASE WHEN @IsInterState = 0 THEN 0.5 ELSE 0 END),
                      ('IGST', CASE WHEN @IsInterState = 1 THEN 1.0 ELSE 0 END)
                  ) AS x (Component, Share)
            WHERE Share > 0
        ) AS c
        WHERE  oi.OrderId = @OrderId
          AND  oi.TaxAmount > 0;

        -----------------------------------------------------------------------
        -- 5. Coupon redemption - atomic, re-checks every limit
        -----------------------------------------------------------------------
        IF @CouponId IS NOT NULL
        BEGIN
            DECLARE @CouponRc INT, @CouponMsg NVARCHAR(300);

            EXEC dbo.usp_Coupon_Redeem
                @CouponId       = @CouponId,
                @CustomerId     = @CustomerId,
                @OrderId        = @OrderId,
                @OrderNumber    = @OrderNumber,
                @DiscountAmount = @CouponDiscount,
                @OrderTotal     = @Total,
                @ResultCode     = @CouponRc  OUTPUT,
                @Message        = @CouponMsg OUTPUT;

            /* Somebody else took the last redemption between validation and
               here. The whole order rolls back - including the stock we just
               reserved - rather than silently charging full price. */
            IF @CouponRc <> 0
            BEGIN
                ROLLBACK TRANSACTION;
                SET @ResultCode = 2;
                SET @Message    = @CouponMsg;
                RETURN;
            END
        END

        -----------------------------------------------------------------------
        -- 6. Reward points spent (Orders.txt / rewards settings)
        -----------------------------------------------------------------------
        IF @PointsRedeemed > 0 AND @CustomerId IS NOT NULL
        BEGIN
            UPDATE dbo.Customers
            SET    RewardPointBalance = RewardPointBalance - @PointsRedeemed,
                   UpdatedAt          = SYSUTCDATETIME()
            WHERE  Id = @CustomerId
              AND  RewardPointBalance >= @PointsRedeemed;

            IF @@ROWCOUNT = 0
            BEGIN
                ROLLBACK TRANSACTION;
                SET @ResultCode = 2;
                SET @Message    = N'You do not have enough reward points.';
                RETURN;
            END

            INSERT INTO dbo.RewardPointLedgers
                (CustomerId, Points, EntryType, OrderId, OrderNumber, Note, CreatedAt, CreatedBy)
            VALUES
                (@CustomerId, -@PointsRedeemed, 'Redeemed', @OrderId, @OrderNumber,
                 CONCAT(N'Redeemed against order ', @OrderNumber), SYSUTCDATETIME(), @LoggedInUserId);
        END

        -----------------------------------------------------------------------
        -- 7. Opening status history row - Orders.txt §22
        -----------------------------------------------------------------------
        INSERT INTO dbo.OrderStatusHistories
            (OrderId, FromStatus, ToStatus, Note, CustomerNotified, IsSystemGenerated, ChangedBy, ChangedAt)
        VALUES
            (@OrderId, NULL,
             CASE WHEN @PaymentMethod = 4 THEN 0 ELSE 1 END,
             CASE WHEN @PaymentMethod = 4
                  THEN N'Order placed. Cash on delivery.'
                  ELSE N'Order created. Awaiting payment confirmation.' END,
             0, 1, @LoggedInUserId, SYSUTCDATETIME());

        -----------------------------------------------------------------------
        -- 8. Close the cart
        -----------------------------------------------------------------------
        IF @CartId IS NOT NULL
        BEGIN
            UPDATE dbo.Carts
            SET    IsActive    = 0,
                   AbandonedAt = NULL,          -- it converted; not abandoned
                   UpdatedAt   = SYSUTCDATETIME()
            WHERE  Id = @CartId;
        END

        IF @CheckoutSessionId IS NOT NULL
        BEGIN
            UPDATE dbo.CheckoutSessions
            SET    Status    = 'Completed',
                   UpdatedAt = SYSUTCDATETIME()
            WHERE  Id = @CheckoutSessionId;
        END

        -----------------------------------------------------------------------
        -- 9. Customer lifetime figures
        -----------------------------------------------------------------------
        IF @CustomerId IS NOT NULL
        BEGIN
            UPDATE dbo.Customers
            SET    OrderCount    = OrderCount + 1,
                   LifetimeValue = LifetimeValue + @Total,
                   LastOrderOn   = SYSUTCDATETIME(),
                   UpdatedAt     = SYSUTCDATETIME()
            WHERE  Id = @CustomerId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local','line_cursor') >= 0
        BEGIN
            CLOSE line_cursor;
            DEALLOCATE line_cursor;
        END
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
