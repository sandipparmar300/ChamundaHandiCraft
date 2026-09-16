/* =============================================================================
   usp_Category_Procedures.sql — Category Management Stored Procedures
   ============================================================================= */

SET NOCOUNT ON;
GO

-- 1. Category Tree
CREATE OR ALTER PROCEDURE dbo.usp_Category_GetTree
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  c.Id,
            c.ParentId,
            ParentName          = p.Name,
            c.Name,
            c.Slug,
            c.Description,
            c.IntroCopy,
            c.ImageUrl,
            c.IconName,
            c.SortOrder,
            c.ShowInMegaMenu,
            c.IsFeaturedOnHome,
            c.Depth,
            c.IsActive,
            c.CreatedAt,
            ProductCount        = (SELECT COUNT(1) FROM dbo.Products pr WHERE (pr.CategoryId = c.Id OR pr.SubCategoryId = c.Id) AND pr.IsDeleted = 0),
            SubCategoryCount    = (SELECT COUNT(1) FROM dbo.Categories sub WHERE sub.ParentId = c.Id AND sub.IsDeleted = 0)
    FROM    dbo.Categories c
    LEFT JOIN dbo.Categories p ON p.Id = c.ParentId AND p.IsDeleted = 0
    WHERE   c.IsDeleted = 0
    ORDER BY c.SortOrder ASC, c.Name ASC;
END
GO

-- 2. Category Grid List (Search, Sort, Pagination)
CREATE OR ALTER PROCEDURE dbo.usp_Category_GridList
    @SearchText            NVARCHAR(200) = NULL,
    @Status                INT           = NULL,  -- NULL: all, 1: active, 0: inactive
    @ParentId              INT           = NULL,
    @SortColumn            VARCHAR(50)   = 'SortOrder',
    @SortOrder             VARCHAR(4)    = 'ASC',
    @PageSize              INT           = 25,
    @PageIndex             INT           = 1,
    @TotalRecords          INT OUTPUT,
    @TotalFilteredRecords  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @SearchText = NULLIF(LTRIM(RTRIM(@SearchText)), '');
    SET @PageSize = CASE WHEN @PageSize <= 0 THEN 25 ELSE @PageSize END;
    SET @PageIndex = CASE WHEN @PageIndex <= 0 THEN 1 ELSE @PageIndex END;

    SELECT @TotalRecords = COUNT(1)
    FROM dbo.Categories
    WHERE IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT  c.Id,
                c.ParentId,
                ParentName          = p.Name,
                c.Name,
                c.Slug,
                c.Description,
                c.ImageUrl,
                c.IconName,
                c.SortOrder,
                c.ShowInMegaMenu,
                c.IsFeaturedOnHome,
                c.Depth,
                c.IsActive,
                c.CreatedAt,
                ProductCount        = (SELECT COUNT(1) FROM dbo.Products pr WHERE (pr.CategoryId = c.Id OR pr.SubCategoryId = c.Id) AND pr.IsDeleted = 0),
                SubCategoryCount    = (SELECT COUNT(1) FROM dbo.Categories sub WHERE sub.ParentId = c.Id AND sub.IsDeleted = 0)
        FROM    dbo.Categories c
        LEFT JOIN dbo.Categories p ON p.Id = c.ParentId AND p.IsDeleted = 0
        WHERE   c.IsDeleted = 0
          AND  (@Status IS NULL OR @Status = -1 OR c.IsActive = @Status)
          AND  (@ParentId IS NULL OR c.ParentId = @ParentId)
          AND  (@SearchText IS NULL OR (
                c.Name LIKE '%' + @SearchText + '%' OR
                c.Slug LIKE '%' + @SearchText + '%' OR
                ISNULL(c.Description, '') LIKE '%' + @SearchText + '%' OR
                ISNULL(p.Name, '') LIKE '%' + @SearchText + '%'
          ))
    )
    SELECT @TotalFilteredRecords = COUNT(1) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT  c.Id,
                c.ParentId,
                ParentName          = p.Name,
                c.Name,
                c.Slug,
                c.Description,
                c.ImageUrl,
                c.IconName,
                c.SortOrder,
                c.ShowInMegaMenu,
                c.IsFeaturedOnHome,
                c.Depth,
                c.IsActive,
                c.CreatedAt,
                ProductCount        = (SELECT COUNT(1) FROM dbo.Products pr WHERE (pr.CategoryId = c.Id OR pr.SubCategoryId = c.Id) AND pr.IsDeleted = 0),
                SubCategoryCount    = (SELECT COUNT(1) FROM dbo.Categories sub WHERE sub.ParentId = c.Id AND sub.IsDeleted = 0)
        FROM    dbo.Categories c
        LEFT JOIN dbo.Categories p ON p.Id = c.ParentId AND p.IsDeleted = 0
        WHERE   c.IsDeleted = 0
          AND  (@Status IS NULL OR @Status = -1 OR c.IsActive = @Status)
          AND  (@ParentId IS NULL OR c.ParentId = @ParentId)
          AND  (@SearchText IS NULL OR (
                c.Name LIKE '%' + @SearchText + '%' OR
                c.Slug LIKE '%' + @SearchText + '%' OR
                ISNULL(c.Description, '') LIKE '%' + @SearchText + '%' OR
                ISNULL(p.Name, '') LIKE '%' + @SearchText + '%'
          ))
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'SortOrder' THEN SortOrder END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'SortOrder' THEN SortOrder END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Name'      THEN Name END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Name'      THEN Name END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CreatedAt' THEN CreatedAt END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CreatedAt' THEN CreatedAt END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'ProductCount' THEN ProductCount END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'ProductCount' THEN ProductCount END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- 3. Category GetById
CREATE OR ALTER PROCEDURE dbo.usp_Category_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Result set 1: Category
    SELECT  c.Id,
            c.ParentId,
            ParentName          = p.Name,
            c.Name,
            c.Slug,
            c.Description,
            c.IntroCopy,
            c.ImageUrl,
            c.IconName,
            c.SortOrder,
            c.ShowInMegaMenu,
            c.IsFeaturedOnHome,
            c.Depth,
            c.TreePath,
            c.IsActive,
            c.CreatedAt,
            c.UpdatedAt,
            ProductCount        = (SELECT COUNT(1) FROM dbo.Products pr WHERE (pr.CategoryId = c.Id OR pr.SubCategoryId = c.Id) AND pr.IsDeleted = 0),
            SubCategoryCount    = (SELECT COUNT(1) FROM dbo.Categories sub WHERE sub.ParentId = c.Id AND sub.IsDeleted = 0)
    FROM    dbo.Categories c
    LEFT JOIN dbo.Categories p ON p.Id = c.ParentId AND p.IsDeleted = 0
    WHERE   c.Id = @Id AND c.IsDeleted = 0;

    -- Result set 2: SEO Meta
    SELECT  MetaTitle,
            MetaDescription,
            MetaKeywords,
            CanonicalUrl
    FROM    dbo.SeoMetas
    WHERE   EntityType = 'Category'
      AND   EntityId = @Id
      AND   IsDeleted = 0;
END
GO

-- 4. Category Save (Insert / Update)
CREATE OR ALTER PROCEDURE dbo.usp_Category_Save
    @Id                 INT             = 0,
    @ParentId           INT             = NULL,
    @Name               NVARCHAR(200),
    @Slug               VARCHAR(220)    = NULL,
    @Description        NVARCHAR(2000)  = NULL,
    @IntroCopy          NVARCHAR(MAX)   = NULL,
    @ImageUrl           NVARCHAR(1000)  = NULL,
    @IconName           VARCHAR(64)     = NULL,
    @SortOrder          INT             = 0,
    @ShowInMegaMenu     BIT             = 1,
    @IsFeaturedOnHome   BIT             = 0,
    @IsActive           BIT             = 1,
    @MetaTitle          NVARCHAR(300)   = NULL,
    @MetaDescription    NVARCHAR(500)   = NULL,
    @MetaKeywords       NVARCHAR(500)   = NULL,
    @CanonicalUrl       NVARCHAR(1000)  = NULL,
    @AdminUserId        INT             = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Sanitize ParentId
    IF @ParentId <= 0 SET @ParentId = NULL;

    -- Prevent setting parent to itself
    IF @Id > 0 AND @ParentId = @Id
        SET @ParentId = NULL;

    -- Slug generation & uniqueness
    IF @Slug IS NULL OR LTRIM(RTRIM(@Slug)) = ''
        SET @Slug = LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@Name)), ' ', '-'), '&', 'and'), '''', ''));

    IF EXISTS (SELECT 1 FROM dbo.Categories WHERE Slug = @Slug AND Id <> @Id AND IsDeleted = 0)
        SET @Slug = @Slug + '-' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS VARCHAR(10));

    -- Calculate Depth and TreePath
    DECLARE @Depth INT = 0;
    DECLARE @TreePath VARCHAR(900) = NULL;

    IF @ParentId IS NOT NULL
    BEGIN
        SELECT @Depth = ISNULL(Depth, 0) + 1,
               @TreePath = ISNULL(TreePath, '/')
        FROM   dbo.Categories
        WHERE  Id = @ParentId;
    END

    BEGIN TRANSACTION;

    IF @Id > 0
    BEGIN
        SET @TreePath = ISNULL(@TreePath, '/') + CAST(@Id AS VARCHAR(10)) + '/';

        UPDATE dbo.Categories
        SET    ParentId         = @ParentId,
               Name             = @Name,
               Slug             = @Slug,
               Description      = @Description,
               IntroCopy        = @IntroCopy,
               ImageUrl         = ISNULL(@ImageUrl, ImageUrl),
               IconName         = @IconName,
               SortOrder        = @SortOrder,
               ShowInMegaMenu   = @ShowInMegaMenu,
               IsFeaturedOnHome = @IsFeaturedOnHome,
               Depth            = @Depth,
               TreePath         = @TreePath,
               IsActive         = @IsActive,
               UpdatedAt        = SYSUTCDATETIME(),
               UpdatedBy        = @AdminUserId
        WHERE  Id = @Id AND IsDeleted = 0;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.Categories
        (
            ParentId, Name, Slug, Description, IntroCopy, ImageUrl, IconName,
            SortOrder, ShowInMegaMenu, IsFeaturedOnHome, Depth, TreePath,
            ProductCount, CreatedAt, CreatedBy, IsActive, IsDeleted
        )
        VALUES
        (
            @ParentId, @Name, @Slug, @Description, @IntroCopy, @ImageUrl, @IconName,
            @SortOrder, @ShowInMegaMenu, @IsFeaturedOnHome, @Depth, '/',
            0, SYSUTCDATETIME(), @AdminUserId, @IsActive, 0
        );

        SET @Id = SCOPE_IDENTITY();
        SET @TreePath = ISNULL(@TreePath, '/') + CAST(@Id AS VARCHAR(10)) + '/';

        UPDATE dbo.Categories
        SET    TreePath = @TreePath
        WHERE  Id = @Id;
    END

    -- Upsert SEO Metadata
    IF @MetaTitle IS NOT NULL OR @MetaDescription IS NOT NULL OR @MetaKeywords IS NOT NULL OR @CanonicalUrl IS NOT NULL
    BEGIN
        DECLARE @RoutePath NVARCHAR(500) = '/c/' + @Slug;

        IF EXISTS (SELECT 1 FROM dbo.SeoMetas WHERE EntityType = 'Category' AND EntityId = @Id)
        BEGIN
            UPDATE dbo.SeoMetas
            SET    RoutePath       = @RoutePath,
                   MetaTitle       = @MetaTitle,
                   MetaDescription = @MetaDescription,
                   MetaKeywords    = @MetaKeywords,
                   CanonicalUrl    = @CanonicalUrl,
                   UpdatedAt       = SYSUTCDATETIME(),
                   UpdatedBy       = @AdminUserId,
                   IsActive        = @IsActive,
                   IsDeleted       = 0
            WHERE  EntityType = 'Category' AND EntityId = @Id;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.SeoMetas
            (
                RoutePath, EntityType, EntityId, MetaTitle, MetaDescription,
                MetaKeywords, CanonicalUrl, NoIndex, NoFollow, CreatedAt, CreatedBy, IsActive, IsDeleted
            )
            VALUES
            (
                @RoutePath, 'Category', @Id, @MetaTitle, @MetaDescription,
                @MetaKeywords, @CanonicalUrl, 0, 0, SYSUTCDATETIME(), @AdminUserId, @IsActive, 0
            );
        END
    END

    COMMIT TRANSACTION;

    SELECT @Id AS Id;
END
GO

-- 5. Category Delete (Soft Delete with Safety Guard)
CREATE OR ALTER PROCEDURE dbo.usp_Category_Delete
    @Id          INT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Guard 1: Subcategories exist
    IF EXISTS (SELECT 1 FROM dbo.Categories WHERE ParentId = @Id AND IsDeleted = 0)
    BEGIN
        RAISERROR('Cannot delete category because it has child subcategories. Please reassign or delete the subcategories first.', 16, 1);
        RETURN;
    END

    -- Guard 2: Products assigned directly or as subcategory
    IF EXISTS (SELECT 1 FROM dbo.Products WHERE (CategoryId = @Id OR SubCategoryId = @Id) AND IsDeleted = 0)
       OR EXISTS (SELECT 1 FROM dbo.ProductCategories WHERE CategoryId = @Id)
    BEGIN
        RAISERROR('Cannot delete category because active products are assigned to it. Please reassign the products first.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    UPDATE dbo.Categories
    SET    IsDeleted = 1,
           IsActive  = 0,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  Id = @Id;

    UPDATE dbo.SeoMetas
    SET    IsDeleted = 1,
           IsActive  = 0,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  EntityType = 'Category' AND EntityId = @Id;

    COMMIT TRANSACTION;

    SELECT CAST(1 AS BIT) AS Success;
END
GO

-- 6. Category Update Status
CREATE OR ALTER PROCEDURE dbo.usp_Category_UpdateStatus
    @Id          INT,
    @IsActive    BIT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Categories
    SET    IsActive  = @IsActive,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  Id = @Id AND IsDeleted = 0;

    SELECT CAST(1 AS BIT) AS Success;
END
GO

-- 7. Category Lookup (For dropdowns)
CREATE OR ALTER PROCEDURE dbo.usp_Category_Lookup
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  Id,
            Name,
            ParentId
    FROM    dbo.Categories
    WHERE   IsActive = 1 AND IsDeleted = 0
    ORDER BY SortOrder ASC, Name ASC;
END
GO
