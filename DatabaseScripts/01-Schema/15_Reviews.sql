/* =============================================================================
   15_Reviews.sql — product reviews, moderation, abuse handling, testimonial media
   -----------------------------------------------------------------------------
   Source specs:
     docs/Admin Flows/Review.txt          (moderation queue, abuse reports, replies)
     docs/Admin Flows/Testimonial.txt     (image / video testimonials)
     docs/Customer Flows/Product Detail.txt  §8  (rating distribution, helpful votes)
     docs/Customer Flows/My Account.txt       §9  (customer's own review history)

   Depends on: 05_Customers, 06_Catalog, 11_Orders, 01_Platform (MediaAssets),
               03_Masters (ReasonCodes), 14_Content (Testimonials).

   Why this file exists: dbo.OrderItems.ReviewId (11_Orders.sql) is a forward
   reference to dbo.Reviews. The FK is created at the end of this file.
   ============================================================================= */

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------------
   Reviews — one row per customer opinion of a product.

   Review.txt §18: "A customer can submit only one review per product unless
   review editing is enabled." Enforced by UX_Reviews_CustomerProduct rather
   than in the service, so a double-submit race cannot create two rows.

   Verified purchase (§6) is stored, not derived: the badge must remain true on
   the review even if the order is later archived or the product is replaced.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Reviews', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Reviews
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        ProductId           INT             NOT NULL,
        VariantId           INT             NULL,
        CustomerId          INT             NULL,          -- null once a customer is hard-anonymised
        /* Provenance of the verified-purchase badge. Null for imported or
           admin-entered reviews, which therefore never earn the badge. */
        OrderId             INT             NULL,
        OrderItemId         BIGINT          NULL,

        /* Display name captured at submission. Survives a later profile rename
           and lets IsAnonymous hide the account without losing the record. */
        AuthorName          NVARCHAR(200)   NOT NULL,
        AuthorEmail         NVARCHAR(256)   NULL,
        IsAnonymous         BIT             NOT NULL CONSTRAINT DF_Reviews_IsAnonymous DEFAULT (0),

        Rating              TINYINT         NOT NULL,
        Title               NVARCHAR(300)   NULL,
        Body                NVARCHAR(MAX)   NULL,
        /* Review.txt §5: "Recommend Product (Yes/No)". Null = not answered. */
        RecommendsProduct   BIT             NULL,

        IsVerifiedPurchase  BIT             NOT NULL CONSTRAINT DF_Reviews_IsVerifiedPurchase DEFAULT (0),

        /* ReviewStatus: 0 Pending, 1 Approved, 2 Rejected, 3 Hidden.
           Review.txt §18: reviews stay invisible until approved. Only status 1
           is ever served to the storefront. */
        Status              TINYINT         NOT NULL CONSTRAINT DF_Reviews_Status DEFAULT (0),
        /* Spam | OffensiveLanguage | FakeReview | Duplicate | Irrelevant | Abuse
           — drawn from dbo.ReasonCodes with ReasonType = 'ReviewModeration'. */
        ModerationReasonId  INT             NULL,
        ModerationNote      NVARCHAR(1000)  NULL,
        ModeratedBy         INT             NULL,
        ModeratedByName     NVARCHAR(200)   NULL,
        ModeratedOn         DATETIME2(3)    NULL,

        /* Denormalised counters. Maintained by their own tables' write paths so
           the review grid and PDP sort by helpfulness without an aggregate. */
        HelpfulCount        INT             NOT NULL CONSTRAINT DF_Reviews_HelpfulCount DEFAULT (0),
        NotHelpfulCount     INT             NOT NULL CONSTRAINT DF_Reviews_NotHelpfulCount DEFAULT (0),
        AbuseReportCount    INT             NOT NULL CONSTRAINT DF_Reviews_AbuseReportCount DEFAULT (0),
        MediaCount          INT             NOT NULL CONSTRAINT DF_Reviews_MediaCount DEFAULT (0),

        SubmittedOn         DATETIME2(3)    NOT NULL CONSTRAINT DF_Reviews_SubmittedOn DEFAULT (SYSUTCDATETIME()),
        IpAddress           VARCHAR(64)     NULL,
        SourceChannel       VARCHAR(32)     NOT NULL CONSTRAINT DF_Reviews_SourceChannel DEFAULT ('Web'),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Reviews_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Reviews_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Reviews_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Reviews PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Reviews_Products   FOREIGN KEY (ProductId)          REFERENCES dbo.Products (Id),
        CONSTRAINT FK_Reviews_Variants   FOREIGN KEY (VariantId)          REFERENCES dbo.ProductVariants (Id),
        CONSTRAINT FK_Reviews_Customers  FOREIGN KEY (CustomerId)         REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_Reviews_Orders     FOREIGN KEY (OrderId)            REFERENCES dbo.Orders (Id),
        CONSTRAINT FK_Reviews_OrderItems FOREIGN KEY (OrderItemId)        REFERENCES dbo.OrderItems (Id),
        CONSTRAINT FK_Reviews_Reasons    FOREIGN KEY (ModerationReasonId) REFERENCES dbo.ReasonCodes (Id),
        /* Product Detail.txt §8 renders a 1-5 star scale. Nothing else is valid. */
        CONSTRAINT CK_Reviews_Rating CHECK (Rating BETWEEN 1 AND 5),
        CONSTRAINT CK_Reviews_Status CHECK (Status IN (0,1,2,3)),
        /* A rejection must say why — the customer notification quotes it. */
        CONSTRAINT CK_Reviews_RejectionHasReason
            CHECK (Status <> 2 OR ModerationReasonId IS NOT NULL OR ModerationNote IS NOT NULL),
        /* The badge is only meaningful when it points at a real order line. */
        CONSTRAINT CK_Reviews_VerifiedNeedsOrder
            CHECK (IsVerifiedPurchase = 0 OR OrderItemId IS NOT NULL)
    );

    /* Review.txt §18 — one review per customer per product. Guest and deleted
       rows are excluded so they cannot block a legitimate submission. */
    CREATE UNIQUE INDEX UX_Reviews_CustomerProduct ON dbo.Reviews (CustomerId, ProductId)
        WHERE CustomerId IS NOT NULL AND IsDeleted = 0;

    /* PDP: approved reviews for one product, newest first. Covers the list. */
    CREATE INDEX IX_Reviews_ProductApproved ON dbo.Reviews (ProductId, SubmittedOn DESC)
        INCLUDE (Rating, Title, AuthorName, IsVerifiedPurchase, HelpfulCount)
        WHERE Status = 1 AND IsDeleted = 0;

    /* Admin moderation queue — the default landing grid. */
    CREATE INDEX IX_Reviews_Moderation ON dbo.Reviews (Status, SubmittedOn DESC)
        WHERE IsDeleted = 0;

    /* Abuse queue (Review.txt §9) and the 1-star alert (§16). */
    CREATE INDEX IX_Reviews_Reported ON dbo.Reviews (AbuseReportCount DESC, SubmittedOn DESC)
        WHERE AbuseReportCount > 0 AND IsDeleted = 0;

    /* My Account §9 — the customer's own review history. */
    CREATE INDEX IX_Reviews_Customer ON dbo.Reviews (CustomerId, SubmittedOn DESC)
        WHERE IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Aspect ratings. Review.txt does not mandate these, but Product Detail.txt §8
   shows a breakdown beyond the single star value and the handicraft domain
   cares about finish and value separately from overall satisfaction.
   Kept as rows, not columns, so a new aspect needs no schema change.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ReviewSubRatings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReviewSubRatings
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ReviewId        INT             NOT NULL,
        /* Quality | Finish | ValueForMoney | Packaging | DeliveryExperience */
        Aspect          VARCHAR(48)     NOT NULL,
        Rating          TINYINT         NOT NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ReviewSubRatings_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,

        CONSTRAINT PK_ReviewSubRatings PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ReviewSubRatings_Reviews FOREIGN KEY (ReviewId) REFERENCES dbo.Reviews (Id),
        CONSTRAINT UQ_ReviewSubRatings_Aspect UNIQUE (ReviewId, Aspect),
        CONSTRAINT CK_ReviewSubRatings_Rating CHECK (Rating BETWEEN 1 AND 5)
    );
END
GO

/* ---------------------------------------------------------------------------
   Review media. Review.txt §5 caps uploads at 5 images + 1 video; the cap is a
   service rule, but the shape has to allow both. Url is stored alongside
   MediaAssetId because customer uploads may bypass the admin media library.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ReviewMedia', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReviewMedia
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ReviewId        INT             NOT NULL,
        MediaAssetId    INT             NULL,
        Url             NVARCHAR(1000)  NOT NULL,
        ThumbnailUrl    NVARCHAR(1000)  NULL,
        /* ProductMediaType: 0 Image, 1 Video */
        MediaType       TINYINT         NOT NULL CONSTRAINT DF_ReviewMedia_MediaType DEFAULT (0),
        SortOrder       INT             NOT NULL CONSTRAINT DF_ReviewMedia_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ReviewMedia_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_ReviewMedia_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ReviewMedia PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ReviewMedia_Reviews FOREIGN KEY (ReviewId)     REFERENCES dbo.Reviews (Id),
        CONSTRAINT FK_ReviewMedia_Assets  FOREIGN KEY (MediaAssetId) REFERENCES dbo.MediaAssets (Id)
    );

    CREATE INDEX IX_ReviewMedia_Review ON dbo.ReviewMedia (ReviewId, SortOrder) WHERE IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Admin (and, later, seller) replies. Review.txt §10 shows one reply thread
   under each review; ParentReplyId keeps the door open for nesting without a
   second table.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ReviewReplies', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReviewReplies
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ReviewId        INT             NOT NULL,
        ParentReplyId   BIGINT          NULL,
        Body            NVARCHAR(MAX)   NOT NULL,
        /* Admin replies are public by default; internal notes are not. */
        IsPublic        BIT             NOT NULL CONSTRAINT DF_ReviewReplies_IsPublic DEFAULT (1),
        RepliedBy       INT             NULL,
        RepliedByName   NVARCHAR(200)   NOT NULL,
        RepliedOn       DATETIME2(3)    NOT NULL CONSTRAINT DF_ReviewReplies_RepliedOn DEFAULT (SYSUTCDATETIME()),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ReviewReplies_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_ReviewReplies_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ReviewReplies PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ReviewReplies_Reviews FOREIGN KEY (ReviewId)      REFERENCES dbo.Reviews (Id),
        CONSTRAINT FK_ReviewReplies_Parent  FOREIGN KEY (ParentReplyId) REFERENCES dbo.ReviewReplies (Id),
        CONSTRAINT FK_ReviewReplies_Admins  FOREIGN KEY (RepliedBy)     REFERENCES dbo.AdminUsers (Id)
    );

    CREATE INDEX IX_ReviewReplies_Review ON dbo.ReviewReplies (ReviewId, RepliedOn) WHERE IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Abuse reports (Review.txt §9). One row per reporter so the same review can be
   reported by several shoppers and the count is auditable rather than a bare
   integer. The unique index stops one account inflating the count.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ReviewAbuseReports', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReviewAbuseReports
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        ReviewId            INT             NOT NULL,
        ReportedByCustomerId INT            NULL,
        ReporterEmail       NVARCHAR(256)   NULL,
        /* ReasonCodes with ReasonType = 'ReviewAbuse': Spam, FakeReview,
           OffensiveContent, Harassment, DuplicateReview, Misleading. */
        ReasonId            INT             NULL,
        Details             NVARCHAR(1000)  NULL,
        /* 0 Open, 1 Upheld (review hidden), 2 Dismissed */
        Status              TINYINT         NOT NULL CONSTRAINT DF_ReviewAbuseReports_Status DEFAULT (0),
        ReviewedBy          INT             NULL,
        ReviewedOn          DATETIME2(3)    NULL,
        DecisionNote        NVARCHAR(1000)  NULL,
        ReportedOn          DATETIME2(3)    NOT NULL CONSTRAINT DF_ReviewAbuseReports_ReportedOn DEFAULT (SYSUTCDATETIME()),
        IpAddress           VARCHAR(64)     NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_ReviewAbuseReports_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_ReviewAbuseReports_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ReviewAbuseReports PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ReviewAbuseReports_Reviews   FOREIGN KEY (ReviewId)             REFERENCES dbo.Reviews (Id),
        CONSTRAINT FK_ReviewAbuseReports_Customers FOREIGN KEY (ReportedByCustomerId) REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_ReviewAbuseReports_Reasons   FOREIGN KEY (ReasonId)             REFERENCES dbo.ReasonCodes (Id),
        CONSTRAINT CK_ReviewAbuseReports_Status CHECK (Status IN (0,1,2))
    );

    CREATE UNIQUE INDEX UX_ReviewAbuseReports_OnePerCustomer
        ON dbo.ReviewAbuseReports (ReviewId, ReportedByCustomerId)
        WHERE ReportedByCustomerId IS NOT NULL AND IsDeleted = 0;

    CREATE INDEX IX_ReviewAbuseReports_Open ON dbo.ReviewAbuseReports (Status, ReportedOn DESC)
        WHERE Status = 0 AND IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Helpful / not helpful votes (Product Detail.txt §8 "Helpful Button").
   One vote per identity; GuestToken carries the anonymous case so a logged-out
   shopper still cannot vote twice from the same browser.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ReviewHelpfulVotes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReviewHelpfulVotes
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ReviewId        INT             NOT NULL,
        CustomerId      INT             NULL,
        GuestToken      VARCHAR(64)     NULL,
        IsHelpful       BIT             NOT NULL,
        VotedOn         DATETIME2(3)    NOT NULL CONSTRAINT DF_ReviewHelpfulVotes_VotedOn DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_ReviewHelpfulVotes PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ReviewHelpfulVotes_Reviews   FOREIGN KEY (ReviewId)   REFERENCES dbo.Reviews (Id),
        CONSTRAINT FK_ReviewHelpfulVotes_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id),
        /* A vote must be attributable to somebody. */
        CONSTRAINT CK_ReviewHelpfulVotes_Voter CHECK (CustomerId IS NOT NULL OR GuestToken IS NOT NULL)
    );

    CREATE UNIQUE INDEX UX_ReviewHelpfulVotes_Customer ON dbo.ReviewHelpfulVotes (ReviewId, CustomerId)
        WHERE CustomerId IS NOT NULL;
    CREATE UNIQUE INDEX UX_ReviewHelpfulVotes_Guest ON dbo.ReviewHelpfulVotes (ReviewId, GuestToken)
        WHERE CustomerId IS NULL AND GuestToken IS NOT NULL;
END
GO

/* ---------------------------------------------------------------------------
   Moderation history. Review.txt §17/§18 require every approve / reject / hide
   / restore to be reconstructable. Append-only: no audit or soft-delete columns
   because a history row is never edited or removed.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ReviewModerationHistories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReviewModerationHistories
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ReviewId        INT             NOT NULL,
        FromStatus      TINYINT         NOT NULL,
        ToStatus        TINYINT         NOT NULL,
        ReasonId        INT             NULL,
        Note            NVARCHAR(1000)  NULL,
        ChangedBy       INT             NULL,
        ChangedByName   NVARCHAR(200)   NULL,
        ChangedOn       DATETIME2(3)    NOT NULL CONSTRAINT DF_ReviewModerationHistories_ChangedOn DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_ReviewModerationHistories PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ReviewModerationHistories_Reviews FOREIGN KEY (ReviewId) REFERENCES dbo.Reviews (Id),
        CONSTRAINT FK_ReviewModerationHistories_Reasons FOREIGN KEY (ReasonId) REFERENCES dbo.ReasonCodes (Id)
    );

    CREATE INDEX IX_ReviewModerationHistories_Review ON dbo.ReviewModerationHistories (ReviewId, ChangedOn DESC);
END
GO

/* ---------------------------------------------------------------------------
   Review invitations. Review.txt §2 starts the workflow at "Customer Receives
   Review Invitation" after delivery; dbo.OrderItems.ReviewRequestedAt records
   that it happened, this table records what was sent and whether it converted.
   Token is the single-use link in the email.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ReviewRequests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReviewRequests
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        OrderItemId     BIGINT          NOT NULL,
        OrderId         INT             NOT NULL,
        CustomerId      INT             NULL,
        ProductId       INT             NOT NULL,
        Token           VARCHAR(64)     NOT NULL,
        /* Email | Sms | WhatsApp | Push */
        Channel         VARCHAR(24)     NOT NULL CONSTRAINT DF_ReviewRequests_Channel DEFAULT ('Email'),
        SentOn          DATETIME2(3)    NULL,
        /* 0 Pending, 1 Sent, 2 Opened, 3 Reviewed, 4 Failed, 5 Expired */
        Status          TINYINT         NOT NULL CONSTRAINT DF_ReviewRequests_Status DEFAULT (0),
        RespondedOn     DATETIME2(3)    NULL,
        ReviewId        INT             NULL,
        ExpiresOn       DATETIME2(3)    NULL,
        ReminderCount   INT             NOT NULL CONSTRAINT DF_ReviewRequests_ReminderCount DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ReviewRequests_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_ReviewRequests_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ReviewRequests PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ReviewRequests_Token UNIQUE (Token),
        CONSTRAINT FK_ReviewRequests_OrderItems FOREIGN KEY (OrderItemId) REFERENCES dbo.OrderItems (Id),
        CONSTRAINT FK_ReviewRequests_Orders     FOREIGN KEY (OrderId)     REFERENCES dbo.Orders (Id),
        CONSTRAINT FK_ReviewRequests_Customers  FOREIGN KEY (CustomerId)  REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_ReviewRequests_Products   FOREIGN KEY (ProductId)   REFERENCES dbo.Products (Id),
        CONSTRAINT FK_ReviewRequests_Reviews    FOREIGN KEY (ReviewId)    REFERENCES dbo.Reviews (Id)
    );

    /* One invitation per order line — the job must not re-send. */
    CREATE UNIQUE INDEX UX_ReviewRequests_OrderItem ON dbo.ReviewRequests (OrderItemId) WHERE IsDeleted = 0;
    /* Drives the ReviewRequestEnabled background job. */
    CREATE INDEX IX_ReviewRequests_Pending ON dbo.ReviewRequests (Status, CreatedAt)
        WHERE Status = 0 AND IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Rating distribution. dbo.Products already carries AverageRating and
   ReviewCount; what it cannot carry cheaply is the five-bar histogram that
   Review.txt §8 and Product Detail.txt §8 render on every PDP load.

   This is the one deliberate summary table in the design: the alternative is a
   GROUP BY over Reviews on every product page view. Rebuilt on review approval
   and rejection, and fully recomputable from dbo.Reviews at any time.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ProductRatingSummaries', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductRatingSummaries
    (
        ProductId       INT             NOT NULL,
        AverageRating   DECIMAL(18,4)   NOT NULL CONSTRAINT DF_ProductRatingSummaries_AverageRating DEFAULT (0),
        ReviewCount     INT             NOT NULL CONSTRAINT DF_ProductRatingSummaries_ReviewCount DEFAULT (0),
        VerifiedCount   INT             NOT NULL CONSTRAINT DF_ProductRatingSummaries_VerifiedCount DEFAULT (0),
        Star1Count      INT             NOT NULL CONSTRAINT DF_ProductRatingSummaries_Star1 DEFAULT (0),
        Star2Count      INT             NOT NULL CONSTRAINT DF_ProductRatingSummaries_Star2 DEFAULT (0),
        Star3Count      INT             NOT NULL CONSTRAINT DF_ProductRatingSummaries_Star3 DEFAULT (0),
        Star4Count      INT             NOT NULL CONSTRAINT DF_ProductRatingSummaries_Star4 DEFAULT (0),
        Star5Count      INT             NOT NULL CONSTRAINT DF_ProductRatingSummaries_Star5 DEFAULT (0),
        RecommendCount  INT             NOT NULL CONSTRAINT DF_ProductRatingSummaries_RecommendCount DEFAULT (0),
        LastReviewOn    DATETIME2(3)    NULL,
        RecalculatedAt  DATETIME2(3)    NOT NULL CONSTRAINT DF_ProductRatingSummaries_RecalculatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_ProductRatingSummaries PRIMARY KEY CLUSTERED (ProductId),
        CONSTRAINT FK_ProductRatingSummaries_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products (Id),
        CONSTRAINT CK_ProductRatingSummaries_Average CHECK (AverageRating BETWEEN 0 AND 5)
    );

    /* "Top Rated Products" / "Lowest Rated Products" on the review dashboard. */
    CREATE INDEX IX_ProductRatingSummaries_Rating ON dbo.ProductRatingSummaries (AverageRating DESC, ReviewCount DESC);
END
GO

/* ---------------------------------------------------------------------------
   Testimonial media. dbo.Testimonials (14_Content.sql) holds a single
   PhotoMediaId, but Testimonial.txt §6 requires video testimonials (uploaded
   MP4, YouTube or Vimeo) plus before/after and product image galleries.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.TestimonialMedia', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TestimonialMedia
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        TestimonialId   INT             NOT NULL,
        MediaAssetId    INT             NULL,
        Url             NVARCHAR(1000)  NOT NULL,
        ThumbnailUrl    NVARCHAR(1000)  NULL,
        /* 0 Image, 1 UploadedVideo, 2 YouTube, 3 Vimeo */
        MediaType       TINYINT         NOT NULL CONSTRAINT DF_TestimonialMedia_MediaType DEFAULT (0),
        Caption         NVARCHAR(300)   NULL,
        DurationSeconds INT             NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_TestimonialMedia_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_TestimonialMedia_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_TestimonialMedia_IsDeleted DEFAULT (0),

        CONSTRAINT PK_TestimonialMedia PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_TestimonialMedia_Testimonials FOREIGN KEY (TestimonialId) REFERENCES dbo.Testimonials (Id),
        CONSTRAINT FK_TestimonialMedia_Assets       FOREIGN KEY (MediaAssetId)  REFERENCES dbo.MediaAssets (Id)
    );

    CREATE INDEX IX_TestimonialMedia_Testimonial ON dbo.TestimonialMedia (TestimonialId, SortOrder) WHERE IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Close the forward reference left open in 11_Orders.sql.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'FK_OrderItems_Reviews', N'F') IS NULL
   AND COL_LENGTH(N'dbo.OrderItems', N'ReviewId') IS NOT NULL
BEGIN
    ALTER TABLE dbo.OrderItems
        ADD CONSTRAINT FK_OrderItems_Reviews FOREIGN KEY (ReviewId) REFERENCES dbo.Reviews (Id);
END
GO
