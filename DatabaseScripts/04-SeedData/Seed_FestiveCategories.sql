/* =============================================================================
   Seed_FestiveCategories.sql
   Configures the dynamic 'Festive & Seasonal' parent category and subcategories.
   ============================================================================= */

SET NOCOUNT ON;

DECLARE @FestiveId INT;

SELECT @FestiveId = Id FROM dbo.Categories WHERE Slug = 'festive';

IF @FestiveId IS NULL
BEGIN
    INSERT INTO dbo.Categories (
        ParentId, Name, Slug, Description, IntroCopy, ImageUrl, 
        IconName, SortOrder, ShowInMegaMenu, IsFeaturedOnHome, Depth, TreePath, 
        ProductCount, CreatedAt, IsActive, IsDeleted
    )
    VALUES (
        NULL, 'Festive & Seasonal', 'festive', 
        'Brass diyas, silver coins, torans and handcrafted festive hampers.',
        'Handmade festive decor and spiritual items by Indian master artisans.',
        '/assets/images/placeholders/banner-festive.svg',
        'i-sparkles', 10, 1, 1, 0, '/festive',
        0, GETDATE(), 1, 0
    );

    SET @FestiveId = SCOPE_IDENTITY();
END
ELSE
BEGIN
    UPDATE dbo.Categories 
    SET IsActive = 1, IsDeleted = 0, ShowInMegaMenu = 1,
        ImageUrl = ISNULL(ImageUrl, '/assets/images/placeholders/banner-festive.svg')
    WHERE Id = @FestiveId;
END

-- Subcategories under Festive
IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE Slug = 'diyas')
BEGIN
    INSERT INTO dbo.Categories (ParentId, Name, Slug, Description, SortOrder, ShowInMegaMenu, Depth, TreePath, ProductCount, CreatedAt, IsActive, IsDeleted)
    VALUES (@FestiveId, 'Diyas & Lights', 'diyas', 'Brass diyas, oil lamps and tea lights.', 1, 1, 1, '/festive/diyas', 0, GETDATE(), 1, 0);
END

IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE Slug = 'pooja-thalis')
BEGIN
    INSERT INTO dbo.Categories (ParentId, Name, Slug, Description, SortOrder, ShowInMegaMenu, Depth, TreePath, ProductCount, CreatedAt, IsActive, IsDeleted)
    VALUES (@FestiveId, 'Pooja Thalis & Decor', 'pooja-thalis', 'Carved pooja thalis, bells and incense holders.', 2, 1, 1, '/festive/pooja-thalis', 0, GETDATE(), 1, 0);
END

IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE Slug = 'gift-hampers')
BEGIN
    INSERT INTO dbo.Categories (ParentId, Name, Slug, Description, SortOrder, ShowInMegaMenu, Depth, TreePath, ProductCount, CreatedAt, IsActive, IsDeleted)
    VALUES (@FestiveId, 'Gift Hampers & Sets', 'gift-hampers', 'Handcrafted artisan hampers and festive gift boxes.', 3, 1, 1, '/festive/gift-hampers', 0, GETDATE(), 1, 0);
END

IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE Slug = 'torans-rangoli')
BEGIN
    INSERT INTO dbo.Categories (ParentId, Name, Slug, Description, SortOrder, ShowInMegaMenu, Depth, TreePath, ProductCount, CreatedAt, IsActive, IsDeleted)
    VALUES (@FestiveId, 'Torans & Rangoli', 'torans-rangoli', 'Traditional door torans, wall hangings and rangoli.', 4, 1, 1, '/festive/torans-rangoli', 0, GETDATE(), 1, 0);
END
GO
