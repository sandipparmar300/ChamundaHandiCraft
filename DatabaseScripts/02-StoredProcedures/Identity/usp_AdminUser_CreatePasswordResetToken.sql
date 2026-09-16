/* =============================================================================
   usp_AdminUser_CreatePasswordResetToken
   -----------------------------------------------------------------------------
   Invalidates active tokens and generates a new password reset request.
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AdminUser_CreatePasswordResetToken
    @AdminUserId    INT,
    @Token          NVARCHAR(256),
    @ExpiresAt      DATETIME2(3),
    @IpAddress      VARCHAR(64)   = NULL,
    @UserAgent      NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Invalidate existing unexpired, unused tokens for this user
    UPDATE dbo.AdminPasswordResets
    SET IsUsed = 1,
        UsedAt = SYSUTCDATETIME()
    WHERE AdminUserId = @AdminUserId
      AND IsUsed = 0;

    -- Insert newly generated token
    INSERT INTO dbo.AdminPasswordResets
    (
        AdminUserId,
        Token,
        ExpiresAt,
        IsUsed,
        IpAddress,
        UserAgent,
        CreatedAt
    )
    VALUES
    (
        @AdminUserId,
        @Token,
        @ExpiresAt,
        0,
        @IpAddress,
        @UserAgent,
        SYSUTCDATETIME()
    );

    SELECT CAST(SCOPE_IDENTITY() AS BIGINT);
END
GO
