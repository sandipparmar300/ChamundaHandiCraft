/* =============================================================================
   14_Content.sql — CmsPages, Faqs, ContactSubmissions, Blog, Banners,
                    Testimonials
   -----------------------------------------------------------------------------
   All content shares ContentStatus (0 Draft, 1 Scheduled, 2 Published,
   3 Unpublished, 4 Archived). Only Published reaches the storefront, and
   Scheduled waits for its PublishOn date.

   A banner without ImageAlt cannot publish: campaign text baked into an image is
   invisible to a screen reader and untranslatable.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.CmsPages', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CmsPages
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Title           NVARCHAR(300)   NOT NULL,
        Slug            VARCHAR(300)    NOT NULL,
        BodyHtml        NVARCHAR(MAX)   NULL,
        /* Policy | Landing | About | Help — decides the Razor layout used. */
        Template        VARCHAR(48)     NOT NULL CONSTRAINT DF_CmsPages_Template DEFAULT ('Policy'),
        /* ContentStatus */
        Status          TINYINT         NOT NULL CONSTRAINT DF_CmsPages_Status DEFAULT (0),
        PublishOn       DATETIME2(3)    NULL,
        PublishedOn     DATETIME2(3)    NULL,
        /* Policy pages are linked from the footer and cannot be deleted. */
        IsSystemPage    BIT             NOT NULL CONSTRAINT DF_CmsPages_IsSystemPage DEFAULT (0),
        /* Publishing a legal page routes through the approval queue. */
        RequiresApproval BIT            NOT NULL CONSTRAINT DF_CmsPages_RequiresApproval DEFAULT (0),
        ViewCount       INT             NOT NULL CONSTRAINT DF_CmsPages_ViewCount DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_CmsPages_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_CmsPages_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_CmsPages_IsDeleted DEFAULT (0),

        CONSTRAINT PK_CmsPages PRIMARY KEY CLUSTERED (Id)
    );

    CREATE UNIQUE INDEX UX_CmsPages_Slug ON dbo.CmsPages (Slug) WHERE IsDeleted = 0;
END
GO

/* Help-centre and PDP FAQs. ProductId is set for a PDP FAQ; Topic groups the
   help-centre ones. */
IF OBJECT_ID(N'dbo.Faqs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Faqs
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Question        NVARCHAR(500)   NOT NULL,
        Answer          NVARCHAR(MAX)   NOT NULL,
        Topic           NVARCHAR(150)   NOT NULL CONSTRAINT DF_Faqs_Topic DEFAULT (N'General'),
        CategoryId      INT             NULL,
        ProductId       INT             NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_Faqs_SortOrder DEFAULT (0),
        HelpfulCount    INT             NOT NULL CONSTRAINT DF_Faqs_HelpfulCount DEFAULT (0),
        NotHelpfulCount INT             NOT NULL CONSTRAINT DF_Faqs_NotHelpfulCount DEFAULT (0),
        /* Included in the FAQPage JSON-LD emitted for the help centre. */
        IncludeInSchema BIT             NOT NULL CONSTRAINT DF_Faqs_IncludeInSchema DEFAULT (1),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Faqs_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Faqs_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Faqs_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Faqs PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Faqs_Categories FOREIGN KEY (CategoryId) REFERENCES dbo.Categories (Id),
        CONSTRAINT FK_Faqs_Products   FOREIGN KEY (ProductId)  REFERENCES dbo.Products (Id)
    );

    CREATE INDEX IX_Faqs_Topic ON dbo.Faqs (Topic, SortOrder) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.ContactSubmissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ContactSubmissions
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Name            NVARCHAR(200)   NOT NULL,
        Email           NVARCHAR(256)   NOT NULL,
        Phone           VARCHAR(24)     NULL,
        Subject         NVARCHAR(300)   NOT NULL,
        Message         NVARCHAR(MAX)   NOT NULL,
        OrderNumber     VARCHAR(32)     NULL,
        CustomerId      INT             NULL,
        SubmittedOn     DATETIME2(3)    NOT NULL CONSTRAINT DF_ContactSubmissions_SubmittedOn DEFAULT (SYSUTCDATETIME()),
        IsHandled       BIT             NOT NULL CONSTRAINT DF_ContactSubmissions_IsHandled DEFAULT (0),
        HandledBy       INT             NULL,
        HandledByName   NVARCHAR(200)   NULL,
        HandledOn       DATETIME2(3)    NULL,
        InternalNote    NVARCHAR(2000)  NULL,
        /* Set when this submission was converted into a support ticket. */
        SupportTicketId INT             NULL,
        IpAddress       VARCHAR(64)     NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ContactSubmissions_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_ContactSubmissions_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_ContactSubmissions_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ContactSubmissions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ContactSubmissions_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id)
    );

    CREATE INDEX IX_ContactSubmissions_Pending ON dbo.ContactSubmissions (SubmittedOn DESC) WHERE IsHandled = 0 AND IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Blog
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.BlogCategories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BlogCategories
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Name            NVARCHAR(200)   NOT NULL,
        Slug            VARCHAR(220)    NOT NULL,
        Description     NVARCHAR(1000)  NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_BlogCategories_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_BlogCategories_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_BlogCategories_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_BlogCategories_IsDeleted DEFAULT (0),

        CONSTRAINT PK_BlogCategories PRIMARY KEY CLUSTERED (Id)
    );

    CREATE UNIQUE INDEX UX_BlogCategories_Slug ON dbo.BlogCategories (Slug) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.BlogAuthors', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BlogAuthors
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Name            NVARCHAR(200)   NOT NULL,
        Slug            VARCHAR(220)    NOT NULL,
        Bio             NVARCHAR(2000)  NULL,
        PhotoMediaId    INT             NULL,
        PhotoUrl        NVARCHAR(1000)  NULL,
        Email           NVARCHAR(256)   NULL,
        /* Linked back to the admin account when the author is a staff member. */
        AdminUserId     INT             NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_BlogAuthors_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_BlogAuthors_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_BlogAuthors_IsDeleted DEFAULT (0),

        CONSTRAINT PK_BlogAuthors PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_BlogAuthors_Media      FOREIGN KEY (PhotoMediaId) REFERENCES dbo.MediaAssets (Id),
        CONSTRAINT FK_BlogAuthors_AdminUsers FOREIGN KEY (AdminUserId)  REFERENCES dbo.AdminUsers (Id)
    );

    CREATE UNIQUE INDEX UX_BlogAuthors_Slug ON dbo.BlogAuthors (Slug) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.BlogPosts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BlogPosts
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Title           NVARCHAR(300)   NOT NULL,
        Slug            VARCHAR(300)    NOT NULL,
        Excerpt         NVARCHAR(1000)  NULL,
        BodyHtml        NVARCHAR(MAX)   NULL,
        CoverMediaId    INT             NULL,
        CoverUrl        NVARCHAR(1000)  NULL,
        CoverAlt        NVARCHAR(300)   NULL,
        CategoryId      INT             NULL,
        AuthorId        INT             NULL,
        ReadMinutes     INT             NOT NULL CONSTRAINT DF_BlogPosts_ReadMinutes DEFAULT (5),
        /* ContentStatus */
        Status          TINYINT         NOT NULL CONSTRAINT DF_BlogPosts_Status DEFAULT (0),
        PublishOn       DATETIME2(3)    NULL,
        PublishedOn     DATETIME2(3)    NULL,
        ViewCount       INT             NOT NULL CONSTRAINT DF_BlogPosts_ViewCount DEFAULT (0),
        CommentCount    INT             NOT NULL CONSTRAINT DF_BlogPosts_CommentCount DEFAULT (0),
        AllowComments   BIT             NOT NULL CONSTRAINT DF_BlogPosts_AllowComments DEFAULT (1),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_BlogPosts_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_BlogPosts_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_BlogPosts_IsDeleted DEFAULT (0),

        CONSTRAINT PK_BlogPosts PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_BlogPosts_Categories FOREIGN KEY (CategoryId)   REFERENCES dbo.BlogCategories (Id),
        CONSTRAINT FK_BlogPosts_Authors    FOREIGN KEY (AuthorId)     REFERENCES dbo.BlogAuthors (Id),
        CONSTRAINT FK_BlogPosts_CoverMedia FOREIGN KEY (CoverMediaId) REFERENCES dbo.MediaAssets (Id)
    );

    CREATE UNIQUE INDEX UX_BlogPosts_Slug ON dbo.BlogPosts (Slug) WHERE IsDeleted = 0;
    CREATE INDEX IX_BlogPosts_Published ON dbo.BlogPosts (Status, PublishedOn DESC) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.BlogPostTags', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BlogPostTags
    (
        Id              BIGINT  IDENTITY(1,1) NOT NULL,
        BlogPostId      INT     NOT NULL,
        TagId           INT     NOT NULL,

        CONSTRAINT PK_BlogPostTags PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_BlogPostTags UNIQUE (BlogPostId, TagId),
        CONSTRAINT FK_BlogPostTags_Posts FOREIGN KEY (BlogPostId) REFERENCES dbo.BlogPosts (Id),
        CONSTRAINT FK_BlogPostTags_Tags  FOREIGN KEY (TagId)      REFERENCES dbo.Tags (Id)
    );
END
GO

/* Drives the "Shop this story" rail — the link from editorial back into the
   catalogue. */
IF OBJECT_ID(N'dbo.BlogPostProducts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BlogPostProducts
    (
        Id              BIGINT  IDENTITY(1,1) NOT NULL,
        BlogPostId      INT     NOT NULL,
        ProductId       INT     NOT NULL,
        SortOrder       INT     NOT NULL CONSTRAINT DF_BlogPostProducts_SortOrder DEFAULT (0),

        CONSTRAINT PK_BlogPostProducts PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_BlogPostProducts UNIQUE (BlogPostId, ProductId),
        CONSTRAINT FK_BlogPostProducts_Posts    FOREIGN KEY (BlogPostId) REFERENCES dbo.BlogPosts (Id),
        CONSTRAINT FK_BlogPostProducts_Products FOREIGN KEY (ProductId)  REFERENCES dbo.Products (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.BlogComments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BlogComments
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        BlogPostId      INT             NOT NULL,
        ParentId        INT             NULL,
        CustomerId      INT             NULL,
        AuthorName      NVARCHAR(200)   NOT NULL,
        AuthorEmail     NVARCHAR(256)   NULL,
        Body            NVARCHAR(MAX)   NOT NULL,
        SubmittedOn     DATETIME2(3)    NOT NULL CONSTRAINT DF_BlogComments_SubmittedOn DEFAULT (SYSUTCDATETIME()),
        /* ModerationStatus: 0 Pending, 1 Approved, 2 Rejected, 3 Spam */
        Status          TINYINT         NOT NULL CONSTRAINT DF_BlogComments_Status DEFAULT (0),
        ModeratedBy     INT             NULL,
        ModeratedOn     DATETIME2(3)    NULL,
        RejectionReason NVARCHAR(500)   NULL,
        IpAddress       VARCHAR(64)     NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_BlogComments_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_BlogComments_IsDeleted DEFAULT (0),

        CONSTRAINT PK_BlogComments PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_BlogComments_Posts     FOREIGN KEY (BlogPostId) REFERENCES dbo.BlogPosts (Id),
        CONSTRAINT FK_BlogComments_Parent    FOREIGN KEY (ParentId)   REFERENCES dbo.BlogComments (Id),
        CONSTRAINT FK_BlogComments_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id)
    );

    CREATE INDEX IX_BlogComments_Post   ON dbo.BlogComments (BlogPostId, Status) WHERE IsDeleted = 0;
    CREATE INDEX IX_BlogComments_Queue  ON dbo.BlogComments (Status, SubmittedOn DESC) WHERE IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Banners. MobileImageUrl is a separate crop, never a scaled desktop image —
   the hero has a 120 KB desktop / 70 KB mobile budget.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Banners', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Banners
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        /* BannerPlacement: 0 HomeHero, 1 HomeBand, 2 CategoryTop, 3 PlpInjection,
           4 CartUpsell, 5 AnnouncementBar */
        Placement           TINYINT         NOT NULL CONSTRAINT DF_Banners_Placement DEFAULT (0),
        Eyebrow             NVARCHAR(150)   NULL,
        Heading             NVARCHAR(300)   NOT NULL,
        SubHeading          NVARCHAR(500)   NULL,

        ImageMediaId        INT             NULL,
        ImageUrl            NVARCHAR(1000)  NOT NULL,
        MobileImageMediaId  INT             NULL,
        MobileImageUrl      NVARCHAR(1000)  NULL,
        /* Required. A banner without alt text cannot be published. */
        ImageAlt            NVARCHAR(300)   NOT NULL CONSTRAINT DF_Banners_ImageAlt DEFAULT (N''),

        PrimaryCtaLabel     NVARCHAR(100)   NULL,
        PrimaryCtaUrl       NVARCHAR(500)   NULL,
        SecondaryCtaLabel   NVARCHAR(100)   NULL,
        SecondaryCtaUrl     NVARCHAR(500)   NULL,

        /* Scopes a CategoryTop or PlpInjection banner to one category. */
        CategoryId          INT             NULL,
        StartsOn            DATETIME2(3)    NULL,
        EndsOn              DATETIME2(3)    NULL,
        SortOrder           INT             NOT NULL CONSTRAINT DF_Banners_SortOrder DEFAULT (0),
        /* ContentStatus */
        Status              TINYINT         NOT NULL CONSTRAINT DF_Banners_Status DEFAULT (0),
        ImpressionCount     INT             NOT NULL CONSTRAINT DF_Banners_ImpressionCount DEFAULT (0),
        ClickCount          INT             NOT NULL CONSTRAINT DF_Banners_ClickCount DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Banners_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Banners_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Banners_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Banners PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Banners_ImageMedia  FOREIGN KEY (ImageMediaId)       REFERENCES dbo.MediaAssets (Id),
        CONSTRAINT FK_Banners_MobileMedia FOREIGN KEY (MobileImageMediaId) REFERENCES dbo.MediaAssets (Id),
        CONSTRAINT FK_Banners_Categories  FOREIGN KEY (CategoryId)         REFERENCES dbo.Categories (Id),
        CONSTRAINT CK_Banners_Window CHECK (EndsOn IS NULL OR StartsOn IS NULL OR EndsOn > StartsOn)
    );

    CREATE INDEX IX_Banners_Placement ON dbo.Banners (Placement, Status, SortOrder) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.Testimonials', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Testimonials
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        CustomerName    NVARCHAR(200)   NOT NULL,
        Location        NVARCHAR(200)   NULL,
        Quote           NVARCHAR(2000)  NOT NULL,
        Rating          TINYINT         NOT NULL CONSTRAINT DF_Testimonials_Rating DEFAULT (5),
        PhotoMediaId    INT             NULL,
        PhotoUrl        NVARCHAR(1000)  NULL,
        /* Links a testimonial to the order that earned it, so it is verifiable. */
        OrderId         INT             NULL,
        ProductId       INT             NULL,
        ShowOnHome      BIT             NOT NULL CONSTRAINT DF_Testimonials_ShowOnHome DEFAULT (0),
        SortOrder       INT             NOT NULL CONSTRAINT DF_Testimonials_SortOrder DEFAULT (0),
        /* ContentStatus */
        Status          TINYINT         NOT NULL CONSTRAINT DF_Testimonials_Status DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Testimonials_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Testimonials_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Testimonials_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Testimonials PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Testimonials_Media    FOREIGN KEY (PhotoMediaId) REFERENCES dbo.MediaAssets (Id),
        CONSTRAINT FK_Testimonials_Orders   FOREIGN KEY (OrderId)      REFERENCES dbo.Orders (Id),
        CONSTRAINT FK_Testimonials_Products FOREIGN KEY (ProductId)    REFERENCES dbo.Products (Id),
        CONSTRAINT CK_Testimonials_Rating CHECK (Rating BETWEEN 1 AND 5)
    );

    CREATE INDEX IX_Testimonials_Home ON dbo.Testimonials (Status, SortOrder) WHERE ShowOnHome = 1 AND IsDeleted = 0;
END
GO
