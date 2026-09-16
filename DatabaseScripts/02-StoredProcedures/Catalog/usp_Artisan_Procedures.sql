/* =============================================================================
   usp_Artisan_Procedures.sql
   -----------------------------------------------------------------------------
   Stored procedures for Module 03 - Artisans.
   Tables: dbo.Artisans
   ============================================================================= */

SET NOCOUNT ON;
GO

-- 1. GridList
CREATE OR ALTER PROCEDURE dbo.usp_Artisan_GridList
    @SearchText             NVARCHAR(200)   = NULL,
    @IsActive               BIT             = NULL,
    @IsGiTagged             BIT             = NULL,
    @SortColumn             VARCHAR(64)     = 'CreatedAt',
    @SortOrder              VARCHAR(4)      = 'DESC',
    @PageSize               INT             = 25,
    @PageIndex              INT             = 1,
    @TotalRecords           INT             OUTPUT,
    @TotalFilteredRecords   INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageSize  IS NULL OR @PageSize  < 1 SET @PageSize  = 25;
    IF @PageIndex IS NULL OR @PageIndex < 1 SET @PageIndex = 1;
    IF @SortOrder IS NULL OR @SortOrder NOT IN ('ASC','DESC') SET @SortOrder = 'DESC';

    SET @SearchText = NULLIF(LTRIM(RTRIM(ISNULL(@SearchText, N''))), N'');

    SELECT @TotalRecords = COUNT(*)
    FROM   dbo.Artisans
    WHERE  IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT  a.Id,
                a.Name,
                a.Slug,
                a.Craft,
                a.Cluster,
                a.PhotoUrl,
                a.AverageRating,
                a.WorkingSinceYear,
                a.PartnerSinceYear,
                a.ApprenticesTrained,
                a.IsGiTagged,
                a.IsActive,
                a.CreatedAt,
                a.UpdatedAt,
                ProductCount = (SELECT COUNT(1) FROM dbo.Products p WHERE p.ArtisanId = a.Id AND p.IsDeleted = 0)
        FROM    dbo.Artisans AS a
        WHERE   a.IsDeleted = 0
          AND  (@IsActive   IS NULL OR a.IsActive   = @IsActive)
          AND  (@IsGiTagged IS NULL OR a.IsGiTagged = @IsGiTagged)
          AND  (@SearchText IS NULL
                OR a.Name    LIKE N'%' + @SearchText + N'%'
                OR a.Craft   LIKE N'%' + @SearchText + N'%'
                OR a.Cluster LIKE N'%' + @SearchText + N'%'
                OR a.Slug    LIKE '%' + @SearchText + '%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT  a.Id,
                a.Name,
                a.Slug,
                a.Craft,
                a.Cluster,
                a.PhotoUrl,
                a.AverageRating,
                a.WorkingSinceYear,
                a.PartnerSinceYear,
                a.ApprenticesTrained,
                a.IsGiTagged,
                a.IsActive,
                a.CreatedAt,
                a.UpdatedAt,
                ProductCount = (SELECT COUNT(1) FROM dbo.Products p WHERE p.ArtisanId = a.Id AND p.IsDeleted = 0)
        FROM    dbo.Artisans AS a
        WHERE   a.IsDeleted = 0
          AND  (@IsActive   IS NULL OR a.IsActive   = @IsActive)
          AND  (@IsGiTagged IS NULL OR a.IsGiTagged = @IsGiTagged)
          AND  (@SearchText IS NULL
                OR a.Name    LIKE N'%' + @SearchText + N'%'
                OR a.Craft   LIKE N'%' + @SearchText + N'%'
                OR a.Cluster LIKE N'%' + @SearchText + N'%'
                OR a.Slug    LIKE '%' + @SearchText + '%')
    )
    SELECT  Id,
            Name,
            Slug,
            Craft,
            Cluster,
            PhotoUrl,
            AverageRating,
            WorkingSinceYear,
            PartnerSinceYear,
            ApprenticesTrained,
            IsGiTagged,
            IsActive,
            CreatedAt,
            UpdatedAt,
            ProductCount
    FROM    Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Name' THEN Name END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Name' THEN Name END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Craft' THEN Craft END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Craft' THEN Craft END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Cluster' THEN Cluster END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Cluster' THEN Cluster END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'ProductCount' THEN ProductCount END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'ProductCount' THEN ProductCount END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CreatedAt' THEN CreatedAt END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CreatedAt' THEN CreatedAt END DESC,
        Id DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- Synonym for generic CRUD convention
CREATE OR ALTER PROCEDURE dbo.GridList_Artisan
    @SearchText             NVARCHAR(200)   = NULL,
    @IsActive               BIT             = NULL,
    @IsGiTagged             BIT             = NULL,
    @SortColumn             VARCHAR(64)     = 'CreatedAt',
    @SortOrder              VARCHAR(4)      = 'DESC',
    @PageSize               INT             = 25,
    @PageIndex              INT             = 1,
    @TotalRecords           INT             OUTPUT,
    @TotalFilteredRecords   INT             OUTPUT
AS
BEGIN
    EXEC dbo.usp_Artisan_GridList
        @SearchText           = @SearchText,
        @IsActive             = @IsActive,
        @IsGiTagged           = @IsGiTagged,
        @SortColumn           = @SortColumn,
        @SortOrder            = @SortOrder,
        @PageSize             = @PageSize,
        @PageIndex            = @PageIndex,
        @TotalRecords         = @TotalRecords OUTPUT,
        @TotalFilteredRecords = @TotalFilteredRecords OUTPUT;
END
GO

-- 2. GetById
CREATE OR ALTER PROCEDURE dbo.usp_Artisan_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  a.Id,
            a.Name,
            a.Slug,
            a.CraftId,
            a.Craft,
            a.Cluster,
            a.Story,
            a.PhotoMediaId,
            a.PhotoUrl,
            a.CoverMediaId,
            a.CoverUrl,
            a.VideoUrl,
            a.CityId,
            a.StateId,
            a.WorkingSinceYear,
            a.PartnerSinceYear,
            a.ApprenticesTrained,
            a.IsGiTagged,
            a.AverageRating,
            a.ProductCount,
            a.IsActive,
            a.CreatedAt,
            a.CreatedBy,
            a.UpdatedAt,
            a.UpdatedBy
    FROM    dbo.Artisans AS a
    WHERE   a.Id = @Id AND a.IsDeleted = 0;
END
GO

-- 3. Save (Insert / Update)
CREATE OR ALTER PROCEDURE dbo.usp_Artisan_Save
    @Id                 INT             = 0,
    @Name               NVARCHAR(200),
    @Slug               VARCHAR(220)    = NULL,
    @Craft              NVARCHAR(200),
    @Cluster            NVARCHAR(200),
    @Story              NVARCHAR(MAX)   = NULL,
    @PhotoUrl           NVARCHAR(1000)  = NULL,
    @CoverUrl           NVARCHAR(1000)  = NULL,
    @VideoUrl           NVARCHAR(1000)  = NULL,
    @WorkingSinceYear   INT             = NULL,
    @PartnerSinceYear   INT             = NULL,
    @ApprenticesTrained INT             = NULL,
    @IsGiTagged         BIT             = 0,
    @IsActive           BIT             = 1,
    @AdminUserId        INT             = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Generate slug if empty
    IF @Slug IS NULL OR LTRIM(RTRIM(@Slug)) = ''
    BEGIN
        SET @Slug = LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@Name)), ' ', '-'), '&', 'and'), '''', ''));
    END

    -- Ensure unique slug
    IF EXISTS (SELECT 1 FROM dbo.Artisans WHERE Slug = @Slug AND Id <> @Id AND IsDeleted = 0)
    BEGIN
        SET @Slug = @Slug + '-' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS VARCHAR(10));
    END

    IF @Id > 0
    BEGIN
        UPDATE dbo.Artisans
        SET    Name               = @Name,
               Slug               = @Slug,
               Craft              = @Craft,
               Cluster            = @Cluster,
               Story              = @Story,
               PhotoUrl           = ISNULL(@PhotoUrl, PhotoUrl),
               CoverUrl           = ISNULL(@CoverUrl, CoverUrl),
               VideoUrl           = @VideoUrl,
               WorkingSinceYear   = @WorkingSinceYear,
               PartnerSinceYear   = @PartnerSinceYear,
               ApprenticesTrained = @ApprenticesTrained,
               IsGiTagged         = @IsGiTagged,
               IsActive           = @IsActive,
               UpdatedAt          = SYSUTCDATETIME(),
               UpdatedBy          = @AdminUserId
        WHERE  Id = @Id AND IsDeleted = 0;

        SELECT @Id AS Id;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.Artisans
        (
            Name, Slug, Craft, Cluster, Story, PhotoUrl, CoverUrl, VideoUrl,
            WorkingSinceYear, PartnerSinceYear, ApprenticesTrained, IsGiTagged,
            IsActive, CreatedAt, CreatedBy
        )
        VALUES
        (
            @Name, @Slug, @Craft, @Cluster, @Story, @PhotoUrl, @CoverUrl, @VideoUrl,
            @WorkingSinceYear, @PartnerSinceYear, @ApprenticesTrained, @IsGiTagged,
            @IsActive, SYSUTCDATETIME(), @AdminUserId
        );

        SELECT SCOPE_IDENTITY() AS Id;
    END
END
GO

-- 4. Delete (Soft Delete)
CREATE OR ALTER PROCEDURE dbo.usp_Artisan_Delete
    @Id          INT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Artisans
    SET    IsDeleted = 1,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  Id = @Id;

    SELECT CAST(1 AS BIT) AS Success;
END
GO

-- 5. UpdateStatus
CREATE OR ALTER PROCEDURE dbo.usp_Artisan_UpdateStatus
    @Id          INT,
    @IsActive    BIT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Artisans
    SET    IsActive  = @IsActive,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  Id = @Id AND IsDeleted = 0;

    SELECT CAST(1 AS BIT) AS Success;
END
GO

-- 6. Lookup
CREATE OR ALTER PROCEDURE dbo.usp_Artisan_GetLookup
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  Id,
            Name = Name + ' (' + Craft + ' - ' + Cluster + ')'
    FROM    dbo.Artisans
    WHERE   IsActive = 1 AND IsDeleted = 0
    ORDER   BY Name ASC;
END
GO
