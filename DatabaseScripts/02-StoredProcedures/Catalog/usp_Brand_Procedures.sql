/* =============================================================================
   usp_Brand_Procedures.sql
   -----------------------------------------------------------------------------
   Stored procedures for Module 03 - Brands.
   Tables: dbo.Brands
   ============================================================================= */

SET NOCOUNT ON;
GO

-- 1. GridList
CREATE OR ALTER PROCEDURE dbo.usp_Brand_GridList
    @SearchText             NVARCHAR(200)   = NULL,
    @IsActive               BIT             = NULL,
    @IsFeatured             BIT             = NULL,
    @SortColumn             VARCHAR(64)     = 'SortOrder',
    @SortOrder              VARCHAR(4)      = 'ASC',
    @PageSize               INT             = 25,
    @PageIndex              INT             = 1,
    @TotalRecords           INT             OUTPUT,
    @TotalFilteredRecords   INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageSize  IS NULL OR @PageSize  < 1 SET @PageSize  = 25;
    IF @PageIndex IS NULL OR @PageIndex < 1 SET @PageIndex = 1;
    IF @SortOrder IS NULL OR @SortOrder NOT IN ('ASC','DESC') SET @SortOrder = 'ASC';

    SET @SearchText = NULLIF(LTRIM(RTRIM(ISNULL(@SearchText, N''))), N'');

    SELECT @TotalRecords = COUNT(*)
    FROM   dbo.Brands
    WHERE  IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT  b.Id,
                b.BrandName,
                b.Slug,
                b.LogoUrl,
                b.Description,
                b.IsFeatured,
                b.SortOrder,
                b.IsActive,
                b.CreatedAt,
                b.UpdatedAt,
                ProductCount = (SELECT COUNT(1) FROM dbo.Products p WHERE p.BrandId = b.Id AND p.IsDeleted = 0)
        FROM    dbo.Brands AS b
        WHERE   b.IsDeleted = 0
          AND  (@IsActive   IS NULL OR b.IsActive   = @IsActive)
          AND  (@IsFeatured IS NULL OR b.IsFeatured = @IsFeatured)
          AND  (@SearchText IS NULL OR b.BrandName LIKE N'%' + @SearchText + N'%' OR b.Slug LIKE '%' + @SearchText + '%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT  b.Id,
                b.BrandName,
                b.Slug,
                b.LogoUrl,
                b.Description,
                b.IsFeatured,
                b.SortOrder,
                b.IsActive,
                b.CreatedAt,
                b.UpdatedAt,
                ProductCount = (SELECT COUNT(1) FROM dbo.Products p WHERE p.BrandId = b.Id AND p.IsDeleted = 0)
        FROM    dbo.Brands AS b
        WHERE   b.IsDeleted = 0
          AND  (@IsActive   IS NULL OR b.IsActive   = @IsActive)
          AND  (@IsFeatured IS NULL OR b.IsFeatured = @IsFeatured)
          AND  (@SearchText IS NULL OR b.BrandName LIKE N'%' + @SearchText + N'%' OR b.Slug LIKE '%' + @SearchText + '%')
    )
    SELECT  Id,
            BrandName,
            Slug,
            LogoUrl,
            Description,
            IsFeatured,
            SortOrder,
            IsActive,
            CreatedAt,
            UpdatedAt,
            ProductCount
    FROM    Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'BrandName' THEN BrandName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'BrandName' THEN BrandName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'ProductCount' THEN ProductCount END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'ProductCount' THEN ProductCount END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'SortOrder' THEN SortOrder END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'SortOrder' THEN SortOrder END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CreatedAt' THEN CreatedAt END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CreatedAt' THEN CreatedAt END DESC,
        SortOrder ASC, Id ASC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- Synonym for generic CRUD convention
CREATE OR ALTER PROCEDURE dbo.GridList_Brand
    @SearchText             NVARCHAR(200)   = NULL,
    @IsActive               BIT             = NULL,
    @IsFeatured             BIT             = NULL,
    @SortColumn             VARCHAR(64)     = 'SortOrder',
    @SortOrder              VARCHAR(4)      = 'ASC',
    @PageSize               INT             = 25,
    @PageIndex              INT             = 1,
    @TotalRecords           INT             OUTPUT,
    @TotalFilteredRecords   INT             OUTPUT
AS
BEGIN
    EXEC dbo.usp_Brand_GridList
        @SearchText           = @SearchText,
        @IsActive             = @IsActive,
        @IsFeatured           = @IsFeatured,
        @SortColumn           = @SortColumn,
        @SortOrder            = @SortOrder,
        @PageSize             = @PageSize,
        @PageIndex            = @PageIndex,
        @TotalRecords         = @TotalRecords OUTPUT,
        @TotalFilteredRecords = @TotalFilteredRecords OUTPUT;
END
GO

-- 2. GetById
CREATE OR ALTER PROCEDURE dbo.usp_Brand_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  b.Id,
            b.BrandName,
            b.Slug,
            b.LogoMediaId,
            b.LogoUrl,
            b.Description,
            b.IsFeatured,
            b.SortOrder,
            b.IsActive,
            b.CreatedAt,
            b.CreatedBy,
            b.UpdatedAt,
            b.UpdatedBy,
            ProductCount = (SELECT COUNT(1) FROM dbo.Products p WHERE p.BrandId = b.Id AND p.IsDeleted = 0)
    FROM    dbo.Brands AS b
    WHERE   b.Id = @Id AND b.IsDeleted = 0;
END
GO

-- 3. Save (Insert / Update)
CREATE OR ALTER PROCEDURE dbo.usp_Brand_Save
    @Id             INT             = 0,
    @BrandName      NVARCHAR(200),
    @Slug           VARCHAR(220)    = NULL,
    @LogoUrl        NVARCHAR(1000)  = NULL,
    @Description    NVARCHAR(2000)  = NULL,
    @IsFeatured     BIT             = 0,
    @SortOrder      INT             = 0,
    @IsActive       BIT             = 1,
    @AdminUserId    INT             = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Generate slug if empty
    IF @Slug IS NULL OR LTRIM(RTRIM(@Slug)) = ''
    BEGIN
        SET @Slug = LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@BrandName)), ' ', '-'), '&', 'and'), '''', ''));
    END

    -- Ensure unique slug
    IF EXISTS (SELECT 1 FROM dbo.Brands WHERE Slug = @Slug AND Id <> @Id AND IsDeleted = 0)
    BEGIN
        SET @Slug = @Slug + '-' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS VARCHAR(10));
    END

    IF @Id > 0
    BEGIN
        UPDATE dbo.Brands
        SET    BrandName   = @BrandName,
               Slug        = @Slug,
               LogoUrl     = ISNULL(@LogoUrl, LogoUrl),
               Description = @Description,
               IsFeatured  = @IsFeatured,
               SortOrder   = @SortOrder,
               IsActive    = @IsActive,
               UpdatedAt   = SYSUTCDATETIME(),
               UpdatedBy   = @AdminUserId
        WHERE  Id = @Id AND IsDeleted = 0;

        SELECT @Id AS Id;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.Brands (BrandName, Slug, LogoUrl, Description, IsFeatured, SortOrder, IsActive, CreatedAt, CreatedBy)
        VALUES (@BrandName, @Slug, @LogoUrl, @Description, @IsFeatured, @SortOrder, @IsActive, SYSUTCDATETIME(), @AdminUserId);

        SELECT SCOPE_IDENTITY() AS Id;
    END
END
GO

-- 4. Delete (Soft Delete)
CREATE OR ALTER PROCEDURE dbo.usp_Brand_Delete
    @Id          INT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Brands
    SET    IsDeleted = 1,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  Id = @Id;

    SELECT CAST(1 AS BIT) AS Success;
END
GO

-- 5. UpdateStatus
CREATE OR ALTER PROCEDURE dbo.usp_Brand_UpdateStatus
    @Id          INT,
    @IsActive    BIT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Brands
    SET    IsActive  = @IsActive,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  Id = @Id AND IsDeleted = 0;

    SELECT CAST(1 AS BIT) AS Success;
END
GO

-- 6. Lookup
CREATE OR ALTER PROCEDURE dbo.usp_Brand_GetLookup
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  Id,
            Name = BrandName
    FROM    dbo.Brands
    WHERE   IsActive = 1 AND IsDeleted = 0
    ORDER   BY SortOrder ASC, BrandName ASC;
END
GO
