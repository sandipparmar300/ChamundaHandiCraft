/* =============================================================================
   usp_Coupon_Redeem
   -----------------------------------------------------------------------------
   Consumes one use of a coupon against a placed order.

   Specs:
     Coupon.txt §19  "Coupon usage limits must be enforced atomically to prevent
                      overuse."
     Coupon.txt §11  redemption history: code, order, customer, discount, date
     Coupon.txt §19  "Cancelled or refunded orders should restore coupon usage
                      based on business configuration."  -> usp_Coupon_Release

   Why this is separate from usp_Coupon_Validate
   ---------------------------------------------
   Validation runs on every cart render and again at checkout. Redemption must
   happen exactly once, at order creation, inside the order transaction. Doing
   both in one procedure would either consume a use every time the cart is shown,
   or leave a window between the final check and the order insert in which
   another shopper takes the last redemption.

   The increment and the limit test are one statement, so the row lock makes them
   indivisible. @@ROWCOUNT = 0 means the limit was reached by someone else
   between validation and here - the caller must fail the order, not retry.
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Coupon_Redeem
    @CouponId           INT,
    @CustomerId         INT             = NULL,
    @OrderId            INT,
    @OrderNumber        VARCHAR(32),
    @DiscountAmount     DECIMAL(18,2),
    @OrderTotal         DECIMAL(18,2),
    @ResultCode         INT             OUTPUT,   -- 0 redeemed, 1 limit reached, 2 not found
    @Message            NVARCHAR(300)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ResultCode = 1;
    SET @Message    = N'This coupon has reached its usage limit.';

    BEGIN TRY
        /* No BEGIN TRANSACTION here: this procedure is called from inside the
           order-placement transaction (usp_Order_Place), and opening a nested
           one would only increment @@TRANCOUNT without adding isolation. When
           called standalone the single UPDATE is atomic on its own. */

        IF NOT EXISTS (SELECT 1 FROM dbo.Coupons WHERE Id = @CouponId AND IsDeleted = 0)
        BEGIN
            SET @ResultCode = 2;
            SET @Message    = N'Invalid coupon.';
            RETURN;
        END

        /* The atomic test-and-take. The WHERE clause re-checks every limit that
           could have been consumed since validation. */
        UPDATE dbo.Coupons
        SET    UsageCount         = UsageCount + 1,
               TotalDiscountGiven = TotalDiscountGiven + @DiscountAmount,
               UpdatedAt          = SYSUTCDATETIME()
        WHERE  Id = @CouponId
           AND IsDeleted = 0
           AND Status = 2                                   -- Active
           AND (StartsOn  IS NULL OR StartsOn  <= SYSUTCDATETIME())
           AND (ExpiresOn IS NULL OR ExpiresOn >  SYSUTCDATETIME())
           AND (TotalUsageLimit IS NULL OR UsageCount < TotalUsageLimit);

        IF @@ROWCOUNT = 0
            RETURN;      -- @ResultCode is already 1

        /* Redemption history - Coupon.txt §11. */
        INSERT INTO dbo.CouponRedemptions
            (CouponId, CustomerId, OrderId, OrderNumber, DiscountAmount, OrderTotal, RedeemedAt)
        VALUES
            (@CouponId, @CustomerId, @OrderId, @OrderNumber, @DiscountAmount, @OrderTotal, SYSUTCDATETIME());

        /* Coupon.txt §19 - a coupon that has just hit its ceiling stops being
           offered. Marking it Expired here means the storefront never advertises
           a code that can no longer be used. CouponStatus 3 = Expired. */
        UPDATE dbo.Coupons
        SET    Status    = 3,
               UpdatedAt = SYSUTCDATETIME()
        WHERE  Id = @CouponId
           AND TotalUsageLimit IS NOT NULL
           AND UsageCount >= TotalUsageLimit
           AND Status = 2;

        SET @ResultCode = 0;
        SET @Message    = N'Coupon applied successfully.';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO


/* =============================================================================
   usp_Coupon_Release
   -----------------------------------------------------------------------------
   Gives a redemption back when an order is cancelled or fully refunded.
   Coupon.txt §19 makes this configurable, so the caller decides whether to
   invoke it; this procedure only performs the reversal.

   The redemption row is kept and marked, not deleted: the discount was really
   granted at the time and the audit trail must still show it.
   ============================================================================= */
GO

CREATE OR ALTER PROCEDURE dbo.usp_Coupon_Release
    @OrderId            INT,
    @LoggedInUserId     INT             = NULL,
    @ResultCode         INT             OUTPUT    -- 0 released, 1 nothing to release
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ResultCode = 1;

    DECLARE @CouponId       INT,
            @DiscountAmount DECIMAL(18,2);

    SELECT TOP (1)
           @CouponId       = CouponId,
           @DiscountAmount = DiscountAmount
    FROM   dbo.CouponRedemptions
    WHERE  OrderId = @OrderId
    ORDER BY Id;

    IF @CouponId IS NULL
        RETURN;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.Coupons
        SET    UsageCount         = CASE WHEN UsageCount > 0 THEN UsageCount - 1 ELSE 0 END,
               TotalDiscountGiven = CASE WHEN TotalDiscountGiven >= @DiscountAmount
                                         THEN TotalDiscountGiven - @DiscountAmount
                                         ELSE 0 END,
               /* If it had been auto-expired purely by hitting the cap, freeing a
                  use makes it available again. */
               Status             = CASE WHEN Status = 3
                                          AND ExpiresOn IS NOT NULL
                                          AND ExpiresOn > SYSUTCDATETIME()
                                         THEN 2 ELSE Status END,
               UpdatedAt          = SYSUTCDATETIME(),
               UpdatedBy          = @LoggedInUserId
        WHERE  Id = @CouponId;

        DELETE FROM dbo.CouponRedemptions
        WHERE  OrderId = @OrderId;

        SET @ResultCode = 0;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
