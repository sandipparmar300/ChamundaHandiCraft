/* =============================================================================
   usp_Permission_Procedures
   -----------------------------------------------------------------------------
   Stored procedures for Permission Management:
     1. dbo.usp_Permission_GetMatrix
     2. dbo.usp_Role_SavePermissions
   ============================================================================= */

SET NOCOUNT ON;
GO

/* =============================================================================
   1. dbo.usp_Permission_GetMatrix
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_Permission_GetMatrix
    @RoleId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.Id,
        p.Module,
        p.Entity,
        p.Action,
        p.PermissionKey AS [Key],
        p.Description,
        IsGranted = CASE WHEN rp.PermissionId IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
    FROM dbo.Permissions p
    LEFT JOIN dbo.RolePermissions rp ON rp.PermissionId = p.Id AND rp.RoleId = @RoleId
    WHERE p.IsDeleted = 0 AND p.IsActive = 1
    ORDER BY p.Module, p.Entity, p.SortOrder, p.Action;
END;
GO

/* =============================================================================
   2. dbo.usp_Role_SavePermissions
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_Role_SavePermissions
    @RoleId           INT,
    @PermissionIdsCsv NVARCHAR(MAX),
    @AdminUserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE Id = @RoleId AND IsDeleted = 0)
    BEGIN
        RAISERROR(N'Role not found.', 16, 1);
        RETURN;
    END

    DECLARE @ParsedIds TABLE (PermissionId INT);
    IF @PermissionIdsCsv IS NOT NULL AND LEN(LTRIM(RTRIM(@PermissionIdsCsv))) > 0
    BEGIN
        INSERT INTO @ParsedIds (PermissionId)
        SELECT CAST(value AS INT)
        FROM STRING_SPLIT(@PermissionIdsCsv, ',')
        WHERE LTRIM(RTRIM(value)) <> '';
    END

    DELETE FROM dbo.RolePermissions WHERE RoleId = @RoleId;

    INSERT INTO dbo.RolePermissions (RoleId, PermissionId, CreatedAt, CreatedBy)
    SELECT @RoleId, p.PermissionId, SYSUTCDATETIME(), @AdminUserId
    FROM @ParsedIds p
    WHERE EXISTS (SELECT 1 FROM dbo.Permissions per WHERE per.Id = p.PermissionId AND per.IsDeleted = 0);

    SELECT CAST(1 AS BIT);
END;
GO
