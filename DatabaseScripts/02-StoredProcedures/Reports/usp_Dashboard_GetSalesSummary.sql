/* =============================================================================
   usp_Dashboard_GetSalesSummary
   -----------------------------------------------------------------------------
   The KPI cards and the sales trend chart on the admin landing page.

   Specs:
     Dashboard.txt §3.1  Total / Today's / Monthly Sales, Orders, Customers,
                         Revenue, Profit, Visitors
     Dashboard.txt §4    monthly / weekly / daily sales chart
     Dashboard.txt §18   Revenue counts completed orders only; cancelled orders
                         are excluded; Profit = Revenue - CostOfGoodsSold;
                         returned orders reduce revenue after refund approval.

   Reads dbo.DailySalesSummaries rather than dbo.Orders. That table exists
   precisely for this path (see 19_Analytics.sql): the dashboard auto-refreshes
   every few minutes for every signed-in administrator, and aggregating the whole
   order history on each refresh does not scale. Today's figures come from
   dbo.Orders directly, because the rollup for the current day is not final.

   Returns four result sets: KPI totals, the trend series, order-status counts,
   and the traffic figures.
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Dashboard_GetSalesSummary
    @FromDate       DATE = NULL,
    @ToDate         DATE = NULL,
    /* Day | Week | Month - the granularity of the trend series. */
    @Granularity    VARCHAR(10) = 'Day'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Today      DATE = CAST(SYSUTCDATETIME() AS DATE);
    DECLARE @MonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);

    SET @ToDate   = ISNULL(@ToDate,   @Today);
    SET @FromDate = ISNULL(@FromDate, DATEADD(DAY, -29, @ToDate));

    /* Order statuses that count as revenue. From the enum documented in
       11_Orders.sql: 7 Delivered, 8 Completed. Cancelled (9), PaymentFailed (14)
       and the return states are excluded per Dashboard.txt §18. */
    DECLARE @CompletedStatuses TABLE (Status TINYINT PRIMARY KEY);
    INSERT INTO @CompletedStatuses (Status) VALUES (7), (8);

    /* -----------------------------------------------------------------------
       1. KPI cards.
       Historical days come from the rollup; today is computed live so the card
       is not up to 24 hours stale.
       ----------------------------------------------------------------------- */
    ;WITH TodayLive AS
    (
        SELECT  OrderCount   = COUNT(*),
                GrossSales   = ISNULL(SUM(o.Total), 0),
                NetSales     = ISNULL(SUM(o.Total - o.TaxTotal - o.RefundedAmount), 0),
                TaxCollected = ISNULL(SUM(o.TaxTotal), 0)
        FROM    dbo.Orders AS o
        WHERE   CAST(o.PlacedOn AS DATE) = @Today
          AND   o.Status IN (SELECT Status FROM @CompletedStatuses)
          AND   o.IsDeleted = 0
    ),
    RangeRollup AS
    (
        SELECT  OrderCount      = ISNULL(SUM(d.CompletedOrderCount), 0),
                GrossSales      = ISNULL(SUM(d.GrossSales), 0),
                NetSales        = ISNULL(SUM(d.NetSales), 0),
                GrossProfit     = ISNULL(SUM(d.GrossProfit), 0),
                TaxCollected    = ISNULL(SUM(d.TaxCollected), 0),
                RefundTotal     = ISNULL(SUM(d.RefundTotal), 0),
                DiscountTotal   = ISNULL(SUM(d.DiscountTotal), 0),
                ItemsSold       = ISNULL(SUM(d.ItemsSold), 0),
                NewCustomers    = ISNULL(SUM(d.NewCustomerCount), 0)
        FROM    dbo.DailySalesSummaries AS d
        WHERE   d.SummaryDate BETWEEN @FromDate AND @ToDate
    ),
    MonthRollup AS
    (
        SELECT  MonthlySales = ISNULL(SUM(d.NetSales), 0)
        FROM    dbo.DailySalesSummaries AS d
        WHERE   d.SummaryDate BETWEEN @MonthStart AND @Today
    ),
    AllTime AS
    (
        SELECT  TotalSales  = ISNULL(SUM(d.NetSales), 0),
                TotalOrders = ISNULL(SUM(d.CompletedOrderCount), 0),
                TotalProfit = ISNULL(SUM(d.GrossProfit), 0)
        FROM    dbo.DailySalesSummaries AS d
    )
    SELECT
        TotalSales          = a.TotalSales,
        TotalOrders         = a.TotalOrders,
        TotalProfit         = a.TotalProfit,
        TodaySales          = t.NetSales,
        TodayOrders         = t.OrderCount,
        MonthlySales        = m.MonthlySales,
        RangeNetSales       = r.NetSales,
        RangeGrossSales     = r.GrossSales,
        RangeGrossProfit    = r.GrossProfit,
        RangeOrderCount     = r.OrderCount,
        RangeItemsSold      = r.ItemsSold,
        RangeTaxCollected   = r.TaxCollected,
        RangeRefundTotal    = r.RefundTotal,
        RangeDiscountTotal  = r.DiscountTotal,
        RangeNewCustomers   = r.NewCustomers,
        AverageOrderValue   = CASE WHEN r.OrderCount > 0
                                   THEN ROUND(r.NetSales / r.OrderCount, 2)
                                   ELSE 0 END,
        ProfitMarginPercent = CASE WHEN r.NetSales > 0
                                   THEN ROUND(100.0 * r.GrossProfit / r.NetSales, 2)
                                   ELSE 0 END,
        TotalCustomers      = (SELECT COUNT(*) FROM dbo.Customers WHERE IsDeleted = 0),
        PendingOrders       = (SELECT COUNT(*) FROM dbo.Orders
                               WHERE Status IN (0,1,2) AND IsDeleted = 0),
        CurrencyCode        = 'INR'
    FROM AllTime AS a
    CROSS JOIN TodayLive   AS t
    CROSS JOIN RangeRollup AS r
    CROSS JOIN MonthRollup AS m;

    /* -----------------------------------------------------------------------
       2. Trend series for the chart.
       ----------------------------------------------------------------------- */
    IF @Granularity = 'Month'
    BEGIN
        SELECT
            Bucket      = DATEFROMPARTS(YEAR(d.SummaryDate), MONTH(d.SummaryDate), 1),
            BucketLabel = FORMAT(d.SummaryDate, 'MMM yyyy'),
            OrderCount  = SUM(d.CompletedOrderCount),
            NetSales    = SUM(d.NetSales),
            GrossProfit = SUM(d.GrossProfit),
            ItemsSold   = SUM(d.ItemsSold)
        FROM   dbo.DailySalesSummaries AS d
        WHERE  d.SummaryDate BETWEEN @FromDate AND @ToDate
        GROUP  BY DATEFROMPARTS(YEAR(d.SummaryDate), MONTH(d.SummaryDate), 1),
                  FORMAT(d.SummaryDate, 'MMM yyyy')
        ORDER  BY Bucket;
    END
    ELSE IF @Granularity = 'Week'
    BEGIN
        SELECT
            Bucket      = DATEADD(DAY, 1 - DATEPART(WEEKDAY, d.SummaryDate), d.SummaryDate),
            BucketLabel = CONCAT(N'Week of ',
                                 FORMAT(DATEADD(DAY, 1 - DATEPART(WEEKDAY, d.SummaryDate), d.SummaryDate), 'dd MMM')),
            OrderCount  = SUM(d.CompletedOrderCount),
            NetSales    = SUM(d.NetSales),
            GrossProfit = SUM(d.GrossProfit),
            ItemsSold   = SUM(d.ItemsSold)
        FROM   dbo.DailySalesSummaries AS d
        WHERE  d.SummaryDate BETWEEN @FromDate AND @ToDate
        GROUP  BY DATEADD(DAY, 1 - DATEPART(WEEKDAY, d.SummaryDate), d.SummaryDate)
        ORDER  BY Bucket;
    END
    ELSE
    BEGIN
        SELECT
            Bucket      = d.SummaryDate,
            BucketLabel = FORMAT(d.SummaryDate, 'dd MMM'),
            OrderCount  = d.CompletedOrderCount,
            NetSales    = d.NetSales,
            GrossProfit = d.GrossProfit,
            ItemsSold   = d.ItemsSold
        FROM   dbo.DailySalesSummaries AS d
        WHERE  d.SummaryDate BETWEEN @FromDate AND @ToDate
        ORDER  BY d.SummaryDate;
    END

    /* -----------------------------------------------------------------------
       3. Order status counts - Dashboard.txt §6.
          Live from dbo.Orders: these are "how many are sitting in this state
          right now", which no historical rollup can answer.
       ----------------------------------------------------------------------- */
    SELECT
        NewOrders        = SUM(CASE WHEN o.Status = 0  THEN 1 ELSE 0 END),
        PaymentPending   = SUM(CASE WHEN o.Status = 1  THEN 1 ELSE 0 END),
        Processing       = SUM(CASE WHEN o.Status = 2  THEN 1 ELSE 0 END),
        Packed           = SUM(CASE WHEN o.Status = 3  THEN 1 ELSE 0 END),
        Shipped          = SUM(CASE WHEN o.Status IN (4,5) THEN 1 ELSE 0 END),
        OutForDelivery   = SUM(CASE WHEN o.Status = 6  THEN 1 ELSE 0 END),
        Delivered        = SUM(CASE WHEN o.Status = 7  THEN 1 ELSE 0 END),
        Completed        = SUM(CASE WHEN o.Status = 8  THEN 1 ELSE 0 END),
        Cancelled        = SUM(CASE WHEN o.Status = 9  THEN 1 ELSE 0 END),
        ReturnRequested  = SUM(CASE WHEN o.Status IN (10,11,12) THEN 1 ELSE 0 END),
        Refunded         = SUM(CASE WHEN o.Status = 13 THEN 1 ELSE 0 END),
        PaymentFailed    = SUM(CASE WHEN o.Status = 14 THEN 1 ELSE 0 END),
        /* Orders.txt §23 - the SLA breach indicator. */
        BreachingSla     = SUM(CASE WHEN o.DeliveryBy IS NOT NULL
                                     AND o.DeliveryBy < SYSUTCDATETIME()
                                     AND o.Status NOT IN (7,8,9,13) THEN 1 ELSE 0 END)
    FROM   dbo.Orders AS o
    WHERE  o.IsDeleted = 0;

    /* -----------------------------------------------------------------------
       4. Website analytics - Dashboard.txt §12.
       ----------------------------------------------------------------------- */
    SELECT
        Sessions            = ISNULL(SUM(t.SessionCount), 0),
        Visitors            = ISNULL(SUM(t.VisitorCount), 0),
        NewVisitors         = ISNULL(SUM(t.NewVisitorCount), 0),
        ReturningVisitors   = ISNULL(SUM(t.ReturningVisitorCount), 0),
        PageViews           = ISNULL(SUM(t.PageViewCount), 0),
        BounceRatePercent   = CASE WHEN SUM(t.SessionCount) > 0
                                   THEN ROUND(100.0 * SUM(t.BounceCount) / SUM(t.SessionCount), 2)
                                   ELSE 0 END,
        ConversionPercent   = CASE WHEN SUM(t.SessionCount) > 0
                                   THEN ROUND(100.0 * SUM(t.ConvertedSessionCount) / SUM(t.SessionCount), 2)
                                   ELSE 0 END,
        AvgSessionSeconds   = CASE WHEN SUM(t.SessionCount) > 0
                                   THEN SUM(CAST(t.AverageSessionSeconds AS BIGINT) * t.SessionCount) / SUM(t.SessionCount)
                                   ELSE 0 END,
        CartsAbandoned      = ISNULL(SUM(t.CartAbandonedCount), 0)
    FROM   dbo.DailyTrafficSummaries AS t
    WHERE  t.SummaryDate BETWEEN @FromDate AND @ToDate;
END
GO
