/* =============================================================================
   12_Payments.sql — Gateways, Payments, Refunds, Settlements, Disputes
   -----------------------------------------------------------------------------
   Live gateway credentials belong in GatewayCredentials, encrypted at rest —
   never in appsettings.json.

   NetAmount on a payment is Amount − GatewayFee: what actually reaches the bank
   account after the gateway takes its cut.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.PaymentGateways', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PaymentGateways
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        GatewayName         NVARCHAR(100)   NOT NULL,
        GatewayCode         VARCHAR(48)     NOT NULL,      -- razorpay|payu|cod|stripe
        LogoUrl             NVARCHAR(1000)  NULL,
        /* Bitmask-free: one row per gateway, with the methods it supports listed
           in SupportedMethods as a comma-separated set of PaymentMethod values. */
        SupportedMethods    VARCHAR(64)     NULL,
        IsTestMode          BIT             NOT NULL CONSTRAINT DF_PaymentGateways_IsTestMode DEFAULT (1),
        IsDefault           BIT             NOT NULL CONSTRAINT DF_PaymentGateways_IsDefault DEFAULT (0),
        /* Percentage the gateway charges, used to estimate NetAmount before the
           settlement statement arrives. */
        FeePercent          DECIMAL(18,4)   NOT NULL CONSTRAINT DF_PaymentGateways_FeePercent DEFAULT (0),
        FeeFixed            DECIMAL(18,2)   NOT NULL CONSTRAINT DF_PaymentGateways_FeeFixed DEFAULT (0),
        MinOrderValue       DECIMAL(18,2)   NULL,
        MaxOrderValue       DECIMAL(18,2)   NULL,
        SortOrder           INT             NOT NULL CONSTRAINT DF_PaymentGateways_SortOrder DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_PaymentGateways_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_PaymentGateways_IsActive  DEFAULT (0),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_PaymentGateways_IsDeleted DEFAULT (0),

        CONSTRAINT PK_PaymentGateways PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_PaymentGateways_Code UNIQUE (GatewayCode)
    );
END
GO

/* Encrypted at rest by the API. Never returned to a grid, never logged. */
IF OBJECT_ID(N'dbo.GatewayCredentials', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GatewayCredentials
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        GatewayId       INT             NOT NULL,
        Environment     VARCHAR(16)     NOT NULL CONSTRAINT DF_GatewayCredentials_Environment DEFAULT ('Test'), -- Test|Live
        CredentialKey   VARCHAR(64)     NOT NULL,      -- KeyId|KeySecret|WebhookSecret|MerchantId
        CipherValue     VARBINARY(MAX)  NOT NULL,
        LastRotatedAt   DATETIME2(3)    NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_GatewayCredentials_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_GatewayCredentials_IsDeleted DEFAULT (0),

        CONSTRAINT PK_GatewayCredentials PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_GatewayCredentials UNIQUE (GatewayId, Environment, CredentialKey),
        CONSTRAINT FK_GatewayCredentials_Gateways FOREIGN KEY (GatewayId) REFERENCES dbo.PaymentGateways (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.Payments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Payments
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        TransactionId       VARCHAR(64)     NOT NULL,      -- our reference
        OrderId             INT             NOT NULL,
        CustomerId          INT             NULL,
        GatewayId           INT             NULL,
        GatewayName         NVARCHAR(100)   NULL,
        /* The gateway's own reference — what support quotes when a bank queries
           a charge, and what the customer sees on their statement. */
        GatewayReference    VARCHAR(128)    NULL,
        GatewayOrderId      VARCHAR(128)    NULL,

        Amount              DECIMAL(18,2)   NOT NULL,
        CurrencyCode        VARCHAR(3)      NOT NULL CONSTRAINT DF_Payments_CurrencyCode DEFAULT ('INR'),
        GatewayFee          DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Payments_GatewayFee DEFAULT (0),
        TaxOnFee            DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Payments_TaxOnFee DEFAULT (0),

        /* PaymentMethod: 0 Upi, 1 Card, 2 NetBanking, 3 Wallet, 4 CashOnDelivery, 5 StoreCredit */
        Method              TINYINT         NOT NULL,
        /* PaymentStatus: 0 Pending, 1 Authorised, 2 Paid, 3 Failed, 4 Refunded,
           5 PartiallyRefunded, 6 CodPending */
        Status              TINYINT         NOT NULL CONSTRAINT DF_Payments_Status DEFAULT (0),
        FailureCode         VARCHAR(64)     NULL,
        FailureReason       NVARCHAR(500)   NULL,

        /* Masked instrument detail, safe to display: "HDFC •••• 4242", "user@upi". */
        InstrumentLabel     NVARCHAR(100)   NULL,
        Bank                NVARCHAR(100)   NULL,
        AuthorisedOn        DATETIME2(3)    NULL,
        PaidOn              DATETIME2(3)    NULL,
        RefundedAmount      DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Payments_RefundedAmount DEFAULT (0),
        SettlementId        INT             NULL,
        /* Raw gateway callback, kept for reconciliation and dispute evidence. */
        RawResponseJson     NVARCHAR(MAX)   NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Payments_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Payments_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Payments_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Payments PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Payments_TransactionId UNIQUE (TransactionId),
        CONSTRAINT FK_Payments_Orders    FOREIGN KEY (OrderId)    REFERENCES dbo.Orders (Id),
        CONSTRAINT FK_Payments_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_Payments_Gateways  FOREIGN KEY (GatewayId)  REFERENCES dbo.PaymentGateways (Id),
        CONSTRAINT CK_Payments_RefundWithinAmount CHECK (RefundedAmount <= Amount)
    );

    CREATE INDEX IX_Payments_Order     ON dbo.Payments (OrderId)          WHERE IsDeleted = 0;
    CREATE INDEX IX_Payments_Status    ON dbo.Payments (Status, PaidOn DESC) WHERE IsDeleted = 0;
    CREATE INDEX IX_Payments_GatewayRef ON dbo.Payments (GatewayReference) WHERE GatewayReference IS NOT NULL;
END
GO

IF OBJECT_ID(N'dbo.Refunds', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Refunds
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        RefundNumber        VARCHAR(32)     NOT NULL,
        OrderId             INT             NOT NULL,
        PaymentId           INT             NULL,
        ReturnRequestId     INT             NULL,
        CustomerId          INT             NULL,

        Amount              DECIMAL(18,2)   NOT NULL,
        /* PaymentMethod the money originally arrived by — a refund goes back the
           same way, except COD which is refunded to a bank account. */
        OriginalMethod      TINYINT         NOT NULL,
        RefundMode          VARCHAR(32)     NOT NULL CONSTRAINT DF_Refunds_RefundMode DEFAULT ('Original'), -- Original|BankTransfer|StoreCredit
        BankAccountLast4    VARCHAR(4)      NULL,

        /* Pending|Approved|Processing|Completed|Failed|Rejected */
        Status              VARCHAR(32)     NOT NULL CONSTRAINT DF_Refunds_Status DEFAULT ('Pending'),
        ReasonCodeId        INT             NULL,
        Reason              NVARCHAR(1000)  NULL,
        /* Large refunds route through the approval queue in 01_Platform.sql. */
        RequiresApproval    BIT             NOT NULL CONSTRAINT DF_Refunds_RequiresApproval DEFAULT (0),
        ApprovalRequestId   INT             NULL,

        RequestedOn         DATETIME2(3)    NOT NULL CONSTRAINT DF_Refunds_RequestedOn DEFAULT (SYSUTCDATETIME()),
        CompletedOn         DATETIME2(3)    NULL,
        /* The reference the customer quotes when their bank has not shown it. */
        GatewayReference    VARCHAR(128)    NULL,
        FailureReason       NVARCHAR(500)   NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Refunds_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Refunds_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Refunds_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Refunds PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Refunds_Number UNIQUE (RefundNumber),
        CONSTRAINT FK_Refunds_Orders     FOREIGN KEY (OrderId)           REFERENCES dbo.Orders (Id),
        CONSTRAINT FK_Refunds_Payments   FOREIGN KEY (PaymentId)         REFERENCES dbo.Payments (Id),
        CONSTRAINT FK_Refunds_Returns    FOREIGN KEY (ReturnRequestId)   REFERENCES dbo.ReturnRequests (Id),
        CONSTRAINT FK_Refunds_Customers  FOREIGN KEY (CustomerId)        REFERENCES dbo.Customers (Id),
        CONSTRAINT FK_Refunds_ReasonCode FOREIGN KEY (ReasonCodeId)      REFERENCES dbo.ReasonCodes (Id),
        CONSTRAINT FK_Refunds_Approval   FOREIGN KEY (ApprovalRequestId) REFERENCES dbo.ApprovalRequests (Id),
        CONSTRAINT CK_Refunds_AmountPositive CHECK (Amount > 0)
    );

    CREATE INDEX IX_Refunds_Order  ON dbo.Refunds (OrderId)                    WHERE IsDeleted = 0;
    CREATE INDEX IX_Refunds_Status ON dbo.Refunds (Status, RequestedOn DESC)   WHERE IsDeleted = 0;
END
GO

/* Gateway payout statements. Reconciling these against Payments is what catches
   a missing settlement before the finance close. */
IF OBJECT_ID(N'dbo.Settlements', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Settlements
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        SettlementId        VARCHAR(64)     NOT NULL,      -- the gateway's id
        GatewayId           INT             NULL,
        SettledOn           DATETIME2(3)    NOT NULL,
        GrossAmount         DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Settlements_GrossAmount DEFAULT (0),
        Fees                DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Settlements_Fees DEFAULT (0),
        TaxOnFees           DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Settlements_TaxOnFees DEFAULT (0),
        RefundsAmount       DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Settlements_RefundsAmount DEFAULT (0),
        AdjustmentsAmount   DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Settlements_AdjustmentsAmount DEFAULT (0),
        NetAmount           DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Settlements_NetAmount DEFAULT (0),
        TransactionCount    INT             NOT NULL CONSTRAINT DF_Settlements_TransactionCount DEFAULT (0),
        BankReference       VARCHAR(128)    NULL,
        Status              VARCHAR(32)     NOT NULL CONSTRAINT DF_Settlements_Status DEFAULT ('Settled'),
        /* Set once every payment in the statement has been matched. */
        ReconciledAt        DATETIME2(3)    NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Settlements_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Settlements_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Settlements_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Settlements PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Settlements_SettlementId UNIQUE (SettlementId),
        CONSTRAINT FK_Settlements_Gateways FOREIGN KEY (GatewayId) REFERENCES dbo.PaymentGateways (Id)
    );

    CREATE INDEX IX_Settlements_SettledOn ON dbo.Settlements (SettledOn DESC) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.FK_Payments_Settlements', N'F') IS NULL
    ALTER TABLE dbo.Payments
        ADD CONSTRAINT FK_Payments_Settlements FOREIGN KEY (SettlementId) REFERENCES dbo.Settlements (Id);
GO

/* Chargebacks. Time-critical: missing the evidence window loses the money
   automatically, which is why EvidenceDueOn is NOT NULL and indexed. */
IF OBJECT_ID(N'dbo.Disputes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Disputes
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        DisputeId           VARCHAR(64)     NOT NULL,      -- the gateway's id
        OrderId             INT             NOT NULL,
        PaymentId           INT             NULL,
        CustomerId          INT             NULL,
        Amount              DECIMAL(18,2)   NOT NULL,
        Reason              NVARCHAR(300)   NOT NULL,
        /* Open|EvidenceSubmitted|Won|Lost|Accepted */
        Status              VARCHAR(32)     NOT NULL CONSTRAINT DF_Disputes_Status DEFAULT ('Open'),
        RaisedOn            DATETIME2(3)    NOT NULL CONSTRAINT DF_Disputes_RaisedOn DEFAULT (SYSUTCDATETIME()),
        EvidenceDueOn       DATETIME2(3)    NOT NULL,
        EvidenceSubmittedOn DATETIME2(3)    NULL,
        EvidenceJson        NVARCHAR(MAX)   NULL,
        ResolvedOn          DATETIME2(3)    NULL,
        ResolutionNote      NVARCHAR(1000)  NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Disputes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Disputes_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Disputes_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Disputes PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Disputes_DisputeId UNIQUE (DisputeId),
        CONSTRAINT FK_Disputes_Orders    FOREIGN KEY (OrderId)    REFERENCES dbo.Orders (Id),
        CONSTRAINT FK_Disputes_Payments  FOREIGN KEY (PaymentId)  REFERENCES dbo.Payments (Id),
        CONSTRAINT FK_Disputes_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (Id)
    );

    /* The queue is sorted by deadline, not by date raised. */
    CREATE INDEX IX_Disputes_Due ON dbo.Disputes (EvidenceDueOn) WHERE Status = 'Open' AND IsDeleted = 0;
END
GO

/* Every inbound gateway and courier callback, stored before it is processed.
   Idempotency: a provider that retries the same event must not double-apply it. */
IF OBJECT_ID(N'dbo.WebhookEvents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.WebhookEvents
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        Provider        VARCHAR(48)     NOT NULL,      -- razorpay|payu|shiprocket|delhivery
        EventType       VARCHAR(100)    NOT NULL,
        ExternalEventId VARCHAR(128)    NULL,
        PayloadJson     NVARCHAR(MAX)   NOT NULL,
        SignatureValid  BIT             NOT NULL CONSTRAINT DF_WebhookEvents_SignatureValid DEFAULT (0),
        ReceivedAt      DATETIME2(3)    NOT NULL CONSTRAINT DF_WebhookEvents_ReceivedAt DEFAULT (SYSUTCDATETIME()),
        ProcessedAt     DATETIME2(3)    NULL,
        ProcessingError NVARCHAR(MAX)   NULL,
        RetryCount      INT             NOT NULL CONSTRAINT DF_WebhookEvents_RetryCount DEFAULT (0),

        CONSTRAINT PK_WebhookEvents PRIMARY KEY CLUSTERED (Id)
    );

    CREATE UNIQUE INDEX UX_WebhookEvents_External ON dbo.WebhookEvents (Provider, ExternalEventId)
        WHERE ExternalEventId IS NOT NULL;
    CREATE INDEX IX_WebhookEvents_Unprocessed ON dbo.WebhookEvents (ReceivedAt) WHERE ProcessedAt IS NULL;
END
GO
