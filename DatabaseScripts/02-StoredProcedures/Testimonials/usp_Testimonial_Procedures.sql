/* =============================================================================
   usp_Testimonial_Procedures.sql
   Stored procedures for Testimonials:
     1. dbo.usp_Testimonial_GridList
     2. dbo.usp_Testimonial_GetById
     3. dbo.usp_Testimonial_Save
     4. dbo.usp_Testimonial_Delete
     5. dbo.usp_Testimonial_UpdateStatus
   ============================================================================= */

SET NOCOUNT ON;
GO

/* 1. GridList */
CREATE OR ALTER PROCEDURE dbo.usp_Testimonial_GridList
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

    SELECT @TotalRecords = COUNT(*) FROM dbo.Testimonials WHERE IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT
            t.Id,
            t.CustomerName,
            t.Location,
            t.Quote,
            t.Rating,
            t.PhotoUrl,
            t.ShowOnHome,
            t.SortOrder,
            t.Status,
            t.CreatedAt,
            t.UpdatedAt,
            t.IsActive
        FROM dbo.Testimonials t
        WHERE t.IsDeleted = 0
          AND (@IsActive IS NULL OR t.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR t.CustomerName LIKE N'%' + @SearchText + N'%'
               OR t.Location LIKE N'%' + @SearchText + N'%'
               OR t.Quote LIKE N'%' + @SearchText + N'%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT
            t.Id,
            t.CustomerName,
            t.Location,
            t.Quote,
            t.Rating,
            t.PhotoUrl,
            t.ShowOnHome,
            t.SortOrder,
            t.Status,
            t.CreatedAt,
            t.UpdatedAt,
            t.IsActive
        FROM dbo.Testimonials t
        WHERE t.IsDeleted = 0
          AND (@IsActive IS NULL OR t.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR t.CustomerName LIKE N'%' + @SearchText + N'%'
               OR t.Location LIKE N'%' + @SearchText + N'%'
               OR t.Quote LIKE N'%' + @SearchText + N'%')
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CustomerName' THEN CustomerName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CustomerName' THEN CustomerName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Rating'       THEN Rating END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Rating'       THEN Rating END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'SortOrder'    THEN SortOrder END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'SortOrder'    THEN SortOrder END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CreatedAt'    THEN CreatedAt END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CreatedAt'    THEN CreatedAt END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

/* 2. GetById */
CREATE OR ALTER PROCEDURE dbo.usp_Testimonial_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.Id,
        t.CustomerName,
        t.Location,
        t.Quote,
        t.Rating,
        t.PhotoMediaId,
        t.PhotoUrl,
        t.OrderId,
        t.ProductId,
        t.ShowOnHome,
        t.SortOrder,
        t.Status,
        t.CreatedAt,
        t.UpdatedAt,
        t.IsActive
    FROM dbo.Testimonials t
    WHERE t.Id = @Id AND t.IsDeleted = 0;
END
GO

/* 3. Save (Insert / Update) */
CREATE OR ALTER PROCEDURE dbo.usp_Testimonial_Save
    @Id             INT             = 0,
    @CustomerName   NVARCHAR(200),
    @Location       NVARCHAR(200)   = NULL,
    @Quote          NVARCHAR(2000),
    @Rating         TINYINT         = 5,
    @PhotoUrl       NVARCHAR(1000)  = NULL,
    @ShowOnHome     BIT             = 0,
    @SortOrder      INT             = 0,
    @Status         TINYINT         = 2,
    @IsActive       BIT             = 1,
    @LoggedInUserId INT             = NULL,
    @NewId          INT             OUTPUT,
    @ErrorMessage   NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    SET @CustomerName = LTRIM(RTRIM(ISNULL(@CustomerName, N'')));
    SET @Quote = LTRIM(RTRIM(ISNULL(@Quote, N'')));

    IF @CustomerName = N''
    BEGIN
        SET @ErrorMessage = N'Author / Customer name is required.';
        RETURN;
    END

    IF @Quote = N''
    BEGIN
        SET @ErrorMessage = N'Testimonial quote is required.';
        RETURN;
    END

    IF @Rating < 1 SET @Rating = 1;
    IF @Rating > 5 SET @Rating = 5;

    IF @Id = 0
    BEGIN
        INSERT INTO dbo.Testimonials
        (
            CustomerName, Location, Quote, Rating, PhotoUrl,
            ShowOnHome, SortOrder, Status, CreatedAt, CreatedBy,
            IsActive, IsDeleted
        )
        VALUES
        (
            @CustomerName, @Location, @Quote, @Rating, @PhotoUrl,
            @ShowOnHome, @SortOrder, @Status, SYSUTCDATETIME(), @LoggedInUserId,
            @IsActive, 0
        );

        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.Testimonials
        SET
            CustomerName = @CustomerName,
            Location = @Location,
            Quote = @Quote,
            Rating = @Rating,
            PhotoUrl = COALESCE(@PhotoUrl, PhotoUrl),
            ShowOnHome = @ShowOnHome,
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
CREATE OR ALTER PROCEDURE dbo.usp_Testimonial_Delete
    @Id             INT,
    @LoggedInUserId INT           = NULL,
    @Success        BIT           OUTPUT,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    IF NOT EXISTS (SELECT 1 FROM dbo.Testimonials WHERE Id = @Id AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Testimonial not found.';
        RETURN;
    END

    UPDATE dbo.Testimonials
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
CREATE OR ALTER PROCEDURE dbo.usp_Testimonial_UpdateStatus
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

    IF NOT EXISTS (SELECT 1 FROM dbo.Testimonials WHERE Id = @Id AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Testimonial not found.';
        RETURN;
    END

    UPDATE dbo.Testimonials
    SET
        IsActive = @IsActive,
        Status = CASE WHEN @IsActive = 1 THEN 2 ELSE 0 END,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id AND IsDeleted = 0;

    SET @Success = 1;
END
GO
