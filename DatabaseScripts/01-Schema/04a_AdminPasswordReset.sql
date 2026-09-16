/* =============================================================================
   04a_AdminPasswordReset.sql — Password reset requests for AdminUsers
   -----------------------------------------------------------------------------
   Stores secure random reset tokens with expiration and single-use flags.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.AdminPasswordResets', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AdminPasswordResets
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        AdminUserId     INT             NOT NULL,
        Token           NVARCHAR(256)   NOT NULL,
        ExpiresAt       DATETIME2(3)    NOT NULL,
        IsUsed          BIT             NOT NULL CONSTRAINT DF_AdminPasswordResets_IsUsed DEFAULT (0),
        UsedAt          DATETIME2(3)    NULL,
        IpAddress       VARCHAR(64)     NULL,
        UserAgent       NVARCHAR(500)   NULL,
        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_AdminPasswordResets_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_AdminPasswordResets PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_AdminPasswordResets_Users FOREIGN KEY (AdminUserId) REFERENCES dbo.AdminUsers (Id)
    );

    CREATE INDEX IX_AdminPasswordResets_Token ON dbo.AdminPasswordResets (Token, ExpiresAt, IsUsed);
    CREATE INDEX IX_AdminPasswordResets_User ON dbo.AdminPasswordResets (AdminUserId, CreatedAt DESC);
END
GO
