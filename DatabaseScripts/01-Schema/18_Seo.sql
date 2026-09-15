/* =============================================================================
   18_Seo.sql — centralised SEO metadata, redirects, sitemap, robots, audits
   -----------------------------------------------------------------------------
   Source specs:
     docs/Admin Flows/SEO.txt             (whole module; §26 recommends dedicated tables)
     docs/Customer Flows/ (every file)    (per-page "SEO Considerations" sections)

   Depends on: 06_Catalog, 07_Categories, 14_Content, 04_Identity.

   Design decision — one SEO store, not a column set per entity.
   SEO.txt §26 is explicit: "Create dedicated tables for SEO instead of
   scattering SEO data across modules", and the prompt's §16 says the same. That
   is why no table in 01-14 carries MetaTitle or MetaDescription.

   The key is RoutePath, not (EntityType, EntityId). The storefront asks
   "what are the meta tags for /p/jaipur-blue-pottery-vase?" — a single indexed
   lookup — and that question has an answer for routes that are not entities at
   all (/, /shop, /contact-us). EntityType/EntityId ride along as provenance so
   the Product screen can find and edit its own row, and so a slug change can
   update the route and write the 301 in the same transaction.

   Column names match ChamundaHandicraft.Helper SeoMetaGridItem and
   RedirectGridItem so the Dapper mapping needs no aliasing.
   ============================================================================= */

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------------
   SeoMetas — one row per public route.
   SEO.txt §21: "Every public page must have a unique SEO title and meta
   description" and "URLs must be unique, lowercase, and SEO-friendly".
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.SeoMetas', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SeoMetas
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        /* The storefront path this metadata serves, leading slash, lowercase,
           no query string: '/p/jaipur-blue-pottery-vase', '/c/home-decor', '/'. */
        RoutePath           NVARCHAR(500)   NOT NULL,
        /* Product | Category | Collection | Brand | Artisan | BlogPost |
           BlogCategory | CmsPage | Offer | Static — provenance, not the key. */
        EntityType          VARCHAR(64)     NOT NULL CONSTRAINT DF_SeoMetas_EntityType DEFAULT ('Static'),
        EntityId            INT             NULL,

        MetaTitle           NVARCHAR(300)   NULL,
        MetaDescription     NVARCHAR(500)   NULL,
        MetaKeywords        NVARCHAR(500)   NULL,
        /* Explicit override. When null the service emits the self-referencing
           canonical, which is SEO.txt §7 "Auto Generate". */
        CanonicalUrl        NVARCHAR(1000)  NULL,

        /* SEO.txt §20: admin, auth, checkout and cart must never be indexed.
           NoIndex is the single flag the <meta robots> tag and the sitemap
           builder both read — they can never disagree. */
        NoIndex             BIT             NOT NULL CONSTRAINT DF_SeoMetas_NoIndex DEFAULT (0),
        NoFollow            BIT             NOT NULL CONSTRAINT DF_SeoMetas_NoFollow DEFAULT (0),

        -- Open Graph (§12) and Twitter cards
        OgTitle             NVARCHAR(300)   NULL,
        OgDescription       NVARCHAR(500)   NULL,
        OgImageUrl          NVARCHAR(1000)  NULL,
        OgType              VARCHAR(48)     NOT NULL CONSTRAINT DF_SeoMetas_OgType DEFAULT ('website'),
        TwitterCard         VARCHAR(48)     NOT NULL CONSTRAINT DF_SeoMetas_TwitterCard DEFAULT ('summary_large_image'),
        TwitterImageUrl     NVARCHAR(1000)  NULL,

        /* Schema.org JSON-LD (§10). Stored rendered rather than assembled at
           request time so a Product page costs one read. */
        StructuredDataJson  NVARCHAR(MAX)   NULL,

        -- Sitemap participation (§5)
        IncludeInSitemap    BIT             NOT NULL CONSTRAINT DF_SeoMetas_IncludeInSitemap DEFAULT (1),
        /* always | hourly | daily | weekly | monthly | yearly | never */
        ChangeFrequency     VARCHAR(16)     NOT NULL CONSTRAINT DF_SeoMetas_ChangeFrequency DEFAULT ('weekly'),
        SitemapPriority     DECIMAL(3,2)    NOT NULL CONSTRAINT DF_SeoMetas_SitemapPriority DEFAULT (0.50),

        /* Cached result of the §14 validation sweep, so the SEO grid can filter
           "Missing Meta" without recomputing. Recalculated by the audit job. */
        LastAuditedOn       DATETIME2(3)    NULL,
        IssueCount          INT             NOT NULL CONSTRAINT DF_SeoMetas_IssueCount DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_SeoMetas_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_SeoMetas_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_SeoMetas_IsDeleted DEFAULT (0),

        CONSTRAINT PK_SeoMetas PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT CK_SeoMetas_Priority CHECK (SitemapPriority BETWEEN 0.00 AND 1.00),
        CONSTRAINT CK_SeoMetas_ChangeFrequency
            CHECK (ChangeFrequency IN ('always','hourly','daily','weekly','monthly','yearly','never')),
        /* A route must start at the site root. */
        CONSTRAINT CK_SeoMetas_RoutePath CHECK (RoutePath LIKE '/%')
    );

    /* The storefront's per-request lookup, and the §21 uniqueness rule. */
    CREATE UNIQUE INDEX UX_SeoMetas_RoutePath ON dbo.SeoMetas (RoutePath) WHERE IsDeleted = 0;

    /* Lets the Product / Category / Blog screens load and edit their own row. */
    CREATE UNIQUE INDEX UX_SeoMetas_Entity ON dbo.SeoMetas (EntityType, EntityId)
        WHERE EntityId IS NOT NULL AND IsDeleted = 0;

    /* Sitemap generation reads only indexable, included routes. */
    CREATE INDEX IX_SeoMetas_Sitemap ON dbo.SeoMetas (EntityType, RoutePath)
        INCLUDE (ChangeFrequency, SitemapPriority, UpdatedAt)
        WHERE IncludeInSitemap = 1 AND NoIndex = 0 AND IsDeleted = 0;

    /* SEO dashboard §3 "Missing Meta Titles / Descriptions". */
    CREATE INDEX IX_SeoMetas_Issues ON dbo.SeoMetas (IssueCount DESC, RoutePath)
        WHERE IssueCount > 0 AND IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Redirects. Referenced by name from 06_Catalog.sql: "Changing [Slug] must
   write a 301 into dbo.Redirects." SEO.txt §9 and §21 require 301 for renames
   so ranking is preserved.

   HitCount and LastHitOn are what let an administrator retire a redirect that
   nothing has followed in a year, rather than accumulating them forever.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Redirects', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Redirects
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        FromPath        NVARCHAR(500)   NOT NULL,
        ToPath          NVARCHAR(1000)  NOT NULL,
        /* 301 Permanent | 302 Temporary — SEO.txt §9. */
        StatusCode      INT             NOT NULL CONSTRAINT DF_Redirects_StatusCode DEFAULT (301),
        /* SlugChanged | ProductDeleted | CategoryMerged | Migration | Manual */
        Reason          VARCHAR(64)     NULL,
        Notes           NVARCHAR(500)   NULL,
        HitCount        INT             NOT NULL CONSTRAINT DF_Redirects_HitCount DEFAULT (0),
        LastHitOn       DATETIME2(3)    NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Redirects_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Redirects_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Redirects_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Redirects PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT CK_Redirects_StatusCode CHECK (StatusCode IN (301,302,307,308)),
        CONSTRAINT CK_Redirects_FromPath CHECK (FromPath LIKE '/%'),
        /* A redirect to itself is an infinite loop. */
        CONSTRAINT CK_Redirects_NotSelf CHECK (FromPath <> ToPath)
    );

    /* One active rule per source path; the 404 handler looks up by FromPath. */
    CREATE UNIQUE INDEX UX_Redirects_FromPath ON dbo.Redirects (FromPath) WHERE IsDeleted = 0;
    CREATE INDEX IX_Redirects_Active ON dbo.Redirects (FromPath) WHERE IsActive = 1 AND IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   404 log. SEO.txt §3 counts "Broken Links" and §19 offers "Delete Redirect";
   the useful workflow is the inverse — see what is 404ing and create a redirect
   from it. Aggregated by path rather than one row per hit, because the value is
   "this path is being requested 400 times a week", not each individual miss.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.NotFoundLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NotFoundLogs
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        Path            NVARCHAR(500)   NOT NULL,
        HitCount        INT             NOT NULL CONSTRAINT DF_NotFoundLogs_HitCount DEFAULT (1),
        FirstHitOn      DATETIME2(3)    NOT NULL CONSTRAINT DF_NotFoundLogs_FirstHitOn DEFAULT (SYSUTCDATETIME()),
        LastHitOn       DATETIME2(3)    NOT NULL CONSTRAINT DF_NotFoundLogs_LastHitOn DEFAULT (SYSUTCDATETIME()),
        LastReferrer    NVARCHAR(1000)  NULL,
        LastUserAgent   NVARCHAR(500)   NULL,
        /* Set once an administrator has created a redirect for this path, so it
           drops out of the "needs attention" grid without being deleted. */
        ResolvedByRedirectId INT        NULL,
        ResolvedOn      DATETIME2(3)    NULL,
        IsIgnored       BIT             NOT NULL CONSTRAINT DF_NotFoundLogs_IsIgnored DEFAULT (0),

        CONSTRAINT PK_NotFoundLogs PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_NotFoundLogs_Redirects FOREIGN KEY (ResolvedByRedirectId) REFERENCES dbo.Redirects (Id)
    );

    CREATE UNIQUE INDEX UX_NotFoundLogs_Path ON dbo.NotFoundLogs (Path);
    /* The admin grid: unresolved, noisiest first. */
    CREATE INDEX IX_NotFoundLogs_Unresolved ON dbo.NotFoundLogs (HitCount DESC, LastHitOn DESC)
        WHERE ResolvedOn IS NULL AND IsIgnored = 0;
END
GO

/* ---------------------------------------------------------------------------
   Sitemap entries. SEO.txt §5 regenerates the XML sitemap after any publish or
   delete. Materialised rather than computed on request because the sitemap
   spans products, categories, blog posts and CMS pages — a UNION over four
   large tables on every crawler request is the thing to avoid.

   Rebuilt wholesale by the SitemapRegeneration job; safe to truncate.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.SitemapEntries', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SitemapEntries
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        /* Absolute URL as written into the XML. */
        Loc             NVARCHAR(1000)  NOT NULL,
        RoutePath       NVARCHAR(500)   NOT NULL,
        EntityType      VARCHAR(64)     NOT NULL,
        EntityId        INT             NULL,
        LastModified    DATETIME2(3)    NULL,
        ChangeFrequency VARCHAR(16)     NOT NULL CONSTRAINT DF_SitemapEntries_ChangeFrequency DEFAULT ('weekly'),
        Priority        DECIMAL(3,2)    NOT NULL CONSTRAINT DF_SitemapEntries_Priority DEFAULT (0.50),
        /* Sitemaps are capped at 50,000 URLs, so large catalogues shard into
           sitemap-products-1.xml, -2.xml and an index file. */
        SitemapFile     VARCHAR(128)    NOT NULL CONSTRAINT DF_SitemapEntries_SitemapFile DEFAULT ('sitemap.xml'),
        /* Image and video sitemap extensions (§24). */
        ImageUrl        NVARCHAR(1000)  NULL,
        ImageCaption    NVARCHAR(300)   NULL,
        GeneratedAt     DATETIME2(3)    NOT NULL CONSTRAINT DF_SitemapEntries_GeneratedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_SitemapEntries PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT CK_SitemapEntries_Priority CHECK (Priority BETWEEN 0.00 AND 1.00)
    );

    CREATE UNIQUE INDEX UX_SitemapEntries_Loc ON dbo.SitemapEntries (Loc);
    CREATE INDEX IX_SitemapEntries_File ON dbo.SitemapEntries (SitemapFile, Id);
END
GO

/* Record of each generation run — SEO.txt §5 statuses Generated | Pending | Failed. */
IF OBJECT_ID(N'dbo.SitemapRuns', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SitemapRuns
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        StartedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_SitemapRuns_StartedAt DEFAULT (SYSUTCDATETIME()),
        CompletedAt     DATETIME2(3)    NULL,
        Status          VARCHAR(24)     NOT NULL CONSTRAINT DF_SitemapRuns_Status DEFAULT ('Pending'),
        UrlCount        INT             NOT NULL CONSTRAINT DF_SitemapRuns_UrlCount DEFAULT (0),
        FileCount       INT             NOT NULL CONSTRAINT DF_SitemapRuns_FileCount DEFAULT (0),
        TriggeredBy     INT             NULL,
        /* Manual | Publish | Scheduled */
        TriggerSource   VARCHAR(32)     NOT NULL CONSTRAINT DF_SitemapRuns_TriggerSource DEFAULT ('Scheduled'),
        ErrorMessage    NVARCHAR(2000)  NULL,

        CONSTRAINT PK_SitemapRuns PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT CK_SitemapRuns_Status CHECK (Status IN ('Pending','Running','Generated','Failed'))
    );

    CREATE INDEX IX_SitemapRuns_Started ON dbo.SitemapRuns (StartedAt DESC);
END
GO

/* ---------------------------------------------------------------------------
   robots.txt as data. SEO.txt §6 wants view / edit / preview / publish /
   restore-default with validation — which means the rules have to be rows, not
   a file on disk that no environment shares.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.RobotsRules', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RobotsRules
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        UserAgent       VARCHAR(128)    NOT NULL CONSTRAINT DF_RobotsRules_UserAgent DEFAULT ('*'),
        /* Allow | Disallow | Crawl-delay | Sitemap */
        Directive       VARCHAR(24)     NOT NULL,
        Value           NVARCHAR(500)   NOT NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_RobotsRules_SortOrder DEFAULT (0),
        /* Seeded defaults (/admin/, /checkout/, /cart/, /login/) cannot be
           deleted — SEO.txt §21 requires them. */
        IsSystem        BIT             NOT NULL CONSTRAINT DF_RobotsRules_IsSystem DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_RobotsRules_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_RobotsRules_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_RobotsRules_IsDeleted DEFAULT (0),

        CONSTRAINT PK_RobotsRules PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_RobotsRules_Rule UNIQUE (UserAgent, Directive, Value),
        CONSTRAINT CK_RobotsRules_Directive CHECK (Directive IN ('Allow','Disallow','Crawl-delay','Sitemap'))
    );

    CREATE INDEX IX_RobotsRules_Render ON dbo.RobotsRules (UserAgent, SortOrder)
        WHERE IsActive = 1 AND IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   SEO audits. SEO.txt §14 lists the checks (missing title, duplicate canonical,
   missing H1, low word count, broken link ...). A run header plus one finding
   per problem lets the dashboard show a trend rather than only "now".
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.SeoAuditRuns', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SeoAuditRuns
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        StartedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_SeoAuditRuns_StartedAt DEFAULT (SYSUTCDATETIME()),
        CompletedAt     DATETIME2(3)    NULL,
        Status          VARCHAR(24)     NOT NULL CONSTRAINT DF_SeoAuditRuns_Status DEFAULT ('Running'),
        PagesScanned    INT             NOT NULL CONSTRAINT DF_SeoAuditRuns_PagesScanned DEFAULT (0),
        IssuesFound     INT             NOT NULL CONSTRAINT DF_SeoAuditRuns_IssuesFound DEFAULT (0),
        /* 0-100 headline number on the SEO dashboard. */
        SeoScore        DECIMAL(5,2)    NULL,
        TriggeredBy     INT             NULL,
        ErrorMessage    NVARCHAR(2000)  NULL,

        CONSTRAINT PK_SeoAuditRuns PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT CK_SeoAuditRuns_Status CHECK (Status IN ('Running','Completed','Failed')),
        CONSTRAINT CK_SeoAuditRuns_Score CHECK (SeoScore IS NULL OR SeoScore BETWEEN 0 AND 100)
    );

    CREATE INDEX IX_SeoAuditRuns_Started ON dbo.SeoAuditRuns (StartedAt DESC);
END
GO

IF OBJECT_ID(N'dbo.SeoAuditFindings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SeoAuditFindings
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        AuditRunId      INT             NOT NULL,
        SeoMetaId       INT             NULL,
        RoutePath       NVARCHAR(500)   NOT NULL,
        /* MissingMetaTitle | LongMetaTitle | ShortMetaTitle | MissingMetaDescription |
           DuplicateMetaTitle | DuplicateCanonical | MissingCanonical | LongUrl |
           BrokenLink | MissingH1 | MultipleH1 | LowWordCount | MissingSchema |
           MissingAltText — SEO.txt §14 */
        IssueCode       VARCHAR(64)     NOT NULL,
        /* 0 Error, 1 Warning, 2 Info */
        Severity        TINYINT         NOT NULL CONSTRAINT DF_SeoAuditFindings_Severity DEFAULT (1),
        Detail          NVARCHAR(1000)  NULL,
        DetectedAt      DATETIME2(3)    NOT NULL CONSTRAINT DF_SeoAuditFindings_DetectedAt DEFAULT (SYSUTCDATETIME()),
        ResolvedAt      DATETIME2(3)    NULL,

        CONSTRAINT PK_SeoAuditFindings PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_SeoAuditFindings_Runs  FOREIGN KEY (AuditRunId) REFERENCES dbo.SeoAuditRuns (Id),
        CONSTRAINT FK_SeoAuditFindings_Metas FOREIGN KEY (SeoMetaId)  REFERENCES dbo.SeoMetas (Id),
        CONSTRAINT CK_SeoAuditFindings_Severity CHECK (Severity IN (0,1,2))
    );

    CREATE INDEX IX_SeoAuditFindings_Run ON dbo.SeoAuditFindings (AuditRunId, Severity, IssueCode);
    CREATE INDEX IX_SeoAuditFindings_Route ON dbo.SeoAuditFindings (RoutePath) WHERE ResolvedAt IS NULL;
END
GO

/* ---------------------------------------------------------------------------
   Broken links found by the crawler (§14, §24 "Broken link crawler").
   Separate from SeoAuditFindings because a broken link is a (source, target)
   pair — the same dead target is usually reached from many pages.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.SeoBrokenLinks', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SeoBrokenLinks
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        SourceRoutePath NVARCHAR(500)   NOT NULL,
        TargetUrl       NVARCHAR(1000)  NOT NULL,
        IsExternal      BIT             NOT NULL CONSTRAINT DF_SeoBrokenLinks_IsExternal DEFAULT (0),
        HttpStatusCode  INT             NULL,
        LinkText        NVARCHAR(300)   NULL,
        FirstDetectedOn DATETIME2(3)    NOT NULL CONSTRAINT DF_SeoBrokenLinks_FirstDetectedOn DEFAULT (SYSUTCDATETIME()),
        LastCheckedOn   DATETIME2(3)    NOT NULL CONSTRAINT DF_SeoBrokenLinks_LastCheckedOn DEFAULT (SYSUTCDATETIME()),
        ResolvedOn      DATETIME2(3)    NULL,
        IsIgnored       BIT             NOT NULL CONSTRAINT DF_SeoBrokenLinks_IsIgnored DEFAULT (0),

        CONSTRAINT PK_SeoBrokenLinks PRIMARY KEY CLUSTERED (Id)
    );

    CREATE UNIQUE INDEX UX_SeoBrokenLinks_Pair ON dbo.SeoBrokenLinks (SourceRoutePath, TargetUrl);
    CREATE INDEX IX_SeoBrokenLinks_Open ON dbo.SeoBrokenLinks (LastCheckedOn DESC)
        WHERE ResolvedOn IS NULL AND IsIgnored = 0;
END
GO

/* ---------------------------------------------------------------------------
   Keyword rankings. SEO.txt §15/§24 place Search Console and Bing Webmaster in
   the future set, but the table is cheap and the shape does not change when the
   integration lands — clicks, impressions, CTR and average position per keyword
   per day is what both APIs return.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.SeoKeywords', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SeoKeywords
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Keyword         NVARCHAR(300)   NOT NULL,
        /* The page we intend to rank for it; null until mapped. */
        TargetRoutePath NVARCHAR(500)   NULL,
        /* Manual watchlist entry vs discovered from Search Console. */
        IsTracked       BIT             NOT NULL CONSTRAINT DF_SeoKeywords_IsTracked DEFAULT (1),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_SeoKeywords_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_SeoKeywords_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_SeoKeywords_IsDeleted DEFAULT (0),

        CONSTRAINT PK_SeoKeywords PRIMARY KEY CLUSTERED (Id)
    );

    CREATE UNIQUE INDEX UX_SeoKeywords_Keyword ON dbo.SeoKeywords (Keyword) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.SeoKeywordRankings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SeoKeywordRankings
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        SeoKeywordId    INT             NOT NULL,
        /* Google | Bing */
        SearchEngine    VARCHAR(24)     NOT NULL CONSTRAINT DF_SeoKeywordRankings_SearchEngine DEFAULT ('Google'),
        CapturedOn      DATE            NOT NULL,
        Clicks          INT             NOT NULL CONSTRAINT DF_SeoKeywordRankings_Clicks DEFAULT (0),
        Impressions     INT             NOT NULL CONSTRAINT DF_SeoKeywordRankings_Impressions DEFAULT (0),
        Ctr             DECIMAL(18,4)   NOT NULL CONSTRAINT DF_SeoKeywordRankings_Ctr DEFAULT (0),
        AveragePosition DECIMAL(18,4)   NULL,
        RoutePath       NVARCHAR(500)   NULL,

        CONSTRAINT PK_SeoKeywordRankings PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_SeoKeywordRankings_Keywords FOREIGN KEY (SeoKeywordId) REFERENCES dbo.SeoKeywords (Id),
        /* One row per keyword per engine per day — re-import must not duplicate. */
        CONSTRAINT UQ_SeoKeywordRankings_Day UNIQUE (SeoKeywordId, SearchEngine, CapturedOn),
        CONSTRAINT CK_SeoKeywordRankings_Counts CHECK (Clicks >= 0 AND Impressions >= 0)
    );

    CREATE INDEX IX_SeoKeywordRankings_Date ON dbo.SeoKeywordRankings (CapturedOn DESC, Clicks DESC);
END
GO
