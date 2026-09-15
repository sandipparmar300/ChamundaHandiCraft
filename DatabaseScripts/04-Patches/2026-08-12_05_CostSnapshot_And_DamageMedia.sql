/* =============================================================================
   2026-08-12_05_CostSnapshot_And_DamageMedia.sql
   -----------------------------------------------------------------------------
   Two corrections.

   PART A - the cost-of-goods snapshot.

   This closes the approximation recorded in
   docs/Database/Database-Architecture.md §13.1.

   dbo.OrderItems already snapshots everything the CUSTOMER sees - name, SKU,
   image, selling price, MRP, discount, tax. It did not snapshot what the item
   COST us, so usp_Analytics_RebuildDailySummaries had to join dbo.Products for
   CostPrice when computing profit.

   That is wrong for the same reason every other snapshot exists
   (prompt §21, Dashboard.txt §18 "Profit = Revenue - Cost of Goods Sold"):
   when a supplier raises a price, re-running the rollup silently restates last
   year's profit. A margin figure that changes retrospectively is not a margin
   figure.

   PART B - damage evidence.

   Inventory.txt §9 lists "Images" as a field on a damage record, and §21
   requires damaged stock to be auditable. dbo.StockAdjustments (the vehicle for
   damage, via ReasonCodes.ReasonType = 'Damage') had nowhere to attach a photo,
   even though dbo.ReturnMedia sets exactly that precedent for returns. Without
   it there is no evidence for a supplier or courier claim.
   ============================================================================= */

SET NOCOUNT ON;
GO

/* =============================================================================
   PART A - OrderItems.UnitCostPrice
   ============================================================================= */

/* Nullable, because rows written before this patch genuinely have no captured
   cost and must not pretend to. Reporting treats NULL as "unknown", not zero -
   a zero would silently inflate margin to 100%. */
IF COL_LENGTH(N'dbo.OrderItems', N'UnitCostPrice') IS NULL
BEGIN
    ALTER TABLE dbo.OrderItems ADD UnitCostPrice DECIMAL(18,2) NULL;
END
GO

IF OBJECT_ID(N'CK_OrderItems_UnitCostPrice', N'C') IS NULL
BEGIN
    ALTER TABLE dbo.OrderItems ADD CONSTRAINT CK_OrderItems_UnitCostPrice
        CHECK (UnitCostPrice IS NULL OR UnitCostPrice >= 0);
END
GO

/* Backfill from the current product cost. This is explicitly a best-effort
   estimate for pre-existing rows, not a true snapshot - the honest position is
   that history before this patch cannot be reconstructed, and the backfill only
   stops the profit report reading zero for every historical day.

   Guarded so a re-run cannot overwrite a value the order path has since
   captured correctly. */
UPDATE oi
SET    oi.UnitCostPrice = p.CostPrice
FROM   dbo.OrderItems AS oi
JOIN   dbo.Products   AS p ON p.Id = oi.ProductId
WHERE  oi.UnitCostPrice IS NULL
  AND  p.CostPrice IS NOT NULL;
GO

/* Variant-level cost is more accurate where it exists; prefer it. */
UPDATE oi
SET    oi.UnitCostPrice = v.CostPrice
FROM   dbo.OrderItems     AS oi
JOIN   dbo.ProductVariants AS v ON v.Id = oi.VariantId
WHERE  oi.VariantId IS NOT NULL
  AND  v.CostPrice IS NOT NULL;
GO

/* -----------------------------------------------------------------------------
   The consuming procedure, dbo.usp_Analytics_RebuildDailySummaries, is updated
   in place (02-StoredProcedures/Reports/) to read oi.UnitCostPrice instead of
   joining dbo.Products for the rate.

   Deliberately NOT a second procedure here. COGS is a business rule, and
   Database-Architecture.md §8 is explicit that a rule with two definitions
   eventually has two answers. There is one COGS expression in the system and it
   lives in the rollup that owns the figure.
   ----------------------------------------------------------------------------- */
GO

/* =============================================================================
   PART B - StockAdjustmentMedia
   ============================================================================= */

IF OBJECT_ID(N'dbo.StockAdjustmentMedia', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.StockAdjustmentMedia
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        StockAdjustmentId   INT             NOT NULL,
        MediaAssetId        INT             NULL,
        Url                 NVARCHAR(1000)  NOT NULL,
        ThumbnailUrl        NVARCHAR(1000)  NULL,
        /* 0 Image, 1 Video */
        MediaType           TINYINT         NOT NULL CONSTRAINT DF_StockAdjustmentMedia_MediaType DEFAULT (0),
        Caption             NVARCHAR(300)   NULL,
        SortOrder           INT             NOT NULL CONSTRAINT DF_StockAdjustmentMedia_SortOrder DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_StockAdjustmentMedia_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_StockAdjustmentMedia_IsDeleted DEFAULT (0),

        CONSTRAINT PK_StockAdjustmentMedia PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_StockAdjustmentMedia_Adjustments
            FOREIGN KEY (StockAdjustmentId) REFERENCES dbo.StockAdjustments (Id),
        CONSTRAINT FK_StockAdjustmentMedia_Assets
            FOREIGN KEY (MediaAssetId) REFERENCES dbo.MediaAssets (Id)
    );

    CREATE INDEX IX_StockAdjustmentMedia_Adjustment
        ON dbo.StockAdjustmentMedia (StockAdjustmentId, SortOrder)
        WHERE IsDeleted = 0;
END
GO

/* Inventory.txt §9 "Actions: Dispose | Repair | Return to Supplier" - what was
   decided about the damaged units. Null for non-damage adjustments. */
IF COL_LENGTH(N'dbo.StockAdjustments', N'DamageAction') IS NULL
BEGIN
    ALTER TABLE dbo.StockAdjustments ADD DamageAction VARCHAR(24) NULL;
    ALTER TABLE dbo.StockAdjustments ADD CONSTRAINT CK_StockAdjustments_DamageAction
        CHECK (DamageAction IS NULL OR DamageAction IN ('Dispose','Repair','ReturnToSupplier','WriteOff'));
END
GO
