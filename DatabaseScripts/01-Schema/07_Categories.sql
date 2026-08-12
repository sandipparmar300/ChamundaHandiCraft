/* =============================================================================
   07_Categories.sql — Categories, ProductCategories, Menus
   -----------------------------------------------------------------------------
   Categories are a tree, not a list. ShowInMegaMenu and IsFeaturedOnHome are
   independent of IsActive: a category can be live and reachable without
   occupying menu space.

   This file closes the loop left open in 06_Catalog.sql by adding the Products
   category foreign keys.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.Categories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Categories
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        ParentId            INT             NULL,
        Name                NVARCHAR(200)   NOT NULL,
        Slug                VARCHAR(220)    NOT NULL,
        Description         NVARCHAR(2000)  NULL,
        /* 80–150 words rendered with the PLP grid. One of the few SEO levers on
           a category page, so it is editorial copy rather than generated text. */
        IntroCopy           NVARCHAR(MAX)   NULL,

        ImageMediaId        INT             NULL,
        ImageUrl            NVARCHAR(1000)  NULL,
        BannerMediaId       INT             NULL,
        IconName            VARCHAR(64)     NULL,

        SortOrder           INT             NOT NULL CONSTRAINT DF_Categories_SortOrder DEFAULT (0),
        ShowInMegaMenu      BIT             NOT NULL CONSTRAINT DF_Categories_ShowInMegaMenu DEFAULT (1),
        IsFeaturedOnHome    BIT             NOT NULL CONSTRAINT DF_Categories_IsFeaturedOnHome DEFAULT (0),

        /* Materialised tree helpers, maintained on save. Depth 0 is a root
           category; TreePath is /1/14/37/ so a subtree reads without recursion. */
        Depth               INT             NOT NULL CONSTRAINT DF_Categories_Depth DEFAULT (0),
        TreePath            VARCHAR(900)    NULL,
        ProductCount        INT             NOT NULL CONSTRAINT DF_Categories_ProductCount DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Categories_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Categories_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Categories_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Categories PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Categories_Parent      FOREIGN KEY (ParentId)      REFERENCES dbo.Categories (Id),
        CONSTRAINT FK_Categories_ImageMedia  FOREIGN KEY (ImageMediaId)  REFERENCES dbo.MediaAssets (Id),
        CONSTRAINT FK_Categories_BannerMedia FOREIGN KEY (BannerMediaId) REFERENCES dbo.MediaAssets (Id)
    );

    CREATE UNIQUE INDEX UX_Categories_Slug ON dbo.Categories (Slug) WHERE IsDeleted = 0;
    CREATE INDEX IX_Categories_Parent ON dbo.Categories (ParentId, SortOrder) WHERE IsDeleted = 0;
    CREATE INDEX IX_Categories_TreePath ON dbo.Categories (TreePath) WHERE IsDeleted = 0;
END
GO

/* Secondary category placements. A product has exactly one primary CategoryId
   (Products.CategoryId, which the breadcrumb and canonical URL use) and may
   additionally appear under any number of others. */
IF OBJECT_ID(N'dbo.ProductCategories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductCategories
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ProductId       INT             NOT NULL,
        CategoryId      INT             NOT NULL,
        IsPrimary       BIT             NOT NULL CONSTRAINT DF_ProductCategories_IsPrimary DEFAULT (0),
        SortOrder       INT             NOT NULL CONSTRAINT DF_ProductCategories_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ProductCategories_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,

        CONSTRAINT PK_ProductCategories PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ProductCategories UNIQUE (ProductId, CategoryId),
        CONSTRAINT FK_ProductCategories_Products   FOREIGN KEY (ProductId)  REFERENCES dbo.Products (Id),
        CONSTRAINT FK_ProductCategories_Categories FOREIGN KEY (CategoryId) REFERENCES dbo.Categories (Id)
    );

    CREATE INDEX IX_ProductCategories_Category ON dbo.ProductCategories (CategoryId, SortOrder);
END
GO

/* Products in a curated collection. */
IF OBJECT_ID(N'dbo.CollectionProducts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CollectionProducts
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        CollectionId    INT             NOT NULL,
        ProductId       INT             NOT NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_CollectionProducts_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_CollectionProducts_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,

        CONSTRAINT PK_CollectionProducts PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_CollectionProducts UNIQUE (CollectionId, ProductId),
        CONSTRAINT FK_CollectionProducts_Collections FOREIGN KEY (CollectionId) REFERENCES dbo.Collections (Id),
        CONSTRAINT FK_CollectionProducts_Products    FOREIGN KEY (ProductId)    REFERENCES dbo.Products (Id)
    );
END
GO

/* ---------------------------------------------------------------------------
   Storefront navigation. Written in Admin, rendered in the header, mega menu,
   footer and mobile drawer. Self-referencing so a footer column is a parent with
   its links as children.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Menus', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Menus
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        ParentId        INT             NULL,
        Title           NVARCHAR(200)   NOT NULL,
        /* Header | MegaMenu | Footer | Mobile */
        Location        VARCHAR(32)     NOT NULL CONSTRAINT DF_Menus_Location DEFAULT ('Header'),
        Url             NVARCHAR(500)   NULL,
        /* When set, Url is derived from the linked entity's slug so a rename
           cannot leave a dead menu item behind. */
        LinkType        VARCHAR(32)     NULL,          -- Custom|Category|Collection|CmsPage|Blog
        LinkEntityId    INT             NULL,
        IconName        VARCHAR(64)     NULL,
        ImageMediaId    INT             NULL,
        Badge           NVARCHAR(50)    NULL,          -- "New", "Sale"
        SortOrder       INT             NOT NULL CONSTRAINT DF_Menus_SortOrder DEFAULT (0),
        OpensInNewTab   BIT             NOT NULL CONSTRAINT DF_Menus_OpensInNewTab DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Menus_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Menus_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Menus_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Menus PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Menus_Parent     FOREIGN KEY (ParentId)     REFERENCES dbo.Menus (Id),
        CONSTRAINT FK_Menus_ImageMedia FOREIGN KEY (ImageMediaId) REFERENCES dbo.MediaAssets (Id)
    );

    CREATE INDEX IX_Menus_Location ON dbo.Menus (Location, ParentId, SortOrder) WHERE IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Deferred foreign keys from 06_Catalog.sql.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.FK_Products_Categories', N'F') IS NULL
    ALTER TABLE dbo.Products
        ADD CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) REFERENCES dbo.Categories (Id);
GO

IF OBJECT_ID(N'dbo.FK_Products_SubCategories', N'F') IS NULL
    ALTER TABLE dbo.Products
        ADD CONSTRAINT FK_Products_SubCategories FOREIGN KEY (SubCategoryId) REFERENCES dbo.Categories (Id);
GO

IF OBJECT_ID(N'dbo.FK_Products_Collections', N'F') IS NULL
    ALTER TABLE dbo.Products
        ADD CONSTRAINT FK_Products_Collections FOREIGN KEY (CollectionId) REFERENCES dbo.Collections (Id);
GO
