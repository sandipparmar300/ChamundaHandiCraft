/* =============================================================================
   usp_Search_GetSuggestions  /  usp_Search_LogQuery  /  usp_Search_GetAnalytics
   -----------------------------------------------------------------------------
   Specs:
     Search.txt §5   the auto-suggest dropdown: products, categories, brands,
                     popular searches, recent searches
     Search.txt §10  last 10 searches, logged-in customers only
     Search.txt §11  popular searches: admin-curated and analytics-driven
     Search.txt §16  search analytics, zero-result tracking, click tracking
     Search.txt §20  published products only; case-insensitive partial matching

   Filed under Seo/ because the Search module has no folder of its own in
   02-StoredProcedures - search and SEO share the discovery surface, and
   SearchTermSummaries feeds the SEO keyword work.
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Search_GetSuggestions
    @Term           NVARCHAR(300),
    @CustomerId     INT = NULL,
    @MaxProducts    INT = 6,
    @MaxCategories  INT = 4,
    @MaxBrands      INT = 3,
    @MaxTerms       INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    SET @Term = NULLIF(LTRIM(RTRIM(ISNULL(@Term, N''))), N'');

    IF @Term IS NULL
    BEGIN
        /* Empty box: Search.txt §5 shows recent searches for a signed-in
           shopper and curated/trending terms for everyone else. */
        SELECT TOP (@MaxTerms)
               Term      = q.Term,
               Kind      = 'Recent'
        FROM  (SELECT DISTINCT TOP (@MaxTerms) sq.Term, sq.SearchedAt
               FROM   dbo.SearchQueries AS sq
               WHERE  sq.CustomerId = @CustomerId
                 AND  @CustomerId IS NOT NULL
               ORDER  BY sq.SearchedAt DESC) AS q
        ORDER BY q.SearchedAt DESC;

        SELECT TOP (@MaxTerms)
               Term       = ps.Term,
               RoutePath  = ps.TargetRoutePath,
               Kind       = 'Popular'
        FROM   dbo.PopularSearches AS ps
        WHERE  ps.IsActive = 1
          AND  ps.IsDeleted = 0
          AND  (ps.StartOn IS NULL OR ps.StartOn <= SYSUTCDATETIME())
          AND  (ps.EndOn   IS NULL OR ps.EndOn   >  SYSUTCDATETIME())
        ORDER  BY ps.SortOrder, ps.Id;

        RETURN;
    END

    DECLARE @Prefix NVARCHAR(302) = @Term + N'%';
    DECLARE @Infix  NVARCHAR(304) = N'%' + @Term + N'%';

    /* ---------------------------------------------------------------------
       Products. Published (Status = 1) and visible in search
       (Visibility 0 Everywhere or 1 SearchOnly) only - Search.txt §20.
       Ordered so an exact prefix match outranks a mid-word match, then by
       commercial signal.
       --------------------------------------------------------------------- */
    SELECT TOP (@MaxProducts)
        p.Id,
        p.Name,
        p.Slug,
        p.Sku,
        p.Price,
        p.Mrp,
        p.AverageRating,
        p.ReviewCount,
        ImageUrl = pm.Url,
        ImageAlt = pm.AltText,
        CategoryName = c.Name
    FROM   dbo.Products AS p
    LEFT JOIN dbo.Categories AS c ON c.Id = p.CategoryId
    OUTER APPLY (
        SELECT TOP (1) m.Url, m.AltText
        FROM   dbo.ProductMedia AS m
        WHERE  m.ProductId = p.Id AND m.IsDeleted = 0 AND m.MediaType = 0
        ORDER  BY m.IsPrimary DESC, m.SortOrder, m.Id
    ) AS pm
    WHERE  p.IsDeleted = 0
      AND  p.Status = 1
      AND  p.Visibility IN (0, 1)
      AND  (p.Name LIKE @Infix OR p.Sku LIKE @Prefix OR p.ProductCode LIKE @Prefix)
    ORDER  BY CASE WHEN p.Name LIKE @Prefix THEN 0 ELSE 1 END,
              p.IsBestseller DESC,
              p.SoldCount DESC,
              p.Name;

    -- Categories
    SELECT TOP (@MaxCategories)
        c.Id, c.Name, c.Slug, c.ProductCount, c.ImageUrl
    FROM   dbo.Categories AS c
    WHERE  c.IsDeleted = 0
      AND  c.IsActive = 1
      AND  c.Name LIKE @Infix
    ORDER  BY CASE WHEN c.Name LIKE @Prefix THEN 0 ELSE 1 END,
              c.ProductCount DESC, c.Name;

    -- Brands
    SELECT TOP (@MaxBrands)
        b.Id, b.BrandName, b.Slug, b.LogoUrl
    FROM   dbo.Brands AS b
    WHERE  b.IsDeleted = 0
      AND  b.IsActive = 1
      AND  b.BrandName LIKE @Infix
    ORDER  BY CASE WHEN b.BrandName LIKE @Prefix THEN 0 ELSE 1 END, b.BrandName;

    /* Matching search terms other shoppers used. Reads the summary table, not
       the raw log - that is the whole reason SearchTermSummaries exists. */
    SELECT TOP (@MaxTerms)
        Term        = s.DisplayTerm,
        SearchCount = s.SearchCount
    FROM   dbo.SearchTermSummaries AS s
    WHERE  s.NormalizedTerm LIKE @Prefix
      AND  s.ZeroResultCount < s.SearchCount     -- never suggest a dead end
    ORDER  BY s.SearchCount DESC, s.DisplayTerm;
END
GO


/* =============================================================================
   usp_Search_LogQuery
   -----------------------------------------------------------------------------
   Records one executed search. Called fire-and-forget after results are served
   so it never sits on the shopper's critical path.
   Search.txt §16 tracks keywords, zero-result searches and click-through.
   ============================================================================= */
GO

CREATE OR ALTER PROCEDURE dbo.usp_Search_LogQuery
    @Term               NVARCHAR(300),
    @ResultCount        INT,
    @CustomerId         INT             = NULL,
    @GuestToken         VARCHAR(64)     = NULL,
    @SessionId          VARCHAR(64)     = NULL,
    @Source             VARCHAR(32)     = 'Header',
    @AppliedFiltersJson NVARCHAR(MAX)   = NULL,
    @IpAddress          VARCHAR(64)     = NULL,
    @SearchQueryId      BIGINT          OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Term = LTRIM(RTRIM(ISNULL(@Term, N'')));

    IF @Term = N''
    BEGIN
        SET @SearchQueryId = NULL;
        RETURN;
    END

    /* Normalisation must match what SearchTermSummaries is keyed on: lowercase,
       trimmed, internal runs of whitespace collapsed to one space. */
    DECLARE @Normalized NVARCHAR(300) =
        LOWER(LTRIM(RTRIM(
            REPLACE(REPLACE(REPLACE(@Term, NCHAR(9), N' '), NCHAR(10), N' '), NCHAR(13), N' ')
        )));

    WHILE CHARINDEX(N'  ', @Normalized) > 0
        SET @Normalized = REPLACE(@Normalized, N'  ', N' ');

    INSERT INTO dbo.SearchQueries
        (Term, NormalizedTerm, CustomerId, GuestToken, SessionId, Source,
         ResultCount, AppliedFiltersJson, SearchedAt, IpAddress)
    VALUES
        (@Term, @Normalized, @CustomerId, @GuestToken, @SessionId, @Source,
         @ResultCount, @AppliedFiltersJson, SYSUTCDATETIME(), @IpAddress);

    SET @SearchQueryId = SCOPE_IDENTITY();

    /* Keep the summary current enough for type-ahead without waiting for the
       nightly rebuild. Cheap: one row touched per search. */
    MERGE dbo.SearchTermSummaries AS tgt
    USING (SELECT @Normalized AS NormalizedTerm) AS src
       ON tgt.NormalizedTerm = src.NormalizedTerm
    WHEN MATCHED THEN
        UPDATE SET SearchCount     = tgt.SearchCount + 1,
                   ZeroResultCount = tgt.ZeroResultCount + CASE WHEN @ResultCount = 0 THEN 1 ELSE 0 END,
                   LastSearchedOn  = SYSUTCDATETIME(),
                   RecalculatedAt  = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (NormalizedTerm, DisplayTerm, SearchCount, ZeroResultCount,
                LastSearchedOn, RecalculatedAt)
        VALUES (@Normalized, @Term, 1,
                CASE WHEN @ResultCount = 0 THEN 1 ELSE 0 END,
                SYSUTCDATETIME(), SYSUTCDATETIME());
END
GO


/* =============================================================================
   usp_Search_GetAnalytics
   -----------------------------------------------------------------------------
   Search.txt §16 / Reports.txt: top terms, zero-result terms, click-through and
   search-to-purchase conversion for a date range.
   ============================================================================= */
GO

CREATE OR ALTER PROCEDURE dbo.usp_Search_GetAnalytics
    @FromDate   DATE,
    @ToDate     DATE,
    @TopN       INT = 25
AS
BEGIN
    SET NOCOUNT ON;

    IF @FromDate IS NULL SET @FromDate = DATEADD(DAY, -29, CAST(SYSUTCDATETIME() AS DATE));
    IF @ToDate   IS NULL SET @ToDate   = CAST(SYSUTCDATETIME() AS DATE);

    DECLARE @From DATETIME2(3) = CAST(@FromDate AS DATETIME2(3));
    DECLARE @To   DATETIME2(3) = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME2(3)));

    -- 1. Headline
    SELECT
        TotalSearches       = COUNT(*),
        UniqueTerms         = COUNT(DISTINCT q.NormalizedTerm),
        ZeroResultSearches  = SUM(CASE WHEN q.ResultCount = 0 THEN 1 ELSE 0 END),
        ZeroResultPercent   = CASE WHEN COUNT(*) > 0
                                   THEN ROUND(100.0 * SUM(CASE WHEN q.ResultCount = 0 THEN 1 ELSE 0 END) / COUNT(*), 2)
                                   ELSE 0 END,
        ClickThroughPercent = CASE WHEN COUNT(*) > 0
                                   THEN ROUND(100.0 * SUM(CASE WHEN q.ClickedProductId IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2)
                                   ELSE 0 END,
        ConversionPercent   = CASE WHEN COUNT(*) > 0
                                   THEN ROUND(100.0 * SUM(CASE WHEN q.ConvertedOrderId IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2)
                                   ELSE 0 END
    FROM   dbo.SearchQueries AS q
    WHERE  q.SearchedAt >= @From AND q.SearchedAt < @To;

    -- 2. Top searched terms
    SELECT TOP (@TopN)
        Term            = MAX(q.Term),
        NormalizedTerm  = q.NormalizedTerm,
        SearchCount     = COUNT(*),
        AvgResultCount  = AVG(CAST(q.ResultCount AS DECIMAL(18,2))),
        ClickCount      = SUM(CASE WHEN q.ClickedProductId IS NOT NULL THEN 1 ELSE 0 END),
        ConversionCount = SUM(CASE WHEN q.ConvertedOrderId IS NOT NULL THEN 1 ELSE 0 END)
    FROM   dbo.SearchQueries AS q
    WHERE  q.SearchedAt >= @From AND q.SearchedAt < @To
    GROUP  BY q.NormalizedTerm
    ORDER  BY COUNT(*) DESC;

    /* 3. Zero-result terms. The most actionable output of the whole module:
          every row is either a missing product or a missing synonym. */
    SELECT TOP (@TopN)
        Term           = MAX(q.Term),
        NormalizedTerm = q.NormalizedTerm,
        SearchCount    = COUNT(*),
        LastSearchedOn = MAX(q.SearchedAt),
        /* Flags whether an admin has already mapped it away. */
        HasSynonym     = CAST(CASE WHEN EXISTS (
                              SELECT 1 FROM dbo.SearchSynonyms AS s
                              WHERE s.IsDeleted = 0 AND s.IsActive = 1
                                AND (s.Term = q.NormalizedTerm OR s.Synonym = q.NormalizedTerm))
                            THEN 1 ELSE 0 END AS BIT)
    FROM   dbo.SearchQueries AS q
    WHERE  q.SearchedAt >= @From AND q.SearchedAt < @To
      AND  q.ResultCount = 0
    GROUP  BY q.NormalizedTerm
    ORDER  BY COUNT(*) DESC;

    -- 4. Products most often reached through search
    SELECT TOP (@TopN)
        p.Id, p.Name, p.Slug, p.Sku,
        ClickCount      = COUNT(*),
        ConversionCount = SUM(CASE WHEN q.ConvertedOrderId IS NOT NULL THEN 1 ELSE 0 END)
    FROM   dbo.SearchQueries AS q
    JOIN   dbo.Products AS p ON p.Id = q.ClickedProductId
    WHERE  q.SearchedAt >= @From AND q.SearchedAt < @To
      AND  q.ClickedProductId IS NOT NULL
    GROUP  BY p.Id, p.Name, p.Slug, p.Sku
    ORDER  BY COUNT(*) DESC;
END
GO
