/* =============================================================================
   05_Customers.sql — Customers, Addresses, Segments, RewardPoints, Wishlists,
                      Consent, Sessions
   -----------------------------------------------------------------------------
   Customers and AdminUsers are deliberately separate tables. A shopper is not a
   back-office account, and merging them would put storefront traffic on the same
   lockout and 2FA rules as the admin panel.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.Customers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Customers
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        FullName            NVARCHAR(200)   NOT NULL,
        Email               NVARCHAR(256)   NULL,
        Phone               VARCHAR(24)     NULL,
        /* Password is null for OTP-only and social accounts. */
        PasswordHash        NVARCHAR(500)   NULL,
        EmailVerified       BIT             NOT NULL CONSTRAINT DF_Customers_EmailVerified  DEFAULT (0),
        MobileVerified      BIT             NOT NULL CONSTRAINT DF_Customers_MobileVerified DEFAULT (0),
        Gender              VARCHAR(16)     NULL,
        DateOfBirth         DATE            NULL,
        AvatarUrl           NVARCHAR(1000)  NULL,
        Gstin               VARCHAR(20)     NULL,

        /* CustomerStatus: 0 Active, 1 Inactive, 2 Blocked, 3 Deleted */
        Status              TINYINT         NOT NULL CONSTRAINT DF_Customers_Status DEFAULT (0),
        BlockedReason       NVARCHAR(500)   NULL,

        /* Denormalised lifetime figures, recalculated on order completion.
           The admin grid reads these; nothing prices from them. */
        OrderCount          INT             NOT NULL CONSTRAINT DF_Customers_OrderCount DEFAULT (0),
        LifetimeValue       DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Customers_LifetimeValue DEFAULT (0),
        LastOrderOn         DATETIME2(3)    NULL,
        RewardPointBalance  INT             NOT NULL CONSTRAINT DF_Customers_RewardPointBalance DEFAULT (0),
        RewardTier          NVARCHAR(50)    NOT NULL CONSTRAINT DF_Customers_RewardTier DEFAULT (N'Bronze'),

        /* The long-lived ch_guest cookie value, retained after the merge so an
           abandoned guest cart can still be attributed. */
        GuestToken          VARCHAR(64)     NULL,
        RegisteredOn        DATETIME2(3)    NOT NULL CONSTRAINT DF_Customers_RegisteredOn DEFAULT (SYSUTCDATETIME()),
        LastLoginOn         DATETIME2(3)    NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Customers_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Customers_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Customers_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Customers PRIMARY KEY CLUSTERED (Id)
    );

    CREATE UNIQUE INDEX UX_Customers_Email ON dbo.Customers (Email) WHERE Email IS NOT NULL AND IsDeleted = 0;
    CREATE UNIQUE INDEX UX_Customers_Phone ON dbo.Customers (Phone) WHERE Phone IS NOT NULL AND IsDeleted = 0;
    CREATE INDEX IX_Customers_GuestToken ON dbo.Customers (GuestToken) WHERE GuestToken IS NOT NULL;
END
GO

IF OBJECT_ID(N'dbo.CustomerAddresses', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CustomerAddresses
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        CustomerId      INT             NOT NULL,
        /* AddressType: 0 Home, 1 Work, 2 Other */
        LabelType       TINYINT         NOT NULL CONSTRAINT DF_CustomerAddresses_LabelType DEFAULT (0),
        FullName        NVARCHAR(200)   NOT NULL,
        Phone           VARCHAR(24)     NOT NULL,
        AlternatePhone  VARCHAR(24)     NULL,
        Line1           NVARCHAR(300)   NOT NULL,
        Line2           NVARCHAR(300)   NULL,
        Landmark        NVARCHAR(200)   NULL,
        CityId          INT             NULL,
        StateId         INT             NULL,
        CountryId       INT             NULL,
        /* Denormalised names, so a historic address still reads correctly if a
           city is later renamed or deactivated. */
        CityName        NVARCHAR(150)   NOT NULL,
        StateName       NVARCHAR(150)   NOT NULL,
        CountryName     NVARCHAR(150)   NOT NULL CONSTRAINT DF_CustomerAddresses_CountryName DEFAULT (N'India'),
        Pincode         VARCHAR(12)     NOT NULL,
        IsDefault       BIT             NOT NULL CONSTRAINT DF_CustomerAddresses_IsDefault DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_CustomerAddresses_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_CustomerAddresses_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_CustomerAddresses_IsDeleted DEFAULT (0),

        CONSTRAINT PK_CustomerAddresses PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_CustomerAddresses_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_CustomerAddresses_Cities    FOREIGN KEY (CityId)     REFERENCES dbo.Cities (Id),
        CONSTRAINT FK_CustomerAddresses_States    FOREIGN KEY (StateId)    REFERENCES dbo.States (Id),
        CONSTRAINT FK_CustomerAddresses_Countries FOREIGN KEY (CountryId)  REFERENCES dbo.Countries (Id)
    );

    CREATE INDEX IX_CustomerAddresses_Customer ON dbo.CustomerAddresses (CustomerId) WHERE IsDeleted = 0;
END
GO

/* Segments. RuleJson is the machine-readable definition; RuleSummary is the
   plain-language line the admin grid shows. */
IF OBJECT_ID(N'dbo.CustomerSegments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CustomerSegments
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Name            NVARCHAR(200)   NOT NULL,
        Description     NVARCHAR(500)   NULL,
        RuleJson        NVARCHAR(MAX)   NULL,
        RuleSummary     NVARCHAR(500)   NULL,
        /* Static segments hold a fixed member list; dynamic ones are re-evaluated. */
        IsDynamic       BIT             NOT NULL CONSTRAINT DF_CustomerSegments_IsDynamic DEFAULT (1),
        CustomerCount   INT             NOT NULL CONSTRAINT DF_CustomerSegments_CustomerCount DEFAULT (0),
        LastEvaluatedOn DATETIME2(3)    NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_CustomerSegments_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_CustomerSegments_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_CustomerSegments_IsDeleted DEFAULT (0),

        CONSTRAINT PK_CustomerSegments PRIMARY KEY CLUSTERED (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.CustomerSegmentMembers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CustomerSegmentMembers
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        SegmentId       INT             NOT NULL,
        CustomerId      INT             NOT NULL,
        AddedAt         DATETIME2(3)    NOT NULL CONSTRAINT DF_CustomerSegmentMembers_AddedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_CustomerSegmentMembers PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_CustomerSegmentMembers UNIQUE (SegmentId, CustomerId),
        CONSTRAINT FK_CustomerSegmentMembers_Segments  FOREIGN KEY (SegmentId)  REFERENCES dbo.CustomerSegments (Id),
        CONSTRAINT FK_CustomerSegmentMembers_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id)
    );

    CREATE INDEX IX_CustomerSegmentMembers_Customer ON dbo.CustomerSegmentMembers (CustomerId);
END
GO

/* Reward points ledger. Customers.RewardPointBalance is a running cache of this;
   the ledger is the truth, and every entry carries the balance it produced so a
   customer statement can be rendered without replaying the whole history. */
IF OBJECT_ID(N'dbo.RewardPointLedgers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RewardPointLedgers
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        CustomerId      INT             NOT NULL,
        /* RewardLedgerType: 0 Earned, 1 Redeemed, 2 Expired, 3 Reversed, 4 Adjusted */
        EntryType       TINYINT         NOT NULL,
        Activity        NVARCHAR(300)   NOT NULL,
        Delta           INT             NOT NULL,      -- signed
        BalanceAfter    INT             NOT NULL,
        OrderId         INT             NULL,          -- FK added in 11_Orders.sql
        ExpiresOn       DATETIME2(3)    NULL,
        Note            NVARCHAR(500)   NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_RewardPointLedgers_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,

        CONSTRAINT PK_RewardPointLedgers PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_RewardPointLedgers_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id)
    );

    CREATE INDEX IX_RewardPointLedgers_Customer ON dbo.RewardPointLedgers (CustomerId, CreatedAt DESC);
END
GO

/* Wishlist. A customer may keep several named lists; the default one is what the
   heart icon writes to. Guest wishlists key on GuestToken until the merge. */
IF OBJECT_ID(N'dbo.Wishlists', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Wishlists
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        CustomerId      INT             NULL,
        GuestToken      VARCHAR(64)     NULL,
        Name            NVARCHAR(200)   NOT NULL CONSTRAINT DF_Wishlists_Name DEFAULT (N'My Wishlist'),
        IsDefault       BIT             NOT NULL CONSTRAINT DF_Wishlists_IsDefault DEFAULT (1),
        /* Shareable read-only link token. Null until the customer shares it. */
        ShareToken      VARCHAR(64)     NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Wishlists_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Wishlists_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Wishlists_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Wishlists PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Wishlists_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id),
        CONSTRAINT CK_Wishlists_Owner CHECK (CustomerId IS NOT NULL OR GuestToken IS NOT NULL)
    );

    CREATE INDEX IX_Wishlists_Customer ON dbo.Wishlists (CustomerId) WHERE IsDeleted = 0;
    CREATE INDEX IX_Wishlists_GuestToken ON dbo.Wishlists (GuestToken) WHERE GuestToken IS NOT NULL;
END
GO

/* WishlistItems.ProductId / VariantId FKs are added in 06_Catalog.sql, which is
   where those tables come into existence. */
IF OBJECT_ID(N'dbo.WishlistItems', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.WishlistItems
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        WishlistId      INT             NOT NULL,
        ProductId       INT             NOT NULL,
        VariantId       INT             NULL,
        /* Price when it was added, so "price dropped" can be stated truthfully. */
        PriceWhenAdded  DECIMAL(18,2)   NULL,
        Note            NVARCHAR(500)   NULL,
        AddedAt         DATETIME2(3)    NOT NULL CONSTRAINT DF_WishlistItems_AddedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_WishlistItems PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_WishlistItems UNIQUE (WishlistId, ProductId, VariantId),
        CONSTRAINT FK_WishlistItems_Wishlists FOREIGN KEY (WishlistId) REFERENCES dbo.Wishlists (Id)
    );
END
GO

/* Consent log. Marketing consent is captured unticked and never assumed, so each
   grant and withdrawal is recorded with its source and timestamp. */
IF OBJECT_ID(N'dbo.CustomerConsents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CustomerConsents
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        CustomerId      INT             NULL,
        Email           NVARCHAR(256)   NULL,
        ConsentType     VARCHAR(64)     NOT NULL,      -- Marketing|Cookies|Terms|Privacy|Whatsapp
        IsGranted       BIT             NOT NULL,
        Source          NVARCHAR(100)   NULL,          -- Footer|Checkout|Signup|AccountSettings
        IpAddress       VARCHAR(64)     NULL,
        RecordedAt      DATETIME2(3)    NOT NULL CONSTRAINT DF_CustomerConsents_RecordedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_CustomerConsents PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_CustomerConsents_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id)
    );

    CREATE INDEX IX_CustomerConsents_Customer ON dbo.CustomerConsents (CustomerId, ConsentType, RecordedAt DESC);
END
GO

IF OBJECT_ID(N'dbo.CustomerSessions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CustomerSessions
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        CustomerId          INT             NOT NULL,
        RefreshTokenHash    CHAR(64)        NOT NULL,
        IssuedAt            DATETIME2(3)    NOT NULL CONSTRAINT DF_CustomerSessions_IssuedAt DEFAULT (SYSUTCDATETIME()),
        ExpiresAt           DATETIME2(3)    NOT NULL,
        RevokedAt           DATETIME2(3)    NULL,
        DeviceLabel         NVARCHAR(200)   NULL,
        IpAddress           VARCHAR(64)     NULL,
        UserAgent           NVARCHAR(500)   NULL,

        CONSTRAINT PK_CustomerSessions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_CustomerSessions_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id)
    );

    CREATE INDEX IX_CustomerSessions_TokenHash ON dbo.CustomerSessions (RefreshTokenHash);
END
GO

/* One-time codes for phone/email verification and passwordless sign-in.
   Only the hash is stored, and attempts are capped. */
IF OBJECT_ID(N'dbo.CustomerOtps', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CustomerOtps
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        Destination     NVARCHAR(256)   NOT NULL,      -- phone or email
        Channel         TINYINT         NOT NULL,      -- NotificationChannel: 0 Email, 1 Sms, 2 WhatsApp
        Purpose         VARCHAR(48)     NOT NULL,      -- Login|VerifyEmail|VerifyPhone|ResetPassword
        CodeHash        CHAR(64)        NOT NULL,
        ExpiresAt       DATETIME2(3)    NOT NULL,
        AttemptCount    INT             NOT NULL CONSTRAINT DF_CustomerOtps_AttemptCount DEFAULT (0),
        ConsumedAt      DATETIME2(3)    NULL,
        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_CustomerOtps_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_CustomerOtps PRIMARY KEY CLUSTERED (Id)
    );

    CREATE INDEX IX_CustomerOtps_Destination ON dbo.CustomerOtps (Destination, Purpose, ExpiresAt DESC);
END
GO
