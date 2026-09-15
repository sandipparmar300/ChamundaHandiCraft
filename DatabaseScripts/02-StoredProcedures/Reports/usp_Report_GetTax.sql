/* =============================================================================
   usp_Report_GetTax
   -----------------------------------------------------------------------------
   The GST reports in Reports.txt §9: GST collected, CGST / SGST / IGST split,
   tax by invoice, tax by state, tax by product, and the HSN summary that GSTR-1
   filing is built from.

   Every figure comes from dbo.OrderItemTaxes, which froze the rate, the taxable
   value and the place of supply at the moment the order was placed
   (20_Concurrency_And_Tax.sql). Nothing here joins to dbo.TaxClasses or
   dbo.Products for a rate - Reports.txt §20 requires tax reports to align with
   invoice data, and prompt §20 forbids depending on current configuration for
   historical reporting.

   Refunds are reported alongside as negative movement, from dbo.RefundTaxes, so
   a credit note reduces the liability in the period it was issued.

   Six result sets:
     1. Summary totals
     2. Component split (CGST / SGST / UTGST / IGST / CESS)
     3. HSN summary - the GSTR-1 shape
     4. By place of supply
     5. By invoice
     6. Refund / credit-note reversals
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Report_GetTax
    @FromDate       DATE,
    @ToDate         DATE,
    @PlaceOfSupply  NVARCHAR(100)   = NULL,
    @HsnCode        VARCHAR(16)     = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @FromDate IS NULL SET @FromDate = DATEFROMPARTS(YEAR(SYSUTCDATETIME()), MONTH(SYSUTCDATETIME()), 1);
    IF @ToDate   IS NULL SET @ToDate   = CAST(SYSUTCDATETIME() AS DATE);

    DECLARE @ToExclusive DATETIME2(3) = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME2(3)));
    DECLARE @FromInclusive DATETIME2(3) = CAST(@FromDate AS DATETIME2(3));

    /* Only orders that represent a real supply. Cancelled (9) and
       PaymentFailed (14) never generated an invoice, so they carry no liability. */
    DECLARE @TaxableOrders TABLE
    (
        OrderId     INT PRIMARY KEY,
        PlacedOn    DATETIME2(3),
        OrderNumber VARCHAR(32)
    );

    INSERT INTO @TaxableOrders (OrderId, PlacedOn, OrderNumber)
    SELECT o.Id, o.PlacedOn, o.OrderNumber
    FROM   dbo.Orders AS o
    WHERE  o.PlacedOn >= @FromInclusive
      AND  o.PlacedOn <  @ToExclusive
      AND  o.Status NOT IN (9, 14)
      AND  o.IsDeleted = 0;

    ----------------------------------------------------------------------------
    -- 1. Summary
    ----------------------------------------------------------------------------
    SELECT
        FromDate        = @FromDate,
        ToDate          = @ToDate,
        OrderCount      = (SELECT COUNT(*) FROM @TaxableOrders),
        InvoiceCount    = (SELECT COUNT(*) FROM dbo.Invoices AS i
                           JOIN @TaxableOrders AS o ON o.OrderId = i.OrderId
                           WHERE i.IsCreditNote = 0 AND i.IsDeleted = 0),
        TaxableValue    = ISNULL(SUM(t.TaxableAmount), 0),
        TotalTax        = ISNULL(SUM(t.TaxAmount), 0),
        Cgst            = ISNULL(SUM(CASE WHEN t.TaxComponent = 'CGST'  THEN t.TaxAmount END), 0),
        Sgst            = ISNULL(SUM(CASE WHEN t.TaxComponent IN ('SGST','UTGST') THEN t.TaxAmount END), 0),
        Igst            = ISNULL(SUM(CASE WHEN t.TaxComponent = 'IGST'  THEN t.TaxAmount END), 0),
        Cess            = ISNULL(SUM(CASE WHEN t.TaxComponent = 'CESS'  THEN t.TaxAmount END), 0),
        RefundedTax     = ISNULL((SELECT SUM(rt.TaxAmount)
                                  FROM   dbo.RefundTaxes AS rt
                                  JOIN   dbo.Refunds AS r ON r.Id = rt.RefundId
                                  WHERE  r.CompletedOn >= @FromInclusive
                                    AND  r.CompletedOn <  @ToExclusive
                                    AND  r.IsDeleted = 0), 0),
        NetTaxLiability = ISNULL(SUM(t.TaxAmount), 0)
                          - ISNULL((SELECT SUM(rt.TaxAmount)
                                    FROM   dbo.RefundTaxes AS rt
                                    JOIN   dbo.Refunds AS r ON r.Id = rt.RefundId
                                    WHERE  r.CompletedOn >= @FromInclusive
                                      AND  r.CompletedOn <  @ToExclusive
                                      AND  r.IsDeleted = 0), 0)
    FROM   dbo.OrderItemTaxes AS t
    JOIN   @TaxableOrders AS o ON o.OrderId = t.OrderId
    WHERE  (@PlaceOfSupply IS NULL OR t.PlaceOfSupply = @PlaceOfSupply)
      AND  (@HsnCode       IS NULL OR t.HsnCode       = @HsnCode);

    ----------------------------------------------------------------------------
    -- 2. Component split
    ----------------------------------------------------------------------------
    SELECT
        t.TaxComponent,
        TaxableValue = SUM(t.TaxableAmount),
        TaxAmount    = SUM(t.TaxAmount),
        LineCount    = COUNT(*)
    FROM   dbo.OrderItemTaxes AS t
    JOIN   @TaxableOrders AS o ON o.OrderId = t.OrderId
    WHERE  (@PlaceOfSupply IS NULL OR t.PlaceOfSupply = @PlaceOfSupply)
      AND  (@HsnCode       IS NULL OR t.HsnCode       = @HsnCode)
    GROUP  BY t.TaxComponent
    ORDER  BY t.TaxComponent;

    ----------------------------------------------------------------------------
    -- 3. HSN summary - this is the GSTR-1 table
    ----------------------------------------------------------------------------
    SELECT
        HsnCode      = ISNULL(t.HsnCode, N'(unclassified)'),
        Description  = MAX(h.Description),
        Quantity     = SUM(oi.Quantity),
        TaxableValue = SUM(t.TaxableAmount),
        Cgst         = SUM(CASE WHEN t.TaxComponent = 'CGST'  THEN t.TaxAmount ELSE 0 END),
        Sgst         = SUM(CASE WHEN t.TaxComponent IN ('SGST','UTGST') THEN t.TaxAmount ELSE 0 END),
        Igst         = SUM(CASE WHEN t.TaxComponent = 'IGST'  THEN t.TaxAmount ELSE 0 END),
        Cess         = SUM(CASE WHEN t.TaxComponent = 'CESS'  THEN t.TaxAmount ELSE 0 END),
        TotalTax     = SUM(t.TaxAmount)
    FROM   dbo.OrderItemTaxes AS t
    JOIN   @TaxableOrders AS o  ON o.OrderId = t.OrderId
    JOIN   dbo.OrderItems AS oi ON oi.Id = t.OrderItemId
    LEFT JOIN dbo.HsnCodes AS h ON h.Code = t.HsnCode
    WHERE  (@PlaceOfSupply IS NULL OR t.PlaceOfSupply = @PlaceOfSupply)
      AND  (@HsnCode       IS NULL OR t.HsnCode       = @HsnCode)
    GROUP  BY ISNULL(t.HsnCode, N'(unclassified)')
    ORDER  BY SUM(t.TaxableAmount) DESC;

    ----------------------------------------------------------------------------
    -- 4. By place of supply
    ----------------------------------------------------------------------------
    SELECT
        PlaceOfSupply = ISNULL(t.PlaceOfSupply, N'(unknown)'),
        IsInterState  = MAX(CAST(t.IsInterState AS TINYINT)),
        OrderCount    = COUNT(DISTINCT t.OrderId),
        TaxableValue  = SUM(t.TaxableAmount),
        Cgst          = SUM(CASE WHEN t.TaxComponent = 'CGST'  THEN t.TaxAmount ELSE 0 END),
        Sgst          = SUM(CASE WHEN t.TaxComponent IN ('SGST','UTGST') THEN t.TaxAmount ELSE 0 END),
        Igst          = SUM(CASE WHEN t.TaxComponent = 'IGST'  THEN t.TaxAmount ELSE 0 END),
        TotalTax      = SUM(t.TaxAmount)
    FROM   dbo.OrderItemTaxes AS t
    JOIN   @TaxableOrders AS o ON o.OrderId = t.OrderId
    WHERE  (@HsnCode IS NULL OR t.HsnCode = @HsnCode)
    GROUP  BY ISNULL(t.PlaceOfSupply, N'(unknown)')
    ORDER  BY SUM(t.TaxAmount) DESC;

    ----------------------------------------------------------------------------
    -- 5. By invoice - Reports.txt §9 "Tax by Invoice", and the audit trail
    ----------------------------------------------------------------------------
    SELECT
        i.InvoiceNumber,
        i.InvoiceDate,
        o.OrderNumber,
        i.CustomerName,
        i.CustomerGstin,
        i.PlaceOfSupply,
        i.TaxableValue,
        i.Cgst,
        i.Sgst,
        i.Igst,
        i.Cess,
        i.RoundOff,
        i.Total,
        i.IsCreditNote
    FROM   dbo.Invoices AS i
    JOIN   @TaxableOrders AS o ON o.OrderId = i.OrderId
    WHERE  i.IsDeleted = 0
      AND  (@PlaceOfSupply IS NULL OR i.PlaceOfSupply = @PlaceOfSupply)
    ORDER  BY i.InvoiceDate, i.InvoiceNumber;

    ----------------------------------------------------------------------------
    -- 6. Credit notes / refund reversals in the period
    ----------------------------------------------------------------------------
    SELECT
        r.RefundNumber,
        r.CompletedOn,
        OrderNumber   = ord.OrderNumber,
        rt.TaxComponent,
        rt.HsnCode,
        rt.PlaceOfSupply,
        TaxableValue  = SUM(rt.TaxableAmount),
        TaxReversed   = SUM(rt.TaxAmount)
    FROM   dbo.RefundTaxes AS rt
    JOIN   dbo.Refunds AS r  ON r.Id = rt.RefundId
    JOIN   dbo.Orders  AS ord ON ord.Id = r.OrderId
    WHERE  r.CompletedOn >= @FromInclusive
      AND  r.CompletedOn <  @ToExclusive
      AND  r.IsDeleted = 0
      AND  (@PlaceOfSupply IS NULL OR rt.PlaceOfSupply = @PlaceOfSupply)
      AND  (@HsnCode       IS NULL OR rt.HsnCode       = @HsnCode)
    GROUP  BY r.RefundNumber, r.CompletedOn, ord.OrderNumber,
              rt.TaxComponent, rt.HsnCode, rt.PlaceOfSupply
    ORDER  BY r.CompletedOn, r.RefundNumber;
END
GO
