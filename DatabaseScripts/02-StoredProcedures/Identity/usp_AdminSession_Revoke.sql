/* =============================================================================
   usp_AdminSession_Revoke
   -----------------------------------------------------------------------------
   Revokes an admin session refresh token handle.
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AdminSession_Revoke
    @RefreshTokenHash   CHAR(64),
    @RevokedReason      NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.AdminSessions
    SET RevokedAt     = SYSUTCDATETIME(),
        RevokedReason = ISNULL(@RevokedReason, N'Explicit logout')
    WHERE RefreshTokenHash = @RefreshTokenHash
      AND RevokedAt IS NULL;

    SELECT @@ROWCOUNT;
END
GO
