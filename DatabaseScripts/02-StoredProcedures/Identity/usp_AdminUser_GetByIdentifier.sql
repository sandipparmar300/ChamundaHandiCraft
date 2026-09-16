/* =============================================================================
   usp_AdminUser_GetByIdentifier
   -----------------------------------------------------------------------------
   Retrieves an active admin user by email address or phone number for
   authentication, along with their roles and distinct permissions.
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AdminUser_GetByIdentifier
    @Identifier NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SET @Identifier = LTRIM(RTRIM(ISNULL(@Identifier, N'')));

    IF @Identifier = N''
        RETURN;

    DECLARE @AdminUserId INT;

    SELECT TOP (1) @AdminUserId = Id
    FROM dbo.AdminUsers
    WHERE (Email = @Identifier OR Phone = @Identifier)
      AND IsDeleted = 0;

    IF @AdminUserId IS NULL
        RETURN;

    -- 1. User Record
    SELECT 
        u.Id,
        u.FullName,
        u.Email,
        u.Phone,
        u.PasswordHash,
        u.PasswordChangedAt,
        u.MustChangePassword,
        u.PhotoUrl,
        u.Timezone,
        u.TwoFactorEnabled,
        u.TwoFactorSecret,
        u.FailedLoginCount,
        u.LockedOutUntil,
        u.LastLoginOn,
        u.LastLoginIp,
        u.IsActive,
        u.IsDeleted
    FROM dbo.AdminUsers AS u
    WHERE u.Id = @AdminUserId;

    -- 2. User Roles
    SELECT 
        r.Id AS RoleId,
        r.RoleName,
        r.RoleKey,
        ur.IsPrimary
    FROM dbo.AdminUserRoles AS ur
    INNER JOIN dbo.Roles AS r ON r.Id = ur.RoleId
    WHERE ur.AdminUserId = @AdminUserId
      AND r.IsActive = 1
      AND r.IsDeleted = 0
    ORDER BY ur.IsPrimary DESC, r.SortOrder ASC;

    -- 3. Distinct Permissions across all assigned roles
    SELECT DISTINCT 
        p.PermissionKey
    FROM dbo.AdminUserRoles AS ur
    INNER JOIN dbo.RolePermissions AS rp ON rp.RoleId = ur.RoleId
    INNER JOIN dbo.Permissions AS p ON p.Id = rp.PermissionId
    WHERE ur.AdminUserId = @AdminUserId
      AND p.IsActive = 1
      AND p.IsDeleted = 0;
END
GO
