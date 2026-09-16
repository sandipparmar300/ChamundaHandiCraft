/* =============================================================================
   usp_AdminSession_Create
   -----------------------------------------------------------------------------
   Records a newly issued refresh token handle into dbo.AdminSessions.
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AdminSession_Create
    @AdminUserId        INT,
    @RefreshTokenHash   CHAR(64),
    @ExpiresAt          DATETIME2(3),
    @IpAddress          VARCHAR(64)   = NULL,
    @UserAgent          NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.AdminSessions
    (
        AdminUserId,
        RefreshTokenHash,
        IssuedAt,
        ExpiresAt,
        IpAddress,
        UserAgent
    )
    VALUES
    (
        @AdminUserId,
        @RefreshTokenHash,
        SYSUTCDATETIME(),
        @ExpiresAt,
        @IpAddress,
        @UserAgent
    );

    SELECT CAST(SCOPE_IDENTITY() AS BIGINT);
END
GO
