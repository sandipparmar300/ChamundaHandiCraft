/* =============================================================================
   06_Catalog.sql — Products, Variants, Options, Media, Attributes, Brands,
                    Artisans, Tags, Collections
   -----------------------------------------------------------------------------
   The publish gate lives on Products. A product reaches the storefront only when
   Status = Published (1), Visibility is Everywhere (0) or CatalogOnly (2),
   PublishOn is null or past, and its category is active. The last condition is
   why Products.CategoryId is required — the check is a join, not a flag.

   Products.CategoryId / SubCategoryId / CollectionId foreign keys are added at
   the end of 07_Categories.sql, because Categories does not exist yet.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.Brands', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Brands
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        BrandName       NVARCHAR(200)   NOT NULL,
        Slug            VARCHAR(220)    NOT NULL,
        LogoMediaId     INT             NULL,
        LogoUrl         NVARCHAR(1000)  NULL,
        Description     NVARCHAR(2000)  NULL,
        IsFeatured      BIT             NOT NULL CONSTRAINT DF_Brands_IsFeatured DEFAULT (0),
        SortOrder       INT             NOT NULL CONSTRAINT DF_Brands_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Brands_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Brands_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Brands_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Brands PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Brands_LogoMedia FOREIGN KEY (LogoMediaId) REFERENCES dbo.MediaAssets (Id)
    );

    CREATE UNIQUE INDEX UX_Brands_Slug ON dbo.Brands (Slug) WHERE IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Artisans. A first-class entity, not a metadata field — the maker is credited
   on the card, the PDP band, the cart line, the order detail and the invoice.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Artisans', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Artisans
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        Name                NVARCHAR(200)   NOT NULL,
        Slug                VARCHAR(220)    NOT NULL,
        CraftId             INT             NULL,
        /* Free-text copies kept alongside the FKs so an artisan page still reads
           correctly if the craft vocabulary is later reorganised. */
        Craft               NVARCHAR(200)   NOT NULL,
        Cluster             NVARCHAR(200)   NOT NULL,
        Story               NVARCHAR(MAX)   NULL,
        PhotoMediaId        INT             NULL,
        PhotoUrl            NVARCHAR(1000)  NULL,
        CoverMediaId        INT             NULL,
        CoverUrl            NVARCHAR(1000)  NULL,
        VideoUrl            NVARCHAR(1000)  NULL,
        CityId              INT             NULL,
        StateId             INT             NULL,
        WorkingSinceYear    INT             NULL,
        PartnerSinceYear    INT             NULL,
        ApprenticesTrained  INT             NULL,
        IsGiTagged          BIT             NOT NULL CONSTRAINT DF_Artisans_IsGiTagged DEFAULT (0),
        /* Maintained by the Reviews module, shown on the artisan card. */
        AverageRating       DECIMAL(18,4)   NOT NULL CONSTRAINT DF_Artisans_AverageRating DEFAULT (0),
        ProductCount        INT             NOT NULL CONSTRAINT DF_Artisans_ProductCount DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Artisans_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Artisans_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Artisans_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Artisans PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Artisans_Crafts      FOREIGN KEY (CraftId)      REFERENCES dbo.Crafts (Id),
        CONSTRAINT FK_Artisans_PhotoMedia  FOREIGN KEY (PhotoMediaId) REFERENCES dbo.MediaAssets (Id),
        CONSTRAINT FK_Artisans_CoverMedia  FOREIGN KEY (CoverMediaId) REFERENCES dbo.MediaAssets (Id),
        CONSTRAINT FK_Artisans_Cities      FOREIGN KEY (CityId)       REFERENCES dbo.Cities (Id),
        CONSTRAINT FK_Artisans_States      FOREIGN KEY (StateId)      REFERENCES dbo.States (Id)
    );

    CREATE UNIQUE INDEX UX_Artisans_Slug ON dbo.Artisans (Slug) WHERE IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Attributes and their values. These become the PLP facet groups and the PDP
   option selectors, so IsFilterable and DisplayType matter far beyond the
   Attribute admin screen.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ProductAttributes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductAttributes
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        AttributeName       NVARCHAR(150)   NOT NULL,
        AttributeCode       VARCHAR(64)     NOT NULL,
        /* Swatch | Pill | Dropdown | Text — decides how the PDP renders it. */
        DisplayType         VARCHAR(24)     NOT NULL CONSTRAINT DF_ProductAttributes_DisplayType DEFAULT ('Pill'),
        /* True when it appears as a filter group on the PLP rail. */
        IsFilterable        BIT             NOT NULL CONSTRAINT DF_ProductAttributes_IsFilterable DEFAULT (1),
        IsRequired          BIT             NOT NULL CONSTRAINT DF_ProductAttributes_IsRequired DEFAULT (0),
        /* True when this attribute takes part in variant generation. */
        IsVariantDefining   BIT             NOT NULL CONSTRAINT DF_ProductAttributes_IsVariantDefining DEFAULT (0),
        IsExpandedByDefault BIT             NOT NULL CONSTRAINT DF_ProductAttributes_IsExpanded DEFAULT (0),
        SortOrder           INT             NOT NULL CONSTRAINT DF_ProductAttributes_SortOrder DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_ProductAttributes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_ProductAttributes_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_ProductAttributes_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ProductAttributes PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ProductAttributes_Code UNIQUE (AttributeCode)
    );
END
GO

IF OBJECT_ID(N'dbo.ProductAttributeValues', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductAttributeValues
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        AttributeId     INT             NOT NULL,
        Label           NVARCHAR(200)   NOT NULL,
        ValueCode       VARCHAR(100)    NOT NULL,
        /* A swatch always carries its colour name as text too (A11Y-05). */
        ColourHex       CHAR(7)         NULL,
        ImageMediaId    INT             NULL,
        ImageUrl        NVARCHAR(1000)  NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_ProductAttributeValues_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ProductAttributeValues_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_ProductAttributeValues_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_ProductAttributeValues_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ProductAttributeValues PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ProductAttributeValues UNIQUE (AttributeId, ValueCode),
        CONSTRAINT FK_ProductAttributeValues_Attributes FOREIGN KEY (AttributeId)  REFERENCES dbo.ProductAttributes (Id),
        CONSTRAINT FK_ProductAttributeValues_Media      FOREIGN KEY (ImageMediaId) REFERENCES dbo.MediaAssets (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.Tags', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Tags
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Name            NVARCHAR(150)   NOT NULL,
        Slug            VARCHAR(160)    NOT NULL,
        /* Product | Blog — one vocabulary table, two uses. */
        TagScope        VARCHAR(24)     NOT NULL CONSTRAINT DF_Tags_TagScope DEFAULT ('Product'),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Tags_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Tags_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Tags_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Tags PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Tags_ScopeSlug UNIQUE (TagScope, Slug)
    );
END
GO

/* Curated merchandising groups — "Diwali Collection", "Under 999". Distinct from
   Categories, which are the taxonomy a product belongs to exactly once. */
IF OBJECT_ID(N'dbo.Collections', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Collections
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Name            NVARCHAR(200)   NOT NULL,
        Slug            VARCHAR(220)    NOT NULL,
        Description     NVARCHAR(2000)  NULL,
        BannerMediaId   INT             NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_Collections_SortOrder DEFAULT (0),
        IsFeatured      BIT             NOT NULL CONSTRAINT DF_Collections_IsFeatured DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Collections_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Collections_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Collections_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Collections PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Collections_BannerMedia FOREIGN KEY (BannerMediaId) REFERENCES dbo.MediaAssets (Id)
    );

    CREATE UNIQUE INDEX UX_Collections_Slug ON dbo.Collections (Slug) WHERE IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Products
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Products', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Products
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,

        -- General
        Name                NVARCHAR(300)   NOT NULL,
        ProductCode         VARCHAR(64)     NOT NULL,
        Sku                 VARCHAR(64)     NOT NULL,
        Barcode             VARCHAR(64)     NULL,
        /* Drives /p/{slug}. Changing it must write a 301 into dbo.Redirects. */
        Slug                VARCHAR(300)    NOT NULL,
        ShortDescription    NVARCHAR(1000)  NOT NULL CONSTRAINT DF_Products_ShortDescription DEFAULT (N''),
        FullDescription     NVARCHAR(MAX)   NULL,
        /* The handmade story rendered in the PDP craft band. */
        ProductStory        NVARCHAR(MAX)   NULL,
        CareInstructions    NVARCHAR(MAX)   NULL,
        WarrantyInformation NVARCHAR(MAX)   NULL,

        -- Classification (Category FKs added in 07_Categories.sql)
        CategoryId          INT             NOT NULL,
        SubCategoryId       INT             NULL,
        CollectionId        INT             NULL,
        BrandId             INT             NULL,
        ArtisanId           INT             NULL,
        MaterialId          INT             NULL,
        CraftId             INT             NULL,
        SizeChartId         INT             NULL,
        Material            NVARCHAR(200)   NULL,
        CraftTechnique      NVARCHAR(200)   NULL,
        OriginCluster       NVARCHAR(200)   NULL,

        -- Pricing. Mrp is the genuine list price; discounts are computed from it.
        Price               DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Products_Price DEFAULT (0),
        Mrp                 DECIMAL(18,2)   NULL,
        CostPrice           DECIMAL(18,2)   NULL,
        TaxClassId          INT             NULL,
        HsnCodeId           INT             NULL,
        IsTaxInclusive      BIT             NOT NULL CONSTRAINT DF_Products_IsTaxInclusive DEFAULT (1),

        -- Dimensions: PDP spec list and courier rate calculation
        LengthCm            DECIMAL(18,4)   NULL,
        WidthCm             DECIMAL(18,4)   NULL,
        HeightCm            DECIMAL(18,4)   NULL,
        WeightGrams         DECIMAL(18,4)   NULL,

        -- Inventory behaviour
        TrackInventory      BIT             NOT NULL CONSTRAINT DF_Products_TrackInventory DEFAULT (1),
        LowStockThreshold   INT             NULL CONSTRAINT DF_Products_LowStockThreshold DEFAULT (5),
        MaxQuantityPerOrder INT             NULL,
        AllowBackorder      BIT             NOT NULL CONSTRAINT DF_Products_AllowBackorder DEFAULT (0),
        IsMadeToOrder       BIT             NOT NULL CONSTRAINT DF_Products_IsMadeToOrder DEFAULT (0),
        MadeToOrderDays     INT             NULL,
        HasVariants         BIT             NOT NULL CONSTRAINT DF_Products_HasVariants DEFAULT (0),

        -- Merchandising / the publish gate
        /* ProductStatus:     0 Draft, 1 Published, 2 Unpublished, 3 Archived */
        Status              TINYINT         NOT NULL CONSTRAINT DF_Products_Status DEFAULT (0),
        /* ProductVisibility: 0 Everywhere, 1 SearchOnly, 2 CatalogOnly, 3 Hidden */
        Visibility          TINYINT         NOT NULL CONSTRAINT DF_Products_Visibility DEFAULT (0),
        IsFeatured          BIT             NOT NULL CONSTRAINT DF_Products_IsFeatured DEFAULT (0),
        IsBestseller        BIT             NOT NULL CONSTRAINT DF_Products_IsBestseller DEFAULT (0),
        IsTrending          BIT             NOT NULL CONSTRAINT DF_Products_IsTrending DEFAULT (0),
        IsHandmade          BIT             NOT NULL CONSTRAINT DF_Products_IsHandmade DEFAULT (1),
        PublishOn           DATETIME2(3)    NULL,
        PublishedAt         DATETIME2(3)    NULL,

        -- Denormalised read-side figures, maintained by their owning modules.
        AverageRating       DECIMAL(18,4)   NOT NULL CONSTRAINT DF_Products_AverageRating DEFAULT (0),
        ReviewCount         INT             NOT NULL CONSTRAINT DF_Products_ReviewCount DEFAULT (0),
        SoldCount           INT             NOT NULL CONSTRAINT DF_Products_SoldCount DEFAULT (0),
        ViewCount           INT             NOT NULL CONSTRAINT DF_Products_ViewCount DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Products_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Products_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Products_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Products PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Products_Brands      FOREIGN KEY (BrandId)     REFERENCES dbo.Brands (Id),
        CONSTRAINT FK_Products_Artisans    FOREIGN KEY (ArtisanId)   REFERENCES dbo.Artisans (Id),
        CONSTRAINT FK_Products_Materials   FOREIGN KEY (MaterialId)  REFERENCES dbo.Materials (Id),
        CONSTRAINT FK_Products_Crafts      FOREIGN KEY (CraftId)     REFERENCES dbo.Crafts (Id),
        CONSTRAINT FK_Products_SizeCharts  FOREIGN KEY (SizeChartId) REFERENCES dbo.SizeCharts (Id),
        CONSTRAINT FK_Products_TaxClasses  FOREIGN KEY (TaxClassId)  REFERENCES dbo.TaxClasses (Id),
        CONSTRAINT FK_Products_HsnCodes    FOREIGN KEY (HsnCodeId)   REFERENCES dbo.HsnCodes (Id),
        /* Mrp is the list price, so it can never sit below the selling price. */
        CONSTRAINT CK_Products_MrpNotBelowPrice CHECK (Mrp IS NULL OR Mrp >= Price),
        CONSTRAINT CK_Products_PriceNonNegative CHECK (Price >= 0)
    );

    CREATE UNIQUE INDEX UX_Products_Slug        ON dbo.Products (Slug)        WHERE IsDeleted = 0;
    CREATE UNIQUE INDEX UX_Products_Sku         ON dbo.Products (Sku)         WHERE IsDeleted = 0;
    CREATE UNIQUE INDEX UX_Products_ProductCode ON dbo.Products (ProductCode) WHERE IsDeleted = 0;

    /* The storefront listing predicate: published, visible, live, by category. */
    CREATE INDEX IX_Products_Storefront ON dbo.Products (Status, Visibility, CategoryId)
        INCLUDE (Slug, Name, Price, Mrp, AverageRating, ReviewCount, PublishOn)
        WHERE IsDeleted = 0;

    CREATE INDEX IX_Products_Brand   ON dbo.Products (BrandId)   WHERE IsDeleted = 0;
    CREATE INDEX IX_Products_Artisan ON dbo.Products (ArtisanId) WHERE IsDeleted = 0;
END
GO

/* Wishlist FKs deferred from 05_Customers.sql now that Products exists. */
IF OBJECT_ID(N'dbo.FK_WishlistItems_Products', N'F') IS NULL
    ALTER TABLE dbo.WishlistItems
        ADD CONSTRAINT FK_WishlistItems_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products (Id);
GO

/* ---------------------------------------------------------------------------
   Variants. A variant carries its own SKU and price; the parent product's price
   is what the card shows ("from"), and the selected variant's price is what the
   buy box and the cart line use.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ProductVariants', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductVariants
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        ProductId       INT             NOT NULL,
        Sku             VARCHAR(64)     NOT NULL,
        Barcode         VARCHAR(64)     NULL,
        /* Rendered on the cart line — "Blue · Large". Composed on save from the
           option values so a line item never has to re-join to display itself. */
        VariantSummary  NVARCHAR(300)   NULL,
        Price           DECIMAL(18,2)   NOT NULL CONSTRAINT DF_ProductVariants_Price DEFAULT (0),
        Mrp             DECIMAL(18,2)   NULL,
        CostPrice       DECIMAL(18,2)   NULL,
        WeightGrams     DECIMAL(18,4)   NULL,
        ImageMediaId    INT             NULL,
        ImageUrl        NVARCHAR(1000)  NULL,
        IsDefault       BIT             NOT NULL CONSTRAINT DF_ProductVariants_IsDefault DEFAULT (0),
        SortOrder       INT             NOT NULL CONSTRAINT DF_ProductVariants_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ProductVariants_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_ProductVariants_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_ProductVariants_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ProductVariants PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ProductVariants_Products FOREIGN KEY (ProductId)    REFERENCES dbo.Products (Id),
        CONSTRAINT FK_ProductVariants_Media    FOREIGN KEY (ImageMediaId) REFERENCES dbo.MediaAssets (Id),
        CONSTRAINT CK_ProductVariants_MrpNotBelowPrice CHECK (Mrp IS NULL OR Mrp >= Price)
    );

    CREATE UNIQUE INDEX UX_ProductVariants_Sku ON dbo.ProductVariants (Sku) WHERE IsDeleted = 0;
    CREATE INDEX IX_ProductVariants_Product ON dbo.ProductVariants (ProductId) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.FK_WishlistItems_Variants', N'F') IS NULL
    ALTER TABLE dbo.WishlistItems
        ADD CONSTRAINT FK_WishlistItems_Variants FOREIGN KEY (VariantId) REFERENCES dbo.ProductVariants (Id);
GO

/* Which attribute values make up a variant. One row per defining attribute. */
IF OBJECT_ID(N'dbo.ProductVariantOptions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductVariantOptions
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        VariantId           INT             NOT NULL,
        AttributeId         INT             NOT NULL,
        AttributeValueId    INT             NOT NULL,

        CONSTRAINT PK_ProductVariantOptions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ProductVariantOptions UNIQUE (VariantId, AttributeId),
        CONSTRAINT FK_ProductVariantOptions_Variants   FOREIGN KEY (VariantId)        REFERENCES dbo.ProductVariants (Id),
        CONSTRAINT FK_ProductVariantOptions_Attributes FOREIGN KEY (AttributeId)      REFERENCES dbo.ProductAttributes (Id),
        CONSTRAINT FK_ProductVariantOptions_Values     FOREIGN KEY (AttributeValueId) REFERENCES dbo.ProductAttributeValues (Id)
    );

    CREATE INDEX IX_ProductVariantOptions_Value ON dbo.ProductVariantOptions (AttributeValueId);
END
GO

/* Non-variant attributes carried by the product itself — these are the PLP
   facets that do not create SKUs (Origin, Finish, Occasion). */
IF OBJECT_ID(N'dbo.ProductAttributeMappings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductAttributeMappings
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        ProductId           INT             NOT NULL,
        AttributeId         INT             NOT NULL,
        AttributeValueId    INT             NULL,
        /* Used when the attribute is free-text rather than a fixed value list. */
        TextValue           NVARCHAR(500)   NULL,

        CONSTRAINT PK_ProductAttributeMappings PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ProductAttributeMappings_Products   FOREIGN KEY (ProductId)        REFERENCES dbo.Products (Id),
        CONSTRAINT FK_ProductAttributeMappings_Attributes FOREIGN KEY (AttributeId)      REFERENCES dbo.ProductAttributes (Id),
        CONSTRAINT FK_ProductAttributeMappings_Values     FOREIGN KEY (AttributeValueId) REFERENCES dbo.ProductAttributeValues (Id)
    );

    CREATE INDEX IX_ProductAttributeMappings_Product ON dbo.ProductAttributeMappings (ProductId);
    CREATE INDEX IX_ProductAttributeMappings_Facet   ON dbo.ProductAttributeMappings (AttributeId, AttributeValueId);
END
GO

IF OBJECT_ID(N'dbo.ProductMedia', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductMedia
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ProductId       INT             NOT NULL,
        VariantId       INT             NULL,
        MediaId         INT             NULL,
        Url             NVARCHAR(1000)  NOT NULL,
        ThumbnailUrl    NVARCHAR(1000)  NULL,
        /* Required. A product image without alt text blocks publication. */
        AltText         NVARCHAR(300)   NOT NULL CONSTRAINT DF_ProductMedia_AltText DEFAULT (N''),
        /* ProductMediaType: 0 Image, 1 Video, 2 Spin360 */
        MediaType       TINYINT         NOT NULL CONSTRAINT DF_ProductMedia_MediaType DEFAULT (0),
        Width           INT             NULL,
        Height          INT             NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_ProductMedia_SortOrder DEFAULT (0),
        IsPrimary       BIT             NOT NULL CONSTRAINT DF_ProductMedia_IsPrimary DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ProductMedia_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_ProductMedia_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_ProductMedia_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ProductMedia PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ProductMedia_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products (Id),
        CONSTRAINT FK_ProductMedia_Variants FOREIGN KEY (VariantId) REFERENCES dbo.ProductVariants (Id),
        CONSTRAINT FK_ProductMedia_Media    FOREIGN KEY (MediaId)   REFERENCES dbo.MediaAssets (Id)
    );

    CREATE INDEX IX_ProductMedia_Product ON dbo.ProductMedia (ProductId, SortOrder) WHERE IsDeleted = 0;
    /* At most one primary image per product. */
    CREATE UNIQUE INDEX UX_ProductMedia_Primary ON dbo.ProductMedia (ProductId)
        WHERE IsPrimary = 1 AND IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.ProductSpecifications', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductSpecifications
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ProductId       INT             NOT NULL,
        GroupTitle      NVARCHAR(200)   NOT NULL,
        SpecKey         NVARCHAR(200)   NOT NULL,
        SpecValue       NVARCHAR(1000)  NOT NULL,
        HelpText        NVARCHAR(500)   NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_ProductSpecifications_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ProductSpecifications_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_ProductSpecifications_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_ProductSpecifications_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ProductSpecifications PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ProductSpecifications_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products (Id)
    );

    CREATE INDEX IX_ProductSpecifications_Product ON dbo.ProductSpecifications (ProductId, SortOrder) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.ProductFaqs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductFaqs
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        ProductId       INT             NOT NULL,
        Question        NVARCHAR(500)   NOT NULL,
        Answer          NVARCHAR(MAX)   NOT NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_ProductFaqs_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ProductFaqs_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_ProductFaqs_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_ProductFaqs_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ProductFaqs PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ProductFaqs_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products (Id)
    );

    CREATE INDEX IX_ProductFaqs_Product ON dbo.ProductFaqs (ProductId, SortOrder) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.ProductTags', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductTags
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ProductId       INT             NOT NULL,
        TagId           INT             NOT NULL,

        CONSTRAINT PK_ProductTags PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ProductTags UNIQUE (ProductId, TagId),
        CONSTRAINT FK_ProductTags_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products (Id),
        CONSTRAINT FK_ProductTags_Tags     FOREIGN KEY (TagId)     REFERENCES dbo.Tags (Id)
    );

    CREATE INDEX IX_ProductTags_Tag ON dbo.ProductTags (TagId);
END
GO

/* Manual badges only — Handmade, Eco, GiTagged, Limited. Sale, Bestseller and
   New are computed by the API from price, sales and publish date, so a badge can
   never claim something untrue. The CHECK is what enforces that at the storage
   layer rather than trusting every caller. */
IF OBJECT_ID(N'dbo.ProductBadges', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductBadges
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ProductId       INT             NOT NULL,
        /* ProductBadge: 3 Handmade, 4 Limited, 5 Eco, 6 GiTagged */
        Badge           TINYINT         NOT NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ProductBadges_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,

        CONSTRAINT PK_ProductBadges PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ProductBadges UNIQUE (ProductId, Badge),
        CONSTRAINT FK_ProductBadges_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products (Id),
        CONSTRAINT CK_ProductBadges_ManualOnly CHECK (Badge IN (3, 4, 5, 6))
    );
END
GO

/* Cross-sell and up-sell rails on the PDP. RelationType keeps the three uses
   apart: Related | Similar | FrequentlyBoughtTogether. */
IF OBJECT_ID(N'dbo.ProductRelations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductRelations
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        ProductId           INT             NOT NULL,
        RelatedProductId    INT             NOT NULL,
        RelationType        VARCHAR(48)     NOT NULL CONSTRAINT DF_ProductRelations_Type DEFAULT ('Related'),
        SortOrder           INT             NOT NULL CONSTRAINT DF_ProductRelations_SortOrder DEFAULT (0),

        CONSTRAINT PK_ProductRelations PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ProductRelations UNIQUE (ProductId, RelatedProductId, RelationType),
        CONSTRAINT FK_ProductRelations_Product        FOREIGN KEY (ProductId)        REFERENCES dbo.Products (Id),
        CONSTRAINT FK_ProductRelations_RelatedProduct FOREIGN KEY (RelatedProductId) REFERENCES dbo.Products (Id),
        CONSTRAINT CK_ProductRelations_NotSelf CHECK (ProductId <> RelatedProductId)
    );
END
GO
