/* =============================================================================
   03_Masters.sql — Currency, TaxClass, HsnCode, ReasonCode, Material, Craft,
                    SizeChart and the generic MasterData lookup
   -----------------------------------------------------------------------------
   Small, mostly-static tables that everything else depends on. MasterData backs
   the generic Admin "Masters" screen (MasterGridItem); the tables with their own
   shape exist because other tables hold foreign keys into them.
   ============================================================================= */

SET NOCOUNT ON;
GO

/* Generic single-column lookup list, keyed by MasterType.
   Used for the small vocabularies that need no columns of their own —
   OrderCancelReason, PackagingType, GiftMessageTemplate and so on. */
IF OBJECT_ID(N'dbo.MasterData', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.MasterData
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        MasterType      VARCHAR(64)     NOT NULL,
        Name            NVARCHAR(200)   NOT NULL,
        Code            VARCHAR(64)     NULL,
        Description     NVARCHAR(500)   NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_MasterData_SortOrder DEFAULT (0),
        /* System rows are created by seed and cannot be deleted from the UI. */
        IsSystem        BIT             NOT NULL CONSTRAINT DF_MasterData_IsSystem DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_MasterData_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_MasterData_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_MasterData_IsDeleted DEFAULT (0),

        CONSTRAINT PK_MasterData PRIMARY KEY CLUSTERED (Id)
    );

    CREATE INDEX IX_MasterData_Type ON dbo.MasterData (MasterType, SortOrder) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.Currencies', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Currencies
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        CurrencyCode    VARCHAR(3)      NOT NULL,
        CurrencyName    NVARCHAR(100)   NOT NULL,
        Symbol          NVARCHAR(8)     NOT NULL,
        /* Rate against the base currency. 4dp because FX is not money. */
        ExchangeRate    DECIMAL(18,4)   NOT NULL CONSTRAINT DF_Currencies_ExchangeRate DEFAULT (1.0000),
        DecimalPlaces   TINYINT         NOT NULL CONSTRAINT DF_Currencies_DecimalPlaces DEFAULT (2),
        IsBaseCurrency  BIT             NOT NULL CONSTRAINT DF_Currencies_IsBase DEFAULT (0),
        RateUpdatedAt   DATETIME2(3)    NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Currencies_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Currencies_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Currencies_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Currencies PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Currencies_Code UNIQUE (CurrencyCode)
    );
END
GO

/* GST classes. A product points at a class; the class carries the rate split. */
IF OBJECT_ID(N'dbo.TaxClasses', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TaxClasses
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        ClassName       NVARCHAR(100)   NOT NULL,
        Code            VARCHAR(32)     NOT NULL,
        /* Total GST percent. Split into CGST+SGST intra-state, IGST inter-state. */
        RatePercent     DECIMAL(18,4)   NOT NULL CONSTRAINT DF_TaxClasses_RatePercent DEFAULT (0),
        CessPercent     DECIMAL(18,4)   NOT NULL CONSTRAINT DF_TaxClasses_CessPercent DEFAULT (0),
        Description     NVARCHAR(300)   NULL,
        IsDefault       BIT             NOT NULL CONSTRAINT DF_TaxClasses_IsDefault DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_TaxClasses_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_TaxClasses_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_TaxClasses_IsDeleted DEFAULT (0),

        CONSTRAINT PK_TaxClasses PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_TaxClasses_Code UNIQUE (Code)
    );
END
GO

IF OBJECT_ID(N'dbo.HsnCodes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HsnCodes
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Code            VARCHAR(16)     NOT NULL,
        Description     NVARCHAR(500)   NOT NULL,
        TaxClassId      INT             NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_HsnCodes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_HsnCodes_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_HsnCodes_IsDeleted DEFAULT (0),

        CONSTRAINT PK_HsnCodes PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_HsnCodes_Code UNIQUE (Code),
        CONSTRAINT FK_HsnCodes_TaxClasses FOREIGN KEY (TaxClassId) REFERENCES dbo.TaxClasses (Id)
    );
END
GO

/* Return, cancellation and stock-adjustment reasons.
   ReasonType keeps the three vocabularies apart; Category = Return maps onto the
   ReturnReason enum so the storefront form and the admin queue use one list. */
IF OBJECT_ID(N'dbo.ReasonCodes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReasonCodes
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        ReasonType      VARCHAR(32)     NOT NULL,      -- Return|Cancellation|Adjustment|Refund|Dispute
        Code            VARCHAR(64)     NOT NULL,
        Label           NVARCHAR(200)   NOT NULL,
        /* Numeric value of the matching Helper enum member, where one exists. */
        EnumValue       INT             NULL,
        RequiresPhoto   BIT             NOT NULL CONSTRAINT DF_ReasonCodes_RequiresPhoto DEFAULT (0),
        RequiresNote    BIT             NOT NULL CONSTRAINT DF_ReasonCodes_RequiresNote DEFAULT (0),
        /* A reason that puts the cost on us — drives the refund-shipping decision. */
        IsOurFault      BIT             NOT NULL CONSTRAINT DF_ReasonCodes_IsOurFault DEFAULT (0),
        SortOrder       INT             NOT NULL CONSTRAINT DF_ReasonCodes_SortOrder DEFAULT (0),
        IsSystem        BIT             NOT NULL CONSTRAINT DF_ReasonCodes_IsSystem DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ReasonCodes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_ReasonCodes_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_ReasonCodes_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ReasonCodes PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ReasonCodes_TypeCode UNIQUE (ReasonType, Code)
    );
END
GO

/* Craft vocabulary. Materials and crafts are first-class because they are PLP
   facets and appear on the PDP spec list, the artisan profile and the invoice. */
IF OBJECT_ID(N'dbo.Materials', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Materials
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Name            NVARCHAR(150)   NOT NULL,
        Slug            VARCHAR(160)    NOT NULL,
        Description     NVARCHAR(1000)  NULL,
        CareNote        NVARCHAR(1000)  NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_Materials_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Materials_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Materials_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Materials_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Materials PRIMARY KEY CLUSTERED (Id)
    );

    CREATE UNIQUE INDEX UX_Materials_Slug ON dbo.Materials (Slug) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.Crafts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Crafts
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Name            NVARCHAR(150)   NOT NULL,
        Slug            VARCHAR(160)    NOT NULL,
        /* The geographic cluster the craft belongs to — Kutch, Channapatna, etc. */
        OriginCluster   NVARCHAR(200)   NULL,
        Description     NVARCHAR(2000)  NULL,
        /* Geographical Indication registered. Surfaces as the GiTagged badge. */
        IsGiTagged      BIT             NOT NULL CONSTRAINT DF_Crafts_IsGiTagged DEFAULT (0),
        SortOrder       INT             NOT NULL CONSTRAINT DF_Crafts_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Crafts_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Crafts_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Crafts_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Crafts PRIMARY KEY CLUSTERED (Id)
    );

    CREATE UNIQUE INDEX UX_Crafts_Slug ON dbo.Crafts (Slug) WHERE IsDeleted = 0;
END
GO

/* Size charts rendered in the PDP size-guide drawer. RowsJson holds the grid so
   a chart can have any number of measurement columns without a schema change. */
IF OBJECT_ID(N'dbo.SizeCharts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SizeCharts
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Name            NVARCHAR(200)   NOT NULL,
        Code            VARCHAR(64)     NOT NULL,
        MeasurementUnit VARCHAR(16)     NOT NULL CONSTRAINT DF_SizeCharts_Unit DEFAULT ('cm'),
        RowsJson        NVARCHAR(MAX)   NULL,
        HowToMeasure    NVARCHAR(MAX)   NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_SizeCharts_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_SizeCharts_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_SizeCharts_IsDeleted DEFAULT (0),

        CONSTRAINT PK_SizeCharts PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_SizeCharts_Code UNIQUE (Code)
    );
END
GO
