/* =============================================================================
   01_Platform.sql — Settings, audit trail, approvals, media library, integrations
   -----------------------------------------------------------------------------
   Runs first because everything else references media assets and reads settings.
   No foreign keys out of this file except within it — the platform layer must be
   creatable against an empty database.
   ============================================================================= */

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------------
   Settings — every figure the storefront quotes originates here.
   Section matches ChamundaHandicraft.Helper SettingsSection constants:
   storefront | shipping | payment | tax | rewards | seo | contact |
   notifications | legal
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Settings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Settings
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Section         VARCHAR(64)     NOT NULL,
        SettingKey      VARCHAR(128)    NOT NULL,
        SettingValue    NVARCHAR(MAX)   NULL,
        DataType        VARCHAR(24)     NOT NULL CONSTRAINT DF_Settings_DataType DEFAULT ('string'),  -- string|int|decimal|bool|json
        DisplayName     NVARCHAR(200)   NULL,
        Description     NVARCHAR(500)   NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_Settings_SortOrder DEFAULT (0),
        /* System settings are created by seed and cannot be deleted from the UI. */
        IsSystem        BIT             NOT NULL CONSTRAINT DF_Settings_IsSystem DEFAULT (0),
        /* Encrypted at rest — gateway keys, SMTP passwords. Never returned to a grid. */
        IsSecret        BIT             NOT NULL CONSTRAINT DF_Settings_IsSecret DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Settings_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Settings_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Settings_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Settings PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Settings_SectionKey UNIQUE (Section, SettingKey)
    );

    CREATE INDEX IX_Settings_Section ON dbo.Settings (Section) INCLUDE (SettingKey, SettingValue) WHERE IsDeleted = 0;
END
GO

/* Versioned history behind the Settings history screen. */
IF OBJECT_ID(N'dbo.SettingHistories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SettingHistories
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        SettingId       INT             NOT NULL,
        Section         VARCHAR(64)     NOT NULL,
        SettingKey      VARCHAR(128)    NOT NULL,
        OldValue        NVARCHAR(MAX)   NULL,
        NewValue        NVARCHAR(MAX)   NULL,
        ChangeNote      NVARCHAR(500)   NULL,
        ChangedBy       INT             NULL,
        ChangedByName   NVARCHAR(200)   NULL,
        ChangedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_SettingHistories_ChangedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_SettingHistories PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_SettingHistories_Settings FOREIGN KEY (SettingId) REFERENCES dbo.Settings (Id)
    );

    CREATE INDEX IX_SettingHistories_Setting ON dbo.SettingHistories (SettingId, ChangedAt DESC);
END
GO

/* ---------------------------------------------------------------------------
   Media library. Every image on the platform lives here; entities reference it.
   AltText is NOT NULL by policy — an asset with blank alt text cannot be
   attached to a published product (enforced in the service layer, surfaced by
   MediaGridItem.IsMissingAltText).
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.MediaFolders', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.MediaFolders
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        ParentId        INT             NULL,
        Name            NVARCHAR(200)   NOT NULL,
        Path            NVARCHAR(1000)  NOT NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_MediaFolders_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_MediaFolders_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_MediaFolders_IsDeleted DEFAULT (0),

        CONSTRAINT PK_MediaFolders PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_MediaFolders_Parent FOREIGN KEY (ParentId) REFERENCES dbo.MediaFolders (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.MediaAssets', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.MediaAssets
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        FolderId        INT             NULL,
        FileName        NVARCHAR(300)   NOT NULL,
        StorageKey      NVARCHAR(1000)  NOT NULL,   -- S3 object key or relative disk path
        Url             NVARCHAR(1000)  NOT NULL,
        ThumbnailUrl    NVARCHAR(1000)  NULL,
        /* ProductMediaType: 0 Image, 1 Video, 2 Spin360 */
        MediaType       TINYINT         NOT NULL CONSTRAINT DF_MediaAssets_MediaType DEFAULT (0),
        MimeType        VARCHAR(120)    NULL,
        AltText         NVARCHAR(300)   NOT NULL CONSTRAINT DF_MediaAssets_AltText DEFAULT (N''),
        Title           NVARCHAR(300)   NULL,
        SizeBytes       BIGINT          NOT NULL CONSTRAINT DF_MediaAssets_SizeBytes DEFAULT (0),
        Width           INT             NULL,
        Height          INT             NULL,
        DurationSeconds INT             NULL,
        /* Denormalised usage counter maintained by the Media service. */
        UsedInCount     INT             NOT NULL CONSTRAINT DF_MediaAssets_UsedInCount DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_MediaAssets_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_MediaAssets_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_MediaAssets_IsDeleted DEFAULT (0),

        CONSTRAINT PK_MediaAssets PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_MediaAssets_Folder FOREIGN KEY (FolderId) REFERENCES dbo.MediaFolders (Id)
    );

    CREATE INDEX IX_MediaAssets_Folder ON dbo.MediaAssets (FolderId) WHERE IsDeleted = 0;
    CREATE INDEX IX_MediaAssets_FileName ON dbo.MediaAssets (FileName) WHERE IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Audit trail. Every create / update / status change / delete writes a header
   row plus one field-level row per changed column.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.AuditLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditLogs
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        Action          VARCHAR(64)     NOT NULL,      -- Create|Update|Delete|StatusChange|Login|Export
        EntityType      VARCHAR(128)    NOT NULL,
        EntityId        INT             NULL,
        EntityName      NVARCHAR(300)   NULL,
        PerformedBy     INT             NULL,
        PerformedByName NVARCHAR(200)   NULL,
        PerformedOn     DATETIME2(3)    NOT NULL CONSTRAINT DF_AuditLogs_PerformedOn DEFAULT (SYSUTCDATETIME()),
        IpAddress       VARCHAR(64)     NULL,
        UserAgent       NVARCHAR(500)   NULL,
        CorrelationId   VARCHAR(64)     NULL,
        /* Human-readable one-line summary rendered in the grid. */
        ChangeSummary   NVARCHAR(1000)  NULL,

        CONSTRAINT PK_AuditLogs PRIMARY KEY CLUSTERED (Id)
    );

    CREATE INDEX IX_AuditLogs_Entity ON dbo.AuditLogs (EntityType, EntityId, PerformedOn DESC);
    CREATE INDEX IX_AuditLogs_PerformedOn ON dbo.AuditLogs (PerformedOn DESC);
    CREATE INDEX IX_AuditLogs_PerformedBy ON dbo.AuditLogs (PerformedBy, PerformedOn DESC);
END
GO

IF OBJECT_ID(N'dbo.AuditLogDetails', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditLogDetails
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        AuditLogId      BIGINT          NOT NULL,
        FieldName       NVARCHAR(200)   NOT NULL,
        OldValue        NVARCHAR(MAX)   NULL,
        NewValue        NVARCHAR(MAX)   NULL,

        CONSTRAINT PK_AuditLogDetails PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_AuditLogDetails_AuditLogs FOREIGN KEY (AuditLogId) REFERENCES dbo.AuditLogs (Id)
    );

    CREATE INDEX IX_AuditLogDetails_AuditLog ON dbo.AuditLogDetails (AuditLogId);
END
GO

/* ---------------------------------------------------------------------------
   Approval queue. Guarded actions — large refunds, high discounts, legal page
   publishes — are parked here rather than applied directly.
   PayloadJson holds the pending change so it can be replayed on approval.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.ApprovalRequests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ApprovalRequests
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        EntityType      VARCHAR(128)    NOT NULL,
        EntityId        INT             NULL,
        EntityName      NVARCHAR(300)   NULL,
        RequestedAction VARCHAR(128)    NOT NULL,
        PayloadJson     NVARCHAR(MAX)   NULL,
        Reason          NVARCHAR(1000)  NULL,
        RequestedBy     INT             NULL,
        RequestedByName NVARCHAR(200)   NULL,
        RequestedOn     DATETIME2(3)    NOT NULL CONSTRAINT DF_ApprovalRequests_RequestedOn DEFAULT (SYSUTCDATETIME()),
        Status          VARCHAR(24)     NOT NULL CONSTRAINT DF_ApprovalRequests_Status DEFAULT ('Pending'), -- Pending|Approved|Rejected|Cancelled
        DecidedBy       INT             NULL,
        DecidedByName   NVARCHAR(200)   NULL,
        DecidedOn       DATETIME2(3)    NULL,
        DecisionNote    NVARCHAR(1000)  NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ApprovalRequests_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_ApprovalRequests_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_ApprovalRequests_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ApprovalRequests PRIMARY KEY CLUSTERED (Id)
    );

    CREATE INDEX IX_ApprovalRequests_Status ON dbo.ApprovalRequests (Status, RequestedOn DESC) WHERE IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   Third-party integrations (analytics, gateways, couriers, marketing tools).
   Credentials live in ConfigJson and are encrypted at rest by the service.
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Integrations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Integrations
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Name            NVARCHAR(200)   NOT NULL,
        IntegrationKey  VARCHAR(100)    NOT NULL,
        Category        VARCHAR(64)     NOT NULL,      -- Payment|Courier|Email|Sms|Analytics|Social
        Provider        NVARCHAR(200)   NULL,
        ConfigJson      NVARCHAR(MAX)   NULL,
        IsConnected     BIT             NOT NULL CONSTRAINT DF_Integrations_IsConnected DEFAULT (0),
        LastSyncOn      DATETIME2(3)    NULL,
        LastSyncStatus  VARCHAR(32)     NULL,
        ErrorMessage    NVARCHAR(1000)  NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Integrations_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Integrations_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Integrations_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Integrations PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Integrations_Key UNIQUE (IntegrationKey)
    );
END
GO

/* Outbound webhook / background job execution log — used by the jobs in
   BackgroundJobs:* and by the retry logic behind gateway callbacks. */
IF OBJECT_ID(N'dbo.JobRuns', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.JobRuns
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        JobName         VARCHAR(128)    NOT NULL,
        StartedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_JobRuns_StartedAt DEFAULT (SYSUTCDATETIME()),
        CompletedAt     DATETIME2(3)    NULL,
        Status          VARCHAR(24)     NOT NULL CONSTRAINT DF_JobRuns_Status DEFAULT ('Running'), -- Running|Succeeded|Failed
        ItemsProcessed  INT             NOT NULL CONSTRAINT DF_JobRuns_ItemsProcessed DEFAULT (0),
        ErrorMessage    NVARCHAR(MAX)   NULL,

        CONSTRAINT PK_JobRuns PRIMARY KEY CLUSTERED (Id)
    );

    CREATE INDEX IX_JobRuns_JobName ON dbo.JobRuns (JobName, StartedAt DESC);
END
GO
