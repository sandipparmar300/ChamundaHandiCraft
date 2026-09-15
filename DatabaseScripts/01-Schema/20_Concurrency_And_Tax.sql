/* =============================================================================
   20_Concurrency_And_Tax.sql — optimistic concurrency + line-level GST breakup
   -----------------------------------------------------------------------------
   Two cross-cutting concerns that belong to no single module, applied last so
   every table they touch already exists.

   Part A — optimistic concurrency (rowversion) on the contended aggregates.
   Part B — per-line GST components, so tax reports and GST filing can be
            produced from frozen historical data.

   This file is additive and idempotent: it only creates what is missing, and it
   never edits or drops anything created by 01-19. Files 01-14 are therefore
   untouched, honouring the "never edit an applied schema script" rule in
   DatabaseScripts/README.md.
   ============================================================================= */

SET NOCOUNT ON;
GO

/* =============================================================================
   PART A — Optimistic concurrency
   -----------------------------------------------------------------------------
   Every table below can be written by two actors at the same moment:

     Products          two merchandisers editing the same product; a price edit
                       racing a publish.
     ProductVariants   variant price and stock edited from two screens.
     InventoryStocks   THE critical one. Inventory.txt §21: "Stock cannot become
                       negative" and Checkout.txt §20: inventory is revalidated
                       immediately before order creation. Two concurrent
                       checkouts reserving the last unit must not both succeed.
     Orders            an agent editing an order while a courier webhook moves
                       its status.
     Coupons           Coupon.txt §19: "Coupon usage limits must be enforced
                       atomically to prevent overuse."
     Offers            Offer.txt §21: usage limits and flash-sale stock allocation.
     Customers         profile edited by the shopper and the support agent at once.
     Carts             the same cart open in two tabs.

   rowversion is chosen over an INT Version column because SQL Server maintains
   it automatically on every UPDATE — no application code can forget to bump it.
   Repositories add "AND [RowVersion] = @RowVersion" to their UPDATE and treat
   zero affected rows as a concurrency conflict.

   rowversion columns are always NOT NULL and are populated by the engine, so
   adding one to a table that already holds rows is safe.
   ============================================================================= */

IF COL_LENGTH(N'dbo.Products', N'RowVersion') IS NULL
    ALTER TABLE dbo.Products ADD [RowVersion] rowversion NOT NULL;
GO

IF COL_LENGTH(N'dbo.ProductVariants', N'RowVersion') IS NULL
    ALTER TABLE dbo.ProductVariants ADD [RowVersion] rowversion NOT NULL;
GO

IF COL_LENGTH(N'dbo.InventoryStocks', N'RowVersion') IS NULL
    ALTER TABLE dbo.InventoryStocks ADD [RowVersion] rowversion NOT NULL;
GO

IF COL_LENGTH(N'dbo.Orders', N'RowVersion') IS NULL
    ALTER TABLE dbo.Orders ADD [RowVersion] rowversion NOT NULL;
GO

IF COL_LENGTH(N'dbo.Coupons', N'RowVersion') IS NULL
    ALTER TABLE dbo.Coupons ADD [RowVersion] rowversion NOT NULL;
GO

IF COL_LENGTH(N'dbo.Offers', N'RowVersion') IS NULL
    ALTER TABLE dbo.Offers ADD [RowVersion] rowversion NOT NULL;
GO

IF COL_LENGTH(N'dbo.Customers', N'RowVersion') IS NULL
    ALTER TABLE dbo.Customers ADD [RowVersion] rowversion NOT NULL;
GO

IF COL_LENGTH(N'dbo.Carts', N'RowVersion') IS NULL
    ALTER TABLE dbo.Carts ADD [RowVersion] rowversion NOT NULL;
GO

/* -----------------------------------------------------------------------------
   Coupon redemption counter.

   Coupon.txt §19 requires usage limits to be "enforced atomically". A rowversion
   check alone turns an over-redemption into a retry storm under load; the
   reliable pattern is a conditional UPDATE that both increments and tests in one
   statement:

       UPDATE dbo.Coupons
          SET UsageCount = UsageCount + 1
        WHERE Id = @Id
          AND (TotalUsageLimit IS NULL OR UsageCount < TotalUsageLimit);
       -- @@ROWCOUNT = 0  =>  limit already reached, reject the coupon

   The CHECK constraint below is the last line of defence: even a buggy write
   path cannot push the counter past the limit.
   ----------------------------------------------------------------------------- */
IF OBJECT_ID(N'CK_Coupons_WithinUsageLimit', N'C') IS NULL
BEGIN
    /* WITH CHECK (the default) so the optimiser can trust it. Any existing row
       that already violates the rule is a data bug and should fail the deploy. */
    ALTER TABLE dbo.Coupons
        ADD CONSTRAINT CK_Coupons_WithinUsageLimit
            CHECK (TotalUsageLimit IS NULL OR UsageCount <= TotalUsageLimit);
END
GO

/* =============================================================================
   PART B — Line-level GST
   -----------------------------------------------------------------------------
   What already exists:
     dbo.OrderItems  TaxPercent, TaxAmount, HsnCode   (the total, and the code)
     dbo.Invoices    Cgst, Sgst, Igst, Cess           (invoice header totals)

   What is missing, and why it matters:
     Reports.txt §9 requires CGST, SGST and IGST reported separately, plus
     "Tax by State" and "Tax by Product", and exports a GST Filing Report.
     Indian GSTR-1 filing is HSN-summary based: per HSN code, the taxable value
     and each component split out. A single blended TaxAmount on the line cannot
     produce that, and the invoice header cannot attribute tax back to a product.

   Snapshot rule (prompt §21, Orders.txt §23): every column here is frozen at
   order time. Nothing in a tax report ever joins back to dbo.TaxClasses or
   dbo.Products for a rate — a later GST change must not rewrite last year's
   filings.

   Why rows rather than six more columns on OrderItems: an intra-state sale
   carries CGST + SGST, an inter-state sale carries IGST, and cess applies to
   neither most of the time. Columns would leave two thirds of them zero on every
   line and would need another migration the day a new component appears.
   ============================================================================= */

IF OBJECT_ID(N'dbo.OrderItemTaxes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderItemTaxes
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        OrderItemId         BIGINT          NOT NULL,
        OrderId             INT             NOT NULL,      -- denormalised: every tax report filters by order first

        /* CGST | SGST | UTGST | IGST | CESS */
        TaxComponent        VARCHAR(16)     NOT NULL,
        /* Rate as a percentage at the time of sale, e.g. 6.0000 for CGST @ 6%. */
        TaxRate             DECIMAL(18,4)   NOT NULL CONSTRAINT DF_OrderItemTaxes_TaxRate DEFAULT (0),
        /* The value the rate was applied to, after line discount. */
        TaxableAmount       DECIMAL(18,2)   NOT NULL CONSTRAINT DF_OrderItemTaxes_TaxableAmount DEFAULT (0),
        TaxAmount           DECIMAL(18,2)   NOT NULL CONSTRAINT DF_OrderItemTaxes_TaxAmount DEFAULT (0),

        /* Snapshots. Frozen so a later master-data edit cannot alter a filed
           return. HsnCode is duplicated from OrderItems so the HSN summary is a
           single-table GROUP BY. */
        HsnCode             VARCHAR(16)     NULL,
        TaxClassName        NVARCHAR(200)   NULL,
        /* "24-Gujarat" — matches dbo.Invoices.PlaceOfSupply, and is what
           "Tax by State" groups on. */
        PlaceOfSupply       NVARCHAR(100)   NULL,
        IsInterState        BIT             NOT NULL CONSTRAINT DF_OrderItemTaxes_IsInterState DEFAULT (0),
        IsTaxInclusive      BIT             NOT NULL CONSTRAINT DF_OrderItemTaxes_IsTaxInclusive DEFAULT (1),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_OrderItemTaxes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,

        CONSTRAINT PK_OrderItemTaxes PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_OrderItemTaxes_OrderItems FOREIGN KEY (OrderItemId) REFERENCES dbo.OrderItems (Id),
        CONSTRAINT FK_OrderItemTaxes_Orders     FOREIGN KEY (OrderId)     REFERENCES dbo.Orders (Id),
        /* One row per component per line — a re-run of tax calculation replaces,
           never duplicates. */
        CONSTRAINT UQ_OrderItemTaxes_Component UNIQUE (OrderItemId, TaxComponent),
        CONSTRAINT CK_OrderItemTaxes_Component
            CHECK (TaxComponent IN ('CGST','SGST','UTGST','IGST','CESS')),
        CONSTRAINT CK_OrderItemTaxes_NonNegative
            CHECK (TaxRate >= 0 AND TaxableAmount >= 0 AND TaxAmount >= 0),
        /* GST law: an inter-state supply attracts IGST, never CGST/SGST, and
           vice versa. Catching this in the database stops a mis-computed order
           reaching a filed return. */
        CONSTRAINT CK_OrderItemTaxes_ComponentMatchesSupply
            CHECK (
                (IsInterState = 1 AND TaxComponent IN ('IGST','CESS'))
                OR
                (IsInterState = 0 AND TaxComponent IN ('CGST','SGST','UTGST','CESS'))
            )
    );

    /* Invoice-level tax breakdown, and the per-order recomputation. */
    CREATE INDEX IX_OrderItemTaxes_Order ON dbo.OrderItemTaxes (OrderId)
        INCLUDE (TaxComponent, TaxableAmount, TaxAmount);

    /* GSTR-1 HSN summary: GROUP BY HsnCode, TaxComponent over a date range. */
    CREATE INDEX IX_OrderItemTaxes_Hsn ON dbo.OrderItemTaxes (HsnCode, TaxComponent)
        INCLUDE (TaxableAmount, TaxAmount);

    /* Reports.txt §9 "Tax by State". */
    CREATE INDEX IX_OrderItemTaxes_PlaceOfSupply ON dbo.OrderItemTaxes (PlaceOfSupply, TaxComponent)
        INCLUDE (TaxableAmount, TaxAmount);
END
GO

/* -----------------------------------------------------------------------------
   Refund tax reversal. Orders.txt §12 and Payments.txt §8 allow partial refunds;
   a credit note must reverse the same components in the same proportions, or the
   GST return will not reconcile. Mirrors OrderItemTaxes on the way out.
   ----------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.RefundTaxes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RefundTaxes
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        RefundId            INT             NOT NULL,
        OrderItemId         BIGINT          NULL,          -- null for an order-level refund
        TaxComponent        VARCHAR(16)     NOT NULL,
        TaxRate             DECIMAL(18,4)   NOT NULL CONSTRAINT DF_RefundTaxes_TaxRate DEFAULT (0),
        TaxableAmount       DECIMAL(18,2)   NOT NULL CONSTRAINT DF_RefundTaxes_TaxableAmount DEFAULT (0),
        TaxAmount           DECIMAL(18,2)   NOT NULL CONSTRAINT DF_RefundTaxes_TaxAmount DEFAULT (0),
        HsnCode             VARCHAR(16)     NULL,
        PlaceOfSupply       NVARCHAR(100)   NULL,
        IsInterState        BIT             NOT NULL CONSTRAINT DF_RefundTaxes_IsInterState DEFAULT (0),
        /* The credit note this reversal appears on. */
        CreditNoteInvoiceId INT             NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_RefundTaxes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,

        CONSTRAINT PK_RefundTaxes PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_RefundTaxes_Refunds    FOREIGN KEY (RefundId)            REFERENCES dbo.Refunds (Id),
        CONSTRAINT FK_RefundTaxes_OrderItems FOREIGN KEY (OrderItemId)         REFERENCES dbo.OrderItems (Id),
        CONSTRAINT FK_RefundTaxes_Invoices   FOREIGN KEY (CreditNoteInvoiceId) REFERENCES dbo.Invoices (Id),
        CONSTRAINT CK_RefundTaxes_Component
            CHECK (TaxComponent IN ('CGST','SGST','UTGST','IGST','CESS')),
        CONSTRAINT CK_RefundTaxes_NonNegative
            CHECK (TaxRate >= 0 AND TaxableAmount >= 0 AND TaxAmount >= 0)
    );

    CREATE INDEX IX_RefundTaxes_Refund ON dbo.RefundTaxes (RefundId);
    CREATE INDEX IX_RefundTaxes_Hsn ON dbo.RefundTaxes (HsnCode, TaxComponent) INCLUDE (TaxableAmount, TaxAmount);
END
GO

/* -----------------------------------------------------------------------------
   Tax rate history. dbo.TaxClasses holds the CURRENT rate for a class. When GST
   on handicrafts moves from 12% to 5%, the current row changes and the old rate
   is lost — but an audit two years later must be able to prove which rate was
   lawful on the order date.

   OrderItemTaxes already freezes what was charged; this table records what the
   configured rate WAS, which is what a tax audit compares against.
   ----------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.TaxRateHistories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TaxRateHistories
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        TaxClassId          INT             NOT NULL,
        TaxClassName        NVARCHAR(200)   NOT NULL,
        HsnCode             VARCHAR(16)     NULL,
        TotalRate           DECIMAL(18,4)   NOT NULL,
        CgstRate            DECIMAL(18,4)   NOT NULL CONSTRAINT DF_TaxRateHistories_CgstRate DEFAULT (0),
        SgstRate            DECIMAL(18,4)   NOT NULL CONSTRAINT DF_TaxRateHistories_SgstRate DEFAULT (0),
        IgstRate            DECIMAL(18,4)   NOT NULL CONSTRAINT DF_TaxRateHistories_IgstRate DEFAULT (0),
        CessRate            DECIMAL(18,4)   NOT NULL CONSTRAINT DF_TaxRateHistories_CessRate DEFAULT (0),
        /* Half-open interval: valid for dates >= EffectiveFrom and < EffectiveTo.
           EffectiveTo null means "still in force". */
        EffectiveFrom       DATETIME2(3)    NOT NULL,
        EffectiveTo         DATETIME2(3)    NULL,
        ChangeNote          NVARCHAR(500)   NULL,
        ChangedBy           INT             NULL,
        ChangedByName       NVARCHAR(200)   NULL,
        ChangedOn           DATETIME2(3)    NOT NULL CONSTRAINT DF_TaxRateHistories_ChangedOn DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_TaxRateHistories PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_TaxRateHistories_TaxClasses FOREIGN KEY (TaxClassId) REFERENCES dbo.TaxClasses (Id),
        CONSTRAINT CK_TaxRateHistories_Rates
            CHECK (TotalRate >= 0 AND CgstRate >= 0 AND SgstRate >= 0 AND IgstRate >= 0 AND CessRate >= 0),
        CONSTRAINT CK_TaxRateHistories_Window CHECK (EffectiveTo IS NULL OR EffectiveTo > EffectiveFrom)
    );

    /* "What was the rate for this class on this date?" */
    CREATE INDEX IX_TaxRateHistories_Lookup ON dbo.TaxRateHistories (TaxClassId, EffectiveFrom DESC);
    /* Only one open-ended row per class. */
    CREATE UNIQUE INDEX UX_TaxRateHistories_Current ON dbo.TaxRateHistories (TaxClassId)
        WHERE EffectiveTo IS NULL;
END
GO
