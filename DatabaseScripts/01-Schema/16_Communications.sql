/* =============================================================================
   16_Communications.sql — notifications, templates, delivery, newsletter, campaigns
   -----------------------------------------------------------------------------
   Source specs:
     docs/Admin Flows/Notification.txt    (templates, channels, queue, retries, prefs)
     docs/Admin Flows/NewsLetter.txt      (subscribers, segments, campaigns, analytics)
     docs/Customer Flows/My Account.txt §11  (customer notification centre)

   Depends on: 04_Identity, 05_Customers, 06_Catalog, 11_Orders, 01_Platform.

   Design decision — one channel model, not four.
   Notification.txt §4 lists Email, SMS, WhatsApp, Push and In-App, and §22
   suggests a table per concern. Four near-identical tables would drift apart the
   first time a retry rule changed. Instead Channel is a discriminator column and
   the provider-specific payload lives in ProviderPayloadJson, which is exactly
   what the IEmailProvider / ISmsProvider abstraction in §23 needs. A new channel
   is a new enum value, not a migration.

   Channel: 0 Email, 1 Sms, 2 WhatsApp, 3 Push, 4 InApp
   ============================================================================= */

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------------
   Event catalogue. Notification.txt §7 lists the automatic triggers; holding
   them as data rather than constants lets an administrator enable, disable or
   re-route an event without a deployment (§20 "feature toggles ... without code
   deployment"). Codes are stable and referenced by the API.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.NotificationEvents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NotificationEvents
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        /* OrderPlaced | PaymentSuccess | Shipped | Delivered | OtpRequested ... */
        EventKey            VARCHAR(100)    NOT NULL,
        Name                NVARCHAR(200)   NOT NULL,
        /* Authentication | Customer | Orders | Payments | Shipping | Marketing |
           Reviews | Inventory | Admin — Notification.txt §6 */
        Category            VARCHAR(48)     NOT NULL,
        Description         NVARCHAR(500)   NULL,
        /* Transactional messages ignore promotional opt-out (§17). Marketing
           messages never may. This flag is what the send path checks. */
        IsTransactional     BIT             NOT NULL CONSTRAINT DF_NotificationEvents_IsTransactional DEFAULT (1),
        /* Comma-separated default channel numbers, e.g. '0,1' for Email + SMS. */
        DefaultChannels     VARCHAR(32)     NOT NULL CONSTRAINT DF_NotificationEvents_DefaultChannels DEFAULT ('0'),
        /* Recipient side: Customer | Admin | Both */
        Audience            VARCHAR(16)     NOT NULL CONSTRAINT DF_NotificationEvents_Audience DEFAULT ('Customer'),
        IsSystem            BIT             NOT NULL CONSTRAINT DF_NotificationEvents_IsSystem DEFAULT (1),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_NotificationEvents_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_NotificationEvents_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_NotificationEvents_IsDeleted DEFAULT (0),

        CONSTRAINT PK_NotificationEvents PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_NotificationEvents_Key UNIQUE (EventKey)
    );
END
GO

/* ---------------------------------------------------------------------------
   Templates. Notification.txt §5: every notification is generated from a
   template, and templates carry {{Placeholders}}. VariablesJson documents the
   tokens a template accepts so the admin editor can validate before save
   instead of failing at send time.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.NotificationTemplates', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NotificationTemplates
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        TemplateCode        VARCHAR(100)    NOT NULL,
        Name                NVARCHAR(200)   NOT NULL,
        /* Channel discriminator — see file header. */
        Channel             TINYINT         NOT NULL CONSTRAINT DF_NotificationTemplates_Channel DEFAULT (0),
        Category            VARCHAR(48)     NOT NULL CONSTRAINT DF_NotificationTemplates_Category DEFAULT ('Orders'),
        Subject             NVARCHAR(500)   NULL,          -- email / push title
        PreviewText         NVARCHAR(300)   NULL,          -- email preheader
        BodyText            NVARCHAR(MAX)   NULL,          -- SMS / WhatsApp / plaintext part
        BodyHtml            NVARCHAR(MAX)   NULL,          -- email
        /* WhatsApp and push need provider-registered template names and payload
           shapes that have no equivalent in email. */
        ProviderTemplateName NVARCHAR(200)  NULL,
        VariablesJson       NVARCHAR(MAX)   NULL,
        LanguageCode        VARCHAR(10)     NOT NULL CONSTRAINT DF_NotificationTemplates_LanguageCode DEFAULT ('en'),
        /* Seeded templates cannot be deleted from the UI. */
        IsSystem            BIT             NOT NULL CONSTRAINT DF_NotificationTemplates_IsSystem DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_NotificationTemplates_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_NotificationTemplates_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_NotificationTemplates_IsDeleted DEFAULT (0),

        CONSTRAINT PK_NotificationTemplates PRIMARY KEY CLUSTERED (Id),
        /* The same logical template exists once per channel per language. */
        CONSTRAINT UQ_NotificationTemplates_CodeChannelLang UNIQUE (TemplateCode, Channel, LanguageCode),
        CONSTRAINT CK_NotificationTemplates_Channel CHECK (Channel IN (0,1,2,3,4)),
        /* A template with no body cannot render anything. */
        CONSTRAINT CK_NotificationTemplates_HasBody CHECK (BodyText IS NOT NULL OR BodyHtml IS NOT NULL OR ProviderTemplateName IS NOT NULL)
    );

    CREATE INDEX IX_NotificationTemplates_Channel ON dbo.NotificationTemplates (Channel, Category) WHERE IsDeleted = 0;
END
GO

/* Which template renders which event on which channel. */
IF OBJECT_ID(N'dbo.NotificationEventTemplates', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NotificationEventTemplates
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        NotificationEventId INT             NOT NULL,
        Channel             TINYINT         NOT NULL,
        TemplateId          INT             NOT NULL,
        IsEnabled           BIT             NOT NULL CONSTRAINT DF_NotificationEventTemplates_IsEnabled DEFAULT (1),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_NotificationEventTemplates_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,

        CONSTRAINT PK_NotificationEventTemplates PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_NotificationEventTemplates_EventChannel UNIQUE (NotificationEventId, Channel),
        CONSTRAINT FK_NotificationEventTemplates_Events    FOREIGN KEY (NotificationEventId) REFERENCES dbo.NotificationEvents (Id),
        CONSTRAINT FK_NotificationEventTemplates_Templates FOREIGN KEY (TemplateId)          REFERENCES dbo.NotificationTemplates (Id),
        CONSTRAINT CK_NotificationEventTemplates_Channel CHECK (Channel IN (0,1,2,3,4))
    );
END
GO

/* ---------------------------------------------------------------------------
   The outbox. Notification.txt §8 defines the queue states and §14 the delivery
   log fields. One row per recipient per channel — that is the unit that can
   succeed, fail and retry independently.

   Rendered Subject/Body are stored rather than re-rendered on retry: the
   customer must receive the same message the second time, even if an
   administrator edited the template in between.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Notifications', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Notifications
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        NotificationEventId INT             NULL,
        EventKey            VARCHAR(100)    NULL,
        TemplateId          INT             NULL,
        Channel             TINYINT         NOT NULL CONSTRAINT DF_Notifications_Channel DEFAULT (0),

        /* Recipient. Exactly one of the two ids is set; the address columns are
           snapshots so the record still reads correctly after a profile edit. */
        RecipientType       VARCHAR(16)     NOT NULL CONSTRAINT DF_Notifications_RecipientType DEFAULT ('Customer'),
        CustomerId          INT             NULL,
        AdminUserId         INT             NULL,
        ToEmail             NVARCHAR(256)   NULL,
        ToPhone             VARCHAR(24)     NULL,
        ToDeviceToken       NVARCHAR(500)   NULL,
        RecipientName       NVARCHAR(200)   NULL,

        Subject             NVARCHAR(500)   NULL,
        BodyText            NVARCHAR(MAX)   NULL,
        BodyHtml            NVARCHAR(MAX)   NULL,
        /* Merge values used to render, kept for support and re-send. */
        PayloadJson         NVARCHAR(MAX)   NULL,

        /* What this message is about — powers "view details" in the customer
           notification centre and the admin drill-down. Intentionally a loose
           pair rather than 12 nullable FKs. */
        RelatedEntityType   VARCHAR(64)     NULL,
        RelatedEntityId     BIGINT          NULL,

        /* NotificationStatus: 0 Pending, 1 Queued, 2 Processing, 3 Sent,
           4 Delivered, 5 Failed, 6 Cancelled, 7 Retrying */
        Status              TINYINT         NOT NULL CONSTRAINT DF_Notifications_Status DEFAULT (0),
        /* 0 High, 1 Normal, 2 Low — OTP must not queue behind a bulk campaign. */
        Priority            TINYINT         NOT NULL CONSTRAINT DF_Notifications_Priority DEFAULT (1),
        IsTransactional     BIT             NOT NULL CONSTRAINT DF_Notifications_IsTransactional DEFAULT (1),

        ScheduledFor        DATETIME2(3)    NULL,
        SentAt              DATETIME2(3)    NULL,
        DeliveredAt         DATETIME2(3)    NULL,
        ReadAt              DATETIME2(3)    NULL,
        FailedAt            DATETIME2(3)    NULL,
        ErrorMessage        NVARCHAR(2000)  NULL,

        RetryCount          INT             NOT NULL CONSTRAINT DF_Notifications_RetryCount DEFAULT (0),
        MaxRetries          INT             NOT NULL CONSTRAINT DF_Notifications_MaxRetries DEFAULT (3),
        NextRetryAt         DATETIME2(3)    NULL,

        Provider            NVARCHAR(100)   NULL,
        ProviderMessageId   NVARCHAR(200)   NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Notifications_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Notifications_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Notifications PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Notifications_Events    FOREIGN KEY (NotificationEventId) REFERENCES dbo.NotificationEvents (Id),
        CONSTRAINT FK_Notifications_Templates FOREIGN KEY (TemplateId)          REFERENCES dbo.NotificationTemplates (Id),
        CONSTRAINT FK_Notifications_Customers FOREIGN KEY (CustomerId)          REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_Notifications_Admins    FOREIGN KEY (AdminUserId)         REFERENCES dbo.AdminUsers (Id),
        CONSTRAINT CK_Notifications_Channel CHECK (Channel IN (0,1,2,3,4)),
        CONSTRAINT CK_Notifications_Status  CHECK (Status BETWEEN 0 AND 7),
        /* A message with nowhere to go must never reach the queue. */
        CONSTRAINT CK_Notifications_HasDestination
            CHECK (ToEmail IS NOT NULL OR ToPhone IS NOT NULL OR ToDeviceToken IS NOT NULL
                   OR Channel = 4 /* InApp resolves by CustomerId */),
        CONSTRAINT CK_Notifications_Retry CHECK (RetryCount >= 0 AND RetryCount <= MaxRetries + 1)
    );

    /* The dispatcher's hot path: what is due to send right now, highest
       priority first. Filtered so the index stays small as history grows. */
    CREATE INDEX IX_Notifications_Dispatch ON dbo.Notifications (Priority, ScheduledFor, Id)
        INCLUDE (Channel, Status)
        WHERE Status IN (0,1,7) AND IsDeleted = 0;

    /* Retry sweeper. */
    CREATE INDEX IX_Notifications_Retry ON dbo.Notifications (NextRetryAt)
        WHERE Status = 7 AND IsDeleted = 0;

    /* Customer notification centre — My Account §11, unread first. */
    CREATE INDEX IX_Notifications_Customer ON dbo.Notifications (CustomerId, CreatedAt DESC)
        INCLUDE (Subject, Channel, ReadAt)
        WHERE CustomerId IS NOT NULL AND IsDeleted = 0;

    /* Admin delivery-log grid and the failure analytics chart (§15). */
    CREATE INDEX IX_Notifications_StatusDate ON dbo.Notifications (Status, CreatedAt DESC) WHERE IsDeleted = 0;

    /* Webhook callbacks arrive keyed by the provider's own id. */
    CREATE INDEX IX_Notifications_ProviderMessage ON dbo.Notifications (ProviderMessageId)
        WHERE ProviderMessageId IS NOT NULL;
END
GO

/* ---------------------------------------------------------------------------
   One row per send attempt. Notification.txt §8 requires retry counts and §14
   the raw provider response. Separated from Notifications so a message that
   retried four times does not overwrite the diagnosis of the first failure.
   Append-only.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.NotificationDeliveryLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NotificationDeliveryLogs
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        NotificationId      BIGINT          NOT NULL,
        AttemptNumber       INT             NOT NULL CONSTRAINT DF_NotificationDeliveryLogs_AttemptNumber DEFAULT (1),
        Provider            NVARCHAR(100)   NULL,
        /* Sent | Delivered | Failed | Bounced | Rejected | Read */
        ResultStatus        VARCHAR(24)     NOT NULL,
        ResponseCode        VARCHAR(64)     NULL,
        ResponseMessage     NVARCHAR(2000)  NULL,
        ProviderMessageId   NVARCHAR(200)   NULL,
        /* Raw payload retained for dispute resolution; may be large. */
        RawResponse         NVARCHAR(MAX)   NULL,
        DurationMs          INT             NULL,
        AttemptedAt         DATETIME2(3)    NOT NULL CONSTRAINT DF_NotificationDeliveryLogs_AttemptedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_NotificationDeliveryLogs PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_NotificationDeliveryLogs_Notifications FOREIGN KEY (NotificationId) REFERENCES dbo.Notifications (Id)
    );

    CREATE INDEX IX_NotificationDeliveryLogs_Notification ON dbo.NotificationDeliveryLogs (NotificationId, AttemptNumber);
    CREATE INDEX IX_NotificationDeliveryLogs_Date ON dbo.NotificationDeliveryLogs (AttemptedAt DESC);
END
GO

/* ---------------------------------------------------------------------------
   Customer channel preferences. Notification.txt §10 and §17: promotional
   messages must respect these; transactional ones override them. Stored one row
   per (customer, channel, category) so "SMS offers off, SMS order updates on"
   is expressible. Absence of a row means the platform default applies.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.NotificationPreferences', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NotificationPreferences
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        CustomerId      INT             NOT NULL,
        Channel         TINYINT         NOT NULL,
        /* Orders | Payments | Shipping | Promotions | Newsletter | Wishlist |
           CartReminder | Reviews — matches Notification.txt §10 groupings. */
        Category        VARCHAR(48)     NOT NULL,
        IsEnabled       BIT             NOT NULL CONSTRAINT DF_NotificationPreferences_IsEnabled DEFAULT (1),
        UpdatedSource   VARCHAR(32)     NULL,            -- MyAccount | UnsubscribeLink | Admin

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_NotificationPreferences_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,

        CONSTRAINT PK_NotificationPreferences PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_NotificationPreferences_Scope UNIQUE (CustomerId, Channel, Category),
        CONSTRAINT FK_NotificationPreferences_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id),
        CONSTRAINT CK_NotificationPreferences_Channel CHECK (Channel IN (0,1,2,3,4))
    );
END
GO

/* ---------------------------------------------------------------------------
   Push device registrations. Notification.txt §4D sends browser and app push;
   a token belongs to a device, not a customer, and expires independently.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.CustomerDevices', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CustomerDevices
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        CustomerId      INT             NULL,
        GuestToken      VARCHAR(64)     NULL,
        DeviceToken     NVARCHAR(500)   NOT NULL,
        /* Web | Android | Ios */
        Platform        VARCHAR(16)     NOT NULL CONSTRAINT DF_CustomerDevices_Platform DEFAULT ('Web'),
        DeviceName      NVARCHAR(200)   NULL,
        UserAgent       NVARCHAR(500)   NULL,
        LastSeenAt      DATETIME2(3)    NULL,
        /* Cleared when the provider reports the token as stale. */
        IsValid         BIT             NOT NULL CONSTRAINT DF_CustomerDevices_IsValid DEFAULT (1),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_CustomerDevices_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_CustomerDevices_IsDeleted DEFAULT (0),

        CONSTRAINT PK_CustomerDevices PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_CustomerDevices_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id)
    );

    CREATE UNIQUE INDEX UX_CustomerDevices_Token ON dbo.CustomerDevices (DeviceToken) WHERE IsDeleted = 0;
    CREATE INDEX IX_CustomerDevices_Customer ON dbo.CustomerDevices (CustomerId)
        WHERE IsValid = 1 AND IsDeleted = 0;
END
GO

/* =============================================================================
   Newsletter — subscribers, segments, campaigns
   ============================================================================= */

/* ---------------------------------------------------------------------------
   Subscribers. NewsLetter.txt §4/§20: email is unique, double opt-in is
   configurable, and unsubscribed addresses must never be mailed again.

   A subscriber is deliberately NOT the same entity as a customer — most
   subscribers arrive from the footer form and have no account. CustomerId links
   the two when they coincide, which is what the "Customers / Non-Customers"
   segments in §5 filter on.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Subscribers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Subscribers
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        Email               NVARCHAR(256)   NOT NULL,
        FullName            NVARCHAR(200)   NULL,
        Phone               VARCHAR(24)     NULL,
        CustomerId          INT             NULL,

        /* SubscriberStatus: 0 PendingVerification, 1 Active, 2 Unsubscribed,
           3 Blocked, 4 Bounced */
        Status              TINYINT         NOT NULL CONSTRAINT DF_Subscribers_Status DEFAULT (0),
        /* WebsiteFooter | HomepagePopup | Checkout | Registration | ContactPage |
           ManualImport | AdminPanel | BlogPage — NewsLetter.txt §4 */
        Source              VARCHAR(48)     NOT NULL CONSTRAINT DF_Subscribers_Source DEFAULT ('WebsiteFooter'),

        /* Double opt-in. VerifyToken is single-use; VerifiedOn proves consent. */
        VerifyToken         VARCHAR(64)     NULL,
        VerifyTokenExpires  DATETIME2(3)    NULL,
        VerifiedOn          DATETIME2(3)    NULL,
        /* Long-lived token embedded in the mandatory unsubscribe link (§20). */
        UnsubscribeToken    VARCHAR(64)     NOT NULL,

        SubscribedOn        DATETIME2(3)    NOT NULL CONSTRAINT DF_Subscribers_SubscribedOn DEFAULT (SYSUTCDATETIME()),
        UnsubscribedOn      DATETIME2(3)    NULL,
        UnsubscribeReason   NVARCHAR(500)   NULL,
        /* Set when a hard bounce takes the address out of circulation. */
        BouncedOn           DATETIME2(3)    NULL,
        BounceCount         INT             NOT NULL CONSTRAINT DF_Subscribers_BounceCount DEFAULT (0),
        LastEmailedOn       DATETIME2(3)    NULL,
        IpAddress           VARCHAR(64)     NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Subscribers_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Subscribers_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Subscribers_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Subscribers PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Subscribers_UnsubscribeToken UNIQUE (UnsubscribeToken),
        CONSTRAINT FK_Subscribers_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id),
        CONSTRAINT CK_Subscribers_Status CHECK (Status BETWEEN 0 AND 4)
    );

    /* NewsLetter.txt §20 — "Email addresses must be unique." */
    CREATE UNIQUE INDEX UX_Subscribers_Email ON dbo.Subscribers (Email) WHERE IsDeleted = 0;
    /* The mailable audience. */
    CREATE INDEX IX_Subscribers_Active ON dbo.Subscribers (Status, SubscribedOn DESC)
        WHERE Status = 1 AND IsDeleted = 0;
    CREATE INDEX IX_Subscribers_Customer ON dbo.Subscribers (CustomerId) WHERE CustomerId IS NOT NULL;
END
GO

/* Free-form tagging from the admin grid (NewsLetter.txt §4 "Tags", §14 bulk "Assign Tag"). */
IF OBJECT_ID(N'dbo.SubscriberTags', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SubscriberTags
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        SubscriberId    INT             NOT NULL,
        Tag             NVARCHAR(100)   NOT NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_SubscriberTags_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,

        CONSTRAINT PK_SubscriberTags PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_SubscriberTags_Unique UNIQUE (SubscriberId, Tag),
        CONSTRAINT FK_SubscriberTags_Subscribers FOREIGN KEY (SubscriberId) REFERENCES dbo.Subscribers (Id)
    );

    CREATE INDEX IX_SubscriberTags_Tag ON dbo.SubscriberTags (Tag);
END
GO

/* ---------------------------------------------------------------------------
   Segments. NewsLetter.txt §5 lists both static lists and rule-driven groups
   ("New Customers", "High Value Customers"). IsDynamic decides which: a dynamic
   segment evaluates RuleJson at send time and keeps no member rows.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.NewsletterSegments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NewsletterSegments
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Name            NVARCHAR(200)   NOT NULL,
        Description     NVARCHAR(500)   NULL,
        IsDynamic       BIT             NOT NULL CONSTRAINT DF_NewsletterSegments_IsDynamic DEFAULT (0),
        RuleJson        NVARCHAR(MAX)   NULL,
        /* Cached size for the campaign audience picker; recomputed on evaluate. */
        MemberCount     INT             NOT NULL CONSTRAINT DF_NewsletterSegments_MemberCount DEFAULT (0),
        LastEvaluatedAt DATETIME2(3)    NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_NewsletterSegments_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_NewsletterSegments_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_NewsletterSegments_IsDeleted DEFAULT (0),

        CONSTRAINT PK_NewsletterSegments PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_NewsletterSegments_Name UNIQUE (Name),
        /* A dynamic segment without a rule would silently match nobody. */
        CONSTRAINT CK_NewsletterSegments_DynamicHasRule CHECK (IsDynamic = 0 OR RuleJson IS NOT NULL)
    );
END
GO

IF OBJECT_ID(N'dbo.NewsletterSegmentMembers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NewsletterSegmentMembers
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        SegmentId       INT             NOT NULL,
        SubscriberId    INT             NOT NULL,
        AddedOn         DATETIME2(3)    NOT NULL CONSTRAINT DF_NewsletterSegmentMembers_AddedOn DEFAULT (SYSUTCDATETIME()),
        AddedBy         INT             NULL,

        CONSTRAINT PK_NewsletterSegmentMembers PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_NewsletterSegmentMembers_Unique UNIQUE (SegmentId, SubscriberId),
        CONSTRAINT FK_NewsletterSegmentMembers_Segments    FOREIGN KEY (SegmentId)    REFERENCES dbo.NewsletterSegments (Id),
        CONSTRAINT FK_NewsletterSegmentMembers_Subscribers FOREIGN KEY (SubscriberId) REFERENCES dbo.Subscribers (Id)
    );

    CREATE INDEX IX_NewsletterSegmentMembers_Subscriber ON dbo.NewsletterSegmentMembers (SubscriberId);
END
GO

/* ---------------------------------------------------------------------------
   Campaigns. NewsLetter.txt §6/§10/§11. The aggregate counters are denormalised
   because the dashboard shows open and click rates for every campaign in the
   list; deriving them from CampaignEvents per row would scan the event table
   once per campaign. They are recomputable from CampaignEvents.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Campaigns', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Campaigns
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        Name                NVARCHAR(200)   NOT NULL,
        Subject             NVARCHAR(500)   NOT NULL,
        PreviewText         NVARCHAR(300)   NULL,
        FromName            NVARCHAR(200)   NULL,
        FromEmail           NVARCHAR(256)   NULL,
        ReplyToEmail        NVARCHAR(256)   NULL,
        /* Newsletter | Promotional | FestivalOffer | ProductLaunch | FlashSale |
           BlogUpdate | Announcement | Survey | Welcome — NewsLetter.txt §6 */
        CampaignType        VARCHAR(48)     NOT NULL CONSTRAINT DF_Campaigns_CampaignType DEFAULT ('Newsletter'),
        TemplateId          INT             NULL,
        BodyHtml            NVARCHAR(MAX)   NULL,
        BodyText            NVARCHAR(MAX)   NULL,
        SegmentId           INT             NULL,          -- null = all active subscribers

        /* CampaignStatus: 0 Draft, 1 Scheduled, 2 Sending, 3 Completed,
           4 Cancelled, 5 Failed — NewsLetter.txt §10 */
        Status              TINYINT         NOT NULL CONSTRAINT DF_Campaigns_Status DEFAULT (0),
        ScheduledFor        DATETIME2(3)    NULL,
        TimeZoneId          NVARCHAR(100)   NULL,
        StartedOn           DATETIME2(3)    NULL,
        CompletedOn         DATETIME2(3)    NULL,

        RecipientCount      INT             NOT NULL CONSTRAINT DF_Campaigns_RecipientCount DEFAULT (0),
        SentCount           INT             NOT NULL CONSTRAINT DF_Campaigns_SentCount DEFAULT (0),
        DeliveredCount      INT             NOT NULL CONSTRAINT DF_Campaigns_DeliveredCount DEFAULT (0),
        OpenedCount         INT             NOT NULL CONSTRAINT DF_Campaigns_OpenedCount DEFAULT (0),
        ClickedCount        INT             NOT NULL CONSTRAINT DF_Campaigns_ClickedCount DEFAULT (0),
        BouncedCount        INT             NOT NULL CONSTRAINT DF_Campaigns_BouncedCount DEFAULT (0),
        UnsubscribedCount   INT             NOT NULL CONSTRAINT DF_Campaigns_UnsubscribedCount DEFAULT (0),
        ComplaintCount      INT             NOT NULL CONSTRAINT DF_Campaigns_ComplaintCount DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Campaigns_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Campaigns_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Campaigns_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Campaigns PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Campaigns_Templates FOREIGN KEY (TemplateId) REFERENCES dbo.NotificationTemplates (Id),
        CONSTRAINT FK_Campaigns_Segments  FOREIGN KEY (SegmentId)  REFERENCES dbo.NewsletterSegments (Id),
        CONSTRAINT CK_Campaigns_Status CHECK (Status BETWEEN 0 AND 5),
        /* A scheduled campaign with no send time would never fire. */
        CONSTRAINT CK_Campaigns_ScheduledHasTime CHECK (Status <> 1 OR ScheduledFor IS NOT NULL)
    );

    CREATE INDEX IX_Campaigns_Status ON dbo.Campaigns (Status, ScheduledFor) WHERE IsDeleted = 0;
END
GO

/* One row per addressee. This is also the suppression record: a subscriber who
   already received campaign X must not be re-sent it on a retry. */
IF OBJECT_ID(N'dbo.CampaignRecipients', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CampaignRecipients
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        CampaignId          INT             NOT NULL,
        SubscriberId        INT             NOT NULL,
        /* Address snapshot — the campaign report must still read correctly if
           the subscriber later changes or deletes their address. */
        Email               NVARCHAR(256)   NOT NULL,
        /* 0 Pending, 1 Sent, 2 Delivered, 3 Bounced, 4 Failed, 5 Skipped */
        Status              TINYINT         NOT NULL CONSTRAINT DF_CampaignRecipients_Status DEFAULT (0),
        SentAt              DATETIME2(3)    NULL,
        DeliveredAt         DATETIME2(3)    NULL,
        FirstOpenedAt       DATETIME2(3)    NULL,
        FirstClickedAt      DATETIME2(3)    NULL,
        OpenCount           INT             NOT NULL CONSTRAINT DF_CampaignRecipients_OpenCount DEFAULT (0),
        ClickCount          INT             NOT NULL CONSTRAINT DF_CampaignRecipients_ClickCount DEFAULT (0),
        ProviderMessageId   NVARCHAR(200)   NULL,
        ErrorMessage        NVARCHAR(1000)  NULL,
        SkipReason          NVARCHAR(200)   NULL,          -- Unsubscribed | Bounced | Suppressed

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_CampaignRecipients_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,

        CONSTRAINT PK_CampaignRecipients PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_CampaignRecipients_Unique UNIQUE (CampaignId, SubscriberId),
        CONSTRAINT FK_CampaignRecipients_Campaigns   FOREIGN KEY (CampaignId)   REFERENCES dbo.Campaigns (Id),
        CONSTRAINT FK_CampaignRecipients_Subscribers FOREIGN KEY (SubscriberId) REFERENCES dbo.Subscribers (Id),
        CONSTRAINT CK_CampaignRecipients_Status CHECK (Status BETWEEN 0 AND 5)
    );

    CREATE INDEX IX_CampaignRecipients_Pending ON dbo.CampaignRecipients (CampaignId, Status)
        WHERE Status = 0;
    CREATE INDEX IX_CampaignRecipients_Subscriber ON dbo.CampaignRecipients (SubscriberId, SentAt DESC);
    CREATE INDEX IX_CampaignRecipients_ProviderMessage ON dbo.CampaignRecipients (ProviderMessageId)
        WHERE ProviderMessageId IS NOT NULL;
END
GO

/* ---------------------------------------------------------------------------
   Engagement events. NewsLetter.txt §25 proposes EmailOpenLogs, EmailClickLogs,
   EmailBounceLogs and EmailUnsubscribeLogs. They would carry identical columns
   and identical indexes, so they are one table with an EventType discriminator
   — the prompt's own §5 guidance ("do not assume separate tables if a
   normalised generic architecture is more appropriate") applied to email.

   Append-only, no audit columns: a webhook event is a fact, never edited.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.CampaignEvents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CampaignEvents
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        CampaignId      INT             NOT NULL,
        RecipientId     BIGINT          NULL,
        SubscriberId    INT             NULL,
        /* Delivered | Open | Click | Bounce | SpamComplaint | Unsubscribe | Failed */
        EventType       VARCHAR(24)     NOT NULL,
        OccurredAt      DATETIME2(3)    NOT NULL CONSTRAINT DF_CampaignEvents_OccurredAt DEFAULT (SYSUTCDATETIME()),
        /* Click only. */
        LinkUrl         NVARCHAR(2000)  NULL,
        /* Bounce only: Hard | Soft, plus the provider's diagnostic. */
        BounceType      VARCHAR(16)     NULL,
        Detail          NVARCHAR(1000)  NULL,
        IpAddress       VARCHAR(64)     NULL,
        UserAgent       NVARCHAR(500)   NULL,
        Provider        NVARCHAR(100)   NULL,
        /* Provider event id — makes webhook processing idempotent. */
        ProviderEventId NVARCHAR(200)   NULL,

        CONSTRAINT PK_CampaignEvents PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_CampaignEvents_Campaigns   FOREIGN KEY (CampaignId)   REFERENCES dbo.Campaigns (Id),
        CONSTRAINT FK_CampaignEvents_Recipients  FOREIGN KEY (RecipientId)  REFERENCES dbo.CampaignRecipients (Id),
        CONSTRAINT FK_CampaignEvents_Subscribers FOREIGN KEY (SubscriberId) REFERENCES dbo.Subscribers (Id)
    );

    CREATE INDEX IX_CampaignEvents_Campaign ON dbo.CampaignEvents (CampaignId, EventType, OccurredAt DESC);
    CREATE INDEX IX_CampaignEvents_Recipient ON dbo.CampaignEvents (RecipientId, OccurredAt DESC);
    /* A provider that redelivers a webhook must not double-count an open. */
    CREATE UNIQUE INDEX UX_CampaignEvents_ProviderEvent ON dbo.CampaignEvents (ProviderEventId)
        WHERE ProviderEventId IS NOT NULL;
END
GO
