/* =============================================================================
   19_Analytics.sql — search, behavioural tracking, traffic, daily rollups, reports
   -----------------------------------------------------------------------------
   Source specs:
     docs/Customer Flows/Search.txt       §10, §11, §16 (history, popular, analytics)
     docs/Admin Flows/Dashboard.txt       §12 (website analytics), §18 (business rules)
     docs/Admin Flows/Reports.txt         (whole module; §25 config vs execution)
     docs/Admin Flows/Banners.txt         §14 (impressions, clicks, CTR)
     docs/Customer Flows/Product Detail.txt §20, docs/Customer Flows/Home.txt §9

   Depends on: 05_Customers, 06_Catalog, 11_Orders, 14_Content, 04_Identity.

   -----------------------------------------------------------------------------
   What this file deliberately does NOT contain
   -----------------------------------------------------------------------------
   Reports.txt §25 and the prompt's §18 both warn against redundant summary
   tables. These candidates were considered and rejected because the figure is
   already available without one:

     * "Most Wishlisted Products"   -> GROUP BY over dbo.WishlistItems.
     * "Best Selling Products"      -> dbo.Products.SoldCount, maintained on
                                       order completion, plus dbo.OrderItems.
     * "Most Viewed Products"       -> dbo.Products.ViewCount.
     * "Recently Viewed Products"   -> TOP n over dbo.ProductViewLogs by customer
                                       (IX_ProductViewLogs_Customer covers it).
     * Abandoned carts              -> dbo.Carts.AbandonedAt / LastActivityAt
                                       already drive the recovery job.
     * KPI snapshots                -> derivable from DailySalesSummaries below.

   Only two rollups survive, both with a stated performance reason and both fully
   rebuildable from transactional tables: DailySalesSummaries and
   DailyTrafficSummaries, plus SearchTermSummaries for the type-ahead path.
   ============================================================================= */

SET NOCOUNT ON;
GO

/* =============================================================================
   Search
   ============================================================================= */

/* ---------------------------------------------------------------------------
   Every executed search. Search.txt §16 tracks keywords, zero-result searches,
   suggestion clicks and search-to-purchase conversion — none of which can be
   reconstructed from any other table.

   NormalizedTerm (trimmed, lowercased, collapsed whitespace) is what everything
   aggregates on; Term keeps what the shopper actually typed for the "did you
   mean" corpus.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.SearchQueries', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SearchQueries
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        Term                NVARCHAR(300)   NOT NULL,
        NormalizedTerm      NVARCHAR(300)   NOT NULL,
        CustomerId          INT             NULL,
        GuestToken          VARCHAR(64)     NULL,
        SessionId           VARCHAR(64)     NULL,
        /* Header | MobileSearch | ShopPage | Blog | Suggestion | Voice */
        Source              VARCHAR(32)     NOT NULL CONSTRAINT DF_SearchQueries_Source DEFAULT ('Header'),
        ResultCount         INT             NOT NULL CONSTRAINT DF_SearchQueries_ResultCount DEFAULT (0),
        /* Filters and sort applied alongside the term, for the §16 "Popular
           Filters" metric. Kept as JSON because the facet set is open-ended. */
        AppliedFiltersJson  NVARCHAR(MAX)   NULL,
        /* Set when the shopper opened a result — Search.txt §16 click tracking. */
        ClickedProductId    INT             NULL,
        ClickedPosition     INT             NULL,
        ClickedAt           DATETIME2(3)    NULL,
        /* Set when a search session ended in an order. Drives search-to-purchase
           conversion without joining across sessions at report time. */
        ConvertedOrderId    INT             NULL,
        SearchedAt          DATETIME2(3)    NOT NULL CONSTRAINT DF_SearchQueries_SearchedAt DEFAULT (SYSUTCDATETIME()),
        IpAddress           VARCHAR(64)     NULL,

        CONSTRAINT PK_SearchQueries PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_SearchQueries_Customers FOREIGN KEY (CustomerId)       REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_SearchQueries_Products  FOREIGN KEY (ClickedProductId) REFERENCES dbo.Products (Id),
        CONSTRAINT FK_SearchQueries_Orders    FOREIGN KEY (ConvertedOrderId) REFERENCES dbo.Orders (Id),
        CONSTRAINT CK_SearchQueries_ResultCount CHECK (ResultCount >= 0)
    );

    /* Search.txt §10 — "Last 10 Searches", logged-in customers only. */
    CREATE INDEX IX_SearchQueries_Customer ON dbo.SearchQueries (CustomerId, SearchedAt DESC)
        INCLUDE (Term)
        WHERE CustomerId IS NOT NULL;

    /* Zero-result report (§16) — the highest-value SEO/merchandising signal. */
    CREATE INDEX IX_SearchQueries_ZeroResult ON dbo.SearchQueries (SearchedAt DESC)
        INCLUDE (NormalizedTerm)
        WHERE ResultCount = 0;

    /* Nightly rollup into SearchTermSummaries. */
    CREATE INDEX IX_SearchQueries_TermDate ON dbo.SearchQueries (NormalizedTerm, SearchedAt);
END
GO

/* ---------------------------------------------------------------------------
   Aggregated search terms.

   Performance justification: the auto-suggest dropdown fires on every keystroke
   (Search.txt §5, debounced) and the homepage renders trending searches. Both
   need "top terms matching this prefix" in single-digit milliseconds. A GROUP BY
   over SearchQueries — which grows by one row per search forever — cannot serve
   that path. Rebuilt nightly, and fully recomputable.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.SearchTermSummaries', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SearchTermSummaries
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        NormalizedTerm      NVARCHAR(300)   NOT NULL,
        DisplayTerm         NVARCHAR(300)   NOT NULL,
        SearchCount         INT             NOT NULL CONSTRAINT DF_SearchTermSummaries_SearchCount DEFAULT (0),
        ZeroResultCount     INT             NOT NULL CONSTRAINT DF_SearchTermSummaries_ZeroResultCount DEFAULT (0),
        ClickCount          INT             NOT NULL CONSTRAINT DF_SearchTermSummaries_ClickCount DEFAULT (0),
        ConversionCount     INT             NOT NULL CONSTRAINT DF_SearchTermSummaries_ConversionCount DEFAULT (0),
        /* Rolling 7-day count — what "trending" actually means. */
        RecentSearchCount   INT             NOT NULL CONSTRAINT DF_SearchTermSummaries_RecentSearchCount DEFAULT (0),
        LastSearchedOn      DATETIME2(3)    NULL,
        RecalculatedAt      DATETIME2(3)    NOT NULL CONSTRAINT DF_SearchTermSummaries_RecalculatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_SearchTermSummaries PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_SearchTermSummaries_Term UNIQUE (NormalizedTerm),
        CONSTRAINT CK_SearchTermSummaries_Counts
            CHECK (SearchCount >= 0 AND ZeroResultCount >= 0 AND ZeroResultCount <= SearchCount)
    );

    /* Type-ahead: prefix match, most searched first. */
    CREATE INDEX IX_SearchTermSummaries_Popular ON dbo.SearchTermSummaries (SearchCount DESC)
        INCLUDE (DisplayTerm);
    CREATE INDEX IX_SearchTermSummaries_Trending ON dbo.SearchTermSummaries (RecentSearchCount DESC)
        INCLUDE (DisplayTerm);
END
GO

/* ---------------------------------------------------------------------------
   Curated popular searches. Search.txt §11 says these are "Admin Managed" as
   well as analytics-driven — a festival term must be promotable before anyone
   has searched it. Kept apart from SearchTermSummaries so a nightly rebuild
   never erases an editorial choice.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.PopularSearches', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PopularSearches
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Term            NVARCHAR(300)   NOT NULL,
        /* Optional direct destination, e.g. straight to a collection page. */
        TargetRoutePath NVARCHAR(500)   NULL,
        /* Trending | Festival | Seasonal | Evergreen — Search.txt §11 */
        Placement       VARCHAR(32)     NOT NULL CONSTRAINT DF_PopularSearches_Placement DEFAULT ('Trending'),
        SortOrder       INT             NOT NULL CONSTRAINT DF_PopularSearches_SortOrder DEFAULT (0),
        StartOn         DATETIME2(3)    NULL,
        EndOn           DATETIME2(3)    NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_PopularSearches_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_PopularSearches_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_PopularSearches_IsDeleted DEFAULT (0),

        CONSTRAINT PK_PopularSearches PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_PopularSearches_Term UNIQUE (Term, Placement),
        /* A scheduled term must not end before it starts. */
        CONSTRAINT CK_PopularSearches_Window CHECK (EndOn IS NULL OR StartOn IS NULL OR EndOn > StartOn)
    );

    CREATE INDEX IX_PopularSearches_Render ON dbo.PopularSearches (Placement, SortOrder)
        WHERE IsActive = 1 AND IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Synonyms. Search.txt §23 lists them under enterprise features, but the
   handicraft domain needs them on day one: a shopper searching "diya" must find
   products titled "oil lamp". Bidirectional by default.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.SearchSynonyms', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SearchSynonyms
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Term            NVARCHAR(200)   NOT NULL,
        Synonym         NVARCHAR(200)   NOT NULL,
        IsBidirectional BIT             NOT NULL CONSTRAINT DF_SearchSynonyms_IsBidirectional DEFAULT (1),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_SearchSynonyms_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_SearchSynonyms_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_SearchSynonyms_IsDeleted DEFAULT (0),

        CONSTRAINT PK_SearchSynonyms PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_SearchSynonyms_Pair UNIQUE (Term, Synonym),
        CONSTRAINT CK_SearchSynonyms_NotSelf CHECK (Term <> Synonym)
    );

    CREATE INDEX IX_SearchSynonyms_Term ON dbo.SearchSynonyms (Term) WHERE IsActive = 1 AND IsDeleted = 0;
END
GO

/* =============================================================================
   Behavioural tracking
   ============================================================================= */

/* ---------------------------------------------------------------------------
   Product views. Feeds "Recently Viewed" (Product Detail.txt §18), the
   most-viewed report, and dbo.Products.ViewCount.

   Blog.txt §20 and Product Detail.txt both require that repeated refreshes
   inside a configurable window are not counted twice; the service enforces that
   before inserting, using (SessionId, ProductId, ViewedAt).
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ProductViewLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductViewLogs
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ProductId       INT             NOT NULL,
        VariantId       INT             NULL,
        CustomerId      INT             NULL,
        GuestToken      VARCHAR(64)     NULL,
        SessionId       VARCHAR(64)     NULL,
        /* Direct | Shop | Search | Category | Home | Blog | Wishlist | Email */
        Source          VARCHAR(32)     NULL,
        ReferrerPath    NVARCHAR(500)   NULL,
        /* Desktop | Tablet | Mobile */
        DeviceType      VARCHAR(16)     NULL,
        DwellMs         INT             NULL,
        ViewedAt        DATETIME2(3)    NOT NULL CONSTRAINT DF_ProductViewLogs_ViewedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_ProductViewLogs PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ProductViewLogs_Products FOREIGN KEY (ProductId)  REFERENCES dbo.Products (Id),
        CONSTRAINT FK_ProductViewLogs_Variants FOREIGN KEY (VariantId)  REFERENCES dbo.ProductVariants (Id),
        CONSTRAINT FK_ProductViewLogs_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id)
    );

    /* "Recently Viewed" for a signed-in shopper — covering, so no key lookup. */
    CREATE INDEX IX_ProductViewLogs_Customer ON dbo.ProductViewLogs (CustomerId, ViewedAt DESC)
        INCLUDE (ProductId)
        WHERE CustomerId IS NOT NULL;

    /* Same, for guests. */
    CREATE INDEX IX_ProductViewLogs_Guest ON dbo.ProductViewLogs (GuestToken, ViewedAt DESC)
        INCLUDE (ProductId)
        WHERE GuestToken IS NOT NULL;

    /* Product performance report and the dedup window check. */
    CREATE INDEX IX_ProductViewLogs_ProductDate ON dbo.ProductViewLogs (ProductId, ViewedAt DESC);
END
GO

/* ---------------------------------------------------------------------------
   Banner impressions and clicks. Banners.txt §14 needs views, clicks and CTR
   per banner, device and location. §25 proposes BannerImpressions and
   BannerClicks as separate tables; they would be column-identical, so one table
   with an EventType discriminator carries both and CTR becomes a single scan.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.BannerEvents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BannerEvents
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        BannerId        INT             NOT NULL,
        /* Impression | Click | Dismiss (popups) */
        EventType       VARCHAR(16)     NOT NULL,
        CustomerId      INT             NULL,
        GuestToken      VARCHAR(64)     NULL,
        SessionId       VARCHAR(64)     NULL,
        /* Where it was rendered — Banners.txt §7 display locations. */
        RoutePath       NVARCHAR(500)   NULL,
        DeviceType      VARCHAR(16)     NULL,
        /* Click only: where the CTA sent them. */
        TargetUrl       NVARCHAR(1000)  NULL,
        OccurredAt      DATETIME2(3)    NOT NULL CONSTRAINT DF_BannerEvents_OccurredAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_BannerEvents PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_BannerEvents_Banners   FOREIGN KEY (BannerId)   REFERENCES dbo.Banners (Id),
        CONSTRAINT FK_BannerEvents_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id),
        CONSTRAINT CK_BannerEvents_EventType CHECK (EventType IN ('Impression','Click','Dismiss'))
    );

    /* CTR per banner over a date range — the analytics screen's only query. */
    CREATE INDEX IX_BannerEvents_BannerDate ON dbo.BannerEvents (BannerId, EventType, OccurredAt);
    CREATE INDEX IX_BannerEvents_Date ON dbo.BannerEvents (OccurredAt DESC);
END
GO

/* ---------------------------------------------------------------------------
   Visitor sessions. Dashboard.txt §12 wants visitors, sessions, bounce rate,
   conversion rate and average session length. None of those can be computed
   from page views alone without a self-join per session on every dashboard
   load, so the session is materialised as its own row and closed by the
   analytics job.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.VisitorSessions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.VisitorSessions
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        SessionId           VARCHAR(64)     NOT NULL,
        CustomerId          INT             NULL,
        GuestToken          VARCHAR(64)     NULL,
        IsNewVisitor        BIT             NOT NULL CONSTRAINT DF_VisitorSessions_IsNewVisitor DEFAULT (1),
        StartedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_VisitorSessions_StartedAt DEFAULT (SYSUTCDATETIME()),
        LastActivityAt      DATETIME2(3)    NOT NULL CONSTRAINT DF_VisitorSessions_LastActivityAt DEFAULT (SYSUTCDATETIME()),
        EndedAt             DATETIME2(3)    NULL,
        DurationSeconds     INT             NULL,
        PageViewCount       INT             NOT NULL CONSTRAINT DF_VisitorSessions_PageViewCount DEFAULT (0),
        /* A single-page session. Stored, not derived, so the dashboard's bounce
           rate is a COUNT over an indexed bit rather than a HAVING clause. */
        IsBounce            BIT             NOT NULL CONSTRAINT DF_VisitorSessions_IsBounce DEFAULT (1),

        LandingRoutePath    NVARCHAR(500)   NULL,
        ExitRoutePath       NVARCHAR(500)   NULL,
        Referrer            NVARCHAR(1000)  NULL,
        /* Direct | Organic | Paid | Social | Email | Referral */
        TrafficSource       VARCHAR(32)     NULL,
        UtmSource           NVARCHAR(200)   NULL,
        UtmMedium           NVARCHAR(200)   NULL,
        UtmCampaign         NVARCHAR(200)   NULL,
        DeviceType          VARCHAR(16)     NULL,
        Browser             NVARCHAR(100)   NULL,
        OperatingSystem     NVARCHAR(100)   NULL,
        CountryCode         VARCHAR(2)      NULL,
        City                NVARCHAR(150)   NULL,
        IpAddress           VARCHAR(64)     NULL,

        /* Conversion. Set when this session produced an order — turns the
           conversion-rate card into a ratio of two indexed counts. */
        ConvertedOrderId    INT             NULL,
        ConvertedAt         DATETIME2(3)    NULL,

        CONSTRAINT PK_VisitorSessions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_VisitorSessions_SessionId UNIQUE (SessionId),
        CONSTRAINT FK_VisitorSessions_Customers FOREIGN KEY (CustomerId)       REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_VisitorSessions_Orders    FOREIGN KEY (ConvertedOrderId) REFERENCES dbo.Orders (Id),
        CONSTRAINT CK_VisitorSessions_PageViewCount CHECK (PageViewCount >= 0)
    );

    CREATE INDEX IX_VisitorSessions_Started ON dbo.VisitorSessions (StartedAt DESC)
        INCLUDE (IsNewVisitor, IsBounce, DurationSeconds, ConvertedOrderId);
    CREATE INDEX IX_VisitorSessions_Customer ON dbo.VisitorSessions (CustomerId, StartedAt DESC)
        WHERE CustomerId IS NOT NULL;
    /* Session close-out job. */
    CREATE INDEX IX_VisitorSessions_Open ON dbo.VisitorSessions (LastActivityAt) WHERE EndedAt IS NULL;
END
GO

/* ---------------------------------------------------------------------------
   Page views. Backs "Top Pages" and "Top Products Viewed" (Dashboard.txt §12),
   the CMS page-view counter, and blog article views (Blog.txt §16).
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.PageViewLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PageViewLogs
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        SessionId       VARCHAR(64)     NULL,
        CustomerId      INT             NULL,
        GuestToken      VARCHAR(64)     NULL,
        RoutePath       NVARCHAR(500)   NOT NULL,
        /* Home | Shop | Product | Category | Blog | CmsPage | Cart | Checkout |
           Account | Search — lets a report group without parsing the path. */
        PageType        VARCHAR(32)     NULL,
        EntityType      VARCHAR(64)     NULL,
        EntityId        INT             NULL,
        Title           NVARCHAR(300)   NULL,
        ReferrerPath    NVARCHAR(500)   NULL,
        DeviceType      VARCHAR(16)     NULL,
        DwellMs         INT             NULL,
        /* Blog.txt §16 reading progress / Static Pages §10 scroll depth. */
        ScrollDepthPct  TINYINT         NULL,
        ViewedAt        DATETIME2(3)    NOT NULL CONSTRAINT DF_PageViewLogs_ViewedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_PageViewLogs PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_PageViewLogs_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id),
        CONSTRAINT CK_PageViewLogs_ScrollDepth CHECK (ScrollDepthPct IS NULL OR ScrollDepthPct BETWEEN 0 AND 100)
    );

    CREATE INDEX IX_PageViewLogs_Date ON dbo.PageViewLogs (ViewedAt DESC) INCLUDE (RoutePath, PageType);
    CREATE INDEX IX_PageViewLogs_Session ON dbo.PageViewLogs (SessionId, ViewedAt);
    /* "Top Pages", and the per-entity view counters for blog and CMS. */
    CREATE INDEX IX_PageViewLogs_Entity ON dbo.PageViewLogs (EntityType, EntityId, ViewedAt DESC)
        WHERE EntityId IS NOT NULL;
END
GO

/* =============================================================================
   Daily rollups — the only two summary tables in the design
   ============================================================================= */

/* ---------------------------------------------------------------------------
   DailySalesSummaries.

   Performance justification (prompt §18 requires one):
     * Dashboard.txt §18 auto-refreshes the dashboard every ~5 minutes for every
       signed-in administrator. Each refresh needs total, today's and monthly
       sales plus a 12-month trend chart.
     * Reports.txt §17 drills Revenue -> Month -> Day -> Order, so day-grain
       aggregates are read directly, not just as a chart source.
   Computing those from dbo.Orders means aggregating the entire order history on
   every refresh. One row per day makes the trend chart a 365-row seek.

   Correctness: rebuilt from dbo.Orders / dbo.OrderItems / dbo.Refunds by the
   ReportAggregation job. It is a cache, never a source of truth — every figure
   here is recomputable, which is why there are no audit columns.

   Business rules encoded (Dashboard.txt §18):
     * Revenue counts completed orders only; cancelled orders are excluded.
     * Profit = Revenue - CostOfGoodsSold.
     * Returned orders reduce revenue once the refund is approved.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.DailySalesSummaries', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DailySalesSummaries
    (
        SummaryDate         DATE            NOT NULL,

        OrderCount          INT             NOT NULL CONSTRAINT DF_DailySalesSummaries_OrderCount DEFAULT (0),
        CompletedOrderCount INT             NOT NULL CONSTRAINT DF_DailySalesSummaries_CompletedOrderCount DEFAULT (0),
        CancelledOrderCount INT             NOT NULL CONSTRAINT DF_DailySalesSummaries_CancelledOrderCount DEFAULT (0),
        ReturnedOrderCount  INT             NOT NULL CONSTRAINT DF_DailySalesSummaries_ReturnedOrderCount DEFAULT (0),
        ItemsSold           INT             NOT NULL CONSTRAINT DF_DailySalesSummaries_ItemsSold DEFAULT (0),

        GrossSales          DECIMAL(18,2)   NOT NULL CONSTRAINT DF_DailySalesSummaries_GrossSales DEFAULT (0),
        DiscountTotal       DECIMAL(18,2)   NOT NULL CONSTRAINT DF_DailySalesSummaries_DiscountTotal DEFAULT (0),
        CouponDiscount      DECIMAL(18,2)   NOT NULL CONSTRAINT DF_DailySalesSummaries_CouponDiscount DEFAULT (0),
        OfferDiscount       DECIMAL(18,2)   NOT NULL CONSTRAINT DF_DailySalesSummaries_OfferDiscount DEFAULT (0),
        ShippingRevenue     DECIMAL(18,2)   NOT NULL CONSTRAINT DF_DailySalesSummaries_ShippingRevenue DEFAULT (0),
        TaxCollected        DECIMAL(18,2)   NOT NULL CONSTRAINT DF_DailySalesSummaries_TaxCollected DEFAULT (0),
        RefundTotal         DECIMAL(18,2)   NOT NULL CONSTRAINT DF_DailySalesSummaries_RefundTotal DEFAULT (0),
        /* Gross sales less discounts, refunds and tax. */
        NetSales            DECIMAL(18,2)   NOT NULL CONSTRAINT DF_DailySalesSummaries_NetSales DEFAULT (0),
        CostOfGoodsSold     DECIMAL(18,2)   NOT NULL CONSTRAINT DF_DailySalesSummaries_CostOfGoodsSold DEFAULT (0),
        GrossProfit         DECIMAL(18,2)   NOT NULL CONSTRAINT DF_DailySalesSummaries_GrossProfit DEFAULT (0),
        AverageOrderValue   DECIMAL(18,2)   NOT NULL CONSTRAINT DF_DailySalesSummaries_AverageOrderValue DEFAULT (0),

        NewCustomerCount    INT             NOT NULL CONSTRAINT DF_DailySalesSummaries_NewCustomerCount DEFAULT (0),
        ReturningCustomerCount INT          NOT NULL CONSTRAINT DF_DailySalesSummaries_ReturningCustomerCount DEFAULT (0),

        CodOrderCount       INT             NOT NULL CONSTRAINT DF_DailySalesSummaries_CodOrderCount DEFAULT (0),
        PrepaidOrderCount   INT             NOT NULL CONSTRAINT DF_DailySalesSummaries_PrepaidOrderCount DEFAULT (0),

        CurrencyCode        VARCHAR(3)      NOT NULL CONSTRAINT DF_DailySalesSummaries_CurrencyCode DEFAULT ('INR'),
        RecalculatedAt      DATETIME2(3)    NOT NULL CONSTRAINT DF_DailySalesSummaries_RecalculatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_DailySalesSummaries PRIMARY KEY CLUSTERED (SummaryDate),
        CONSTRAINT CK_DailySalesSummaries_Counts
            CHECK (OrderCount >= 0 AND CompletedOrderCount >= 0 AND CompletedOrderCount <= OrderCount)
    );
END
GO

/* ---------------------------------------------------------------------------
   DailyTrafficSummaries. Same justification, traffic side: Dashboard.txt §12
   renders visitors, sessions, bounce and conversion for a date range on every
   load. Rebuilt from VisitorSessions and PageViewLogs.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.DailyTrafficSummaries', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DailyTrafficSummaries
    (
        SummaryDate         DATE            NOT NULL,
        SessionCount        INT             NOT NULL CONSTRAINT DF_DailyTrafficSummaries_SessionCount DEFAULT (0),
        VisitorCount        INT             NOT NULL CONSTRAINT DF_DailyTrafficSummaries_VisitorCount DEFAULT (0),
        NewVisitorCount     INT             NOT NULL CONSTRAINT DF_DailyTrafficSummaries_NewVisitorCount DEFAULT (0),
        ReturningVisitorCount INT           NOT NULL CONSTRAINT DF_DailyTrafficSummaries_ReturningVisitorCount DEFAULT (0),
        PageViewCount       INT             NOT NULL CONSTRAINT DF_DailyTrafficSummaries_PageViewCount DEFAULT (0),
        BounceCount         INT             NOT NULL CONSTRAINT DF_DailyTrafficSummaries_BounceCount DEFAULT (0),
        BounceRate          DECIMAL(18,4)   NOT NULL CONSTRAINT DF_DailyTrafficSummaries_BounceRate DEFAULT (0),
        AverageSessionSeconds INT           NOT NULL CONSTRAINT DF_DailyTrafficSummaries_AverageSessionSeconds DEFAULT (0),
        ConvertedSessionCount INT           NOT NULL CONSTRAINT DF_DailyTrafficSummaries_ConvertedSessionCount DEFAULT (0),
        ConversionRate      DECIMAL(18,4)   NOT NULL CONSTRAINT DF_DailyTrafficSummaries_ConversionRate DEFAULT (0),
        CartCreatedCount    INT             NOT NULL CONSTRAINT DF_DailyTrafficSummaries_CartCreatedCount DEFAULT (0),
        CartAbandonedCount  INT             NOT NULL CONSTRAINT DF_DailyTrafficSummaries_CartAbandonedCount DEFAULT (0),
        SearchCount         INT             NOT NULL CONSTRAINT DF_DailyTrafficSummaries_SearchCount DEFAULT (0),
        ZeroResultSearchCount INT           NOT NULL CONSTRAINT DF_DailyTrafficSummaries_ZeroResultSearchCount DEFAULT (0),
        DesktopSessionCount INT             NOT NULL CONSTRAINT DF_DailyTrafficSummaries_DesktopSessionCount DEFAULT (0),
        MobileSessionCount  INT             NOT NULL CONSTRAINT DF_DailyTrafficSummaries_MobileSessionCount DEFAULT (0),
        TabletSessionCount  INT             NOT NULL CONSTRAINT DF_DailyTrafficSummaries_TabletSessionCount DEFAULT (0),
        RecalculatedAt      DATETIME2(3)    NOT NULL CONSTRAINT DF_DailyTrafficSummaries_RecalculatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_DailyTrafficSummaries PRIMARY KEY CLUSTERED (SummaryDate),
        CONSTRAINT CK_DailyTrafficSummaries_Rates
            CHECK (BounceRate BETWEEN 0 AND 1 AND ConversionRate BETWEEN 0 AND 1)
    );
END
GO

/* =============================================================================
   Report configuration and execution — Reports.txt §25
   ============================================================================= */

/* ---------------------------------------------------------------------------
   The catalogue of available reports. Held as data so a permission key and a
   default column set attach to each report without a code change.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ReportDefinitions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReportDefinitions
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        /* Sales | Profit | Customer | Inventory | Product | Tax | Payment |
           Order | Return | Search — Reports.txt §4-§12 */
        ReportCode          VARCHAR(64)     NOT NULL,
        Name                NVARCHAR(200)   NOT NULL,
        Category            VARCHAR(48)     NOT NULL,
        Description         NVARCHAR(500)   NULL,
        /* The stored procedure that produces it. */
        ProcedureName       VARCHAR(128)    NULL,
        /* Column and filter metadata the generic report screen renders from. */
        ColumnsJson         NVARCHAR(MAX)   NULL,
        DefaultFiltersJson  NVARCHAR(MAX)   NULL,
        /* Reports.txt §20: "Sensitive financial reports should be accessible
           only to authorized roles." Checked against the session key set. */
        PermissionKey       VARCHAR(128)    NULL,
        /* Reports.txt §20: large reports run asynchronously. */
        SupportsAsync       BIT             NOT NULL CONSTRAINT DF_ReportDefinitions_SupportsAsync DEFAULT (0),
        SortOrder           INT             NOT NULL CONSTRAINT DF_ReportDefinitions_SortOrder DEFAULT (0),
        IsSystem            BIT             NOT NULL CONSTRAINT DF_ReportDefinitions_IsSystem DEFAULT (1),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_ReportDefinitions_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_ReportDefinitions_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_ReportDefinitions_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ReportDefinitions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ReportDefinitions_Code UNIQUE (ReportCode)
    );
END
GO

/* A named filter set an administrator saved (Reports.txt §23 "Saved Reports"). */
IF OBJECT_ID(N'dbo.SavedReports', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SavedReports
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        ReportDefinitionId  INT             NOT NULL,
        Name                NVARCHAR(200)   NOT NULL,
        FiltersJson         NVARCHAR(MAX)   NULL,
        ColumnsJson         NVARCHAR(MAX)   NULL,
        SortJson            NVARCHAR(MAX)   NULL,
        OwnerAdminUserId    INT             NULL,
        /* Private to the owner unless shared with the whole back office. */
        IsShared            BIT             NOT NULL CONSTRAINT DF_SavedReports_IsShared DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_SavedReports_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_SavedReports_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_SavedReports_IsDeleted DEFAULT (0),

        CONSTRAINT PK_SavedReports PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_SavedReports_Definitions FOREIGN KEY (ReportDefinitionId) REFERENCES dbo.ReportDefinitions (Id),
        CONSTRAINT FK_SavedReports_Owners      FOREIGN KEY (OwnerAdminUserId)   REFERENCES dbo.AdminUsers (Id)
    );

    CREATE INDEX IX_SavedReports_Owner ON dbo.SavedReports (OwnerAdminUserId) WHERE IsDeleted = 0;
END
GO

/* Reports.txt §16 — daily / weekly / monthly / quarterly / yearly, emailed out. */
IF OBJECT_ID(N'dbo.ScheduledReports', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ScheduledReports
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        ReportDefinitionId  INT             NOT NULL,
        SavedReportId       INT             NULL,
        Name                NVARCHAR(200)   NOT NULL,
        /* Daily | Weekly | Monthly | Quarterly | Yearly */
        Frequency           VARCHAR(24)     NOT NULL,
        /* 1-7 for weekly, 1-31 for monthly. Null for daily. */
        DayOfWeek           TINYINT         NULL,
        DayOfMonth          TINYINT         NULL,
        RunAtTime           TIME(0)         NOT NULL CONSTRAINT DF_ScheduledReports_RunAtTime DEFAULT ('06:00:00'),
        TimeZoneId          NVARCHAR(100)   NOT NULL CONSTRAINT DF_ScheduledReports_TimeZoneId DEFAULT (N'India Standard Time'),
        /* Excel | Csv | Pdf */
        ExportFormat        VARCHAR(16)     NOT NULL CONSTRAINT DF_ScheduledReports_ExportFormat DEFAULT ('Excel'),
        FiltersJson         NVARCHAR(MAX)   NULL,
        NextRunOn           DATETIME2(3)    NULL,
        LastRunOn           DATETIME2(3)    NULL,
        LastRunStatus       VARCHAR(24)     NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_ScheduledReports_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_ScheduledReports_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_ScheduledReports_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ScheduledReports PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ScheduledReports_Definitions FOREIGN KEY (ReportDefinitionId) REFERENCES dbo.ReportDefinitions (Id),
        CONSTRAINT FK_ScheduledReports_Saved       FOREIGN KEY (SavedReportId)      REFERENCES dbo.SavedReports (Id),
        CONSTRAINT CK_ScheduledReports_Frequency
            CHECK (Frequency IN ('Daily','Weekly','Monthly','Quarterly','Yearly')),
        CONSTRAINT CK_ScheduledReports_Format CHECK (ExportFormat IN ('Excel','Csv','Pdf')),
        CONSTRAINT CK_ScheduledReports_DayOfWeek  CHECK (DayOfWeek  IS NULL OR DayOfWeek  BETWEEN 1 AND 7),
        CONSTRAINT CK_ScheduledReports_DayOfMonth CHECK (DayOfMonth IS NULL OR DayOfMonth BETWEEN 1 AND 31),
        /* A weekly schedule with no weekday would never fire. */
        CONSTRAINT CK_ScheduledReports_WeeklyHasDay CHECK (Frequency <> 'Weekly' OR DayOfWeek IS NOT NULL)
    );

    /* The scheduler's due query. */
    CREATE INDEX IX_ScheduledReports_NextRun ON dbo.ScheduledReports (NextRunOn)
        WHERE IsActive = 1 AND IsDeleted = 0;
END
GO

/* Reports.txt §16 recipients: Owner | Admin | Accountant, or any address. */
IF OBJECT_ID(N'dbo.ScheduledReportRecipients', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ScheduledReportRecipients
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        ScheduledReportId   INT             NOT NULL,
        AdminUserId         INT             NULL,
        Email               NVARCHAR(256)   NOT NULL,
        DisplayName         NVARCHAR(200)   NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_ScheduledReportRecipients_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,

        CONSTRAINT PK_ScheduledReportRecipients PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ScheduledReportRecipients_Email UNIQUE (ScheduledReportId, Email),
        CONSTRAINT FK_ScheduledReportRecipients_Reports FOREIGN KEY (ScheduledReportId) REFERENCES dbo.ScheduledReports (Id),
        CONSTRAINT FK_ScheduledReportRecipients_Admins  FOREIGN KEY (AdminUserId)       REFERENCES dbo.AdminUsers (Id)
    );
END
GO

/* ---------------------------------------------------------------------------
   Execution history. Covers Reports.txt §19 (report generated / exported /
   printed / scheduled / shared) and §20's asynchronous generation: a run row is
   created immediately, the file lands later, the UI polls Status.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ReportRuns', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReportRuns
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        ReportDefinitionId  INT             NOT NULL,
        SavedReportId       INT             NULL,
        ScheduledReportId   INT             NULL,
        /* Manual | Scheduled | Api */
        TriggerSource       VARCHAR(24)     NOT NULL CONSTRAINT DF_ReportRuns_TriggerSource DEFAULT ('Manual'),
        RequestedBy         INT             NULL,
        RequestedByName     NVARCHAR(200)   NULL,
        FiltersJson         NVARCHAR(MAX)   NULL,
        /* View | Excel | Csv | Pdf | Print | Email */
        OutputFormat        VARCHAR(16)     NOT NULL CONSTRAINT DF_ReportRuns_OutputFormat DEFAULT ('View'),
        /* 0 Queued, 1 Running, 2 Completed, 3 Failed, 4 Cancelled */
        Status              TINYINT         NOT NULL CONSTRAINT DF_ReportRuns_Status DEFAULT (0),
        StartedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_ReportRuns_StartedAt DEFAULT (SYSUTCDATETIME()),
        CompletedAt         DATETIME2(3)    NULL,
        DurationMs          INT             NULL,
        RowCountProduced    INT             NULL,
        FileUrl             NVARCHAR(1000)  NULL,
        FileSizeBytes       BIGINT          NULL,
        /* Generated exports are purged after this date. */
        ExpiresOn           DATETIME2(3)    NULL,
        ErrorMessage        NVARCHAR(2000)  NULL,

        CONSTRAINT PK_ReportRuns PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ReportRuns_Definitions FOREIGN KEY (ReportDefinitionId) REFERENCES dbo.ReportDefinitions (Id),
        CONSTRAINT FK_ReportRuns_Saved       FOREIGN KEY (SavedReportId)      REFERENCES dbo.SavedReports (Id),
        CONSTRAINT FK_ReportRuns_Scheduled   FOREIGN KEY (ScheduledReportId)  REFERENCES dbo.ScheduledReports (Id),
        CONSTRAINT FK_ReportRuns_Admins      FOREIGN KEY (RequestedBy)        REFERENCES dbo.AdminUsers (Id),
        CONSTRAINT CK_ReportRuns_Status CHECK (Status BETWEEN 0 AND 4)
    );

    CREATE INDEX IX_ReportRuns_Definition ON dbo.ReportRuns (ReportDefinitionId, StartedAt DESC);
    CREATE INDEX IX_ReportRuns_Queue ON dbo.ReportRuns (Status, StartedAt) WHERE Status IN (0,1);
    CREATE INDEX IX_ReportRuns_Requester ON dbo.ReportRuns (RequestedBy, StartedAt DESC);
END
GO
