/* =============================================================================
   usp_Cart_CustomerProcedures.sql
   -----------------------------------------------------------------------------
   Customer Storefront Stored Procedures for Priority 3:
     1. dbo.usp_Cart_GetOrCreate
     2. dbo.usp_Cart_Get
     3. dbo.usp_Cart_AddItem
     4. dbo.usp_Cart_UpdateQuantity
     5. dbo.usp_Cart_RemoveItem
     6. dbo.usp_Cart_ApplyCoupon
     7. dbo.usp_Cart_RemoveCoupon
     8. dbo.usp_Cart_MergeGuestCart
   ============================================================================= */

SET NOCOUNT ON;
GO

-- 1. Get or Create Active Cart
CREATE OR ALTER PROCEDURE dbo.usp_Cart_GetOrCreate
    @CustomerId INT          = NULL,
    @GuestToken VARCHAR(100) = NULL,
    @CartId     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @CartId = NULL;

    -- 1. Try finding by CustomerId first if customer logged in
    IF @CustomerId IS NOT NULL AND @CustomerId > 0
    BEGIN
        SELECT TOP 1 @CartId = Id
        FROM   dbo.Carts
        WHERE  CustomerId = @CustomerId
          AND  IsActive = 1
          AND  IsDeleted = 0
          AND  ConvertedOrderId IS NULL
          AND  MergedIntoCartId IS NULL
        ORDER BY LastActivityAt DESC, Id DESC;
    END

    -- 2. If not found and GuestToken is supplied, find by GuestToken
    IF @CartId IS NULL AND @GuestToken IS NOT NULL AND @GuestToken <> ''
    BEGIN
        SELECT TOP 1 @CartId = Id
        FROM   dbo.Carts
        WHERE  GuestToken = @GuestToken
          AND  IsActive = 1
          AND  IsDeleted = 0
          AND  ConvertedOrderId IS NULL
          AND  MergedIntoCartId IS NULL
        ORDER BY LastActivityAt DESC, Id DESC;
    END

    -- 3. If still not found, create new cart
    IF @CartId IS NULL
    BEGIN
        INSERT INTO dbo.Carts (
            CustomerId,
            GuestToken,
            CouponId,
            CouponCode,
            GiftWrapSelected,
            GiftMessage,
            PointsApplied,
            DeliveryPincode,
            MergedIntoCartId,
            MergedAt,
            ConvertedOrderId,
            LastActivityAt,
            CreatedAt,
            CreatedBy,
            IsActive,
            IsDeleted
        )
        VALUES (
            @CustomerId,
            @GuestToken,
            NULL,
            NULL,
            0,
            NULL,
            0,
            NULL,
            NULL,
            NULL,
            NULL,
            SYSUTCDATETIME(),
            SYSUTCDATETIME(),
            @CustomerId,
            1,
            0
        );

        SET @CartId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        -- Update last activity
        UPDATE dbo.Carts
        SET    LastActivityAt = SYSUTCDATETIME()
        WHERE  Id = @CartId;
    END
END
GO

-- 2. Get Cart Details (Summary + Lines + SavedForLater)
CREATE OR ALTER PROCEDURE dbo.usp_Cart_Get
    @CustomerId            INT             = NULL,
    @GuestToken            VARCHAR(100)    = NULL,
    @FreeShippingThreshold DECIMAL(18,2)   = 999.00
AS
BEGIN
    SET NOCOUNT ON;

    IF @FreeShippingThreshold IS NULL OR @FreeShippingThreshold <= 0
        SET @FreeShippingThreshold = 999.00;

    DECLARE @CartId INT = NULL;
    EXEC dbo.usp_Cart_GetOrCreate @CustomerId = @CustomerId, @GuestToken = @GuestToken, @CartId = @CartId OUTPUT;

    -- Temporary table for active lines
    IF OBJECT_ID('tempdb..#ActiveLines') IS NOT NULL DROP TABLE #ActiveLines;

    SELECT  ci.Id AS CartItemId,
            ci.CartId,
            ci.ProductId,
            ci.VariantId,
            p.Name,
            p.Slug,
            ImageUrl = ISNULL(
                (SELECT TOP 1 m.Url FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 ORDER BY m.IsPrimary DESC, m.SortOrder ASC, m.Id ASC),
                '/assets/images/placeholders/brass.svg'
            ),
            ImageAlt = ISNULL(p.Name, ''),
            VariantSummary = ISNULL(v.VariantSummary, N'Standard Piece'),
            Sku = ISNULL(v.Sku, p.Sku),
            Price = ISNULL(v.Price, p.Price),
            Mrp = ISNULL(v.Mrp, p.Mrp),
            ci.Quantity,
            MaxQuantity = ISNULL(p.MaxQuantityPerOrder, 10),
            StockState = CASE 
                WHEN ISNULL(v.Id, 0) > 0 THEN
                    CASE 
                        WHEN ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.VariantId = v.Id AND s.IsDeleted = 0), 10) <= 0 THEN 2
                        WHEN ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.VariantId = v.Id AND s.IsDeleted = 0), 10) <= 3 THEN 1
                        ELSE 0
                    END
                ELSE
                    CASE 
                        WHEN ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0), 10) <= 0 THEN 2
                        WHEN ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0), 10) <= ISNULL(p.LowStockThreshold, 5) THEN 1
                        ELSE 0
                    END
            END,
            StockCount = CASE 
                WHEN ISNULL(v.Id, 0) > 0 THEN (SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.VariantId = v.Id AND s.IsDeleted = 0)
                ELSE (SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.IsDeleted = 0)
            END,
            IsHandmade = ISNULL(p.IsHandmade, 1),
            LineTotal = CAST(ci.Quantity * ISNULL(v.Price, p.Price) AS DECIMAL(18,2))
    INTO    #ActiveLines
    FROM    dbo.CartItems ci
    JOIN    dbo.Products p ON p.Id = ci.ProductId AND p.IsActive = 1 AND p.IsDeleted = 0
    LEFT JOIN dbo.ProductVariants v ON v.Id = ci.VariantId AND v.IsActive = 1 AND v.IsDeleted = 0
    WHERE   ci.CartId = @CartId
      AND   ci.IsSavedForLater = 0
      AND   ci.IsDeleted = 0;

    -- Aggregate totals
    DECLARE @Subtotal DECIMAL(18,2) = ISNULL((SELECT SUM(LineTotal) FROM #ActiveLines), 0.00);
    DECLARE @MrpTotal DECIMAL(18,2) = ISNULL((SELECT SUM(Quantity * ISNULL(Mrp, Price)) FROM #ActiveLines), 0.00);
    DECLARE @ItemCount INT = ISNULL((SELECT SUM(Quantity) FROM #ActiveLines), 0);

    -- Check and validate coupon if attached to cart
    DECLARE @CouponCode VARCHAR(64) = NULL;
    DECLARE @CouponDiscount DECIMAL(18,2) = 0.00;
    DECLARE @CouponValid BIT = 0;
    DECLARE @CouponMessage NVARCHAR(300) = NULL;
    DECLARE @ValidatedCouponId INT = NULL;

    SELECT @CouponCode = CouponCode
    FROM   dbo.Carts
    WHERE  Id = @CartId;

    IF @CouponCode IS NOT NULL AND @CouponCode <> '' AND @Subtotal > 0
    BEGIN
        EXEC dbo.usp_Coupon_Validate
            @Code           = @CouponCode,
            @CustomerId     = @CustomerId,
            @CartSubTotal   = @Subtotal,
            @IsFirstOrder   = 0,
            @ProductIds     = NULL,
            @IsValid        = @CouponValid OUTPUT,
            @CouponId       = @ValidatedCouponId OUTPUT,
            @DiscountAmount = @CouponDiscount OUTPUT,
            @Message        = @CouponMessage OUTPUT;

        IF @CouponValid = 0
        BEGIN
            -- Coupon expired or no longer valid with current cart value
            UPDATE dbo.Carts
            SET    CouponId = NULL,
                   CouponCode = NULL
            WHERE  Id = @CartId;

            SET @CouponCode = NULL;
            SET @CouponDiscount = 0.00;
        END
    END
    ELSE IF @Subtotal = 0 AND @CouponCode IS NOT NULL
    BEGIN
        UPDATE dbo.Carts
        SET    CouponId = NULL,
               CouponCode = NULL
        WHERE  Id = @CartId;

        SET @CouponCode = NULL;
        SET @CouponDiscount = 0.00;
    END

    -- Shipping fee
    DECLARE @ShippingFee DECIMAL(18,2) = 0.00;
    IF @Subtotal > 0 AND @Subtotal < @FreeShippingThreshold
    BEGIN
        SET @ShippingFee = 99.00;
    END

    -- Gift Wrap fee
    DECLARE @GiftWrapFee DECIMAL(18,2) = 0.00;
    DECLARE @GiftWrapSelected BIT = 0;
    DECLARE @GiftMessage NVARCHAR(500) = NULL;

    SELECT @GiftWrapSelected = ISNULL(GiftWrapSelected, 0),
           @GiftMessage = GiftMessage
    FROM   dbo.Carts
    WHERE  Id = @CartId;

    IF @GiftWrapSelected = 1
        SET @GiftWrapFee = 50.00;

    -- Result Set 1: Cart Header & Summary
    SELECT  CartId = @CartId,
            CustomerId = @CustomerId,
            GuestToken = @GuestToken,
            Subtotal = @Subtotal,
            MrpTotal = @MrpTotal,
            CouponCode = @CouponCode,
            CouponDiscount = @CouponDiscount,
            Shipping = @ShippingFee,
            CodFee = 0.00,
            GiftWrap = @GiftWrapFee,
            PointsApplied = 0.00,
            TaxTotal = 0.00,
            TaxInclusive = 1,
            ItemCount = @ItemCount,
            FreeShippingThreshold = @FreeShippingThreshold,
            GiftWrapSelected = @GiftWrapSelected,
            GiftMessage = @GiftMessage;

    -- Result Set 2: Active Cart Lines
    SELECT  Id = CartItemId,
            ProductId,
            VariantId,
            Slug,
            Name,
            ImageUrl,
            ImageAlt,
            VariantSummary,
            Sku,
            Price,
            Mrp,
            Quantity,
            MaxQuantity,
            Stock = StockState,
            StockCount,
            IsHandmade,
            LineTotal
    FROM    #ActiveLines
    ORDER BY CartItemId ASC;

    -- Result Set 3: Saved For Later Lines
    SELECT  ci.Id,
            ci.ProductId,
            ci.VariantId,
            p.Slug,
            p.Name,
            ImageUrl = ISNULL(
                (SELECT TOP 1 m.Url FROM dbo.ProductMedia m WHERE m.ProductId = p.Id AND m.IsDeleted = 0 ORDER BY m.IsPrimary DESC, m.SortOrder ASC, m.Id ASC),
                '/assets/images/placeholders/brass.svg'
            ),
            ImageAlt = ISNULL(p.Name, ''),
            VariantSummary = ISNULL(v.VariantSummary, N'Standard Piece'),
            Sku = ISNULL(v.Sku, p.Sku),
            Price = ISNULL(v.Price, p.Price),
            Mrp = ISNULL(v.Mrp, p.Mrp),
            ci.Quantity,
            MaxQuantity = ISNULL(p.MaxQuantityPerOrder, 10),
            Stock = 0,
            StockCount = 10,
            IsHandmade = ISNULL(p.IsHandmade, 1),
            LineTotal = CAST(ci.Quantity * ISNULL(v.Price, p.Price) AS DECIMAL(18,2))
    FROM    dbo.CartItems ci
    JOIN    dbo.Products p ON p.Id = ci.ProductId AND p.IsActive = 1 AND p.IsDeleted = 0
    LEFT JOIN dbo.ProductVariants v ON v.Id = ci.VariantId AND v.IsActive = 1 AND v.IsDeleted = 0
    WHERE   ci.CartId = @CartId
      AND   ci.IsSavedForLater = 1
      AND   ci.IsDeleted = 0
    ORDER BY ci.Id ASC;
END
GO

-- 3. Add Item to Cart
CREATE OR ALTER PROCEDURE dbo.usp_Cart_AddItem
    @CustomerId            INT             = NULL,
    @GuestToken            VARCHAR(100)    = NULL,
    @ProductId             INT,
    @VariantId             INT             = NULL,
    @Quantity              INT             = 1,
    @Note                  NVARCHAR(500)   = NULL,
    @FreeShippingThreshold DECIMAL(18,2)   = 999.00
AS
BEGIN
    SET NOCOUNT ON;

    IF @Quantity < 1 SET @Quantity = 1;

    -- Verify product exists and active
    IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE Id = @ProductId AND IsActive = 1 AND IsDeleted = 0)
    BEGIN
        RAISERROR('The requested handcrafted piece is no longer available.', 16, 1);
        RETURN;
    END

    -- If product has variants and no VariantId passed, auto-select default or first variant
    IF @VariantId IS NULL
    BEGIN
        SELECT TOP 1 @VariantId = Id
        FROM   dbo.ProductVariants
        WHERE  ProductId = @ProductId AND IsActive = 1 AND IsDeleted = 0
        ORDER BY IsDefault DESC, SortOrder ASC, Id ASC;
    END

    DECLARE @CartId INT = NULL;
    EXEC dbo.usp_Cart_GetOrCreate @CustomerId = @CustomerId, @GuestToken = @GuestToken, @CartId = @CartId OUTPUT;

    -- Check if item is already in cart
    DECLARE @ExistingCartItemId BIGINT = NULL;
    DECLARE @CurrentQuantity INT = 0;

    SELECT TOP 1 
           @ExistingCartItemId = Id,
           @CurrentQuantity = Quantity
    FROM   dbo.CartItems
    WHERE  CartId = @CartId
      AND  ProductId = @ProductId
      AND  (VariantId = @VariantId OR (VariantId IS NULL AND @VariantId IS NULL))
      AND  IsSavedForLater = 0
      AND  IsDeleted = 0;

    -- Get live price and MRP
    DECLARE @LivePrice DECIMAL(18,2) = 0.00;
    DECLARE @LiveMrp DECIMAL(18,2) = NULL;

    IF @VariantId IS NOT NULL
    BEGIN
        SELECT @LivePrice = v.Price, @LiveMrp = v.Mrp
        FROM   dbo.ProductVariants v
        WHERE  v.Id = @VariantId;
    END
    ELSE
    BEGIN
        SELECT @LivePrice = p.Price, @LiveMrp = p.Mrp
        FROM   dbo.Products p
        WHERE  p.Id = @ProductId;
    END

    IF @ExistingCartItemId IS NOT NULL
    BEGIN
        -- Increment quantity, capped at 10
        DECLARE @NewQty INT = @CurrentQuantity + @Quantity;
        IF @NewQty > 10 SET @NewQty = 10;

        UPDATE dbo.CartItems
        SET    Quantity = @NewQty,
               Price = @LivePrice,
               Mrp = @LiveMrp,
               UpdatedAt = SYSUTCDATETIME(),
               UpdatedBy = @CustomerId
        WHERE  Id = @ExistingCartItemId;
    END
    ELSE
    BEGIN
        IF @Quantity > 10 SET @Quantity = 10;

        INSERT INTO dbo.CartItems (
            CartId,
            ProductId,
            VariantId,
            Quantity,
            PriceWhenAdded,
            Price,
            Mrp,
            IsSavedForLater,
            Note,
            CreatedAt,
            CreatedBy,
            IsDeleted
        )
        VALUES (
            @CartId,
            @ProductId,
            @VariantId,
            @Quantity,
            @LivePrice,
            @LivePrice,
            @LiveMrp,
            0,
            @Note,
            SYSUTCDATETIME(),
            @CustomerId,
            0
        );
    END

    UPDATE dbo.Carts
    SET    LastActivityAt = SYSUTCDATETIME(),
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @CustomerId
    WHERE  Id = @CartId;

    -- Return updated cart
    EXEC dbo.usp_Cart_Get @CustomerId = @CustomerId, @GuestToken = @GuestToken, @FreeShippingThreshold = @FreeShippingThreshold;
END
GO

-- 4. Update Cart Item Quantity
CREATE OR ALTER PROCEDURE dbo.usp_Cart_UpdateQuantity
    @CartItemId            BIGINT,
    @Quantity              INT,
    @CustomerId            INT             = NULL,
    @GuestToken            VARCHAR(100)    = NULL,
    @FreeShippingThreshold DECIMAL(18,2)   = 999.00
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CartId INT = NULL;
    EXEC dbo.usp_Cart_GetOrCreate @CustomerId = @CustomerId, @GuestToken = @GuestToken, @CartId = @CartId OUTPUT;

    IF @Quantity <= 0
    BEGIN
        UPDATE dbo.CartItems
        SET    IsDeleted = 1,
               UpdatedAt = SYSUTCDATETIME(),
               UpdatedBy = @CustomerId
        WHERE  Id = @CartItemId AND CartId = @CartId;
    END
    ELSE
    BEGIN
        IF @Quantity > 10 SET @Quantity = 10;

        UPDATE dbo.CartItems
        SET    Quantity = @Quantity,
               UpdatedAt = SYSUTCDATETIME(),
               UpdatedBy = @CustomerId
        WHERE  Id = @CartItemId AND CartId = @CartId;
    END

    UPDATE dbo.Carts
    SET    LastActivityAt = SYSUTCDATETIME(),
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @CustomerId
    WHERE  Id = @CartId;

    EXEC dbo.usp_Cart_Get @CustomerId = @CustomerId, @GuestToken = @GuestToken, @FreeShippingThreshold = @FreeShippingThreshold;
END
GO

-- 5. Remove Item from Cart
CREATE OR ALTER PROCEDURE dbo.usp_Cart_RemoveItem
    @CartItemId            BIGINT,
    @CustomerId            INT             = NULL,
    @GuestToken            VARCHAR(100)    = NULL,
    @FreeShippingThreshold DECIMAL(18,2)   = 999.00
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CartId INT = NULL;
    EXEC dbo.usp_Cart_GetOrCreate @CustomerId = @CustomerId, @GuestToken = @GuestToken, @CartId = @CartId OUTPUT;

    UPDATE dbo.CartItems
    SET    IsDeleted = 1,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @CustomerId
    WHERE  Id = @CartItemId AND CartId = @CartId;

    UPDATE dbo.Carts
    SET    LastActivityAt = SYSUTCDATETIME(),
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @CustomerId
    WHERE  Id = @CartId;

    EXEC dbo.usp_Cart_Get @CustomerId = @CustomerId, @GuestToken = @GuestToken, @FreeShippingThreshold = @FreeShippingThreshold;
END
GO

-- 6. Apply Coupon
CREATE OR ALTER PROCEDURE dbo.usp_Cart_ApplyCoupon
    @CouponCode            VARCHAR(64),
    @CustomerId            INT             = NULL,
    @GuestToken            VARCHAR(100)    = NULL,
    @FreeShippingThreshold DECIMAL(18,2)   = 999.00
AS
BEGIN
    SET NOCOUNT ON;

    SET @CouponCode = LTRIM(RTRIM(@CouponCode));
    IF @CouponCode = ''
    BEGIN
        RAISERROR('Please enter a valid coupon code.', 16, 1);
        RETURN;
    END

    DECLARE @CartId INT = NULL;
    EXEC dbo.usp_Cart_GetOrCreate @CustomerId = @CustomerId, @GuestToken = @GuestToken, @CartId = @CartId OUTPUT;

    -- Calculate current subtotal
    DECLARE @Subtotal DECIMAL(18,2) = ISNULL((
        SELECT SUM(ci.Quantity * ISNULL(v.Price, p.Price))
        FROM   dbo.CartItems ci
        JOIN   dbo.Products p ON p.Id = ci.ProductId AND p.IsActive = 1 AND p.IsDeleted = 0
        LEFT JOIN dbo.ProductVariants v ON v.Id = ci.VariantId AND v.IsActive = 1 AND v.IsDeleted = 0
        WHERE  ci.CartId = @CartId AND ci.IsSavedForLater = 0 AND ci.IsDeleted = 0
    ), 0.00);

    IF @Subtotal <= 0
    BEGIN
        RAISERROR('Your cart is empty. Add handcrafted pieces before applying a coupon.', 16, 1);
        RETURN;
    END

    DECLARE @IsValid BIT = 0;
    DECLARE @CouponId INT = NULL;
    DECLARE @DiscountAmount DECIMAL(18,2) = 0.00;
    DECLARE @Message NVARCHAR(300) = NULL;

    EXEC dbo.usp_Coupon_Validate
        @Code           = @CouponCode,
        @CustomerId     = @CustomerId,
        @CartSubTotal   = @Subtotal,
        @IsFirstOrder   = 0,
        @ProductIds     = NULL,
        @IsValid        = @IsValid OUTPUT,
        @CouponId       = @CouponId OUTPUT,
        @DiscountAmount = @DiscountAmount OUTPUT,
        @Message        = @Message OUTPUT;

    IF @IsValid = 0
    BEGIN
        -- Clear coupon from cart
        UPDATE dbo.Carts
        SET    CouponId = NULL,
               CouponCode = NULL,
               LastActivityAt = SYSUTCDATETIME()
        WHERE  Id = @CartId;

        RAISERROR(@Message, 16, 1);
        RETURN;
    END

    -- Valid: attach coupon
    UPDATE dbo.Carts
    SET    CouponId = @CouponId,
           CouponCode = @CouponCode,
           LastActivityAt = SYSUTCDATETIME(),
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @CustomerId
    WHERE  Id = @CartId;

    -- Return updated cart
    EXEC dbo.usp_Cart_Get @CustomerId = @CustomerId, @GuestToken = @GuestToken, @FreeShippingThreshold = @FreeShippingThreshold;
END
GO

-- 7. Remove Coupon
CREATE OR ALTER PROCEDURE dbo.usp_Cart_RemoveCoupon
    @CustomerId            INT             = NULL,
    @GuestToken            VARCHAR(100)    = NULL,
    @FreeShippingThreshold DECIMAL(18,2)   = 999.00
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CartId INT = NULL;
    EXEC dbo.usp_Cart_GetOrCreate @CustomerId = @CustomerId, @GuestToken = @GuestToken, @CartId = @CartId OUTPUT;

    UPDATE dbo.Carts
    SET    CouponId = NULL,
           CouponCode = NULL,
           LastActivityAt = SYSUTCDATETIME(),
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @CustomerId
    WHERE  Id = @CartId;

    EXEC dbo.usp_Cart_Get @CustomerId = @CustomerId, @GuestToken = @GuestToken, @FreeShippingThreshold = @FreeShippingThreshold;
END
GO

-- 8. Merge Guest Cart Into Customer Cart on Sign-In
CREATE OR ALTER PROCEDURE dbo.usp_Cart_MergeGuestCart
    @CustomerId            INT,
    @GuestToken            VARCHAR(100),
    @FreeShippingThreshold DECIMAL(18,2)   = 999.00
AS
BEGIN
    SET NOCOUNT ON;

    IF @CustomerId IS NULL OR @GuestToken IS NULL OR @GuestToken = ''
    BEGIN
        EXEC dbo.usp_Cart_Get @CustomerId = @CustomerId, @GuestToken = @GuestToken, @FreeShippingThreshold = @FreeShippingThreshold;
        RETURN;
    END

    -- Find guest cart
    DECLARE @GuestCartId INT = NULL;
    SELECT TOP 1 @GuestCartId = Id
    FROM   dbo.Carts
    WHERE  GuestToken = @GuestToken
      AND  IsActive = 1
      AND  IsDeleted = 0
      AND  ConvertedOrderId IS NULL
      AND  MergedIntoCartId IS NULL
    ORDER BY Id DESC;

    -- If no guest cart or guest cart is empty, simply return customer's cart
    IF @GuestCartId IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.CartItems WHERE CartId = @GuestCartId AND IsDeleted = 0)
    BEGIN
        EXEC dbo.usp_Cart_Get @CustomerId = @CustomerId, @GuestToken = NULL, @FreeShippingThreshold = @FreeShippingThreshold;
        RETURN;
    END

    -- Get or create customer cart
    DECLARE @CustomerCartId INT = NULL;
    EXEC dbo.usp_Cart_GetOrCreate @CustomerId = @CustomerId, @GuestToken = NULL, @CartId = @CustomerCartId OUTPUT;

    -- Migrate guest items into customer cart
    -- 1. For items that already exist in customer cart, increment quantity (cap at 10)
    UPDATE cust_item
    SET    cust_item.Quantity = CASE WHEN (cust_item.Quantity + guest_item.Quantity) > 10 THEN 10 ELSE (cust_item.Quantity + guest_item.Quantity) END,
           cust_item.UpdatedAt = SYSUTCDATETIME(),
           cust_item.UpdatedBy = @CustomerId
    FROM   dbo.CartItems cust_item
    JOIN   dbo.CartItems guest_item ON guest_item.CartId = @GuestCartId 
                                   AND guest_item.ProductId = cust_item.ProductId
                                   AND (guest_item.VariantId = cust_item.VariantId OR (guest_item.VariantId IS NULL AND cust_item.VariantId IS NULL))
                                   AND guest_item.IsSavedForLater = cust_item.IsSavedForLater
                                   AND guest_item.IsDeleted = 0
    WHERE  cust_item.CartId = @CustomerCartId
      AND  cust_item.IsDeleted = 0;

    -- 2. For items that do NOT exist in customer cart, reassign CartId to CustomerCartId
    UPDATE guest_item
    SET    guest_item.CartId = @CustomerCartId,
           guest_item.UpdatedAt = SYSUTCDATETIME(),
           guest_item.UpdatedBy = @CustomerId
    FROM   dbo.CartItems guest_item
    WHERE  guest_item.CartId = @GuestCartId
      AND  guest_item.IsDeleted = 0
      AND  NOT EXISTS (
               SELECT 1 FROM dbo.CartItems c
               WHERE  c.CartId = @CustomerCartId
                 AND  c.ProductId = guest_item.ProductId
                 AND  (c.VariantId = guest_item.VariantId OR (c.VariantId IS NULL AND guest_item.VariantId IS NULL))
                 AND  c.IsSavedForLater = guest_item.IsSavedForLater
                 AND  c.IsDeleted = 0
           );

    -- 3. Mark guest cart as merged
    UPDATE dbo.Carts
    SET    MergedIntoCartId = @CustomerCartId,
           MergedAt = SYSUTCDATETIME(),
           IsActive = 0
    WHERE  Id = @GuestCartId;

    -- Return the customer cart
    EXEC dbo.usp_Cart_Get @CustomerId = @CustomerId, @GuestToken = NULL, @FreeShippingThreshold = @FreeShippingThreshold;
END
GO
