/* =============================================================================
   usp_Order_CreateFromCart.sql
   -----------------------------------------------------------------------------
   Atomically creates an order directly from the customer's / guest's active cart.
   1. Validates active cart and active lines.
   2. Validates inventory stock and reserves/deducts stock.
   3. Re-validates coupon and records redemption.
   4. Resolves or saves customer shipping/billing addresses in dbo.OrderAddresses
      (and dbo.CustomerAddresses if requested).
   5. Generates official OrderNumber (e.g. CH-2026-000001).
   6. Inserts into dbo.Orders and dbo.OrderItems (with snapshot).
   7. Inserts initial audit into dbo.OrderStatusHistories.
   8. If online payment, inserts pending record into dbo.Payments.
   9. Closes the active cart (IsActive = 0, ConvertedOrderId = @OrderId).
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Order_CreateFromCart
    @CustomerId                 INT             = NULL,
    @GuestToken                 VARCHAR(100)    = NULL,
    @CustomerName               NVARCHAR(200),
    @CustomerEmail              NVARCHAR(256)   = NULL,
    @CustomerPhone              VARCHAR(24),
    @PaymentMethod              TINYINT         = 4,      -- 1=Card, 2=NetBanking, 3=UPI, 4=COD
    @DeliveryMethod             VARCHAR(50)     = 'Standard',
    @PointsRedeemed             INT             = 0,
    @CustomerNote               NVARCHAR(1000)  = NULL,
    @ShippingAddressId          INT             = NULL,
    @ShippingFullName           NVARCHAR(200)   = NULL,
    @ShippingPhone              VARCHAR(24)     = NULL,
    @ShippingLine1              NVARCHAR(300)   = NULL,
    @ShippingLine2              NVARCHAR(300)   = NULL,
    @ShippingLandmark           NVARCHAR(200)   = NULL,
    @ShippingCity               NVARCHAR(150)   = NULL,
    @ShippingState              NVARCHAR(150)   = NULL,
    @ShippingPincode            VARCHAR(12)     = NULL,
    @BillingSameAsShipping      BIT             = 1,
    @BillingFullName            NVARCHAR(200)   = NULL,
    @BillingPhone               VARCHAR(24)     = NULL,
    @BillingLine1               NVARCHAR(300)   = NULL,
    @BillingLine2               NVARCHAR(300)   = NULL,
    @BillingCity                NVARCHAR(150)   = NULL,
    @BillingState               NVARCHAR(150)   = NULL,
    @BillingPincode             VARCHAR(12)     = NULL,
    @SaveAddressForCustomer     BIT             = 0,
    @FreeShippingThreshold      DECIMAL(18,2)   = 1000.00,

    @OrderId                    INT             OUTPUT,
    @OrderNumber                VARCHAR(32)     OUTPUT,
    @TotalAmount                DECIMAL(18,2)   OUTPUT,
    @ResultCode                 INT             OUTPUT,
    @Message                    NVARCHAR(300)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @OrderId     = NULL;
    SET @OrderNumber = NULL;
    SET @TotalAmount = 0.00;
    SET @ResultCode  = 0;
    SET @Message     = N'Order placed successfully.';

    IF @FreeShippingThreshold IS NULL OR @FreeShippingThreshold <= 0
        SET @FreeShippingThreshold = 1000.00;

    -- 1. Locate active cart
    DECLARE @CartId INT = NULL;
    EXEC dbo.usp_Cart_GetOrCreate @CustomerId = @CustomerId, @GuestToken = @GuestToken, @CartId = @CartId OUTPUT;

    IF @CartId IS NULL
    BEGIN
        SET @ResultCode = 3;
        SET @Message    = N'Your cart is empty. Please add items before placing an order.';
        RETURN;
    END

    -- Check if cart has active items
    IF NOT EXISTS (
        SELECT 1 FROM dbo.CartItems
        WHERE CartId = @CartId AND IsSavedForLater = 0 AND IsDeleted = 0 AND Quantity > 0
    )
    BEGIN
        SET @ResultCode = 3;
        SET @Message    = N'Your cart has no active items. Please add items before checking out.';
        RETURN;
    END

    -- 2. Resolve Shipping Address details
    IF @ShippingAddressId IS NOT NULL AND @ShippingAddressId > 0
    BEGIN
        SELECT TOP 1
            @ShippingFullName = FullName,
            @ShippingPhone    = Phone,
            @ShippingLine1    = Line1,
            @ShippingLine2    = Line2,
            @ShippingLandmark = Landmark,
            @ShippingCity     = CityName,
            @ShippingState    = StateName,
            @ShippingPincode  = Pincode
        FROM dbo.CustomerAddresses
        WHERE Id = @ShippingAddressId AND IsDeleted = 0;
    END

    IF @ShippingFullName IS NULL OR @ShippingFullName = '' SET @ShippingFullName = @CustomerName;
    IF @ShippingPhone IS NULL OR @ShippingPhone = '' SET @ShippingPhone = @CustomerPhone;

    IF @ShippingLine1 IS NULL OR @ShippingLine1 = '' OR @ShippingCity IS NULL OR @ShippingCity = '' OR @ShippingPincode IS NULL OR @ShippingPincode = ''
    BEGIN
        SET @ResultCode = 5;
        SET @Message    = N'Complete delivery address (street, city, and PIN code) is required.';
        RETURN;
    END

    -- Save address to CustomerAddresses if requested and customer logged in
    IF @SaveAddressForCustomer = 1 AND @CustomerId IS NOT NULL AND @CustomerId > 0
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM dbo.CustomerAddresses
            WHERE CustomerId = @CustomerId
              AND Line1 = @ShippingLine1
              AND Pincode = @ShippingPincode
              AND IsDeleted = 0
        )
        BEGIN
            INSERT INTO dbo.CustomerAddresses (
                CustomerId, LabelType, FullName, Phone, AlternatePhone,
                Line1, Line2, Landmark, CityName, StateName, CountryName,
                Pincode, IsDefault, CreatedAt, CreatedBy, IsActive, IsDeleted
            )
            VALUES (
                @CustomerId, 0, @ShippingFullName, @ShippingPhone, NULL,
                @ShippingLine1, @ShippingLine2, @ShippingLandmark, @ShippingCity, @ShippingState, 'India',
                @ShippingPincode, 0, SYSUTCDATETIME(), @CustomerId, 1, 0
            );
        END
    END

    -- 3. Billing Address Resolution
    IF @BillingSameAsShipping = 1
    BEGIN
        SET @BillingFullName = @ShippingFullName;
        SET @BillingPhone    = @ShippingPhone;
        SET @BillingLine1    = @ShippingLine1;
        SET @BillingLine2    = @ShippingLine2;
        SET @BillingCity     = @ShippingCity;
        SET @BillingState    = @ShippingState;
        SET @BillingPincode  = @ShippingPincode;
    END
    ELSE
    BEGIN
        IF @BillingFullName IS NULL OR @BillingFullName = '' SET @BillingFullName = @ShippingFullName;
        IF @BillingPhone IS NULL OR @BillingPhone = '' SET @BillingPhone = @ShippingPhone;
        IF @BillingLine1 IS NULL OR @BillingLine1 = '' SET @BillingLine1 = @ShippingLine1;
        IF @BillingCity IS NULL OR @BillingCity = '' SET @BillingCity = @ShippingCity;
        IF @BillingState IS NULL OR @BillingState = '' SET @BillingState = @ShippingState;
        IF @BillingPincode IS NULL OR @BillingPincode = '' SET @BillingPincode = @ShippingPincode;
    END

    -- 4. Calculate Subtotals and Check Live Inventory
    IF OBJECT_ID('tempdb..#CheckoutLines') IS NOT NULL DROP TABLE #CheckoutLines;

    SELECT
        ci.Id AS CartItemId,
        ci.ProductId,
        ci.VariantId,
        ci.Quantity,
        p.Name AS ProductName,
        p.Slug,
        p.Sku AS ProductSku,
        ISNULL(v.Sku, p.Sku) AS Sku,
        ISNULL(v.VariantSummary, N'Standard Piece') AS VariantSummary,
        ISNULL(v.Price, p.Price) AS UnitPrice,
        ISNULL(v.Mrp, p.Mrp) AS UnitMrp,
        CAST(ci.Quantity * ISNULL(v.Price, p.Price) AS DECIMAL(18,2)) AS LineTotal,
        ImageUrl = ISNULL(
            (SELECT TOP 1 m.Url FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 ORDER BY m.IsPrimary DESC, m.SortOrder ASC, m.Id ASC),
            '/assets/images/placeholders/brass.svg'
        ),
        p.TrackInventory,
        AvailableStock = CASE
            WHEN ISNULL(v.Id, 0) > 0 THEN ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.VariantId = v.Id AND s.IsDeleted = 0), 10)
            ELSE ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0), 10)
        END
    INTO #CheckoutLines
    FROM dbo.CartItems ci
    JOIN dbo.Products p ON p.Id = ci.ProductId AND p.IsActive = 1 AND p.IsDeleted = 0
    LEFT JOIN dbo.ProductVariants v ON v.Id = ci.VariantId AND v.IsActive = 1 AND v.IsDeleted = 0
    WHERE ci.CartId = @CartId
      AND ci.IsSavedForLater = 0
      AND ci.IsDeleted = 0
      AND ci.Quantity > 0;

    -- Verify stock for tracked items
    DECLARE @OosItemName NVARCHAR(300) = NULL;
    DECLARE @OosAvailable INT = 0;

    SELECT TOP 1
        @OosItemName = ProductName,
        @OosAvailable = AvailableStock
    FROM #CheckoutLines
    WHERE TrackInventory = 1 AND AvailableStock < Quantity;

    IF @OosItemName IS NOT NULL
    BEGIN
        SET @ResultCode = 1;
        SET @Message = CASE
            WHEN @OosAvailable > 0 THEN CONCAT(N'Only ', @OosAvailable, N' piece(s) available for ', @OosItemName, N'. Please update your quantity.')
            ELSE CONCAT(@OosItemName, N' just went out of stock.')
        END;
        RETURN;
    END

    -- Financial calculations
    DECLARE @Subtotal DECIMAL(18,2) = ISNULL((SELECT SUM(LineTotal) FROM #CheckoutLines), 0.00);
    DECLARE @MrpTotal DECIMAL(18,2) = ISNULL((SELECT SUM(Quantity * ISNULL(UnitMrp, UnitPrice)) FROM #CheckoutLines), 0.00);
    DECLARE @ItemCount INT = ISNULL((SELECT SUM(Quantity) FROM #CheckoutLines), 0);

    -- 5. Coupon validation
    DECLARE @CouponId INT = NULL;
    DECLARE @CouponCode VARCHAR(64) = NULL;
    DECLARE @CouponDiscount DECIMAL(18,2) = 0.00;
    DECLARE @CouponValid BIT = 0;
    DECLARE @CouponMsg NVARCHAR(300) = NULL;

    SELECT
        @CouponId = CouponId,
        @CouponCode = CouponCode
    FROM dbo.Carts
    WHERE Id = @CartId;

    IF @CouponCode IS NOT NULL AND @CouponCode <> '' AND @Subtotal > 0
    BEGIN
        EXEC dbo.usp_Coupon_Validate
            @Code           = @CouponCode,
            @CustomerId     = @CustomerId,
            @CartSubTotal   = @Subtotal,
            @IsFirstOrder   = 0,
            @ProductIds     = NULL,
            @IsValid        = @CouponValid OUTPUT,
            @CouponId       = @CouponId OUTPUT,
            @DiscountAmount = @CouponDiscount OUTPUT,
            @Message        = @CouponMsg OUTPUT;

        IF @CouponValid = 0
        BEGIN
            SET @ResultCode = 2;
            SET @Message = ISNULL(@CouponMsg, N'Applied coupon is no longer valid. Please remove it and try again.');
            RETURN;
        END
    END

    -- Shipping cost
    DECLARE @ShippingCost DECIMAL(18,2) = 0.00;
    IF @Subtotal < @FreeShippingThreshold
        SET @ShippingCost = 99.00;

    IF @DeliveryMethod = 'Express' OR @DeliveryMethod = '2'
        SET @ShippingCost = @ShippingCost + 199.00;

    -- COD fee
    DECLARE @CodFee DECIMAL(18,2) = 0.00;
    IF @PaymentMethod = 4 -- COD
        SET @CodFee = 49.00;

    -- Gift wrap
    DECLARE @GiftWrapCost DECIMAL(18,2) = 0.00;
    DECLARE @GiftWrapSelected BIT = 0;
    DECLARE @GiftMessage NVARCHAR(500) = NULL;

    SELECT
        @GiftWrapSelected = ISNULL(GiftWrapSelected, 0),
        @GiftMessage = GiftMessage
    FROM dbo.Carts
    WHERE Id = @CartId;

    IF @GiftWrapSelected = 1
        SET @GiftWrapCost = 99.00;

    -- Points discount
    DECLARE @PointsDiscount DECIMAL(18,2) = 0.00;
    IF @PointsRedeemed > 0 AND @CustomerId IS NOT NULL
    BEGIN
        DECLARE @CustPoints INT = 0;
        SELECT @CustPoints = ISNULL(RewardPointBalance, 0) FROM dbo.Customers WHERE Id = @CustomerId;
        IF @PointsRedeemed > @CustPoints SET @PointsRedeemed = @CustPoints;
        SET @PointsDiscount = CAST(@PointsRedeemed AS DECIMAL(18,2));
    END
    ELSE
    BEGIN
        SET @PointsRedeemed = 0;
    END

    -- Final payable total
    DECLARE @GrandTotal DECIMAL(18,2) = @Subtotal - @CouponDiscount - @PointsDiscount + @ShippingCost + @CodFee + @GiftWrapCost;
    IF @GrandTotal < 0.00 SET @GrandTotal = 0.00;

    SET @TotalAmount = @GrandTotal;

    -- 6. Generate official OrderNumber (e.g. CH-2026-000001)
    DECLARE @YearStr VARCHAR(4) = CAST(YEAR(SYSUTCDATETIME()) AS VARCHAR(4));
    DECLARE @NextSeq INT = 1;
    SELECT @NextSeq = ISNULL(MAX(Id), 0) + 1 FROM dbo.Orders;
    SET @OrderNumber = CONCAT('CH-', @YearStr, '-', RIGHT('000000' + CAST(@NextSeq AS VARCHAR(6)), 6));

    DECLARE @DeliveryEstimate DATETIME2(3) = DATEADD(DAY, CASE WHEN @DeliveryMethod = 'Express' OR @DeliveryMethod = '2' THEN 2 ELSE 4 END, SYSUTCDATETIME());

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 7. Insert Order Header
        INSERT INTO dbo.Orders (
            OrderNumber,
            CustomerId,
            GuestToken,
            CartId,
            CustomerName,
            CustomerEmail,
            CustomerPhone,
            PlacedOn,
            Status,
            PaymentStatus,
            PaymentMethod,
            SubTotal,
            MrpTotal,
            CouponId,
            CouponCode,
            CouponDiscount,
            OfferDiscount,
            PointsRedeemed,
            PointsDiscount,
            ShippingCost,
            CodFee,
            GiftWrapCost,
            TaxTotal,
            IsTaxInclusive,
            Total,
            CurrencyCode,
            ItemCount,
            GiftWrapSelected,
            GiftMessage,
            CustomerNote,
            ShipToCity,
            ShipToPincode,
            DeliveryBy,
            SourceChannel,
            CreatedAt,
            CreatedBy,
            IsActive,
            IsDeleted
        )
        VALUES (
            @OrderNumber,
            @CustomerId,
            @GuestToken,
            @CartId,
            @CustomerName,
            @CustomerEmail,
            @CustomerPhone,
            SYSUTCDATETIME(),
            CASE WHEN @PaymentMethod = 4 THEN 0 ELSE 1 END,     -- 0=Placed (COD), 1=PaymentPending (Online)
            CASE WHEN @PaymentMethod = 4 THEN 6 ELSE 0 END,     -- 6=CodPending, 0=Pending
            @PaymentMethod,
            @Subtotal,
            @MrpTotal,
            @CouponId,
            @CouponCode,
            @CouponDiscount,
            0.00,
            @PointsRedeemed,
            @PointsDiscount,
            @ShippingCost,
            @CodFee,
            @GiftWrapCost,
            0.00,
            1,
            @GrandTotal,
            'INR',
            @ItemCount,
            @GiftWrapSelected,
            @GiftMessage,
            @CustomerNote,
            @ShippingCity,
            @ShippingPincode,
            @DeliveryEstimate,
            'Web',
            SYSUTCDATETIME(),
            @CustomerId,
            1,
            0
        );

        SET @OrderId = SCOPE_IDENTITY();

        -- 8. Insert Order Items
        INSERT INTO dbo.OrderItems (
            OrderId,
            ProductId,
            VariantId,
            ProductName,
            Sku,
            Slug,
            VariantSummary,
            ImageUrl,
            ImageAlt,
            Quantity,
            UnitPrice,
            UnitMrp,
            LineDiscount,
            TaxPercent,
            TaxAmount,
            LineTotal,
            CreatedAt,
            CreatedBy
        )
        SELECT
            @OrderId,
            cl.ProductId,
            cl.VariantId,
            cl.ProductName,
            cl.Sku,
            cl.Slug,
            cl.VariantSummary,
            cl.ImageUrl,
            cl.ProductName,
            cl.Quantity,
            cl.UnitPrice,
            cl.UnitMrp,
            0.00,
            0.00,
            0.00,
            cl.LineTotal,
            SYSUTCDATETIME(),
            @CustomerId
        FROM #CheckoutLines cl;

        -- 9. Insert Shipping & Billing Addresses
        INSERT INTO dbo.OrderAddresses (
            OrderId, AddressKind, LabelType, FullName, Phone, AlternatePhone,
            Line1, Line2, Landmark, CityName, StateName, CountryName, Pincode, CreatedAt
        )
        VALUES (
            @OrderId, 'Shipping', 0, @ShippingFullName, @ShippingPhone, NULL,
            @ShippingLine1, @ShippingLine2, @ShippingLandmark, @ShippingCity, @ShippingState, 'India', @ShippingPincode, SYSUTCDATETIME()
        );

        INSERT INTO dbo.OrderAddresses (
            OrderId, AddressKind, LabelType, FullName, Phone, AlternatePhone,
            Line1, Line2, Landmark, CityName, StateName, CountryName, Pincode, CreatedAt
        )
        VALUES (
            @OrderId, 'Billing', 0, @BillingFullName, @BillingPhone, NULL,
            @BillingLine1, @BillingLine2, NULL, @BillingCity, @BillingState, 'India', @BillingPincode, SYSUTCDATETIME()
        );

        -- 10. Reserve Stock
        UPDATE s
        SET s.Reserved = s.Reserved + cl.Quantity,
            s.UpdatedAt = SYSUTCDATETIME()
        FROM dbo.InventoryStocks s
        JOIN #CheckoutLines cl ON (cl.VariantId IS NOT NULL AND s.VariantId = cl.VariantId)
                               OR (cl.VariantId IS NULL AND s.ProductId = cl.ProductId AND s.VariantId IS NULL)
        WHERE s.IsDeleted = 0;

        -- 11. Record Coupon Redemption
        IF @CouponId IS NOT NULL
        BEGIN
            UPDATE dbo.Coupons
            SET UsageCount = UsageCount + 1,
                TotalDiscountGiven = TotalDiscountGiven + @CouponDiscount,
                UpdatedAt = SYSUTCDATETIME()
            WHERE Id = @CouponId;
        END

        -- 12. Record Points Ledger
        IF @PointsRedeemed > 0 AND @CustomerId IS NOT NULL
        BEGIN
            DECLARE @CurrentBal INT = 0;
            SELECT @CurrentBal = ISNULL(RewardPointBalance, 0) FROM dbo.Customers WHERE Id = @CustomerId;

            UPDATE dbo.Customers
            SET RewardPointBalance = RewardPointBalance - @PointsRedeemed,
                UpdatedAt = SYSUTCDATETIME()
            WHERE Id = @CustomerId;

            INSERT INTO dbo.RewardPointLedgers (
                CustomerId, EntryType, Activity, Delta, BalanceAfter, OrderId, Note, CreatedAt, CreatedBy
            )
            VALUES (
                @CustomerId, 2, N'Redeemed', -@PointsRedeemed, (@CurrentBal - @PointsRedeemed), @OrderId,
                CONCAT(N'Redeemed against order ', @OrderNumber), SYSUTCDATETIME(), @CustomerId
            );
        END

        -- 13. Audit Status History
        INSERT INTO dbo.OrderStatusHistories (
            OrderId, FromStatus, ToStatus, Note, CustomerNotified, IsSystemGenerated, ChangedBy, ChangedAt
        )
        VALUES (
            @OrderId, NULL,
            CASE WHEN @PaymentMethod = 4 THEN 0 ELSE 1 END,
            CASE WHEN @PaymentMethod = 4 THEN N'Order placed successfully. Cash on delivery.' ELSE N'Order created. Awaiting online payment.' END,
            0, 1, @CustomerId, SYSUTCDATETIME()
        );

        -- 14. If Online Payment, record in dbo.Payments
        IF @PaymentMethod <> 4
        BEGIN
            DECLARE @TxnId VARCHAR(64) = CONCAT('TXN-', CAST(NEWID() AS VARCHAR(36)));
            INSERT INTO dbo.Payments (
                TransactionId, OrderId, CustomerId, GatewayName, GatewayOrderId,
                Amount, CurrencyCode, Method, Status, CreatedAt, CreatedBy, IsActive, IsDeleted
            )
            VALUES (
                @TxnId, @OrderId, @CustomerId, 'Razorpay', @OrderNumber,
                @GrandTotal, 'INR', @PaymentMethod, 0, SYSUTCDATETIME(), @CustomerId, 1, 0
            );
        END

        -- 15. Close the active cart
        UPDATE dbo.Carts
        SET IsActive = 0,
            ConvertedOrderId = @OrderId,
            UpdatedAt = SYSUTCDATETIME()
        WHERE Id = @CartId;

        -- 16. Customer Lifetime Updates
        IF @CustomerId IS NOT NULL
        BEGIN
            UPDATE dbo.Customers
            SET OrderCount = OrderCount + 1,
                LifetimeValue = LifetimeValue + @GrandTotal,
                LastOrderOn = SYSUTCDATETIME(),
                UpdatedAt = SYSUTCDATETIME()
            WHERE Id = @CustomerId;
        END

        COMMIT TRANSACTION;

        SET @ResultCode = 0;
        SET @Message = N'Order placed successfully.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @ResultCode = 99;
        SET @Message = ERROR_MESSAGE();
    END CATCH
END
GO
