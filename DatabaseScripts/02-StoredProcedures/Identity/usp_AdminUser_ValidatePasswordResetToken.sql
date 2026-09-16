/* =============================================================================
   usp_AdminUser_ValidatePasswordResetToken
   -----------------------------------------------------------------------------
   Validates whether a reset token is valid, unconsumed, and unexpired.
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AdminUser_ValidatePasswordResetToken
    @Token NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SET @Token = LTRIM(RTRIM(ISNULL(@Token, N'')));

    IF @Token = N''
        RETURN;

    SELECT TOP (1)
        r.Id AS ResetId,
        r.AdminUserId,
        r.ExpiresAt,
        r.IsUsed,
        u.FullName,
        u.Email,
        u.IsActive,
        u.IsDeleted
    FROM dbo.AdminPasswordResets AS r
    INNER JOIN dbo.AdminUsers AS u ON u.Id = r.AdminUserId
    WHERE r.Token = @Token
      AND r.IsUsed = 0
      AND r.ExpiresAt > SYSUTCDATETIME()
      AND u.IsActive = 1
      AND u.IsDeleted = 0;
END
GO
