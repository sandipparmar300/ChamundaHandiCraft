/* =============================================================================
   usp_AdminSession_GetByHash
   -----------------------------------------------------------------------------
   Retrieves active unrevoked session by refresh token hash.
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AdminSession_GetByHash
    @RefreshTokenHash CHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
        s.Id,
        s.AdminUserId,
        s.RefreshTokenHash,
        s.IssuedAt,
        s.ExpiresAt,
        s.RevokedAt,
        s.RevokedReason,
        s.IpAddress,
        s.UserAgent,
        u.Email,
        u.FullName,
        u.IsActive,
        u.IsDeleted
    FROM dbo.AdminSessions AS s
    INNER JOIN dbo.AdminUsers AS u ON u.Id = s.AdminUserId
    WHERE s.RefreshTokenHash = @RefreshTokenHash
      AND s.RevokedAt IS NULL
      AND s.ExpiresAt > SYSUTCDATETIME()
      AND u.IsActive = 1
      AND u.IsDeleted = 0;
END
GO
