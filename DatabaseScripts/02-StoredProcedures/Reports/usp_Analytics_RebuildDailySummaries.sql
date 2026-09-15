/* =============================================================================
   usp_Analytics_RebuildDailySummaries
   -----------------------------------------------------------------------------
   Rebuilds dbo.DailySalesSummaries and dbo.DailyTrafficSummaries from the
   transactional tables.

   This procedure is what makes those two rollups legitimate. They are caches,
   not sources of truth: any row can be thrown away and reproduced exactly from
   dbo.Orders, dbo.OrderItems, dbo.Refunds, dbo.VisitorSessions,
   dbo.PageViewLogs, dbo.Carts and dbo.SearchQueries. Nothing else in the system
   writes to them.

   Run by the ReportAggregation background job (appsettings BackgroundJobs
   section). Default window is the last 7 days, which absorbs late-arriving
   refunds and delivery confirmations; pass an explicit range to backfill.

   Business rules from Dashboard.txt §18, encoded here rather than in the
   reading procedures so every consumer sees the same definition:
     * Revenue counts completed orders only  -> Status IN (7 Delivered, 8 Completed)
     * Cancelled orders are excluded         -> Status 9 counted separately
     * Profit = Revenue - CostOfGoodsSold    -> COGS from the CostPrice snapshot
     * Returned orders reduce revenue after refund approval
                                             -> RefundTotal subtracted in NetSales
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Analytics_RebuildDailySummaries
    @FromDate   DATE = NULL,
    @ToDate     DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @ToDate   IS NULL SET @ToDate   = CAST(SYSUTCDATETIME() AS DATE);
    IF @FromDate IS NULL SET @FromDate = DATEADD(DAY, -6, @ToDate);

    IF @FromDate > @ToDate
        THROW 50001, 'usp_Analytics_RebuildDailySummaries: @FromDate is after @ToDate.', 1;

    DECLARE @From DATETIME2(3) = CAST(@FromDate AS DATETIME2(3));
    DECLARE @To   DATETIME2(3) = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME2(3)));

    BEGIN TRY
        BEGIN TRANSACTION;

        /* Every date in the window, including days with no activity - a gap in
           the series would break the trend chart's x-axis. */
        ;WITH Dates AS
        (
            SELECT d = @FromDate
            UNION ALL
            SELECT DATEADD(DAY, 1, d) FROM Dates WHERE d < @ToDate
        )
        SELECT d AS SummaryDate
        INTO   #Dates
        FROM   Dates
        OPTION (MAXRECURSION 0);

        ------------------------------------------------------------------------
        -- Sales
        ------------------------------------------------------------------------
        ;WITH OrderDay AS
        (
            SELECT  SummaryDate         = CAST(o.PlacedOn AS DATE),
                    OrderCount          = COUNT(*),
                    CompletedOrderCount = SUM(CASE WHEN o.Status IN (7,8) THEN 1 ELSE 0 END),
                    CancelledOrderCount = SUM(CASE WHEN o.Status = 9  THEN 1 ELSE 0 END),
                    ReturnedOrderCount  = SUM(CASE WHEN o.Status IN (10,11,12,13) THEN 1 ELSE 0 END),
                    GrossSales          = SUM(CASE WHEN o.Status IN (7,8) THEN o.Total ELSE 0 END),
                    DiscountTotal       = SUM(CASE WHEN o.Status IN (7,8)
                                                   THEN o.CouponDiscount + o.OfferDiscount + o.PointsDiscount
                                                   ELSE 0 END),
                    CouponDiscount      = SUM(CASE WHEN o.Status IN (7,8) THEN o.CouponDiscount ELSE 0 END),
                    OfferDiscount       = SUM(CASE WHEN o.Status IN (7,8) THEN o.OfferDiscount  ELSE 0 END),
                    ShippingRevenue     = SUM(CASE WHEN o.Status IN (7,8) THEN o.ShippingCost   ELSE 0 END),
                    TaxCollected        = SUM(CASE WHEN o.Status IN (7,8) THEN o.TaxTotal       ELSE 0 END),
                    ItemsSold           = SUM(CASE WHEN o.Status IN (7,8) THEN o.ItemCount      ELSE 0 END),
                    CodOrderCount       = SUM(CASE WHEN o.Status IN (7,8) AND o.PaymentMethod = 4 THEN 1 ELSE 0 END),
                    PrepaidOrderCount   = SUM(CASE WHEN o.Status IN (7,8) AND o.PaymentMethod <> 4 THEN 1 ELSE 0 END)
            FROM    dbo.Orders AS o
            WHERE   o.PlacedOn >= @From AND o.PlacedOn < @To
              AND   o.IsDeleted = 0
            GROUP   BY CAST(o.PlacedOn AS DATE)
        ),
        /* Cost of goods sold, from the cost SNAPSHOT captured on the order line
           at the time of sale (dbo.OrderItems.UnitCostPrice, added by
           04-Patches/2026-08-12_05). A supplier raising a price must not
           restate last year's margin.

           The ISNULL fallback to dbo.Products covers order lines written before
           that patch, which genuinely have no captured cost. It is deliberately
           visible rather than hidden, and becomes dead code once no null
           UnitCostPrice rows remain. Cancelled quantities are excluded - we did
           not buy what we did not ship. */
        CogsDay AS
        (
            SELECT  SummaryDate = CAST(o.PlacedOn AS DATE),
                    Cogs = SUM(
                              ISNULL(oi.UnitCostPrice, ISNULL(p.CostPrice, 0))
                              * (oi.Quantity - oi.QuantityCancelled)
                           )
            FROM    dbo.OrderItems AS oi
            JOIN    dbo.Orders     AS o ON o.Id = oi.OrderId
            LEFT JOIN dbo.Products AS p ON p.Id = oi.ProductId
            WHERE   o.PlacedOn >= @From AND o.PlacedOn < @To
              AND   o.Status IN (7,8)
              AND   o.IsDeleted = 0
            GROUP   BY CAST(o.PlacedOn AS DATE)
        ),
        RefundDay AS
        (
            SELECT  SummaryDate = CAST(r.CompletedOn AS DATE),
                    RefundTotal = SUM(r.Amount)
            FROM    dbo.Refunds AS r
            WHERE   r.CompletedOn >= @From AND r.CompletedOn < @To
              AND   r.IsDeleted = 0
            GROUP   BY CAST(r.CompletedOn AS DATE)
        ),
        CustomerDay AS
        (
            SELECT  SummaryDate = CAST(c.RegisteredOn AS DATE),
                    NewCustomers = COUNT(*)
            FROM    dbo.Customers AS c
            WHERE   c.RegisteredOn >= @From AND c.RegisteredOn < @To
              AND   c.IsDeleted = 0
            GROUP   BY CAST(c.RegisteredOn AS DATE)
        ),
        /* A "returning" buyer is one who had already placed an order before the
           one counted on this day. */
        ReturningDay AS
        (
            SELECT  SummaryDate = CAST(o.PlacedOn AS DATE),
                    ReturningCustomers = COUNT(DISTINCT o.CustomerId)
            FROM    dbo.Orders AS o
            WHERE   o.PlacedOn >= @From AND o.PlacedOn < @To
              AND   o.Status IN (7,8)
              AND   o.CustomerId IS NOT NULL
              AND   o.IsDeleted = 0
              AND   EXISTS (SELECT 1 FROM dbo.Orders AS prev
                            WHERE prev.CustomerId = o.CustomerId
                              AND prev.PlacedOn < o.PlacedOn
                              AND prev.Status IN (7,8)
                              AND prev.IsDeleted = 0)
            GROUP   BY CAST(o.PlacedOn AS DATE)
        ),
        Combined AS
        (
            SELECT
                d.SummaryDate,
                OrderCount          = ISNULL(o.OrderCount, 0),
                CompletedOrderCount = ISNULL(o.CompletedOrderCount, 0),
                CancelledOrderCount = ISNULL(o.CancelledOrderCount, 0),
                ReturnedOrderCount  = ISNULL(o.ReturnedOrderCount, 0),
                ItemsSold           = ISNULL(o.ItemsSold, 0),
                GrossSales          = ISNULL(o.GrossSales, 0),
                DiscountTotal       = ISNULL(o.DiscountTotal, 0),
                CouponDiscount      = ISNULL(o.CouponDiscount, 0),
                OfferDiscount       = ISNULL(o.OfferDiscount, 0),
                ShippingRevenue     = ISNULL(o.ShippingRevenue, 0),
                TaxCollected        = ISNULL(o.TaxCollected, 0),
                RefundTotal         = ISNULL(rf.RefundTotal, 0),
                CostOfGoodsSold     = ISNULL(cg.Cogs, 0),
                NewCustomerCount    = ISNULL(cu.NewCustomers, 0),
                ReturningCustomerCount = ISNULL(rt.ReturningCustomers, 0),
                CodOrderCount       = ISNULL(o.CodOrderCount, 0),
                PrepaidOrderCount   = ISNULL(o.PrepaidOrderCount, 0)
            FROM   #Dates AS d
            LEFT JOIN OrderDay     AS o  ON o.SummaryDate  = d.SummaryDate
            LEFT JOIN RefundDay    AS rf ON rf.SummaryDate = d.SummaryDate
            LEFT JOIN CogsDay      AS cg ON cg.SummaryDate = d.SummaryDate
            LEFT JOIN CustomerDay  AS cu ON cu.SummaryDate = d.SummaryDate
            LEFT JOIN ReturningDay AS rt ON rt.SummaryDate = d.SummaryDate
        )
        MERGE dbo.DailySalesSummaries AS tgt
        USING (
            SELECT
                c.*,
                NetSales = c.GrossSales - c.TaxCollected - c.RefundTotal,
                GrossProfit = (c.GrossSales - c.TaxCollected - c.RefundTotal) - c.CostOfGoodsSold,
                AverageOrderValue = CASE WHEN c.CompletedOrderCount > 0
                                         THEN ROUND(c.GrossSales / c.CompletedOrderCount, 2)
                                         ELSE 0 END
            FROM Combined AS c
        ) AS src
           ON tgt.SummaryDate = src.SummaryDate
        WHEN MATCHED THEN UPDATE SET
            OrderCount             = src.OrderCount,
            CompletedOrderCount    = src.CompletedOrderCount,
            CancelledOrderCount    = src.CancelledOrderCount,
            ReturnedOrderCount     = src.ReturnedOrderCount,
            ItemsSold              = src.ItemsSold,
            GrossSales             = src.GrossSales,
            DiscountTotal          = src.DiscountTotal,
            CouponDiscount         = src.CouponDiscount,
            OfferDiscount          = src.OfferDiscount,
            ShippingRevenue        = src.ShippingRevenue,
            TaxCollected           = src.TaxCollected,
            RefundTotal            = src.RefundTotal,
            NetSales               = src.NetSales,
            CostOfGoodsSold        = src.CostOfGoodsSold,
            GrossProfit            = src.GrossProfit,
            AverageOrderValue      = src.AverageOrderValue,
            NewCustomerCount       = src.NewCustomerCount,
            ReturningCustomerCount = src.ReturningCustomerCount,
            CodOrderCount          = src.CodOrderCount,
            PrepaidOrderCount      = src.PrepaidOrderCount,
            RecalculatedAt         = SYSUTCDATETIME()
        WHEN NOT MATCHED BY TARGET THEN INSERT
        (
            SummaryDate, OrderCount, CompletedOrderCount, CancelledOrderCount,
            ReturnedOrderCount, ItemsSold, GrossSales, DiscountTotal,
            CouponDiscount, OfferDiscount, ShippingRevenue, TaxCollected,
            RefundTotal, NetSales, CostOfGoodsSold, GrossProfit,
            AverageOrderValue, NewCustomerCount, ReturningCustomerCount,
            CodOrderCount, PrepaidOrderCount, RecalculatedAt
        )
        VALUES
        (
            src.SummaryDate, src.OrderCount, src.CompletedOrderCount, src.CancelledOrderCount,
            src.ReturnedOrderCount, src.ItemsSold, src.GrossSales, src.DiscountTotal,
            src.CouponDiscount, src.OfferDiscount, src.ShippingRevenue, src.TaxCollected,
            src.RefundTotal, src.NetSales, src.CostOfGoodsSold, src.GrossProfit,
            src.AverageOrderValue, src.NewCustomerCount, src.ReturningCustomerCount,
            src.CodOrderCount, src.PrepaidOrderCount, SYSUTCDATETIME()
        );

        ------------------------------------------------------------------------
        -- Traffic
        ------------------------------------------------------------------------
        ;WITH SessionDay AS
        (
            SELECT  SummaryDate           = CAST(s.StartedAt AS DATE),
                    SessionCount          = COUNT(*),
                    VisitorCount          = COUNT(DISTINCT ISNULL(CAST(s.CustomerId AS VARCHAR(32)), s.GuestToken)),
                    NewVisitorCount       = SUM(CASE WHEN s.IsNewVisitor = 1 THEN 1 ELSE 0 END),
                    ReturningVisitorCount = SUM(CASE WHEN s.IsNewVisitor = 0 THEN 1 ELSE 0 END),
                    BounceCount           = SUM(CASE WHEN s.IsBounce = 1 THEN 1 ELSE 0 END),
                    ConvertedSessionCount = SUM(CASE WHEN s.ConvertedOrderId IS NOT NULL THEN 1 ELSE 0 END),
                    TotalDurationSeconds  = SUM(CAST(ISNULL(s.DurationSeconds, 0) AS BIGINT)),
                    DesktopSessionCount   = SUM(CASE WHEN s.DeviceType = 'Desktop' THEN 1 ELSE 0 END),
                    MobileSessionCount    = SUM(CASE WHEN s.DeviceType = 'Mobile'  THEN 1 ELSE 0 END),
                    TabletSessionCount    = SUM(CASE WHEN s.DeviceType = 'Tablet'  THEN 1 ELSE 0 END)
            FROM    dbo.VisitorSessions AS s
            WHERE   s.StartedAt >= @From AND s.StartedAt < @To
            GROUP   BY CAST(s.StartedAt AS DATE)
        ),
        PageDay AS
        (
            SELECT  SummaryDate = CAST(pv.ViewedAt AS DATE), PageViewCount = COUNT(*)
            FROM    dbo.PageViewLogs AS pv
            WHERE   pv.ViewedAt >= @From AND pv.ViewedAt < @To
            GROUP   BY CAST(pv.ViewedAt AS DATE)
        ),
        SearchDay AS
        (
            SELECT  SummaryDate = CAST(q.SearchedAt AS DATE),
                    SearchCount = COUNT(*),
                    ZeroResultSearchCount = SUM(CASE WHEN q.ResultCount = 0 THEN 1 ELSE 0 END)
            FROM    dbo.SearchQueries AS q
            WHERE   q.SearchedAt >= @From AND q.SearchedAt < @To
            GROUP   BY CAST(q.SearchedAt AS DATE)
        ),
        CartDay AS
        (
            SELECT  SummaryDate = CAST(c.CreatedAt AS DATE), CartCreatedCount = COUNT(*)
            FROM    dbo.Carts AS c
            WHERE   c.CreatedAt >= @From AND c.CreatedAt < @To
            GROUP   BY CAST(c.CreatedAt AS DATE)
        ),
        AbandonDay AS
        (
            SELECT  SummaryDate = CAST(c.AbandonedAt AS DATE), CartAbandonedCount = COUNT(*)
            FROM    dbo.Carts AS c
            WHERE   c.AbandonedAt >= @From AND c.AbandonedAt < @To
            GROUP   BY CAST(c.AbandonedAt AS DATE)
        )
        MERGE dbo.DailyTrafficSummaries AS tgt
        USING (
            SELECT
                d.SummaryDate,
                SessionCount          = ISNULL(s.SessionCount, 0),
                VisitorCount          = ISNULL(s.VisitorCount, 0),
                NewVisitorCount       = ISNULL(s.NewVisitorCount, 0),
                ReturningVisitorCount = ISNULL(s.ReturningVisitorCount, 0),
                PageViewCount         = ISNULL(p.PageViewCount, 0),
                BounceCount           = ISNULL(s.BounceCount, 0),
                BounceRate            = CASE WHEN ISNULL(s.SessionCount, 0) > 0
                                             THEN CAST(1.0 * s.BounceCount / s.SessionCount AS DECIMAL(18,4))
                                             ELSE 0 END,
                AverageSessionSeconds = CASE WHEN ISNULL(s.SessionCount, 0) > 0
                                             THEN CAST(s.TotalDurationSeconds / s.SessionCount AS INT)
                                             ELSE 0 END,
                ConvertedSessionCount = ISNULL(s.ConvertedSessionCount, 0),
                ConversionRate        = CASE WHEN ISNULL(s.SessionCount, 0) > 0
                                             THEN CAST(1.0 * s.ConvertedSessionCount / s.SessionCount AS DECIMAL(18,4))
                                             ELSE 0 END,
                CartCreatedCount      = ISNULL(cd.CartCreatedCount, 0),
                CartAbandonedCount    = ISNULL(ab.CartAbandonedCount, 0),
                SearchCount           = ISNULL(sq.SearchCount, 0),
                ZeroResultSearchCount = ISNULL(sq.ZeroResultSearchCount, 0),
                DesktopSessionCount   = ISNULL(s.DesktopSessionCount, 0),
                MobileSessionCount    = ISNULL(s.MobileSessionCount, 0),
                TabletSessionCount    = ISNULL(s.TabletSessionCount, 0)
            FROM   #Dates AS d
            LEFT JOIN SessionDay AS s  ON s.SummaryDate  = d.SummaryDate
            LEFT JOIN PageDay    AS p  ON p.SummaryDate  = d.SummaryDate
            LEFT JOIN SearchDay  AS sq ON sq.SummaryDate = d.SummaryDate
            LEFT JOIN CartDay    AS cd ON cd.SummaryDate = d.SummaryDate
            LEFT JOIN AbandonDay AS ab ON ab.SummaryDate = d.SummaryDate
        ) AS src
           ON tgt.SummaryDate = src.SummaryDate
        WHEN MATCHED THEN UPDATE SET
            SessionCount          = src.SessionCount,
            VisitorCount          = src.VisitorCount,
            NewVisitorCount       = src.NewVisitorCount,
            ReturningVisitorCount = src.ReturningVisitorCount,
            PageViewCount         = src.PageViewCount,
            BounceCount           = src.BounceCount,
            BounceRate            = src.BounceRate,
            AverageSessionSeconds = src.AverageSessionSeconds,
            ConvertedSessionCount = src.ConvertedSessionCount,
            ConversionRate        = src.ConversionRate,
            CartCreatedCount      = src.CartCreatedCount,
            CartAbandonedCount    = src.CartAbandonedCount,
            SearchCount           = src.SearchCount,
            ZeroResultSearchCount = src.ZeroResultSearchCount,
            DesktopSessionCount   = src.DesktopSessionCount,
            MobileSessionCount    = src.MobileSessionCount,
            TabletSessionCount    = src.TabletSessionCount,
            RecalculatedAt        = SYSUTCDATETIME()
        WHEN NOT MATCHED BY TARGET THEN INSERT
        (
            SummaryDate, SessionCount, VisitorCount, NewVisitorCount,
            ReturningVisitorCount, PageViewCount, BounceCount, BounceRate,
            AverageSessionSeconds, ConvertedSessionCount, ConversionRate,
            CartCreatedCount, CartAbandonedCount, SearchCount,
            ZeroResultSearchCount, DesktopSessionCount, MobileSessionCount,
            TabletSessionCount, RecalculatedAt
        )
        VALUES
        (
            src.SummaryDate, src.SessionCount, src.VisitorCount, src.NewVisitorCount,
            src.ReturningVisitorCount, src.PageViewCount, src.BounceCount, src.BounceRate,
            src.AverageSessionSeconds, src.ConvertedSessionCount, src.ConversionRate,
            src.CartCreatedCount, src.CartAbandonedCount, src.SearchCount,
            src.ZeroResultSearchCount, src.DesktopSessionCount, src.MobileSessionCount,
            src.TabletSessionCount, SYSUTCDATETIME()
        );

        /* Rolling 7-day counter behind "trending" in the search suggestions. */
        UPDATE s
        SET    s.RecentSearchCount = x.RecentCount,
               s.RecalculatedAt    = SYSUTCDATETIME()
        FROM   dbo.SearchTermSummaries AS s
        JOIN  (SELECT q.NormalizedTerm, RecentCount = COUNT(*)
               FROM   dbo.SearchQueries AS q
               WHERE  q.SearchedAt >= DATEADD(DAY, -7, SYSUTCDATETIME())
               GROUP  BY q.NormalizedTerm) AS x
          ON   x.NormalizedTerm = s.NormalizedTerm;

        DROP TABLE #Dates;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
