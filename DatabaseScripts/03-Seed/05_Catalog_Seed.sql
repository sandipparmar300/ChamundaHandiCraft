/* =============================================================================
   03-Seed/05_Catalog_Seed.sql
   -----------------------------------------------------------------------------
   Initial Seed Data for Categories, Brands, Artisans, Attributes, and Products.
   ============================================================================= */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- 0. Default Warehouse
IF NOT EXISTS (SELECT 1 FROM dbo.Warehouses WHERE Code = 'WH-MAIN')
BEGIN
    INSERT INTO dbo.Warehouses (WarehouseName, Code, Line1, CityName, StateName, Pincode, IsDefault, IsActive, CreatedAt)
    VALUES (N'Ahmedabad Central Fulfillment Center', 'WH-MAIN', N'Plot 45, GIDC Naroda', N'Ahmedabad', N'Gujarat', '382330', 1, 1, SYSUTCDATETIME());
END
GO

-- 1. Categories
IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE Slug = 'brass-and-metalware')
BEGIN
    INSERT INTO dbo.Categories (Name, Slug, Description, SortOrder, IsActive, CreatedAt)
    VALUES (N'Brass & Metalware', 'brass-and-metalware', N'Exquisite handcrafted brass idols, diyas, bells and heritage artifacts.', 1, 1, SYSUTCDATETIME());
END

IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE Slug = 'wooden-handicrafts')
BEGIN
    INSERT INTO dbo.Categories (Name, Slug, Description, SortOrder, IsActive, CreatedAt)
    VALUES (N'Wooden Handicrafts', 'wooden-handicrafts', N'Traditional lacquered wooden furniture, Sankheda craft and hand-carved decor.', 2, 1, SYSUTCDATETIME());
END

IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE Slug = 'handloom-textiles')
BEGIN
    INSERT INTO dbo.Categories (Name, Slug, Description, SortOrder, IsActive, CreatedAt)
    VALUES (N'Handloom & Textiles', 'handloom-textiles', N'Authentic Patola silk, Bandhani, Ajrakh block prints, and Kutch embroidery.', 3, 1, SYSUTCDATETIME());
END

IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE Slug = 'terracotta-and-clay')
BEGIN
    INSERT INTO dbo.Categories (Name, Slug, Description, SortOrder, IsActive, CreatedAt)
    VALUES (N'Clay & Terracotta', 'terracotta-and-clay', N'Handmade clay lamps, pottery, and decorative terracotta murals.', 4, 1, SYSUTCDATETIME());
END
GO

-- 2. Brands
IF NOT EXISTS (SELECT 1 FROM dbo.Brands WHERE Slug = 'chamunda-heritage')
BEGIN
    INSERT INTO dbo.Brands (BrandName, Slug, Description, IsFeatured, SortOrder, IsActive, CreatedAt)
    VALUES (N'Chamunda Heritage', 'chamunda-heritage', N'Signature collection of sacred brass artifacts and traditional temple handicraft.', 1, 1, 1, SYSUTCDATETIME());
END

IF NOT EXISTS (SELECT 1 FROM dbo.Brands WHERE Slug = 'sankheda-artisans')
BEGIN
    INSERT INTO dbo.Brands (BrandName, Slug, Description, IsFeatured, SortOrder, IsActive, CreatedAt)
    VALUES (N'Sankheda Artisans', 'sankheda-artisans', N'Traditional lacquerware wooden craft from the historic town of Sankheda.', 1, 2, 1, SYSUTCDATETIME());
END

IF NOT EXISTS (SELECT 1 FROM dbo.Brands WHERE Slug = 'patan-patola-weaves')
BEGIN
    INSERT INTO dbo.Brands (BrandName, Slug, Description, IsFeatured, SortOrder, IsActive, CreatedAt)
    VALUES (N'Patan Patola Weaves', 'patan-patola-weaves', N'Double ikat pure silk handwoven masterworks from the weavers of Patan.', 1, 3, 1, SYSUTCDATETIME());
END

IF NOT EXISTS (SELECT 1 FROM dbo.Brands WHERE Slug = 'kutch-craft-collective')
BEGIN
    INSERT INTO dbo.Brands (BrandName, Slug, Description, IsFeatured, SortOrder, IsActive, CreatedAt)
    VALUES (N'Kutch Craft Collective', 'kutch-craft-collective', N'Authentic mirror work, Rogan art, and mud relief work from artisan clusters in Kutch.', 0, 4, 1, SYSUTCDATETIME());
END
GO

-- 3. Artisans
IF NOT EXISTS (SELECT 1 FROM dbo.Artisans WHERE Slug = 'ramesh-soni')
BEGIN
    INSERT INTO dbo.Artisans (Name, Slug, Craft, Cluster, Story, WorkingSinceYear, PartnerSinceYear, ApprenticesTrained, IsGiTagged, IsActive, CreatedAt)
    VALUES (N'Ramesh Soni', 'ramesh-soni', N'Brass Metal Casting', N'Surendranagar', N'Carrying forward four generations of traditional brass lost-wax casting, specialized in temple idols and ornate diyas.', 1988, 2020, 14, 1, 1, SYSUTCDATETIME());
END

IF NOT EXISTS (SELECT 1 FROM dbo.Artisans WHERE Slug = 'kalpesh-mistry')
BEGIN
    INSERT INTO dbo.Artisans (Name, Slug, Craft, Cluster, Story, WorkingSinceYear, PartnerSinceYear, ApprenticesTrained, IsGiTagged, IsActive, CreatedAt)
    VALUES (N'Kalpesh Mistry', 'kalpesh-mistry', N'Sankheda Woodwork', N'Sankheda, Chhota Udaipur', N'Master craftsman specializing in teakwood turning, floral tin foils and organic lacquer coats.', 1995, 2021, 8, 1, 1, SYSUTCDATETIME());
END

IF NOT EXISTS (SELECT 1 FROM dbo.Artisans WHERE Slug = 'hansaben-vankar')
BEGIN
    INSERT INTO dbo.Artisans (Name, Slug, Craft, Cluster, Story, WorkingSinceYear, PartnerSinceYear, ApprenticesTrained, IsGiTagged, IsActive, CreatedAt)
    VALUES (N'Hansaben Vankar', 'hansaben-vankar', N'Kutch Handloom Weaving', N'Bhujodi, Kutch', N'Award-winning master weaver creating wool and organic cotton shawls with traditional extra-weft motifs.', 2002, 2022, 19, 1, 1, SYSUTCDATETIME());
END
GO

-- 4. ProductAttributes & Values
DECLARE @AttrId INT;

IF NOT EXISTS (SELECT 1 FROM dbo.ProductAttributes WHERE AttributeCode = 'MATERIAL')
BEGIN
    INSERT INTO dbo.ProductAttributes (AttributeName, AttributeCode, DisplayType, IsFilterable, IsRequired, IsVariantDefining, SortOrder, IsActive, CreatedAt)
    VALUES (N'Material', 'MATERIAL', 'Pill', 1, 1, 0, 1, 1, SYSUTCDATETIME());
    SET @AttrId = SCOPE_IDENTITY();

    INSERT INTO dbo.ProductAttributeValues (AttributeId, Label, ValueCode, SortOrder, IsActive, CreatedAt)
    VALUES (@AttrId, N'Pure Brass', 'pure-brass', 1, 1, SYSUTCDATETIME()),
           (@AttrId, N'Teakwood', 'teakwood', 2, 1, SYSUTCDATETIME()),
           (@AttrId, N'Pure Silk', 'pure-silk', 3, 1, SYSUTCDATETIME()),
           (@AttrId, N'Terracotta', 'terracotta', 4, 1, SYSUTCDATETIME());
END

IF NOT EXISTS (SELECT 1 FROM dbo.ProductAttributes WHERE AttributeCode = 'FINISH')
BEGIN
    INSERT INTO dbo.ProductAttributes (AttributeName, AttributeCode, DisplayType, IsFilterable, IsRequired, IsVariantDefining, SortOrder, IsActive, CreatedAt)
    VALUES (N'Finish', 'FINISH', 'Dropdown', 1, 0, 0, 2, 1, SYSUTCDATETIME());
    SET @AttrId = SCOPE_IDENTITY();

    INSERT INTO dbo.ProductAttributeValues (AttributeId, Label, ValueCode, SortOrder, IsActive, CreatedAt)
    VALUES (@AttrId, N'Antique Gold', 'antique-gold', 1, 1, SYSUTCDATETIME()),
           (@AttrId, N'Lacquered Polished', 'lacquered-polished', 2, 1, SYSUTCDATETIME()),
           (@AttrId, N'Matte Natural', 'matte-natural', 3, 1, SYSUTCDATETIME());
END

IF NOT EXISTS (SELECT 1 FROM dbo.ProductAttributes WHERE AttributeCode = 'COLOR')
BEGIN
    INSERT INTO dbo.ProductAttributes (AttributeName, AttributeCode, DisplayType, IsFilterable, IsRequired, IsVariantDefining, SortOrder, IsActive, CreatedAt)
    VALUES (N'Color', 'COLOR', 'Swatch', 1, 0, 1, 3, 1, SYSUTCDATETIME());
    SET @AttrId = SCOPE_IDENTITY();

    INSERT INTO dbo.ProductAttributeValues (AttributeId, Label, ValueCode, ColourHex, SortOrder, IsActive, CreatedAt)
    VALUES (@AttrId, N'Royal Gold', 'royal-gold', '#F3C969', 1, 1, SYSUTCDATETIME()),
           (@AttrId, N'Deep Maroon', 'deep-maroon', '#8E1F2F', 2, 1, SYSUTCDATETIME()),
           (@AttrId, N'Walnut Brown', 'walnut-brown', '#5C4033', 3, 1, SYSUTCDATETIME()),
           (@AttrId, N'Peacock Blue', 'peacock-blue', '#004953', 4, 1, SYSUTCDATETIME());
END
GO

-- 5. Sample Products
DECLARE @CatBrass INT = (SELECT TOP 1 Id FROM dbo.Categories WHERE Slug = 'brass-and-metalware');
DECLARE @CatWood  INT = (SELECT TOP 1 Id FROM dbo.Categories WHERE Slug = 'wooden-handicrafts');
DECLARE @CatText  INT = (SELECT TOP 1 Id FROM dbo.Categories WHERE Slug = 'handloom-textiles');

DECLARE @BrandChamunda INT = (SELECT TOP 1 Id FROM dbo.Brands WHERE Slug = 'chamunda-heritage');
DECLARE @BrandSankheda INT = (SELECT TOP 1 Id FROM dbo.Brands WHERE Slug = 'sankheda-artisans');
DECLARE @BrandPatan    INT = (SELECT TOP 1 Id FROM dbo.Brands WHERE Slug = 'patan-patola-weaves');

DECLARE @ArtisanRamesh  INT = (SELECT TOP 1 Id FROM dbo.Artisans WHERE Slug = 'ramesh-soni');
DECLARE @ArtisanKalpesh INT = (SELECT TOP 1 Id FROM dbo.Artisans WHERE Slug = 'kalpesh-mistry');
DECLARE @ArtisanHansa   INT = (SELECT TOP 1 Id FROM dbo.Artisans WHERE Slug = 'hansaben-vankar');
DECLARE @DefaultWarehouseId INT = (SELECT TOP 1 Id FROM dbo.Warehouses WHERE Code = 'WH-MAIN');

DECLARE @ProdId INT;

-- Product 1: Brass Radha Krishna Idol
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE Sku = 'CH-BRS-001')
BEGIN
    INSERT INTO dbo.Products
    (
        Name, ProductCode, Sku, Barcode, Slug, ShortDescription, FullDescription,
        ProductStory, CareInstructions, WarrantyInformation, CategoryId, BrandId,
        ArtisanId, Material, CraftTechnique, OriginCluster, Price, Mrp, CostPrice,
        TrackInventory, LowStockThreshold, Status, Visibility, IsFeatured, IsBestseller,
        IsHandmade, PublishedAt, IsActive, CreatedAt
    )
    VALUES
    (
        N'Handcrafted Brass Radha Krishna Idol (12 Inch)', 'CH-BRS-001', 'CH-BRS-001', '890123456701',
        'handcrafted-brass-radha-krishna-idol-12-inch',
        N'Stunning antique-finished pure brass divine idol of Radha and Krishna, hand-engraved with intricate temple jewelry patterns.',
        N'This magnificent 12-inch Radha Krishna idol represents the pinnacle of Surendranagar lost-wax metal craftsmanship. Meticulously hand-poured from solid virgin brass and finished by senior artisans over 14 days.',
        N'Cast using age-old sand and clay moulds passed down through four generations of the Soni artisan family.',
        N'Wipe gently with a soft dry cloth. Do not use abrasive chemicals or harsh scouring pads.',
        N'1-year craftsmanship guarantee covering manufacturing defects.',
        @CatBrass, @BrandChamunda, @ArtisanRamesh, N'Pure Brass', N'Lost-Wax Casting & Chasing', N'Surendranagar, Gujarat',
        4999.00, 6499.00, 2800.00, 1, 3, 1, 0, 1, 1, 1, SYSUTCDATETIME(), 1, SYSUTCDATETIME()
    );
    SET @ProdId = SCOPE_IDENTITY();

    INSERT INTO dbo.ProductMedia (ProductId, Url, AltText, SortOrder, IsPrimary, CreatedAt)
    VALUES (@ProdId, '/assets/images/default-profile.png', N'Handcrafted Brass Radha Krishna Idol', 1, 1, SYSUTCDATETIME());

    INSERT INTO dbo.InventoryStocks (ProductId, WarehouseId, OnHand, Reserved, LowStockThreshold, CreatedAt)
    VALUES (@ProdId, @DefaultWarehouseId, 15, 2, 3, SYSUTCDATETIME());
END

-- Product 2: Sankheda Carved Teakwood Armchair
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE Sku = 'CH-WOD-002')
BEGIN
    INSERT INTO dbo.Products
    (
        Name, ProductCode, Sku, Barcode, Slug, ShortDescription, FullDescription,
        ProductStory, CareInstructions, WarrantyInformation, CategoryId, BrandId,
        ArtisanId, Material, CraftTechnique, OriginCluster, Price, Mrp, CostPrice,
        TrackInventory, LowStockThreshold, Status, Visibility, IsFeatured, IsBestseller,
        IsHandmade, PublishedAt, IsActive, CreatedAt
    )
    VALUES
    (
        N'Royal Sankheda Lacquered Teakwood Armchair', 'CH-WOD-002', 'CH-WOD-002', '890123456702',
        'royal-sankheda-lacquered-teakwood-armchair',
        N'Classic Sankheda ceremonial chair crafted from seasoned teakwood, adorned with traditional gold leaf floral motifs and cushioned velvet seating.',
        N'Originating from the royal courts of Gujarat, this genuine Sankheda armchair exemplifies centuries of woodwork mastery. Hand-turned spindles and rich organic lacquer preserve its brilliant sheen for decades.',
        N'Hand-lathed by certified GI-tagged Sankheda craftsmen using indigenous organic dyes and lac coatings.',
        N'Dust regularly with a dry micro-fiber cloth. Keep away from direct excessive sunlight and continuous moisture.',
        N'3-year termite and structural warranty.',
        @CatWood, @BrandSankheda, @ArtisanKalpesh, N'Seasoned Teakwood', N'Lacquered Wood Turning (Kharadi)', N'Sankheda, Gujarat',
        8499.00, 10999.00, 5200.00, 1, 2, 1, 0, 1, 0, 1, SYSUTCDATETIME(), 1, SYSUTCDATETIME()
    );
    SET @ProdId = SCOPE_IDENTITY();

    INSERT INTO dbo.ProductMedia (ProductId, Url, AltText, SortOrder, IsPrimary, CreatedAt)
    VALUES (@ProdId, '/assets/images/default-profile.png', N'Royal Sankheda Lacquered Teakwood Armchair', 1, 1, SYSUTCDATETIME());

    INSERT INTO dbo.InventoryStocks (ProductId, WarehouseId, OnHand, Reserved, LowStockThreshold, CreatedAt)
    VALUES (@ProdId, @DefaultWarehouseId, 8, 0, 2, SYSUTCDATETIME());
END

-- Product 3: Patan Double Ikat Pure Silk Patola
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE Sku = 'CH-TEX-003')
BEGIN
    INSERT INTO dbo.Products
    (
        Name, ProductCode, Sku, Barcode, Slug, ShortDescription, FullDescription,
        ProductStory, CareInstructions, WarrantyInformation, CategoryId, BrandId,
        ArtisanId, Material, CraftTechnique, OriginCluster, Price, Mrp, CostPrice,
        TrackInventory, LowStockThreshold, Status, Visibility, IsFeatured, IsBestseller,
        IsHandmade, PublishedAt, IsActive, CreatedAt
    )
    VALUES
    (
        N'Authentic Patan Double Ikat Silk Patola Dupatta', 'CH-TEX-003', 'CH-TEX-003', '890123456703',
        'authentic-patan-double-ikat-silk-patola-dupatta',
        N'Rare geometric jewel-toned double ikat Patola dupatta in pure mulberry silk, featuring heritage elephant and parrot motifs.',
        N'A masterpiece of precision weaving where warp and weft are both tie-dyed before weaving, ensuring an identical vibrant pattern on both sides.',
        N'Handcrafted on an inclined bamboo loom by master handloom weavers over 45 days.',
        N'Dry clean only. Store wrapped in pure muslin cloth with cedar balls.',
        N'Certificate of authenticity from Silk Mark India & GI Registry included.',
        @CatText, @BrandPatan, @ArtisanHansa, N'Pure Mulberry Silk', N'Double Ikat Weaving', N'Patan, Gujarat',
        14999.00, 17999.00, 9500.00, 1, 2, 1, 0, 1, 1, 1, SYSUTCDATETIME(), 1, SYSUTCDATETIME()
    );
    SET @ProdId = SCOPE_IDENTITY();

    INSERT INTO dbo.ProductMedia (ProductId, Url, AltText, SortOrder, IsPrimary, CreatedAt)
    VALUES (@ProdId, '/assets/images/default-profile.png', N'Authentic Patan Double Ikat Silk Patola Dupatta', 1, 1, SYSUTCDATETIME());

    INSERT INTO dbo.InventoryStocks (ProductId, WarehouseId, OnHand, Reserved, LowStockThreshold, CreatedAt)
    VALUES (@ProdId, @DefaultWarehouseId, 5, 1, 2, SYSUTCDATETIME());
END
GO
