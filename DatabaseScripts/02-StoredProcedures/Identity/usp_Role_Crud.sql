/* =============================================================================
   usp_Role_Crud
   -----------------------------------------------------------------------------
   Stored procedures for Role Management:
     1. dbo.usp_Role_GridList
     2. dbo.usp_Role_GetById
     3. dbo.usp_Role_Save
     4. dbo.usp_Role_Delete
     5. dbo.usp_Role_UpdateStatus
     6. dbo.usp_Role_GetLookup
   ============================================================================= */

SET NOCOUNT ON;
GO

/* =============================================================================
   1. dbo.usp_Role_GridList
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_Role_GridList
    @SearchText           NVARCHAR(200)   = NULL,
    @IsActive             BIT             = NULL,
    @SortColumn           VARCHAR(64)     = 'SortOrder',
    @SortOrder            VARCHAR(4)      = 'ASC',
    @PageSize             INT             = 25,
    @PageIndex            INT             = 1,
    @TotalRecords         INT             OUTPUT,
    @TotalFilteredRecords INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageSize  IS NULL OR @PageSize  < 1 SET @PageSize  = 25;
    IF @PageIndex IS NULL OR @PageIndex < 1 SET @PageIndex = 1;
    IF @SortOrder IS NULL OR @SortOrder NOT IN ('ASC','DESC') SET @SortOrder = 'ASC';
    SET @SearchText = NULLIF(LTRIM(RTRIM(ISNULL(@SearchText, N''))), N'');

    SELECT @TotalRecords = COUNT(*) FROM dbo.Roles WHERE IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT
            r.Id,
            r.RoleName,
            r.RoleKey,
            r.Description,
            r.IsSystem,
            r.IsActive,
            r.SortOrder,
            CreatedOn = r.CreatedAt,
            UserCount = (
                SELECT COUNT(*)
                FROM dbo.AdminUserRoles ur
                JOIN dbo.AdminUsers u ON ur.AdminUserId = u.Id
                WHERE ur.RoleId = r.Id AND u.IsDeleted = 0
            ),
            PermissionCount = (
                SELECT COUNT(*)
                FROM dbo.RolePermissions rp
                JOIN dbo.Permissions p ON rp.PermissionId = p.Id
                WHERE rp.RoleId = r.Id AND p.IsDeleted = 0 AND p.IsActive = 1
            )
        FROM dbo.Roles r
        WHERE r.IsDeleted = 0
          AND (@IsActive IS NULL OR r.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR r.RoleName LIKE N'%' + @SearchText + N'%'
               OR r.RoleKey LIKE N'%' + @SearchText + N'%'
               OR r.Description LIKE N'%' + @SearchText + N'%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT
            r.Id,
            r.RoleName,
            r.RoleKey,
            r.Description,
            r.IsSystem,
            r.IsActive,
            r.SortOrder,
            CreatedOn = r.CreatedAt,
            UserCount = (
                SELECT COUNT(*)
                FROM dbo.AdminUserRoles ur
                JOIN dbo.AdminUsers u ON ur.AdminUserId = u.Id
                WHERE ur.RoleId = r.Id AND u.IsDeleted = 0
            ),
            PermissionCount = (
                SELECT COUNT(*)
                FROM dbo.RolePermissions rp
                JOIN dbo.Permissions p ON rp.PermissionId = p.Id
                WHERE rp.RoleId = r.Id AND p.IsDeleted = 0 AND p.IsActive = 1
            )
        FROM dbo.Roles r
        WHERE r.IsDeleted = 0
          AND (@IsActive IS NULL OR r.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR r.RoleName LIKE N'%' + @SearchText + N'%'
               OR r.RoleKey LIKE N'%' + @SearchText + N'%'
               OR r.Description LIKE N'%' + @SearchText + N'%')
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'RoleName'        THEN RoleName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'RoleName'        THEN RoleName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'UserCount'       THEN UserCount END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'UserCount'       THEN UserCount END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'PermissionCount' THEN PermissionCount END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'PermissionCount' THEN PermissionCount END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'SortOrder'       THEN SortOrder END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'SortOrder'       THEN SortOrder END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn NOT IN ('RoleName','UserCount','PermissionCount','SortOrder') THEN SortOrder END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn NOT IN ('RoleName','UserCount','PermissionCount','SortOrder') THEN SortOrder END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO

/* =============================================================================
   2. dbo.usp_Role_GetById
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_Role_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Role Details
    SELECT
        r.Id,
        r.RoleName,
        r.RoleKey,
        r.Description,
        r.IsSystem,
        r.IsActive,
        r.CreatedAt AS CreatedOn,
        UserCount = (
            SELECT COUNT(*)
            FROM dbo.AdminUserRoles ur
            JOIN dbo.AdminUsers u ON ur.AdminUserId = u.Id
            WHERE ur.RoleId = r.Id AND u.IsDeleted = 0
        ),
        PermissionCount = (
            SELECT COUNT(*)
            FROM dbo.RolePermissions rp
            JOIN dbo.Permissions p ON rp.PermissionId = p.Id
            WHERE rp.RoleId = r.Id AND p.IsDeleted = 0 AND p.IsActive = 1
        )
    FROM dbo.Roles r
    WHERE r.Id = @Id AND r.IsDeleted = 0;

    -- 2. Assigned Permission IDs
    SELECT rp.PermissionId
    FROM dbo.RolePermissions rp
    JOIN dbo.Permissions p ON rp.PermissionId = p.Id
    WHERE rp.RoleId = @Id AND p.IsDeleted = 0 AND p.IsActive = 1;
END;
GO

/* =============================================================================
   3. dbo.usp_Role_Save
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_Role_Save
    @Id                 INT             = 0,
    @RoleName           NVARCHAR(100),
    @RoleKey            VARCHAR(64)     = NULL,
    @Description        NVARCHAR(500)   = NULL,
    @IsActive           BIT             = 1,
    @PermissionIdsCsv   NVARCHAR(MAX)   = NULL,
    @AdminUserId        INT             = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    IF @RoleKey IS NULL OR LEN(LTRIM(RTRIM(@RoleKey))) = 0
    BEGIN
        SET @RoleKey = LOWER(REPLACE(LTRIM(RTRIM(@RoleName)), ' ', '-'));
    END

    IF EXISTS (SELECT 1 FROM dbo.Roles WHERE (RoleName = @RoleName OR RoleKey = @RoleKey) AND Id <> @Id AND IsDeleted = 0)
    BEGIN
        RAISERROR(N'A role with this name or key already exists.', 16, 1);
        RETURN -1;
    END

    DECLARE @ResultId INT = @Id;

    IF @Id <= 0
    BEGIN
        INSERT INTO dbo.Roles (
            RoleName, RoleKey, Description, IsSystem, RequiresTwoFactor,
            SortOrder, CreatedAt, CreatedBy, IsActive, IsDeleted
        )
        VALUES (
            @RoleName, @RoleKey, @Description, 0, 0,
            10, SYSUTCDATETIME(), @AdminUserId, @IsActive, 0
        );

        SET @ResultId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        -- Super Admin role safeguard
        IF EXISTS (SELECT 1 FROM dbo.Roles WHERE Id = @Id AND (RoleKey = 'super-admin' OR RoleName = 'Super Admin'))
        BEGIN
            SET @IsActive = 1;
        END

        UPDATE dbo.Roles
        SET RoleName = @RoleName,
            RoleKey = @RoleKey,
            Description = @Description,
            IsActive = @IsActive,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @AdminUserId
        WHERE Id = @Id AND IsDeleted = 0;
    END

    -- Synchronize permissions
    IF @PermissionIdsCsv IS NOT NULL
    BEGIN
        DECLARE @ParsedIds TABLE (PermissionId INT);
        IF LEN(LTRIM(RTRIM(@PermissionIdsCsv))) > 0
        BEGIN
            INSERT INTO @ParsedIds (PermissionId)
            SELECT CAST(value AS INT)
            FROM STRING_SPLIT(@PermissionIdsCsv, ',')
            WHERE LTRIM(RTRIM(value)) <> '';
        END

        DELETE FROM dbo.RolePermissions WHERE RoleId = @ResultId;

        INSERT INTO dbo.RolePermissions (RoleId, PermissionId, CreatedAt, CreatedBy)
        SELECT @ResultId, p.PermissionId, SYSUTCDATETIME(), @AdminUserId
        FROM @ParsedIds p
        WHERE EXISTS (SELECT 1 FROM dbo.Permissions per WHERE per.Id = p.PermissionId AND per.IsDeleted = 0);
    END

    SELECT @ResultId;
END;
GO

/* =============================================================================
   4. dbo.usp_Role_Delete
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_Role_Delete
    @Id          INT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.Roles WHERE Id = @Id AND (RoleKey = 'super-admin' OR RoleName = 'Super Admin' OR Id = 1))
    BEGIN
        RAISERROR(N'Super Admin role cannot be deleted.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.AdminUserRoles ur JOIN dbo.AdminUsers u ON ur.AdminUserId = u.Id WHERE ur.RoleId = @Id AND u.IsDeleted = 0)
    BEGIN
        RAISERROR(N'Cannot delete role because active admin users are assigned to it.', 16, 1);
        RETURN;
    END

    UPDATE dbo.Roles
    SET IsDeleted = 1,
        IsActive = 0,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @AdminUserId
    WHERE Id = @Id;

    SELECT CAST(1 AS BIT);
END;
GO

/* =============================================================================
   5. dbo.usp_Role_UpdateStatus
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_Role_UpdateStatus
    @Id          INT,
    @IsActive    BIT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.Roles WHERE Id = @Id AND (RoleKey = 'super-admin' OR RoleName = 'Super Admin')) AND @IsActive = 0
    BEGIN
        RAISERROR(N'Super Admin role cannot be deactivated.', 16, 1);
        RETURN;
    END

    UPDATE dbo.Roles
    SET IsActive = @IsActive,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @AdminUserId
    WHERE Id = @Id AND IsDeleted = 0;

    SELECT CAST(1 AS BIT);
END;
GO

/* =============================================================================
   6. dbo.usp_Role_GetLookup
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_Role_GetLookup
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, RoleName AS Name
    FROM dbo.Roles
    WHERE IsDeleted = 0 AND IsActive = 1
    ORDER BY SortOrder, RoleName;
END;
GO
