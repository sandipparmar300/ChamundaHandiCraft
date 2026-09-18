/* =============================================================================
   usp_Product_Procedures.sql
   -----------------------------------------------------------------------------
   Stored procedures for Module 03 - Products (GetById, Save, Delete, Status, Lookups).
   GridList is already in usp_Product_GridList.sql.
   ============================================================================= */

SET NOCOUNT ON;
GO

-- 1. GetById
CREATE OR ALTER PROCEDURE dbo.usp_Product_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Result set 1: Product Main Record
    SELECT  p.Id,
            p.Name,
            p.ProductCode,
            p.Sku,
            p.Barcode,
            p.Slug,
            p.ShortDescription,
            p.FullDescription,
            p.ProductStory,
            p.CareInstructions,
            p.WarrantyInformation,
            p.VideoUrl,
            p.CategoryId,
            p.SubCategoryId,
            p.CollectionId,
            p.BrandId,
            p.ArtisanId,
            p.MaterialId,
            p.CraftId,
            p.Material,
            p.CraftTechnique,
            p.OriginCluster,
            p.Price,
            p.Mrp,
            p.CostPrice,
            p.TaxClassId,
            p.IsTaxInclusive,
            p.LengthCm,
            p.WidthCm,
            p.HeightCm,
            p.WeightGrams,
            p.TrackInventory,
            p.LowStockThreshold,
            p.MaxQuantityPerOrder,
            p.AllowBackorder,
            p.IsMadeToOrder,
            p.MadeToOrderDays,
            p.HasVariants,
            p.Status,
            p.Visibility,
            p.IsFeatured,
            p.IsBestseller,
            p.IsTrending,
            p.IsHandmade,
            p.PublishOn,
            p.PublishedAt,
            p.AverageRating,
            p.ReviewCount,
            p.SoldCount,
            p.ViewCount,
            p.IsActive,
            p.CreatedAt,
            p.CreatedBy,
            p.UpdatedAt,
            p.UpdatedBy,
            CategoryName = c.Name,
            BrandName    = b.BrandName,
            ArtisanName  = a.Name,
            StockQuantity = ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.VariantId IS NULL AND s.IsDeleted = 0), 0),
            WarehouseId   = (SELECT TOP 1 s.WarehouseId FROM dbo.InventoryStocks s WHERE s.ProductId = p.Id AND s.VariantId IS NULL AND s.IsDeleted = 0)
    FROM    dbo.Products AS p
    LEFT JOIN dbo.Categories AS c ON c.Id = p.CategoryId
    LEFT JOIN dbo.Brands     AS b ON b.Id = p.BrandId
    LEFT JOIN dbo.Artisans   AS a ON a.Id = p.ArtisanId
    WHERE   p.Id = @Id AND p.IsDeleted = 0;

    -- Result set 2: Media
    SELECT  m.Id,
            m.ProductId,
            m.VariantId,
            m.MediaId,
            m.Url,
            m.ThumbnailUrl,
            m.AltText,
            m.MediaType,
            m.SortOrder,
            m.IsPrimary
    FROM    dbo.ProductMedia AS m
    WHERE   m.ProductId = @Id AND m.IsDeleted = 0
    ORDER BY m.IsPrimary DESC, m.SortOrder ASC, m.Id ASC;

    -- Result set 3: Variants
    SELECT  v.Id,
            v.ProductId,
            v.Sku,
            v.Barcode,
            v.VariantSummary,
            v.Price,
            v.Mrp,
            v.CostPrice,
            v.WeightGrams,
            v.ImageUrl,
            v.IsDefault,
            v.SortOrder,
            v.IsActive,
            StockQuantity = ISNULL((SELECT SUM(s.OnHand - s.Reserved) FROM dbo.InventoryStocks s WHERE s.VariantId = v.Id AND s.IsDeleted = 0), 0)
    FROM    dbo.ProductVariants AS v
    WHERE   v.ProductId = @Id AND v.IsDeleted = 0
    ORDER BY v.SortOrder ASC, v.Id ASC;

    -- Result set 4: Related Products
    SELECT  r.Id,
            r.ProductId,
            r.RelatedProductId,
            r.RelationType,
            r.SortOrder,
            RelatedProductName = rp.Name,
            RelatedProductSku  = rp.Sku,
            RelatedProductPrice= rp.Price,
            RelatedProductImage= (SELECT TOP (1) pm.Url FROM dbo.ProductMedia pm WHERE pm.ProductId = rp.Id AND pm.IsDeleted = 0 ORDER BY pm.IsPrimary DESC)
    FROM    dbo.ProductRelations AS r
    JOIN    dbo.Products AS rp ON rp.Id = r.RelatedProductId AND rp.IsDeleted = 0
    WHERE   r.ProductId = @Id
    ORDER BY r.SortOrder ASC, r.Id ASC;

    -- Result set 5: SEO
    SELECT  s.MetaTitle,
            s.MetaDescription,
            s.MetaKeywords,
            s.CanonicalUrl,
            s.OgTitle,
            s.OgDescription
    FROM    dbo.SeoMetas AS s
    WHERE   s.EntityType = 'Product' AND s.EntityId = @Id AND s.IsDeleted = 0;
END
GO

-- 2. Save
CREATE OR ALTER PROCEDURE dbo.usp_Product_Save
    @Id                  INT             = 0,
    @Name                NVARCHAR(300),
    @ProductCode         VARCHAR(64)     = NULL,
    @Sku                 VARCHAR(64),
    @Barcode             VARCHAR(64)     = NULL,
    @Slug                VARCHAR(300)    = NULL,
    @ShortDescription    NVARCHAR(1000)  = '',
    @FullDescription     NVARCHAR(MAX)   = NULL,
    @ProductStory        NVARCHAR(MAX)   = NULL,
    @CareInstructions    NVARCHAR(MAX)   = NULL,
    @WarrantyInformation NVARCHAR(MAX)   = NULL,
    @VideoUrl            NVARCHAR(1000)  = NULL,
    @CategoryId          INT,
    @SubCategoryId       INT             = NULL,
    @CollectionId        INT             = NULL,
    @BrandId             INT             = NULL,
    @ArtisanId           INT             = NULL,
    @Material            NVARCHAR(200)   = NULL,
    @CraftTechnique      NVARCHAR(200)   = NULL,
    @OriginCluster       NVARCHAR(200)   = NULL,
    @Price               DECIMAL(18,2)   = 0,
    @Mrp                 DECIMAL(18,2)   = NULL,
    @CostPrice           DECIMAL(18,2)   = NULL,
    @TaxClassId          INT             = NULL,
    @IsTaxInclusive      BIT             = 1,
    @LengthCm            DECIMAL(18,4)   = NULL,
    @WidthCm             DECIMAL(18,4)   = NULL,
    @HeightCm            DECIMAL(18,4)   = NULL,
    @WeightGrams         DECIMAL(18,4)   = NULL,
    @TrackInventory      BIT             = 1,
    @LowStockThreshold   INT             = 5,
    @MaxQuantityPerOrder INT             = NULL,
    @AllowBackorder      BIT             = 0,
    @IsMadeToOrder       BIT             = 0,
    @MadeToOrderDays     INT             = NULL,
    @HasVariants         BIT             = 0,
    @Status              TINYINT         = 0,
    @Visibility          TINYINT         = 0,
    @IsFeatured          BIT             = 0,
    @IsBestseller        BIT             = 0,
    @IsTrending          BIT             = 0,
    @IsHandmade          BIT             = 1,
    @PublishOn           DATETIME2(3)    = NULL,
    @IsActive            BIT             = 1,
    @StockQuantity       INT             = 0,
    @MetaTitle           NVARCHAR(300)   = NULL,
    @MetaDescription     NVARCHAR(1000)  = NULL,
    @MetaKeywords        NVARCHAR(500)   = NULL,
    @CanonicalUrl        NVARCHAR(500)   = NULL,
    @OgTitle             NVARCHAR(300)   = NULL,
    @MediaJson           NVARCHAR(MAX)   = NULL,  -- [{"Url":"...","AltText":"...","IsPrimary":true,"MediaType":0,"SortOrder":0}]
    @VariantsJson        NVARCHAR(MAX)   = NULL,  -- [{"Id":0,"Sku":"...","Price":100,"Mrp":120,"StockQuantity":10,"IsDefault":true,"ImageUrl":"..."}]
    @RelatedJson         NVARCHAR(MAX)   = NULL,  -- [{"RelatedProductId":2,"RelationType":"Related","SortOrder":0}]
    @AdminUserId         INT             = NULL,
    @WarehouseId         INT             = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Defaults and fallbacks
    IF @ProductCode IS NULL OR LTRIM(RTRIM(@ProductCode)) = ''
        SET @ProductCode = @Sku;

    IF @Slug IS NULL OR LTRIM(RTRIM(@Slug)) = ''
        SET @Slug = LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@Name)), ' ', '-'), '&', 'and'), '''', ''));

    IF EXISTS (SELECT 1 FROM dbo.Products WHERE Slug = @Slug AND Id <> @Id AND IsDeleted = 0)
        SET @Slug = @Slug + '-' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS VARCHAR(10));

    IF EXISTS (SELECT 1 FROM dbo.Products WHERE Sku = @Sku AND Id <> @Id AND IsDeleted = 0)
        SET @Sku = @Sku + '-' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS VARCHAR(10));

    IF EXISTS (SELECT 1 FROM dbo.Products WHERE ProductCode = @ProductCode AND Id <> @Id AND IsDeleted = 0)
        SET @ProductCode = @ProductCode + '-' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS VARCHAR(10));

    BEGIN TRANSACTION;

    IF @Id > 0
    BEGIN
        UPDATE dbo.Products
        SET    Name                = @Name,
               ProductCode         = @ProductCode,
               Sku                 = @Sku,
               Barcode             = @Barcode,
               Slug                = @Slug,
               ShortDescription    = ISNULL(@ShortDescription, N''),
               FullDescription     = @FullDescription,
               ProductStory        = @ProductStory,
               CareInstructions    = @CareInstructions,
               WarrantyInformation = @WarrantyInformation,
               VideoUrl            = @VideoUrl,
               CategoryId          = @CategoryId,
               SubCategoryId       = @SubCategoryId,
               CollectionId        = @CollectionId,
               BrandId             = @BrandId,
               ArtisanId           = @ArtisanId,
               Material            = @Material,
               CraftTechnique      = @CraftTechnique,
               OriginCluster       = @OriginCluster,
               Price               = @Price,
               Mrp                 = @Mrp,
               CostPrice           = @CostPrice,
               TaxClassId          = @TaxClassId,
               IsTaxInclusive      = @IsTaxInclusive,
               LengthCm            = @LengthCm,
               WidthCm             = @WidthCm,
               HeightCm            = @HeightCm,
               WeightGrams         = @WeightGrams,
               TrackInventory      = @TrackInventory,
               LowStockThreshold   = @LowStockThreshold,
               MaxQuantityPerOrder = @MaxQuantityPerOrder,
               AllowBackorder      = @AllowBackorder,
               IsMadeToOrder       = @IsMadeToOrder,
               MadeToOrderDays     = @MadeToOrderDays,
               HasVariants         = @HasVariants,
               Status              = @Status,
               Visibility          = @Visibility,
               IsFeatured          = @IsFeatured,
               IsBestseller        = @IsBestseller,
               IsTrending          = @IsTrending,
               IsHandmade          = @IsHandmade,
               PublishOn           = @PublishOn,
               PublishedAt         = CASE WHEN @Status = 1 AND PublishedAt IS NULL THEN SYSUTCDATETIME() ELSE PublishedAt END,
               IsActive            = @IsActive,
               UpdatedAt           = SYSUTCDATETIME(),
               UpdatedBy           = @AdminUserId
        WHERE  Id = @Id AND IsDeleted = 0;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.Products
        (
            Name, ProductCode, Sku, Barcode, Slug, ShortDescription, FullDescription,
            ProductStory, CareInstructions, WarrantyInformation, VideoUrl, CategoryId, SubCategoryId,
            CollectionId, BrandId, ArtisanId, Material, CraftTechnique, OriginCluster,
            Price, Mrp, CostPrice, TaxClassId, IsTaxInclusive, LengthCm, WidthCm,
            HeightCm, WeightGrams, TrackInventory, LowStockThreshold, MaxQuantityPerOrder,
            AllowBackorder, IsMadeToOrder, MadeToOrderDays, HasVariants, Status,
            Visibility, IsFeatured, IsBestseller, IsTrending, IsHandmade, PublishOn,
            PublishedAt, IsActive, CreatedAt, CreatedBy
        )
        VALUES
        (
            @Name, @ProductCode, @Sku, @Barcode, @Slug, ISNULL(@ShortDescription, N''), @FullDescription,
            @ProductStory, @CareInstructions, @WarrantyInformation, @VideoUrl, @CategoryId, @SubCategoryId,
            @CollectionId, @BrandId, @ArtisanId, @Material, @CraftTechnique, @OriginCluster,
            @Price, @Mrp, @CostPrice, @TaxClassId, @IsTaxInclusive, @LengthCm, @WidthCm,
            @HeightCm, @WeightGrams, @TrackInventory, @LowStockThreshold, @MaxQuantityPerOrder,
            @AllowBackorder, @IsMadeToOrder, @MadeToOrderDays, @HasVariants, @Status,
            @Visibility, @IsFeatured, @IsBestseller, @IsTrending, @IsHandmade, @PublishOn,
            CASE WHEN @Status = 1 THEN SYSUTCDATETIME() ELSE NULL END,
            @IsActive, SYSUTCDATETIME(), @AdminUserId
        );

        SET @Id = SCOPE_IDENTITY();
    END

    -- Sync Media
    IF @MediaJson IS NOT NULL AND ISJSON(@MediaJson) = 1
    BEGIN
        SELECT  Url       = COALESCE(JSON_VALUE(j.value, '$.Url'), JSON_VALUE(j.value, '$.url')),
                AltText   = ISNULL(COALESCE(JSON_VALUE(j.value, '$.AltText'), JSON_VALUE(j.value, '$.altText')), @Name),
                IsPrimary = ISNULL(CAST(COALESCE(JSON_VALUE(j.value, '$.IsPrimary'), JSON_VALUE(j.value, '$.isPrimary')) AS BIT), 0),
                MediaType = ISNULL(CAST(COALESCE(JSON_VALUE(j.value, '$.MediaType'), JSON_VALUE(j.value, '$.mediaType')) AS TINYINT), 0),
                SortOrder = ISNULL(CAST(COALESCE(JSON_VALUE(j.value, '$.SortOrder'), JSON_VALUE(j.value, '$.sortOrder')) AS INT), 0)
        INTO    #IncomingMedia
        FROM    OPENJSON(@MediaJson) AS j
        WHERE   COALESCE(JSON_VALUE(j.value, '$.Url'), JSON_VALUE(j.value, '$.url')) IS NOT NULL;

        IF EXISTS (SELECT 1 FROM #IncomingMedia)
        BEGIN
            -- Ensure at least one media item is primary
            IF NOT EXISTS (SELECT 1 FROM #IncomingMedia WHERE IsPrimary = 1)
            BEGIN
                UPDATE TOP (1) #IncomingMedia SET IsPrimary = 1;
            END

            -- Soft delete old media
            UPDATE  dbo.ProductMedia
            SET     IsDeleted = 1, UpdatedAt = SYSUTCDATETIME(), UpdatedBy = @AdminUserId
            WHERE   ProductId = @Id AND IsDeleted = 0;

            -- Insert new media
            INSERT INTO dbo.ProductMedia (ProductId, Url, AltText, MediaType, SortOrder, IsPrimary, CreatedAt, CreatedBy, IsActive, IsDeleted)
            SELECT @Id, Url, AltText, MediaType, SortOrder, IsPrimary, SYSUTCDATETIME(), @AdminUserId, 1, 0
            FROM   #IncomingMedia;
        END

        DROP TABLE #IncomingMedia;
    END

    -- 1. Sync Base Product Stock in InventoryStocks
    DECLARE @TargetWarehouseId INT = ISNULL(@WarehouseId, 1);
    IF @TrackInventory = 1
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.InventoryStocks WHERE ProductId = @Id AND VariantId IS NULL AND WarehouseId = @TargetWarehouseId AND IsDeleted = 0)
        BEGIN
            INSERT INTO dbo.InventoryStocks (ProductId, VariantId, WarehouseId, OnHand, Reserved, Incoming, LowStockThreshold, CreatedAt, CreatedBy, IsActive, IsDeleted)
            VALUES (@Id, NULL, @TargetWarehouseId, ISNULL(@StockQuantity, 0), 0, 0, ISNULL(@LowStockThreshold, 5), SYSUTCDATETIME(), @AdminUserId, 1, 0);
        END
        ELSE
        BEGIN
            UPDATE dbo.InventoryStocks
            SET    OnHand = ISNULL(@StockQuantity, 0),
                   LowStockThreshold = ISNULL(@LowStockThreshold, 5),
                   UpdatedAt = SYSUTCDATETIME(),
                   UpdatedBy = @AdminUserId
            WHERE  ProductId = @Id AND VariantId IS NULL AND WarehouseId = @TargetWarehouseId AND IsDeleted = 0;
        END
    END

    -- 2. Sync Variants
    IF (@HasVariants = 1 OR (@VariantsJson IS NOT NULL AND @VariantsJson <> '[]' AND @VariantsJson <> ''))
    BEGIN
        UPDATE dbo.Products SET HasVariants = 1 WHERE Id = @Id AND HasVariants = 0;

        SELECT  VarId         = ISNULL(CAST(COALESCE(JSON_VALUE(j.value, '$.Id'), JSON_VALUE(j.value, '$.id')) AS INT), 0),
                VarSku        = ISNULL(COALESCE(JSON_VALUE(j.value, '$.Sku'), JSON_VALUE(j.value, '$.sku')), @Sku + '-V' + CAST(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS VARCHAR(10))),
                VarPrice      = ISNULL(CAST(COALESCE(JSON_VALUE(j.value, '$.Price'), JSON_VALUE(j.value, '$.price')) AS DECIMAL(18,2)), @Price),
                VarMrp        = CAST(COALESCE(JSON_VALUE(j.value, '$.Mrp'), JSON_VALUE(j.value, '$.mrp')) AS DECIMAL(18,2)),
                VarStockQty   = ISNULL(CAST(COALESCE(JSON_VALUE(j.value, '$.StockQuantity'), JSON_VALUE(j.value, '$.stockQuantity')) AS INT), 0),
                VarIsDefault  = ISNULL(CAST(COALESCE(JSON_VALUE(j.value, '$.IsDefault'), JSON_VALUE(j.value, '$.isDefault')) AS BIT), 0),
                VarImageUrl   = COALESCE(JSON_VALUE(j.value, '$.ImageUrl'), JSON_VALUE(j.value, '$.imageUrl'))
        INTO    #IncomingVariants
        FROM    OPENJSON(@VariantsJson) AS j;

        IF NOT EXISTS (SELECT 1 FROM #IncomingVariants WHERE VarIsDefault = 1)
        BEGIN
            UPDATE TOP (1) #IncomingVariants SET VarIsDefault = 1;
        END

        UPDATE dbo.ProductVariants
        SET    IsDeleted = 1, UpdatedAt = SYSUTCDATETIME(), UpdatedBy = @AdminUserId
        WHERE  ProductId = @Id AND IsDeleted = 0 AND Id NOT IN (SELECT VarId FROM #IncomingVariants WHERE VarId > 0);

        UPDATE v
        SET    v.Sku         = iv.VarSku,
               v.Price       = iv.VarPrice,
               v.Mrp         = iv.VarMrp,
               v.IsDefault   = iv.VarIsDefault,
               v.ImageUrl    = ISNULL(iv.VarImageUrl, v.ImageUrl),
               v.IsDeleted   = 0,
               v.UpdatedAt   = SYSUTCDATETIME(),
               v.UpdatedBy   = @AdminUserId
        FROM   dbo.ProductVariants v
        JOIN   #IncomingVariants iv ON iv.VarId = v.Id
        WHERE  v.ProductId = @Id;

        INSERT INTO dbo.ProductVariants (ProductId, Sku, Price, Mrp, IsDefault, ImageUrl, CreatedAt, CreatedBy)
        SELECT @Id, VarSku, VarPrice, VarMrp, VarIsDefault, VarImageUrl, SYSUTCDATETIME(), @AdminUserId
        FROM   #IncomingVariants
        WHERE  VarId = 0 OR VarId NOT IN (SELECT Id FROM dbo.ProductVariants WHERE ProductId = @Id);

        MERGE INTO dbo.InventoryStocks AS target
        USING (
            SELECT v.Id AS VariantId, iv.VarStockQty
            FROM   dbo.ProductVariants v
            JOIN   #IncomingVariants iv ON iv.VarSku = v.Sku
            WHERE  v.ProductId = @Id AND v.IsDeleted = 0
        ) AS source
        ON (target.ProductId = @Id AND target.VariantId = source.VariantId AND target.WarehouseId = @TargetWarehouseId AND target.IsDeleted = 0)
        WHEN MATCHED THEN
            UPDATE SET target.OnHand = source.VarStockQty, target.UpdatedAt = SYSUTCDATETIME(), target.UpdatedBy = @AdminUserId
        WHEN NOT MATCHED THEN
            INSERT (ProductId, VariantId, WarehouseId, OnHand, Reserved, Incoming, LowStockThreshold, CreatedAt, CreatedBy, IsActive, IsDeleted)
            VALUES (@Id, source.VariantId, @TargetWarehouseId, source.VarStockQty, 0, 0, ISNULL(@LowStockThreshold, 5), SYSUTCDATETIME(), @AdminUserId, 1, 0);

        DROP TABLE #IncomingVariants;
    END

    -- 3. Sync SEO
    IF @MetaTitle IS NOT NULL OR @MetaDescription IS NOT NULL OR @MetaKeywords IS NOT NULL OR @CanonicalUrl IS NOT NULL OR @OgTitle IS NOT NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.SeoMetas WHERE EntityType = 'Product' AND EntityId = @Id)
        BEGIN
            UPDATE dbo.SeoMetas
            SET    RoutePath       = '/p/' + @Slug,
                   MetaTitle       = @MetaTitle,
                   MetaDescription = @MetaDescription,
                   MetaKeywords    = @MetaKeywords,
                   CanonicalUrl    = @CanonicalUrl,
                   OgTitle         = @OgTitle,
                   OgDescription   = @MetaDescription,
                   UpdatedAt       = SYSUTCDATETIME(),
                   UpdatedBy       = @AdminUserId,
                   IsDeleted       = 0
            WHERE  EntityType = 'Product' AND EntityId = @Id;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.SeoMetas
            (
                RoutePath, EntityType, EntityId, MetaTitle, MetaDescription,
                MetaKeywords, CanonicalUrl, OgTitle, OgDescription,
                CreatedAt, CreatedBy, IsActive, IsDeleted
            )
            VALUES
            (
                '/p/' + @Slug, 'Product', @Id, @MetaTitle, @MetaDescription,
                @MetaKeywords, @CanonicalUrl, @OgTitle, @MetaDescription,
                SYSUTCDATETIME(), @AdminUserId, 1, 0
            );
        END
    END

    -- 4. Sync Related
    IF @RelatedJson IS NOT NULL AND ISJSON(@RelatedJson) = 1
    BEGIN
        DELETE FROM dbo.ProductRelations WHERE ProductId = @Id;

        INSERT INTO dbo.ProductRelations (ProductId, RelatedProductId, RelationType, SortOrder)
        SELECT  @Id,
                CAST(COALESCE(JSON_VALUE(j.value, '$.RelatedProductId'), JSON_VALUE(j.value, '$.relatedProductId')) AS INT),
                ISNULL(COALESCE(JSON_VALUE(j.value, '$.RelationType'), JSON_VALUE(j.value, '$.relationType')), 'Complementary'),
                ISNULL(CAST(COALESCE(JSON_VALUE(j.value, '$.SortOrder'), JSON_VALUE(j.value, '$.sortOrder')) AS INT), 0)
        FROM    OPENJSON(@RelatedJson) AS j
        WHERE   CAST(COALESCE(JSON_VALUE(j.value, '$.RelatedProductId'), JSON_VALUE(j.value, '$.relatedProductId')) AS INT) <> @Id
          AND   CAST(COALESCE(JSON_VALUE(j.value, '$.RelatedProductId'), JSON_VALUE(j.value, '$.relatedProductId')) AS INT) > 0;
    END

    COMMIT TRANSACTION;

    SELECT @Id AS Id;
END
GO

-- 3. Delete (Soft Delete)
CREATE OR ALTER PROCEDURE dbo.usp_Product_Delete
    @Id          INT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;

    UPDATE dbo.Products
    SET    IsDeleted = 1,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  Id = @Id;

    UPDATE dbo.ProductVariants
    SET    IsDeleted = 1,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  ProductId = @Id;

    UPDATE dbo.ProductMedia
    SET    IsDeleted = 1,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  ProductId = @Id;

    COMMIT TRANSACTION;

    SELECT CAST(1 AS BIT) AS Success;
END
GO

-- 4. UpdateStatus
CREATE OR ALTER PROCEDURE dbo.usp_Product_UpdateStatus
    @Id          INT,
    @Status      TINYINT, -- 0 Draft, 1 Published, 2 Unpublished, 3 Archived
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Products
    SET    Status      = @Status,
           PublishedAt = CASE WHEN @Status = 1 AND PublishedAt IS NULL THEN SYSUTCDATETIME() ELSE PublishedAt END,
           UpdatedAt   = SYSUTCDATETIME(),
           UpdatedBy   = @AdminUserId
    WHERE  Id = @Id AND IsDeleted = 0;

    SELECT CAST(1 AS BIT) AS Success;
END
GO

-- 5. Lookups for Product Add/Edit Screen
CREATE OR ALTER PROCEDURE dbo.usp_Product_GetLookups
AS
BEGIN
    SET NOCOUNT ON;

    -- Result set 1: Categories
    SELECT Id, Name FROM dbo.Categories WHERE IsActive = 1 AND IsDeleted = 0 ORDER BY SortOrder ASC, Name ASC;

    -- Result set 2: Brands
    SELECT Id, Name = BrandName FROM dbo.Brands WHERE IsActive = 1 AND IsDeleted = 0 ORDER BY SortOrder ASC, BrandName ASC;

    -- Result set 3: Artisans
    SELECT Id, Name = Name + ' (' + Craft + ')' FROM dbo.Artisans WHERE IsActive = 1 AND IsDeleted = 0 ORDER BY Name ASC;

    -- Result set 4: TaxClasses
    SELECT Id, Name = ClassName FROM dbo.TaxClasses WHERE IsActive = 1 ORDER BY Id ASC;

    -- Result set 5: Attributes
    SELECT Id, Name = AttributeName FROM dbo.ProductAttributes WHERE IsActive = 1 AND IsDeleted = 0 ORDER BY SortOrder ASC, AttributeName ASC;

    -- Result set 6: Products (for Related Products lookup)
    SELECT Id, Name FROM dbo.Products WHERE IsDeleted = 0 ORDER BY Name ASC;
END
GO
