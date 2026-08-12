/* =============================================================================
   04_Identity.sql — AdminUsers, Roles, Permissions, Pages, Sessions, LoginHistory
   -----------------------------------------------------------------------------
   Two complementary RBAC surfaces, both loaded into session at login:

     Permissions / RolePermissions   key-based, format module.entity.action.
                                     Guards the API: [HasApiPermission("catalog.product.create")]
     AdminPages  / RolePages         page-and-action rights for the Admin panel
                                     sidebar and [PagePermission(IsEdit)].

   The key set is the authority; the page rights decide what the sidebar renders.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.Roles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Roles
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        RoleName        NVARCHAR(100)   NOT NULL,
        RoleKey         VARCHAR(64)     NOT NULL,
        Description     NVARCHAR(500)   NULL,
        /* System roles cannot be deleted, nor stripped of their key permissions. */
        IsSystem        BIT             NOT NULL CONSTRAINT DF_Roles_IsSystem DEFAULT (0),
        /* Requires 2FA at login — Security:TwoFactorRequiredForRoles in appsettings. */
        RequiresTwoFactor BIT           NOT NULL CONSTRAINT DF_Roles_RequiresTwoFactor DEFAULT (0),
        SortOrder       INT             NOT NULL CONSTRAINT DF_Roles_SortOrder DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Roles_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Roles_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Roles_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Roles PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Roles_Key UNIQUE (RoleKey)
    );
END
GO

/* One row per permission key. PermissionKey is a persisted computed column so a
   key can never drift from its three parts. */
IF OBJECT_ID(N'dbo.Permissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Permissions
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        Module          VARCHAR(64)     NOT NULL,
        Entity          VARCHAR(64)     NOT NULL,
        Action          VARCHAR(64)     NOT NULL,
        PermissionKey   AS (LOWER(Module + '.' + Entity + '.' + Action)) PERSISTED NOT NULL,
        Description     NVARCHAR(300)   NULL,
        SortOrder       INT             NOT NULL CONSTRAINT DF_Permissions_SortOrder DEFAULT (0),
        IsSystem        BIT             NOT NULL CONSTRAINT DF_Permissions_IsSystem DEFAULT (1),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Permissions_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Permissions_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Permissions_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Permissions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Permissions_Key UNIQUE (PermissionKey)
    );

    CREATE INDEX IX_Permissions_Module ON dbo.Permissions (Module, Entity, SortOrder);
END
GO

IF OBJECT_ID(N'dbo.RolePermissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RolePermissions
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        RoleId          INT             NOT NULL,
        PermissionId    INT             NOT NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_RolePermissions_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,

        CONSTRAINT PK_RolePermissions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_RolePermissions UNIQUE (RoleId, PermissionId),
        CONSTRAINT FK_RolePermissions_Roles       FOREIGN KEY (RoleId)       REFERENCES dbo.Roles (Id),
        CONSTRAINT FK_RolePermissions_Permissions FOREIGN KEY (PermissionId) REFERENCES dbo.Permissions (Id)
    );
END
GO

/* Admin sidebar. Self-referencing for section → page nesting. */
IF OBJECT_ID(N'dbo.AdminPages', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AdminPages
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        ParentId        INT             NULL,
        PageName        NVARCHAR(150)   NOT NULL,
        PageKey         VARCHAR(100)    NOT NULL,
        ControllerName  VARCHAR(100)    NULL,
        ActionName      VARCHAR(100)    NULL CONSTRAINT DF_AdminPages_ActionName DEFAULT ('Index'),
        Url             NVARCHAR(300)   NULL,
        IconName        VARCHAR(64)     NULL,
        ModuleNumber    INT             NULL,          -- matches docs/ui-ux module numbering
        SortOrder       INT             NOT NULL CONSTRAINT DF_AdminPages_SortOrder DEFAULT (0),
        /* False for pages reachable only by deep link (details, edit). */
        IsMenuItem      BIT             NOT NULL CONSTRAINT DF_AdminPages_IsMenuItem DEFAULT (1),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_AdminPages_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_AdminPages_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_AdminPages_IsDeleted DEFAULT (0),

        CONSTRAINT PK_AdminPages PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_AdminPages_Key UNIQUE (PageKey),
        CONSTRAINT FK_AdminPages_Parent FOREIGN KEY (ParentId) REFERENCES dbo.AdminPages (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.RolePages', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RolePages
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        RoleId          INT             NOT NULL,
        PageId          INT             NOT NULL,
        IsView          BIT             NOT NULL CONSTRAINT DF_RolePages_IsView    DEFAULT (0),
        IsAdd           BIT             NOT NULL CONSTRAINT DF_RolePages_IsAdd     DEFAULT (0),
        IsEdit          BIT             NOT NULL CONSTRAINT DF_RolePages_IsEdit    DEFAULT (0),
        IsDelete        BIT             NOT NULL CONSTRAINT DF_RolePages_IsDelete  DEFAULT (0),
        IsExport        BIT             NOT NULL CONSTRAINT DF_RolePages_IsExport  DEFAULT (0),
        IsApprove       BIT             NOT NULL CONSTRAINT DF_RolePages_IsApprove DEFAULT (0),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_RolePages_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,

        CONSTRAINT PK_RolePages PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_RolePages UNIQUE (RoleId, PageId),
        CONSTRAINT FK_RolePages_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles (Id),
        CONSTRAINT FK_RolePages_Pages FOREIGN KEY (PageId) REFERENCES dbo.AdminPages (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.AdminUsers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AdminUsers
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        FullName            NVARCHAR(200)   NOT NULL,
        Email               NVARCHAR(256)   NOT NULL,
        Phone               VARCHAR(24)     NULL,
        /* PBKDF2/BCrypt output. The salt is embedded in the hash string. */
        PasswordHash        NVARCHAR(500)   NOT NULL,
        PasswordChangedAt   DATETIME2(3)    NULL,
        /* Forces the change-password screen on next login — seed sets this true
           for the first Super Admin. */
        MustChangePassword  BIT             NOT NULL CONSTRAINT DF_AdminUsers_MustChangePassword DEFAULT (0),

        PhotoMediaId        INT             NULL,
        PhotoUrl            NVARCHAR(1000)  NULL,
        Timezone            VARCHAR(64)     NOT NULL CONSTRAINT DF_AdminUsers_Timezone DEFAULT ('Asia/Kolkata'),

        TwoFactorEnabled    BIT             NOT NULL CONSTRAINT DF_AdminUsers_TwoFactorEnabled DEFAULT (0),
        TwoFactorSecret     NVARCHAR(300)   NULL,

        /* Lockout — Security:MaxFailedLoginAttempts / LockoutMinutes. */
        FailedLoginCount    INT             NOT NULL CONSTRAINT DF_AdminUsers_FailedLoginCount DEFAULT (0),
        LockedOutUntil      DATETIME2(3)    NULL,
        LastLoginOn         DATETIME2(3)    NULL,
        LastLoginIp         VARCHAR(64)     NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_AdminUsers_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_AdminUsers_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_AdminUsers_IsDeleted DEFAULT (0),

        CONSTRAINT PK_AdminUsers PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_AdminUsers_PhotoMedia FOREIGN KEY (PhotoMediaId) REFERENCES dbo.MediaAssets (Id)
    );

    /* Email is unique among live accounts only — a soft-deleted user must not
       block the address from being reused. */
    CREATE UNIQUE INDEX UX_AdminUsers_Email ON dbo.AdminUsers (Email) WHERE IsDeleted = 0;
END
GO

/* A user can hold more than one role; the effective key set is the union. */
IF OBJECT_ID(N'dbo.AdminUserRoles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AdminUserRoles
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        AdminUserId     INT             NOT NULL,
        RoleId          INT             NOT NULL,
        IsPrimary       BIT             NOT NULL CONSTRAINT DF_AdminUserRoles_IsPrimary DEFAULT (1),

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_AdminUserRoles_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,

        CONSTRAINT PK_AdminUserRoles PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_AdminUserRoles UNIQUE (AdminUserId, RoleId),
        CONSTRAINT FK_AdminUserRoles_Users FOREIGN KEY (AdminUserId) REFERENCES dbo.AdminUsers (Id),
        CONSTRAINT FK_AdminUserRoles_Roles FOREIGN KEY (RoleId)      REFERENCES dbo.Roles (Id)
    );
END
GO

/* Refresh tokens. The access token is not stored; only the refresh handle is,
   so a stolen database row cannot be replayed as a bearer token. */
IF OBJECT_ID(N'dbo.AdminSessions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AdminSessions
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        AdminUserId         INT             NOT NULL,
        RefreshTokenHash    CHAR(64)        NOT NULL,
        IssuedAt            DATETIME2(3)    NOT NULL CONSTRAINT DF_AdminSessions_IssuedAt DEFAULT (SYSUTCDATETIME()),
        ExpiresAt           DATETIME2(3)    NOT NULL,
        RevokedAt           DATETIME2(3)    NULL,
        RevokedReason       NVARCHAR(200)   NULL,
        IpAddress           VARCHAR(64)     NULL,
        UserAgent           NVARCHAR(500)   NULL,

        CONSTRAINT PK_AdminSessions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_AdminSessions_Users FOREIGN KEY (AdminUserId) REFERENCES dbo.AdminUsers (Id)
    );

    CREATE INDEX IX_AdminSessions_TokenHash ON dbo.AdminSessions (RefreshTokenHash);
    CREATE INDEX IX_AdminSessions_User ON dbo.AdminSessions (AdminUserId, ExpiresAt DESC);
END
GO

IF OBJECT_ID(N'dbo.LoginHistories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LoginHistories
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        AdminUserId     INT             NULL,          -- null when the email did not resolve
        AttemptedEmail  NVARCHAR(256)   NULL,
        IsSuccess       BIT             NOT NULL,
        FailureReason   NVARCHAR(200)   NULL,
        IpAddress       VARCHAR(64)     NULL,
        UserAgent       NVARCHAR(500)   NULL,
        AttemptedAt     DATETIME2(3)    NOT NULL CONSTRAINT DF_LoginHistories_AttemptedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_LoginHistories PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_LoginHistories_Users FOREIGN KEY (AdminUserId) REFERENCES dbo.AdminUsers (Id)
    );

    CREATE INDEX IX_LoginHistories_User ON dbo.LoginHistories (AdminUserId, AttemptedAt DESC);
    CREATE INDEX IX_LoginHistories_Email ON dbo.LoginHistories (AttemptedEmail, AttemptedAt DESC);
END
GO

/* Stops a password being cycled back within the reuse window. */
IF OBJECT_ID(N'dbo.PasswordHistories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PasswordHistories
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        AdminUserId     INT             NOT NULL,
        PasswordHash    NVARCHAR(500)   NOT NULL,
        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_PasswordHistories_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_PasswordHistories PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_PasswordHistories_Users FOREIGN KEY (AdminUserId) REFERENCES dbo.AdminUsers (Id)
    );

    CREATE INDEX IX_PasswordHistories_User ON dbo.PasswordHistories (AdminUserId, CreatedAt DESC);
END
GO
