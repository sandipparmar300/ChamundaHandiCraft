/* =============================================================================
   usp_AdminUser_ResetPassword
   -----------------------------------------------------------------------------
   Applies new password hash, consumes reset token, clears lockout, and
   records change in dbo.PasswordHistories.
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AdminUser_ResetPassword
    @Token              NVARCHAR(256),
    @NewPasswordHash    NVARCHAR(500),
    @IpAddress          VARCHAR(64) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Token = LTRIM(RTRIM(ISNULL(@Token, N'')));

    DECLARE @ResetId     BIGINT;
    DECLARE @AdminUserId INT;

    SELECT TOP (1)
        @ResetId     = r.Id,
        @AdminUserId = r.AdminUserId
    FROM dbo.AdminPasswordResets AS r
    INNER JOIN dbo.AdminUsers AS u ON u.Id = r.AdminUserId
    WHERE r.Token = @Token
      AND r.IsUsed = 0
      AND r.ExpiresAt > SYSUTCDATETIME()
      AND u.IsActive = 1
      AND u.IsDeleted = 0;

    IF @ResetId IS NULL OR @AdminUserId IS NULL
    BEGIN
        SELECT Success = 0, Message = 'Invalid or expired password reset token.';
        RETURN;
    END

    BEGIN TRANSACTION;

    -- 1. Update user password and clear lockout
    UPDATE dbo.AdminUsers
    SET PasswordHash        = @NewPasswordHash,
        PasswordChangedAt   = SYSUTCDATETIME(),
        MustChangePassword  = 0,
        FailedLoginCount    = 0,
        LockedOutUntil      = NULL,
        UpdatedAt           = SYSUTCDATETIME(),
        UpdatedBy           = @AdminUserId
    WHERE Id = @AdminUserId;

    -- 2. Mark reset token as used
    UPDATE dbo.AdminPasswordResets
    SET IsUsed    = 1,
        UsedAt    = SYSUTCDATETIME(),
        IpAddress = COALESCE(@IpAddress, IpAddress)
    WHERE Id = @ResetId;

    -- 3. Log into password history to track modifications
    INSERT INTO dbo.PasswordHistories
    (
        AdminUserId,
        PasswordHash,
        CreatedAt
    )
    VALUES
    (
        @AdminUserId,
        @NewPasswordHash,
        SYSUTCDATETIME()
    );

    COMMIT TRANSACTION;

    SELECT Success = 1, Message = 'Password has been reset successfully.';
END
GO
