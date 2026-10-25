/* =============================================================================
   usp_Banner_Procedures.sql
   Stored procedures for Banners:
     1. dbo.usp_Banner_GridList
     2. dbo.usp_Banner_GetById
     3. dbo.usp_Banner_Save
     4. dbo.usp_Banner_Delete
     5. dbo.usp_Banner_UpdateStatus
   ============================================================================= */

SET NOCOUNT ON;
GO

/* 1. GridList */
CREATE OR ALTER PROCEDURE dbo.usp_Banner_GridList
    @SearchText           NVARCHAR(200)   = NULL,
    @IsActive             BIT             = NULL,
    @SortColumn           VARCHAR(64)     = 'CreatedAt',
    @SortOrder            VARCHAR(4)      = 'DESC',
    @PageSize             INT             = 25,
    @PageIndex            INT             = 1,
    @TotalRecords         INT             OUTPUT,
    @TotalFilteredRecords INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageSize  IS NULL OR @PageSize  < 1 SET @PageSize  = 25;
    IF @PageIndex IS NULL OR @PageIndex < 1 SET @PageIndex = 1;
    IF @SortOrder IS NULL OR @SortOrder NOT IN ('ASC','DESC') SET @SortOrder = 'DESC';
    SET @SearchText = NULLIF(LTRIM(RTRIM(ISNULL(@SearchText, N''))), N'');

    SELECT @TotalRecords = COUNT(*) FROM dbo.Banners WHERE IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT
            b.Id,
            b.Placement,
            b.Eyebrow,
            b.Heading,
            b.SubHeading,
            b.ImageUrl,
            b.MobileImageUrl,
            b.ImageAlt,
            b.PrimaryCtaLabel,
            b.PrimaryCtaUrl,
            b.SecondaryCtaLabel,
            b.SecondaryCtaUrl,
            b.StartsOn,
            b.EndsOn,
            b.SortOrder,
            b.Status,
            b.ImpressionCount,
            b.ClickCount,
            b.CreatedAt,
            b.UpdatedAt,
            b.IsActive
        FROM dbo.Banners b
        WHERE b.IsDeleted = 0
          AND (@IsActive IS NULL OR b.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR b.Heading LIKE N'%' + @SearchText + N'%'
               OR b.SubHeading LIKE N'%' + @SearchText + N'%'
               OR b.Eyebrow LIKE N'%' + @SearchText + N'%'
               OR b.ImageAlt LIKE N'%' + @SearchText + N'%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT
            b.Id,
            b.Placement,
            b.Eyebrow,
            b.Heading,
            b.SubHeading,
            b.ImageUrl,
            b.MobileImageUrl,
            b.ImageAlt,
            b.PrimaryCtaLabel,
            b.PrimaryCtaUrl,
            b.SecondaryCtaLabel,
            b.SecondaryCtaUrl,
            b.StartsOn,
            b.EndsOn,
            b.SortOrder,
            b.Status,
            b.ImpressionCount,
            b.ClickCount,
            b.CreatedAt,
            b.UpdatedAt,
            b.IsActive
        FROM dbo.Banners b
        WHERE b.IsDeleted = 0
          AND (@IsActive IS NULL OR b.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR b.Heading LIKE N'%' + @SearchText + N'%'
               OR b.SubHeading LIKE N'%' + @SearchText + N'%'
               OR b.Eyebrow LIKE N'%' + @SearchText + N'%'
               OR b.ImageAlt LIKE N'%' + @SearchText + N'%')
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Heading'   THEN Heading END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Heading'   THEN Heading END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Placement' THEN Placement END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Placement' THEN Placement END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'SortOrder' THEN SortOrder END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'SortOrder' THEN SortOrder END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CreatedAt' THEN CreatedAt END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CreatedAt' THEN CreatedAt END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

/* 2. GetById */
CREATE OR ALTER PROCEDURE dbo.usp_Banner_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        b.Id,
        b.Placement,
        b.Eyebrow,
        b.Heading,
        Title = b.Heading,
        b.SubHeading,
        Subtitle = b.SubHeading,
        b.ImageUrl,
        b.MobileImageUrl,
        b.ImageAlt,
        b.PrimaryCtaLabel,
        b.PrimaryCtaUrl,
        b.SecondaryCtaLabel,
        b.SecondaryCtaUrl,
        b.CategoryId,
        b.StartsOn,
        b.EndsOn,
        b.SortOrder,
        b.Status,
        b.ImpressionCount,
        b.ClickCount,
        b.CreatedAt,
        b.UpdatedAt,
        b.IsActive
    FROM dbo.Banners b
    WHERE b.Id = @Id AND b.IsDeleted = 0;
END
GO

/* 3. Save (Insert / Update) */
CREATE OR ALTER PROCEDURE dbo.usp_Banner_Save
    @Id                INT             = 0,
    @Placement         TINYINT         = 0,
    @Eyebrow           NVARCHAR(100)   = NULL,
    @Heading           NVARCHAR(200),
    @SubHeading        NVARCHAR(500)   = NULL,
    @ImageUrl          NVARCHAR(1000)  = NULL,
    @MobileImageUrl    NVARCHAR(1000)  = NULL,
    @ImageAlt          NVARCHAR(200)   = NULL,
    @PrimaryCtaLabel   NVARCHAR(100)   = NULL,
    @PrimaryCtaUrl     NVARCHAR(1000)  = NULL,
    @SecondaryCtaLabel NVARCHAR(100)   = NULL,
    @SecondaryCtaUrl   NVARCHAR(1000)  = NULL,
    @StartsOn          DATETIME2       = NULL,
    @EndsOn            DATETIME2       = NULL,
    @SortOrder         INT             = 0,
    @Status            TINYINT         = 2,
    @IsActive          BIT             = 1,
    @LoggedInUserId    INT             = NULL,
    @NewId             INT             OUTPUT,
    @ErrorMessage      NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    SET @Heading = LTRIM(RTRIM(ISNULL(@Heading, N'')));
    IF @Heading = N''
    BEGIN
        SET @ErrorMessage = N'Banner Heading / Title is required.';
        RETURN;
    END

    IF ISNULL(@ImageAlt, N'') = N''
        SET @ImageAlt = @Heading;

    IF ISNULL(@ImageUrl, N'') = N''
        SET @ImageUrl = N'/assets/images/default-banner.png';

    IF @Id = 0
    BEGIN
        INSERT INTO dbo.Banners
        (
            Placement, Eyebrow, Heading, SubHeading, ImageUrl, MobileImageUrl,
            ImageAlt, PrimaryCtaLabel, PrimaryCtaUrl, SecondaryCtaLabel, SecondaryCtaUrl,
            StartsOn, EndsOn, SortOrder, Status, ImpressionCount, ClickCount,
            CreatedAt, CreatedBy, IsActive, IsDeleted
        )
        VALUES
        (
            @Placement, @Eyebrow, @Heading, @SubHeading, @ImageUrl, @MobileImageUrl,
            @ImageAlt, @PrimaryCtaLabel, @PrimaryCtaUrl, @SecondaryCtaLabel, @SecondaryCtaUrl,
            @StartsOn, @EndsOn, @SortOrder, @Status, 0, 0,
            SYSUTCDATETIME(), @LoggedInUserId, @IsActive, 0
        );

        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.Banners
        SET
            Placement = @Placement,
            Eyebrow = @Eyebrow,
            Heading = @Heading,
            SubHeading = @SubHeading,
            ImageUrl = COALESCE(@ImageUrl, ImageUrl),
            MobileImageUrl = COALESCE(@MobileImageUrl, MobileImageUrl),
            ImageAlt = @ImageAlt,
            PrimaryCtaLabel = @PrimaryCtaLabel,
            PrimaryCtaUrl = @PrimaryCtaUrl,
            SecondaryCtaLabel = @SecondaryCtaLabel,
            SecondaryCtaUrl = @SecondaryCtaUrl,
            StartsOn = @StartsOn,
            EndsOn = @EndsOn,
            SortOrder = @SortOrder,
            Status = @Status,
            IsActive = @IsActive,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE Id = @Id AND IsDeleted = 0;

        SET @NewId = @Id;
    END
END
GO

/* 4. Delete */
CREATE OR ALTER PROCEDURE dbo.usp_Banner_Delete
    @Id             INT,
    @LoggedInUserId INT           = NULL,
    @Success        BIT           OUTPUT,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    IF NOT EXISTS (SELECT 1 FROM dbo.Banners WHERE Id = @Id AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Banner not found.';
        RETURN;
    END

    UPDATE dbo.Banners
    SET
        IsDeleted = 1,
        IsActive = 0,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id;

    SET @Success = 1;
END
GO

/* 5. UpdateStatus */
CREATE OR ALTER PROCEDURE dbo.usp_Banner_UpdateStatus
    @Id             INT,
    @IsActive       BIT,
    @LoggedInUserId INT           = NULL,
    @Success        BIT           OUTPUT,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    IF NOT EXISTS (SELECT 1 FROM dbo.Banners WHERE Id = @Id AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Banner not found.';
        RETURN;
    END

    UPDATE dbo.Banners
    SET
        IsActive = @IsActive,
        Status = CASE WHEN @IsActive = 1 THEN 2 ELSE 0 END, -- 2 = Published, 0 = Draft
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id AND IsDeleted = 0;

    SET @Success = 1;
END
GO
