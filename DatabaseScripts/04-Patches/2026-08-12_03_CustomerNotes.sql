/* =============================================================================
   2026-08-12_03_CustomerNotes.sql
   -----------------------------------------------------------------------------
   Internal notes on a customer account.

   Why this was missing
   --------------------
     Users.txt §10  "Customer Notes - Internal notes visible only to
                     administrators.
                     Examples: VIP Customer, Fraud Alert, Manual Discount
                     Approved, High Return Rate."

   The first pass had nowhere to put these. dbo.OrderNotes covers notes about an
   *order*; this covers notes about a *person*, which is what a support agent
   opening an account needs to see before they speak to them.

   Design
   ------
   NoteType is a small controlled set rather than free text, because the value
   of "Fraud Alert" is that it renders as a red banner - which requires the
   system to know it is a fraud alert, not a paragraph that happens to contain
   the word.

   IsPinned surfaces a note at the top of the profile regardless of age; that is
   what makes "VIP Customer" useful two years later.

   These notes are ALWAYS internal. There is no IsInternal flag, because a
   customer-visible note about a customer is a support ticket message, and that
   already has a home in dbo.SupportTicketMessages.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.CustomerNotes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CustomerNotes
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        CustomerId      INT             NOT NULL,

        /* General | Vip | FraudAlert | DiscountApproved | HighReturnRate |
           PaymentIssue | DeliveryIssue | Complaint | Preference
           Drives the badge colour and the profile banner. */
        NoteType        VARCHAR(48)     NOT NULL CONSTRAINT DF_CustomerNotes_NoteType DEFAULT ('General'),
        Body            NVARCHAR(2000)  NOT NULL,

        /* Pinned notes show above the fold on the customer profile. */
        IsPinned        BIT             NOT NULL CONSTRAINT DF_CustomerNotes_IsPinned DEFAULT (0),
        /* 0 High, 1 Normal, 2 Low - a fraud alert outranks a preference note. */
        Severity        TINYINT         NOT NULL CONSTRAINT DF_CustomerNotes_Severity DEFAULT (1),

        /* Optional context: the order or ticket that prompted the note. */
        RelatedOrderId  INT             NULL,
        RelatedTicketId INT             NULL,

        /* Time-limited notes - "manual discount approved until end of season". */
        ExpiresOn       DATETIME2(3)    NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_CustomerNotes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        CreatedByName   NVARCHAR(200)   NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_CustomerNotes_IsDeleted DEFAULT (0),

        CONSTRAINT PK_CustomerNotes PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_CustomerNotes_Customers FOREIGN KEY (CustomerId)      REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_CustomerNotes_Orders    FOREIGN KEY (RelatedOrderId)  REFERENCES dbo.Orders (Id),
        CONSTRAINT FK_CustomerNotes_Tickets   FOREIGN KEY (RelatedTicketId) REFERENCES dbo.SupportTickets (Id),
        CONSTRAINT CK_CustomerNotes_Severity CHECK (Severity IN (0,1,2)),
        CONSTRAINT CK_CustomerNotes_NoteType CHECK (NoteType IN
            ('General','Vip','FraudAlert','DiscountApproved','HighReturnRate',
             'PaymentIssue','DeliveryIssue','Complaint','Preference'))
    );

    /* The customer profile panel: pinned first, then newest. */
    CREATE INDEX IX_CustomerNotes_Customer
        ON dbo.CustomerNotes (CustomerId, IsPinned DESC, CreatedAt DESC)
        INCLUDE (NoteType, Body, Severity, CreatedByName)
        WHERE IsDeleted = 0;

    /* "Show me every flagged account" - the fraud and returns review queue.
       Filtered, so it stays tiny however many ordinary notes accumulate. */
    CREATE INDEX IX_CustomerNotes_Flags
        ON dbo.CustomerNotes (NoteType, CreatedAt DESC)
        INCLUDE (CustomerId)
        WHERE IsDeleted = 0 AND NoteType IN ('FraudAlert','HighReturnRate','Vip');
END
GO
