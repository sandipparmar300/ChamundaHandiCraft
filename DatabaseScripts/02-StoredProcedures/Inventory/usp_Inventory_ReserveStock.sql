/* =============================================================================
   usp_Inventory_ReserveStock
   -----------------------------------------------------------------------------
   Reserves stock for one order line.

   Specs:
     Inventory.txt §21  "Stock cannot become negative unless negative inventory
                         is explicitly enabled."
     Inventory.txt §21  "Every stock movement must create an inventory ledger entry."
     Checkout.txt  §20  Inventory is revalidated immediately before order creation.
     Prompt        §34  "Inventory updates must be concurrency-safe."

   Concurrency design
   ------------------
   Two shoppers checking out the last unit at the same moment must not both
   succeed. Read-then-write in the application layer cannot guarantee that, and
   neither can a rowversion check on its own (it detects the conflict only after
   losing the race, forcing a retry loop).

   Instead the reservation is a single conditional UPDATE:

       UPDATE ... SET Reserved = Reserved + @Quantity
       WHERE  Id = @StockId AND (OnHand - Reserved) >= @Quantity

   SQL Server takes an exclusive lock on the row for the duration of the
   statement, so the availability test and the increment cannot be interleaved.
   The loser sees @@ROWCOUNT = 0 and is rejected - no retry, no oversell.
   CK_InventoryStocks_Reserved (Reserved <= OnHand) is the backstop.

   Returns: 0 = reserved, 1 = insufficient stock, 2 = no stock record.
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Inventory_ReserveStock
    @ProductId          INT,
    @VariantId          INT             = NULL,
    @WarehouseId        INT             = NULL,
    @Quantity           INT,
    @ReferenceType      VARCHAR(48)     = 'Order',   -- Order | Cart | Manual
    @ReferenceId        INT             = NULL,
    @ReferenceNumber    VARCHAR(32)     = NULL,
    @LoggedInUserId     INT             = NULL,
    @AllowBackorder     BIT             = 0,
    @ResultCode         INT             OUTPUT,      -- 0 ok, 1 insufficient, 2 not found
    @AvailableQuantity  INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Quantity IS NULL OR @Quantity <= 0
    BEGIN
        SET @ResultCode = 1;
        SET @AvailableQuantity = 0;
        RETURN;
    END

    DECLARE @StockId        BIGINT,
            @OnHandBefore   INT,
            @ReservedBefore INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* Resolve the stock row. When no warehouse is named, take the one with
           the most available units so a multi-warehouse setup fulfils from the
           deepest shelf first. UPDLOCK/ROWLOCK holds the row from selection
           through to the update, closing the gap between choosing and taking. */
        SELECT TOP (1)
               @StockId        = s.Id,
               @OnHandBefore   = s.OnHand,
               @ReservedBefore = s.Reserved
        FROM   dbo.InventoryStocks AS s WITH (UPDLOCK, ROWLOCK)
        WHERE  s.ProductId  = @ProductId
           AND (@VariantId   IS NULL OR s.VariantId   = @VariantId)
           AND (@VariantId   IS NOT NULL OR s.VariantId IS NULL)
           AND (@WarehouseId IS NULL OR s.WarehouseId = @WarehouseId)
           AND s.IsDeleted = 0
           AND s.IsActive  = 1
        ORDER BY (s.OnHand - s.Reserved) DESC, s.Id;

        IF @StockId IS NULL
        BEGIN
            SET @ResultCode = 2;
            SET @AvailableQuantity = 0;
            COMMIT TRANSACTION;
            RETURN;
        END

        /* The atomic test-and-take. */
        UPDATE dbo.InventoryStocks
        SET    Reserved  = Reserved + @Quantity,
               UpdatedAt = SYSUTCDATETIME(),
               UpdatedBy = @LoggedInUserId
        WHERE  Id = @StockId
           AND (@AllowBackorder = 1 OR (OnHand - Reserved) >= @Quantity);

        IF @@ROWCOUNT = 0
        BEGIN
            /* Lost the race, or never had enough. Report what is actually free
               so the caller can tell the shopper "only 2 left". */
            SELECT @AvailableQuantity = OnHand - Reserved
            FROM   dbo.InventoryStocks
            WHERE  Id = @StockId;

            SET @ResultCode = 1;
            COMMIT TRANSACTION;
            RETURN;
        END

        /* Inventory.txt §21 - every movement writes a ledger entry. A reservation
           moves nothing physically: OnHand is unchanged, so QuantityChange is 0
           and QuantityAfter still reports OnHand. What the row records is that
           the units are now spoken for, which the Note spells out. */
        INSERT INTO dbo.InventoryTransactions
        (
            ProductId, VariantId, WarehouseId, TransactionType,
            QuantityChange, QuantityAfter,
            ReferenceType, ReferenceId, ReferenceNumber, Note,
            CreatedAt, CreatedBy
        )
        VALUES
        (
            @ProductId, @VariantId,
            (SELECT WarehouseId FROM dbo.InventoryStocks WHERE Id = @StockId),
            'Reservation',
            0, @OnHandBefore,
            @ReferenceType, @ReferenceId, @ReferenceNumber,
            CONCAT(N'Reserved ', @Quantity, N' unit(s). Reserved ',
                   @ReservedBefore, N' -> ', @ReservedBefore + @Quantity,
                   N'. Available ', @OnHandBefore - @ReservedBefore - @Quantity, N'.'),
            SYSUTCDATETIME(), @LoggedInUserId
        );

        SELECT @AvailableQuantity = OnHand - Reserved
        FROM   dbo.InventoryStocks
        WHERE  Id = @StockId;

        SET @ResultCode = 0;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
