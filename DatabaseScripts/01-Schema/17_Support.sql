/* =============================================================================
   17_Support.sql — inquiry categories, support tickets, conversation, SLA
   -----------------------------------------------------------------------------
   Source specs:
     docs/Customer Flows/Contact.txt      §5 (inquiry types), §15 (inquiry tracking)
     docs/Admin Flows/CMS.txt             §7 (view enquiries, reply, assign, resolve)
     docs/Customer Flows/My Account.txt   (contact support from an order)

   Depends on: 04_Identity, 05_Customers, 11_Orders, 06_Catalog, 14_Content.

   Why tickets exist alongside dbo.ContactSubmissions (14_Content.sql):
   a submission is the raw inbound form post — immutable evidence of what the
   visitor typed. A ticket is the work item it becomes: assignable, prioritised,
   SLA-tracked and conversational. ContactSubmissions.SupportTicketId already
   anticipates this split; the FK is created at the end of this file.
   Not every submission becomes a ticket (spam is handled and closed), and not
   every ticket starts from a submission (an agent can raise one from an order).
   ============================================================================= */

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------------
   Inquiry categories. Contact.txt §5 enumerates the Subject dropdown. Held as
   rows so the business can add "Export Inquiry" or retire "Partnership" without
   a deployment, and so each type can carry its own SLA and routing.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.InquiryCategories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.InquiryCategories
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        /* GeneralInquiry | ProductInquiry | OrderSupport | ReturnRequest |
           Refund | WholesaleInquiry | BulkOrder | CustomHandmade |
           ExportInquiry | Partnership | Feedback | Complaint | Other */
        CategoryCode        VARCHAR(64)     NOT NULL,
        Name                NVARCHAR(200)   NOT NULL,
        Description         NVARCHAR(500)   NULL,
        /* Routing: new tickets in this category default to this role's queue. */
        DefaultRoleId       INT             NULL,
        DefaultAssigneeId   INT             NULL,
        /* Contact.txt §14 "Expected Response Time ... Within 24 Hours". Drives
           SupportTickets.FirstResponseDueOn and the breach indicator. */
        FirstResponseSlaHours INT           NOT NULL CONSTRAINT DF_InquiryCategories_FirstResponseSlaHours DEFAULT (24),
        ResolutionSlaHours  INT             NOT NULL CONSTRAINT DF_InquiryCategories_ResolutionSlaHours DEFAULT (72),
        /* 0 High, 1 Normal, 2 Low — a Complaint should not queue behind Feedback. */
        DefaultPriority     TINYINT         NOT NULL CONSTRAINT DF_InquiryCategories_DefaultPriority DEFAULT (1),
        SortOrder           INT             NOT NULL CONSTRAINT DF_InquiryCategories_SortOrder DEFAULT (0),
        /* Shown in the storefront Subject dropdown; some categories are
           agent-only (e.g. an internally raised escalation). */
        IsPublic            BIT             NOT NULL CONSTRAINT DF_InquiryCategories_IsPublic DEFAULT (1),
        IsSystem            BIT             NOT NULL CONSTRAINT DF_InquiryCategories_IsSystem DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_InquiryCategories_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_InquiryCategories_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_InquiryCategories_IsDeleted DEFAULT (0),

        CONSTRAINT PK_InquiryCategories PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_InquiryCategories_Code UNIQUE (CategoryCode),
        CONSTRAINT FK_InquiryCategories_Roles     FOREIGN KEY (DefaultRoleId)     REFERENCES dbo.Roles (Id),
        CONSTRAINT FK_InquiryCategories_Assignee  FOREIGN KEY (DefaultAssigneeId) REFERENCES dbo.AdminUsers (Id),
        CONSTRAINT CK_InquiryCategories_Sla CHECK (FirstResponseSlaHours > 0 AND ResolutionSlaHours > 0),
        CONSTRAINT CK_InquiryCategories_Priority CHECK (DefaultPriority IN (0,1,2))
    );

    CREATE INDEX IX_InquiryCategories_Public ON dbo.InquiryCategories (SortOrder)
        WHERE IsPublic = 1 AND IsActive = 1 AND IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Support tickets. Contact.txt §15 requires a customer-facing reference number
   and the status set Submitted → Assigned → In Progress → Resolved → Closed.
   Reopened and WaitingOnCustomer are added because a resolved ticket that the
   customer disputes must not lose its history by becoming a new ticket.

   TicketStatus: 0 Submitted, 1 Assigned, 2 InProgress, 3 WaitingOnCustomer,
                 4 Resolved, 5 Closed, 6 Reopened, 7 Cancelled
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.SupportTickets', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SupportTickets
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        /* Contact.txt §21: "Every inquiry receives a unique reference number."
           Human-quotable, e.g. CHX-SUP-000148. */
        TicketNumber        VARCHAR(32)     NOT NULL,
        InquiryCategoryId   INT             NULL,
        ContactSubmissionId INT             NULL,

        /* Requester. CustomerId is null for a guest; the contact snapshot below
           is what the agent replies to either way. */
        CustomerId          INT             NULL,
        RequesterName       NVARCHAR(200)   NOT NULL,
        RequesterEmail      NVARCHAR(256)   NULL,
        RequesterPhone      VARCHAR(24)     NULL,

        /* What the ticket is about, when it is about something specific. */
        OrderId             INT             NULL,
        ProductId           INT             NULL,

        Subject             NVARCHAR(300)   NOT NULL,
        Description         NVARCHAR(MAX)   NOT NULL,

        Status              TINYINT         NOT NULL CONSTRAINT DF_SupportTickets_Status DEFAULT (0),
        /* 0 High, 1 Normal, 2 Low */
        Priority            TINYINT         NOT NULL CONSTRAINT DF_SupportTickets_Priority DEFAULT (1),

        AssignedTo          INT             NULL,
        AssignedToName      NVARCHAR(200)   NULL,
        AssignedOn          DATETIME2(3)    NULL,

        /* SLA. Due timestamps are stamped at creation from the category so a
           later category-SLA edit does not retroactively breach old tickets. */
        FirstResponseDueOn  DATETIME2(3)    NULL,
        FirstRespondedOn    DATETIME2(3)    NULL,
        ResolutionDueOn     DATETIME2(3)    NULL,
        ResolvedOn          DATETIME2(3)    NULL,
        ClosedOn            DATETIME2(3)    NULL,
        ReopenedOn          DATETIME2(3)    NULL,
        ReopenCount         INT             NOT NULL CONSTRAINT DF_SupportTickets_ReopenCount DEFAULT (0),
        ResolutionNote      NVARCHAR(MAX)   NULL,

        /* Post-resolution feedback, 1-5. Feeds the support quality report. */
        SatisfactionRating  TINYINT         NULL,
        SatisfactionComment NVARCHAR(1000)  NULL,

        MessageCount        INT             NOT NULL CONSTRAINT DF_SupportTickets_MessageCount DEFAULT (0),
        LastMessageOn       DATETIME2(3)    NULL,
        /* Who spoke last — drives the "awaiting our reply" agent filter. */
        LastMessageBy       VARCHAR(16)     NULL,          -- Customer | Agent | System

        Source              VARCHAR(32)     NOT NULL CONSTRAINT DF_SupportTickets_Source DEFAULT ('ContactForm'),
        SubmittedOn         DATETIME2(3)    NOT NULL CONSTRAINT DF_SupportTickets_SubmittedOn DEFAULT (SYSUTCDATETIME()),
        IpAddress           VARCHAR(64)     NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_SupportTickets_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_SupportTickets_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_SupportTickets_IsDeleted DEFAULT (0),

        CONSTRAINT PK_SupportTickets PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_SupportTickets_Number UNIQUE (TicketNumber),
        CONSTRAINT FK_SupportTickets_Categories  FOREIGN KEY (InquiryCategoryId)   REFERENCES dbo.InquiryCategories (Id),
        CONSTRAINT FK_SupportTickets_Submissions FOREIGN KEY (ContactSubmissionId) REFERENCES dbo.ContactSubmissions (Id),
        CONSTRAINT FK_SupportTickets_Customers   FOREIGN KEY (CustomerId)          REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_SupportTickets_Orders      FOREIGN KEY (OrderId)             REFERENCES dbo.Orders (Id),
        CONSTRAINT FK_SupportTickets_Products    FOREIGN KEY (ProductId)           REFERENCES dbo.Products (Id),
        CONSTRAINT FK_SupportTickets_Assignee    FOREIGN KEY (AssignedTo)          REFERENCES dbo.AdminUsers (Id),
        CONSTRAINT CK_SupportTickets_Status   CHECK (Status BETWEEN 0 AND 7),
        CONSTRAINT CK_SupportTickets_Priority CHECK (Priority IN (0,1,2)),
        CONSTRAINT CK_SupportTickets_Satisfaction CHECK (SatisfactionRating IS NULL OR SatisfactionRating BETWEEN 1 AND 5),
        /* A requester must be reachable, otherwise the ticket cannot be answered. */
        CONSTRAINT CK_SupportTickets_HasContact CHECK (RequesterEmail IS NOT NULL OR RequesterPhone IS NOT NULL),
        /* Resolved and Closed must record when. */
        CONSTRAINT CK_SupportTickets_ResolvedHasDate CHECK (Status <> 4 OR ResolvedOn IS NOT NULL),
        CONSTRAINT CK_SupportTickets_ClosedHasDate   CHECK (Status <> 5 OR ClosedOn   IS NOT NULL)
    );

    /* The agent's open queue, most urgent and oldest first. */
    CREATE INDEX IX_SupportTickets_Queue ON dbo.SupportTickets (Status, Priority, SubmittedOn)
        INCLUDE (TicketNumber, Subject, AssignedTo, FirstResponseDueOn)
        WHERE Status IN (0,1,2,3,6) AND IsDeleted = 0;

    /* "My tickets" for an agent. */
    CREATE INDEX IX_SupportTickets_Assignee ON dbo.SupportTickets (AssignedTo, Status, SubmittedOn)
        WHERE AssignedTo IS NOT NULL AND IsDeleted = 0;

    /* SLA breach report: unanswered past the due time. */
    CREATE INDEX IX_SupportTickets_SlaBreach ON dbo.SupportTickets (FirstResponseDueOn)
        WHERE FirstRespondedOn IS NULL AND Status IN (0,1,2) AND IsDeleted = 0;

    /* Customer-side history and the order support panel. */
    CREATE INDEX IX_SupportTickets_Customer ON dbo.SupportTickets (CustomerId, SubmittedOn DESC)
        WHERE CustomerId IS NOT NULL AND IsDeleted = 0;
    CREATE INDEX IX_SupportTickets_Order ON dbo.SupportTickets (OrderId)
        WHERE OrderId IS NOT NULL AND IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   The conversation. One row per message in either direction, plus internal
   agent notes that the customer never sees (CMS.txt §7 "Assign Staff",
   Users.txt "Customer Notes ... visible only to administrators").
   IsInternalNote is the single flag that decides visibility — there is no
   separate notes table to keep in sync with the thread ordering.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.SupportTicketMessages', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SupportTicketMessages
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        TicketId        INT             NOT NULL,
        /* Customer | Agent | System */
        SenderType      VARCHAR(16)     NOT NULL CONSTRAINT DF_SupportTicketMessages_SenderType DEFAULT ('Customer'),
        SenderCustomerId INT            NULL,
        SenderAdminId   INT             NULL,
        SenderName      NVARCHAR(200)   NOT NULL,
        Body            NVARCHAR(MAX)   NOT NULL,
        /* True = never rendered to the customer. */
        IsInternalNote  BIT             NOT NULL CONSTRAINT DF_SupportTicketMessages_IsInternalNote DEFAULT (0),
        /* Set when this message was also emailed / WhatsApped out. */
        NotificationId  BIGINT          NULL,
        SentOn          DATETIME2(3)    NOT NULL CONSTRAINT DF_SupportTicketMessages_SentOn DEFAULT (SYSUTCDATETIME()),
        ReadByCustomerOn DATETIME2(3)   NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_SupportTicketMessages_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_SupportTicketMessages_IsDeleted DEFAULT (0),

        CONSTRAINT PK_SupportTicketMessages PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_SupportTicketMessages_Tickets       FOREIGN KEY (TicketId)         REFERENCES dbo.SupportTickets (Id),
        CONSTRAINT FK_SupportTicketMessages_Customers     FOREIGN KEY (SenderCustomerId) REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_SupportTicketMessages_Admins        FOREIGN KEY (SenderAdminId)    REFERENCES dbo.AdminUsers (Id),
        CONSTRAINT FK_SupportTicketMessages_Notifications FOREIGN KEY (NotificationId)   REFERENCES dbo.Notifications (Id),
        CONSTRAINT CK_SupportTicketMessages_SenderType CHECK (SenderType IN ('Customer','Agent','System')),
        /* Only an agent can write an internal note. */
        CONSTRAINT CK_SupportTicketMessages_InternalIsAgent
            CHECK (IsInternalNote = 0 OR SenderType = 'Agent')
    );

    CREATE INDEX IX_SupportTicketMessages_Ticket ON dbo.SupportTicketMessages (TicketId, SentOn)
        WHERE IsDeleted = 0;
    /* The customer-visible thread excludes internal notes. */
    CREATE INDEX IX_SupportTicketMessages_Public ON dbo.SupportTicketMessages (TicketId, SentOn)
        WHERE IsInternalNote = 0 AND IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Attachments. Contact.txt §5 allows images, PDFs and documents on the inbound
   form; agents attach invoices and shipping proofs on the way out. MessageId is
   nullable so a file can hang off the ticket itself rather than a reply.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.SupportTicketAttachments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SupportTicketAttachments
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        TicketId        INT             NOT NULL,
        MessageId       BIGINT          NULL,
        MediaAssetId    INT             NULL,
        FileName        NVARCHAR(300)   NOT NULL,
        Url             NVARCHAR(1000)  NOT NULL,
        MimeType        VARCHAR(120)    NULL,
        SizeBytes       BIGINT          NOT NULL CONSTRAINT DF_SupportTicketAttachments_SizeBytes DEFAULT (0),
        UploadedBy      VARCHAR(16)     NOT NULL CONSTRAINT DF_SupportTicketAttachments_UploadedBy DEFAULT ('Customer'),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_SupportTicketAttachments_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_SupportTicketAttachments_IsDeleted DEFAULT (0),

        CONSTRAINT PK_SupportTicketAttachments PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_SupportTicketAttachments_Tickets  FOREIGN KEY (TicketId)     REFERENCES dbo.SupportTickets (Id),
        CONSTRAINT FK_SupportTicketAttachments_Messages FOREIGN KEY (MessageId)    REFERENCES dbo.SupportTicketMessages (Id),
        CONSTRAINT FK_SupportTicketAttachments_Assets   FOREIGN KEY (MediaAssetId) REFERENCES dbo.MediaAssets (Id),
        CONSTRAINT CK_SupportTicketAttachments_Size CHECK (SizeBytes >= 0)
    );

    CREATE INDEX IX_SupportTicketAttachments_Ticket ON dbo.SupportTicketAttachments (TicketId) WHERE IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Status history. Contact.txt §15 tracks the inquiry through its states and the
   support quality report needs the dwell time in each. Append-only, mirroring
   dbo.OrderStatusHistories.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.SupportTicketStatusHistories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SupportTicketStatusHistories
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        TicketId        INT             NOT NULL,
        FromStatus      TINYINT         NULL,              -- null on creation
        ToStatus        TINYINT         NOT NULL,
        FromAssignedTo  INT             NULL,
        ToAssignedTo    INT             NULL,
        Note            NVARCHAR(1000)  NULL,
        ChangedBy       INT             NULL,
        ChangedByName   NVARCHAR(200)   NULL,
        ChangedOn       DATETIME2(3)    NOT NULL CONSTRAINT DF_SupportTicketStatusHistories_ChangedOn DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_SupportTicketStatusHistories PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_SupportTicketStatusHistories_Tickets FOREIGN KEY (TicketId) REFERENCES dbo.SupportTickets (Id),
        CONSTRAINT CK_SupportTicketStatusHistories_ToStatus CHECK (ToStatus BETWEEN 0 AND 7)
    );

    CREATE INDEX IX_SupportTicketStatusHistories_Ticket
        ON dbo.SupportTicketStatusHistories (TicketId, ChangedOn DESC);
END
GO

/* ---------------------------------------------------------------------------
   Close the forward reference left open in 14_Content.sql.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'FK_ContactSubmissions_SupportTickets', N'F') IS NULL
   AND COL_LENGTH(N'dbo.ContactSubmissions', N'SupportTicketId') IS NOT NULL
BEGIN
    ALTER TABLE dbo.ContactSubmissions
        ADD CONSTRAINT FK_ContactSubmissions_SupportTickets
            FOREIGN KEY (SupportTicketId) REFERENCES dbo.SupportTickets (Id);
END
GO
