/* =============================================================================
   02_Locations.sql — Country, State, City, ZipCode, GeoZone
   -----------------------------------------------------------------------------
   Serviceability lives here. ZipCodes is what decides whether checkout can accept
   an address at all, and what the PDP PIN check answers.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.Countries', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Countries
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        CountryName     NVARCHAR(150)   NOT NULL,
        IsoCode         VARCHAR(3)      NOT NULL,      -- ISO 3166-1 alpha-2 or alpha-3
        Iso3Code        VARCHAR(3)      NULL,
        DialCode        VARCHAR(8)      NULL,
        CurrencyCode    VARCHAR(3)      NULL,
        FlagUrl         NVARCHAR(500)   NULL,
        Description     NVARCHAR(500)   NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_Countries_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Countries_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Countries_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Countries_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Countries PRIMARY KEY CLUSTERED (Id)
    );

    CREATE UNIQUE INDEX UX_Countries_IsoCode ON dbo.Countries (IsoCode) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.States', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.States
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        CountryId       INT             NOT NULL,
        StateName       NVARCHAR(150)   NOT NULL,
        StateCode       VARCHAR(10)     NULL,
        /* Two-digit GST state code. Drives place-of-supply and the CGST/SGST vs
           IGST split on every invoice — see 12_Payments.sql Invoices. */
        GstStateCode    VARCHAR(2)      NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_States_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_States_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_States_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_States_IsDeleted DEFAULT (0),

        CONSTRAINT PK_States PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_States_Countries FOREIGN KEY (CountryId) REFERENCES dbo.Countries (Id)
    );

    CREATE INDEX IX_States_Country ON dbo.States (CountryId) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.Cities', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Cities
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        StateId         INT             NOT NULL,
        CityName        NVARCHAR(150)   NOT NULL,
        IsMetro         BIT             NOT NULL CONSTRAINT DF_Cities_IsMetro DEFAULT (0),
        Latitude        DECIMAL(9,6)    NULL,
        Longitude       DECIMAL(9,6)    NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_Cities_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Cities_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Cities_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Cities_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Cities PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Cities_States FOREIGN KEY (StateId) REFERENCES dbo.States (Id)
    );

    CREATE INDEX IX_Cities_State ON dbo.Cities (StateId) WHERE IsDeleted = 0;
    CREATE INDEX IX_Cities_Name ON dbo.Cities (CityName) WHERE IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Delivery zoning. A GeoZone groups pincodes for delivery-day promises
   (Metro / Rest of India / North East etc). Shipping rate cards reference their
   own ShippingZones in 13_Shipping.sql — these two are deliberately separate so
   a courier rate change cannot silently alter a delivery promise.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.GeoZones', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GeoZones
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        ZoneName            NVARCHAR(150)   NOT NULL,
        ZoneCode            VARCHAR(32)     NOT NULL,
        Description         NVARCHAR(500)   NULL,
        StandardDeliveryDays INT            NOT NULL CONSTRAINT DF_GeoZones_StandardDays DEFAULT (6),
        ExpressDeliveryDays INT             NULL,
        SortOrder           INT             NOT NULL CONSTRAINT DF_GeoZones_SortOrder DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_GeoZones_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_GeoZones_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_GeoZones_IsDeleted DEFAULT (0),

        CONSTRAINT PK_GeoZones PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_GeoZones_Code UNIQUE (ZoneCode)
    );
END
GO

/* ---------------------------------------------------------------------------
   ZipCodes — serviceability and the delivery promise.
   The PDP PIN check, the cart estimate and the checkout address validation all
   read this one table, so there is a single answer to "can you deliver here".
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ZipCodes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ZipCodes
    (
        Id                      INT             IDENTITY(1,1) NOT NULL,
        Pincode                 VARCHAR(12)     NOT NULL,
        CityId                  INT             NOT NULL,
        GeoZoneId               INT             NULL,
        AreaName                NVARCHAR(200)   NULL,
        IsServiceable           BIT             NOT NULL CONSTRAINT DF_ZipCodes_IsServiceable DEFAULT (1),
        CodAvailable            BIT             NOT NULL CONSTRAINT DF_ZipCodes_CodAvailable DEFAULT (1),
        PrepaidAvailable        BIT             NOT NULL CONSTRAINT DF_ZipCodes_PrepaidAvailable DEFAULT (1),
        ReversePickupAvailable  BIT             NOT NULL CONSTRAINT DF_ZipCodes_ReversePickup DEFAULT (1),
        StandardDeliveryDays    INT             NOT NULL CONSTRAINT DF_ZipCodes_StandardDays DEFAULT (6),
        ExpressDeliveryDays     INT             NULL,
        /* Shown to the shopper when not serviceable, so they know why. */
        UnavailableReason       NVARCHAR(300)   NULL,

        CreatedAt               DATETIME2(3)    NOT NULL CONSTRAINT DF_ZipCodes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy               INT             NULL,
        UpdatedAt               DATETIME2(3)    NULL,
        UpdatedBy               INT             NULL,
        IsActive                BIT             NOT NULL CONSTRAINT DF_ZipCodes_IsActive  DEFAULT (1),
        IsDeleted               BIT             NOT NULL CONSTRAINT DF_ZipCodes_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ZipCodes PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ZipCodes_Cities   FOREIGN KEY (CityId)    REFERENCES dbo.Cities (Id),
        CONSTRAINT FK_ZipCodes_GeoZones FOREIGN KEY (GeoZoneId) REFERENCES dbo.GeoZones (Id)
    );

    /* The PIN check hits this on every PDP view — it must be a single seek. */
    CREATE UNIQUE INDEX UX_ZipCodes_Pincode ON dbo.ZipCodes (Pincode) WHERE IsDeleted = 0;
    CREATE INDEX IX_ZipCodes_City ON dbo.ZipCodes (CityId) WHERE IsDeleted = 0;
END
GO
