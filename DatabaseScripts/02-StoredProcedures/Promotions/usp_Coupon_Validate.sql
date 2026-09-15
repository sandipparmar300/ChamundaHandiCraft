/* =============================================================================
   usp_Coupon_Validate
   -----------------------------------------------------------------------------
   Runs the full eligibility gate for a coupon code without consuming it.

   Specs:
     Coupon.txt §10  the ordered validation rule list and the exact messages
     Coupon.txt §19  codes are case-insensitive; limits are enforced per customer
     Cart.txt   §4   applied on the cart page
     Checkout.txt §20 "Coupons must be revalidated immediately before payment."

   This procedure is deliberately read-only. Redemption is a separate, atomic
   step (usp_Coupon_Redeem) because validation happens many times per cart while
   redemption must happen exactly once per order.

   Returns @IsValid plus a message drawn from the wording in Coupon.txt §10, and
   the discount the caller should apply.
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Coupon_Validate
    @Code               VARCHAR(64),
    @CustomerId         INT             = NULL,
    @CartSubTotal       DECIMAL(18,2),
    @IsFirstOrder       BIT             = 0,
    @ProductIds         NVARCHAR(MAX)   = NULL,   -- comma-separated, for product/category scoping
    @IsValid            BIT             OUTPUT,
    @CouponId           INT             OUTPUT,
    @DiscountAmount     DECIMAL(18,2)   OUTPUT,
    @Message            NVARCHAR(300)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @IsValid        = 0;
    SET @CouponId       = NULL;
    SET @DiscountAmount = 0;
    SET @Message        = N'Invalid coupon.';

    DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();

    DECLARE @DiscountType     TINYINT,
            @DiscountValue    DECIMAL(18,2),
            @MaxDiscount      DECIMAL(18,2),
            @MinimumOrderValue DECIMAL(18,2),
            @StartsOn         DATETIME2(3),
            @ExpiresOn        DATETIME2(3),
            @TotalUsageLimit  INT,
            @PerCustomerLimit INT,
            @UsageCount       INT,
            @FirstOrderOnly   BIT,
            @Status           TINYINT,
            @IsPublic         BIT;

    /* Coupon.txt §19: "Coupon codes are case-insensitive during validation."
       The column collation is case-insensitive, so a straight equality match is
       correct; LTRIM/RTRIM guards against a pasted code with stray spaces. */
    SELECT  @CouponId          = Id,
            @DiscountType      = DiscountType,
            @DiscountValue     = DiscountValue,
            @MaxDiscount       = MaxDiscount,
            @MinimumOrderValue = MinimumOrderValue,
            @StartsOn          = StartsOn,
            @ExpiresOn         = ExpiresOn,
            @TotalUsageLimit   = TotalUsageLimit,
            @PerCustomerLimit  = PerCustomerLimit,
            @UsageCount        = UsageCount,
            @FirstOrderOnly    = FirstOrderOnly,
            @Status            = Status,
            @IsPublic          = IsPublic
    FROM    dbo.Coupons
    WHERE   Code = LTRIM(RTRIM(@Code))
      AND   IsDeleted = 0;

    -- 1. Exists
    IF @CouponId IS NULL
    BEGIN
        SET @Message = N'Invalid coupon.';
        RETURN;
    END

    -- 2. Active. CouponStatus: 0 Draft, 1 Scheduled, 2 Active, 3 Expired, 4 Disabled, 5 Archived
    IF @Status <> 2
    BEGIN
        SET @Message = CASE WHEN @Status = 3 THEN N'This coupon has expired.'
                            ELSE N'This coupon is not currently available.' END;
        RETURN;
    END

    -- 3. Within its window
    IF @StartsOn IS NOT NULL AND @Now < @StartsOn
    BEGIN
        SET @Message = N'This coupon is not active yet.';
        RETURN;
    END

    IF @ExpiresOn IS NOT NULL AND @Now >= @ExpiresOn
    BEGIN
        SET @Message = N'This coupon has expired.';
        RETURN;
    END

    -- 4. Overall usage limit
    IF @TotalUsageLimit IS NOT NULL AND @UsageCount >= @TotalUsageLimit
    BEGIN
        SET @Message = N'This coupon has reached its usage limit.';
        RETURN;
    END

    -- 5. Per-customer limit
    IF @CustomerId IS NOT NULL AND @PerCustomerLimit IS NOT NULL
    BEGIN
        DECLARE @CustomerUses INT;

        SELECT @CustomerUses = COUNT(*)
        FROM   dbo.CouponRedemptions
        WHERE  CouponId = @CouponId
          AND  CustomerId = @CustomerId;

        IF @CustomerUses >= @PerCustomerLimit
        BEGIN
            SET @Message = N'You have already used this coupon.';
            RETURN;
        END
    END

    -- 6. First-order-only coupons
    IF @FirstOrderOnly = 1 AND @IsFirstOrder = 0
    BEGIN
        SET @Message = N'This coupon is valid on your first order only.';
        RETURN;
    END

    -- 7. Private coupons require an identified, explicitly targeted customer
    IF @IsPublic = 0
    BEGIN
        IF @CustomerId IS NULL
        BEGIN
            SET @Message = N'Please sign in to use this coupon.';
            RETURN;
        END

        IF NOT EXISTS (
            SELECT 1
            FROM   dbo.CouponSegments AS cs
            JOIN   dbo.CustomerSegmentMembers AS m ON m.SegmentId = cs.SegmentId
            WHERE  cs.CouponId = @CouponId
              AND  m.CustomerId = @CustomerId)
        BEGIN
            SET @Message = N'This coupon is not applicable to your account.';
            RETURN;
        END
    END

    -- 8. Minimum order value
    IF @MinimumOrderValue IS NOT NULL AND @CartSubTotal < @MinimumOrderValue
    BEGIN
        SET @Message = CONCAT(N'Add ',
                              FORMAT(@MinimumOrderValue - @CartSubTotal, N'N2'),
                              N' more to use this coupon.');
        RETURN;
    END

    /* 9. Product / category scoping. A coupon with no CouponProducts and no
          CouponCategories rows applies to the whole catalogue; one with either
          applies only when the cart contains a qualifying line. */
    IF EXISTS (SELECT 1 FROM dbo.CouponProducts   WHERE CouponId = @CouponId)
    OR EXISTS (SELECT 1 FROM dbo.CouponCategories WHERE CouponId = @CouponId)
    BEGIN
        IF @ProductIds IS NULL OR LTRIM(RTRIM(@ProductIds)) = N''
        BEGIN
            SET @Message = N'This coupon does not apply to the items in your cart.';
            RETURN;
        END

        DECLARE @Cart TABLE (ProductId INT PRIMARY KEY);

        INSERT INTO @Cart (ProductId)
        SELECT DISTINCT TRY_CAST(value AS INT)
        FROM   STRING_SPLIT(@ProductIds, ',')
        WHERE  TRY_CAST(value AS INT) IS NOT NULL;

        IF NOT EXISTS (
            SELECT 1
            FROM   @Cart AS c
            WHERE  EXISTS (SELECT 1 FROM dbo.CouponProducts AS cp
                           WHERE cp.CouponId = @CouponId AND cp.ProductId = c.ProductId)
               OR  EXISTS (SELECT 1
                           FROM   dbo.CouponCategories AS cc
                           JOIN   dbo.ProductCategories AS pc ON pc.CategoryId = cc.CategoryId
                           WHERE  cc.CouponId = @CouponId AND pc.ProductId = c.ProductId))
        BEGIN
            SET @Message = N'This coupon does not apply to the items in your cart.';
            RETURN;
        END
    END

    /* ---------------------------------------------------------------------
       All gates passed. Compute the discount.
       DiscountType: 0 Percentage, 1 FixedAmount, 2 FreeShipping, 3 BuyXGetY
       Coupon.txt §19: "Discount cannot exceed the configured maximum discount."
       --------------------------------------------------------------------- */
    IF @DiscountType = 0
    BEGIN
        SET @DiscountAmount = ROUND(@CartSubTotal * (@DiscountValue / 100.0), 2);
        IF @MaxDiscount IS NOT NULL AND @DiscountAmount > @MaxDiscount
            SET @DiscountAmount = @MaxDiscount;
    END
    ELSE IF @DiscountType = 1
    BEGIN
        SET @DiscountAmount = @DiscountValue;
    END
    ELSE
    BEGIN
        /* Free shipping and BuyXGetY are priced by the cart engine, which knows
           the shipping quote and the line quantities. Nothing to apply here. */
        SET @DiscountAmount = 0;
    END

    /* A discount can never exceed the goods it is discounting. */
    IF @DiscountAmount > @CartSubTotal
        SET @DiscountAmount = @CartSubTotal;

    IF @DiscountAmount < 0
        SET @DiscountAmount = 0;

    SET @IsValid = 1;
    SET @Message = N'Coupon applied successfully.';
END
GO
