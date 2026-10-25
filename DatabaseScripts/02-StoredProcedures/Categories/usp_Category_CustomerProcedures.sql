SET NOCOUNT ON;
GO

/* =============================================================================
   dbo.usp_Category_GetMegaMenu
   Returns active categories configured for the Mega Menu.
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_Category_GetMegaMenu
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
            SubCategoryCount    = (SELECT COUNT(1) FROM dbo.Categories sub WHERE sub.ParentId = c.Id AND sub.IsDeleted = 0 AND sub.IsActive = 1)
    FROM    dbo.Categories c
    LEFT JOIN dbo.Categories p ON p.Id = c.ParentId AND p.IsDeleted = 0
    WHERE   c.IsDeleted = 0
      AND   c.IsActive = 1
      AND   (c.ShowInMegaMenu = 1 OR c.ParentId IS NOT NULL)
    ORDER BY c.SortOrder ASC, c.Name ASC;
END
GO

/* =============================================================================
   dbo.usp_Category_GetFeatured
   Returns featured categories for Homepage "Shop by Category".
   Fallback to top active root categories if none explicitly marked featured.
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_Category_GetFeatured
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.Categories WHERE IsDeleted = 0 AND IsActive = 1 AND IsFeaturedOnHome = 1)
    BEGIN
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
          AND   c.IsActive = 1
          AND   c.IsFeaturedOnHome = 1
        ORDER BY c.SortOrder ASC, c.Name ASC;
    END
    ELSE
    BEGIN
        SELECT TOP 6
                c.Id,
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
          AND   c.IsActive = 1
          AND   c.ParentId IS NULL
        ORDER BY c.SortOrder ASC, c.Name ASC;
    END
END
GO
