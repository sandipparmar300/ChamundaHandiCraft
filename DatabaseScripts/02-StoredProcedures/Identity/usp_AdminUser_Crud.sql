/* =============================================================================
   usp_AdminUser_Crud
   -----------------------------------------------------------------------------
   Stored procedures for Admin User Management:
     1. dbo.usp_AdminUser_GridList
     2. dbo.usp_AdminUser_GetById
     3. dbo.usp_AdminUser_Save
     4. dbo.usp_AdminUser_Delete
     5. dbo.usp_AdminUser_UpdateStatus
     6. dbo.usp_AdminUser_ChangePassword
   ============================================================================= */

SET NOCOUNT ON;
GO

/* =============================================================================
   1. dbo.usp_AdminUser_GridList
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_AdminUser_GridList
    @SearchText           NVARCHAR(200)   = NULL,
    @RoleId               INT             = NULL,
    @IsActive             BIT             = NULL,
    @SortColumn           VARCHAR(64)     = 'CreatedAt',
    @SortOrder            VARCHAR(4)      = 'DESC',
    @PageSize             INT             = 25,
    @PageIndex            INT             = 1,
    @TotalRecords         INT             OUTPUT,
    @TotalFilteredRecords INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageSize  IS NULL OR @PageSize  < 1 SET @PageSize  = 25;
    IF @PageIndex IS NULL OR @PageIndex < 1 SET @PageIndex = 1;
    IF @SortOrder IS NULL OR @SortOrder NOT IN ('ASC','DESC') SET @SortOrder = 'DESC';
    SET @SearchText = NULLIF(LTRIM(RTRIM(ISNULL(@SearchText, N''))), N'');

    SELECT @TotalRecords = COUNT(*) FROM dbo.AdminUsers WHERE IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT
            u.Id,
            u.FullName,
            u.Email,
            u.Phone,
            u.PhotoUrl,
            u.LastLoginOn,
            u.TwoFactorEnabled,
            IsLocked = CASE WHEN u.LockedOutUntil IS NOT NULL AND u.LockedOutUntil > SYSUTCDATETIME() THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
            u.IsActive,
            CreatedOn = u.CreatedAt,
            RoleName = ISNULL(r.RoleName, '—')
        FROM dbo.AdminUsers u
        OUTER APPLY (
            SELECT TOP 1 r1.Id, r1.RoleName
            FROM dbo.AdminUserRoles ur1
            JOIN dbo.Roles r1 ON ur1.RoleId = r1.Id AND r1.IsDeleted = 0
            WHERE ur1.AdminUserId = u.Id
            ORDER BY ur1.IsPrimary DESC, ur1.Id ASC
        ) r
        WHERE u.IsDeleted = 0
          AND (@IsActive IS NULL OR u.IsActive = @IsActive)
          AND (@RoleId IS NULL OR EXISTS (SELECT 1 FROM dbo.AdminUserRoles ur2 WHERE ur2.AdminUserId = u.Id AND ur2.RoleId = @RoleId))
          AND (@SearchText IS NULL
               OR u.FullName LIKE N'%' + @SearchText + N'%'
               OR u.Email LIKE N'%' + @SearchText + N'%'
               OR u.Phone LIKE N'%' + @SearchText + N'%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT
            u.Id,
            u.FullName,
            u.Email,
            u.Phone,
            u.PhotoUrl,
            u.LastLoginOn,
            u.TwoFactorEnabled,
            IsLocked = CASE WHEN u.LockedOutUntil IS NOT NULL AND u.LockedOutUntil > SYSUTCDATETIME() THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
            u.IsActive,
            CreatedOn = u.CreatedAt,
            RoleName = ISNULL(r.RoleName, '—')
        FROM dbo.AdminUsers u
        OUTER APPLY (
            SELECT TOP 1 r1.Id, r1.RoleName
            FROM dbo.AdminUserRoles ur1
            JOIN dbo.Roles r1 ON ur1.RoleId = r1.Id AND r1.IsDeleted = 0
            WHERE ur1.AdminUserId = u.Id
            ORDER BY ur1.IsPrimary DESC, ur1.Id ASC
        ) r
        WHERE u.IsDeleted = 0
          AND (@IsActive IS NULL OR u.IsActive = @IsActive)
          AND (@RoleId IS NULL OR EXISTS (SELECT 1 FROM dbo.AdminUserRoles ur2 WHERE ur2.AdminUserId = u.Id AND ur2.RoleId = @RoleId))
          AND (@SearchText IS NULL
               OR u.FullName LIKE N'%' + @SearchText + N'%'
               OR u.Email LIKE N'%' + @SearchText + N'%'
               OR u.Phone LIKE N'%' + @SearchText + N'%')
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'FullName'    THEN FullName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'FullName'    THEN FullName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Email'       THEN Email END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Email'       THEN Email END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'RoleName'    THEN RoleName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'RoleName'    THEN RoleName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'LastLoginOn' THEN LastLoginOn END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'LastLoginOn' THEN LastLoginOn END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CreatedOn'   THEN CreatedOn END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CreatedOn'   THEN CreatedOn END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn NOT IN ('FullName','Email','RoleName','LastLoginOn','CreatedOn') THEN CreatedOn END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn NOT IN ('FullName','Email','RoleName','LastLoginOn','CreatedOn') THEN CreatedOn END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO

/* =============================================================================
   2. dbo.usp_AdminUser_GetById
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_AdminUser_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.Id,
        u.FullName,
        u.Email,
        u.Phone AS Mobile,
        u.PhotoUrl,
        u.Timezone,
        u.IsActive,
        u.CreatedAt AS CreatedOn,
        u.LastLoginOn,
        u.TwoFactorEnabled,
        IsLocked = CASE WHEN u.LockedOutUntil IS NOT NULL AND u.LockedOutUntil > SYSUTCDATETIME() THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
        RoleId = ISNULL(r.RoleId, 0),
        RoleName = ISNULL(r.RoleName, '')
    FROM dbo.AdminUsers u
    OUTER APPLY (
        SELECT TOP 1 ur.RoleId, ro.RoleName
        FROM dbo.AdminUserRoles ur
        JOIN dbo.Roles ro ON ur.RoleId = ro.Id
        WHERE ur.AdminUserId = u.Id
        ORDER BY ur.IsPrimary DESC, ur.Id ASC
    ) r
    WHERE u.Id = @Id AND u.IsDeleted = 0;
END;
GO

/* =============================================================================
   3. dbo.usp_AdminUser_Save
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_AdminUser_Save
    @Id               INT             = 0,
    @FullName         NVARCHAR(200),
    @Email            NVARCHAR(256),
    @Phone            VARCHAR(24)     = NULL,
    @PasswordHash     NVARCHAR(500)   = NULL,
    @PhotoUrl         NVARCHAR(1000)  = NULL,
    @Timezone         VARCHAR(64)     = 'Asia/Kolkata',
    @RoleId           INT             = NULL,
    @IsActive         BIT             = 1,
    @AdminUserId      INT             = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    -- Validate unique email
    IF EXISTS (SELECT 1 FROM dbo.AdminUsers WHERE Email = @Email AND Id <> @Id AND IsDeleted = 0)
    BEGIN
        RAISERROR(N'Email address "%s" is already registered.', 16, 1, @Email);
        RETURN -1;
    END

    DECLARE @ResultId INT = @Id;

    IF @Id <= 0
    BEGIN
        -- Insert new admin user
        INSERT INTO dbo.AdminUsers (
            FullName, Email, Phone, PasswordHash, PhotoUrl,
            Timezone, TwoFactorEnabled, FailedLoginCount,
            CreatedAt, CreatedBy, IsActive, IsDeleted, MustChangePassword
        )
        VALUES (
            @FullName, @Email, @Phone, ISNULL(@PasswordHash, ''), @PhotoUrl,
            ISNULL(@Timezone, 'Asia/Kolkata'), 0, 0,
            SYSUTCDATETIME(), @AdminUserId, @IsActive, 0, 0
        );

        SET @ResultId = SCOPE_IDENTITY();

        IF @RoleId IS NOT NULL AND @RoleId > 0
        BEGIN
            INSERT INTO dbo.AdminUserRoles (AdminUserId, RoleId, IsPrimary, CreatedAt, CreatedBy)
            VALUES (@ResultId, @RoleId, 1, SYSUTCDATETIME(), @AdminUserId);
        END
    END
    ELSE
    BEGIN
        -- Protect primary Super Admin (Id = 1) from deactivation
        IF @Id = 1
        BEGIN
            SET @IsActive = 1;
        END

        UPDATE dbo.AdminUsers
        SET FullName = @FullName,
            Email = @Email,
            Phone = @Phone,
            PhotoUrl = COALESCE(@PhotoUrl, PhotoUrl),
            Timezone = ISNULL(@Timezone, Timezone),
            PasswordHash = CASE WHEN @PasswordHash IS NOT NULL AND LEN(@PasswordHash) > 0 THEN @PasswordHash ELSE PasswordHash END,
            PasswordChangedAt = CASE WHEN @PasswordHash IS NOT NULL AND LEN(@PasswordHash) > 0 THEN SYSUTCDATETIME() ELSE PasswordChangedAt END,
            IsActive = @IsActive,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @AdminUserId
        WHERE Id = @Id AND IsDeleted = 0;

        IF @RoleId IS NOT NULL AND @RoleId > 0
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.AdminUserRoles WHERE AdminUserId = @Id)
            BEGIN
                UPDATE dbo.AdminUserRoles
                SET RoleId = @RoleId
                WHERE AdminUserId = @Id AND IsPrimary = 1;

                IF @@ROWCOUNT = 0
                BEGIN
                    UPDATE TOP(1) dbo.AdminUserRoles
                    SET RoleId = @RoleId, IsPrimary = 1
                    WHERE AdminUserId = @Id;
                END
            END
            ELSE
            BEGIN
                INSERT INTO dbo.AdminUserRoles (AdminUserId, RoleId, IsPrimary, CreatedAt, CreatedBy)
                VALUES (@Id, @RoleId, 1, SYSUTCDATETIME(), @AdminUserId);
            END
        END
    END

    SELECT @ResultId;
END;
GO

/* =============================================================================
   4. dbo.usp_AdminUser_Delete
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_AdminUser_Delete
    @Id          INT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id = 1
    BEGIN
        RAISERROR(N'Primary Super Admin account cannot be deleted.', 16, 1);
        RETURN;
    END

    UPDATE dbo.AdminUsers
    SET IsDeleted = 1,
        IsActive = 0,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @AdminUserId
    WHERE Id = @Id;

    SELECT CAST(1 AS BIT);
END;
GO

/* =============================================================================
   5. dbo.usp_AdminUser_UpdateStatus
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_AdminUser_UpdateStatus
    @Id          INT,
    @IsActive    BIT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id = 1 AND @IsActive = 0
    BEGIN
        RAISERROR(N'Primary Super Admin account cannot be deactivated.', 16, 1);
        RETURN;
    END

    UPDATE dbo.AdminUsers
    SET IsActive = @IsActive,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @AdminUserId
    WHERE Id = @Id AND IsDeleted = 0;

    SELECT CAST(1 AS BIT);
END;
GO

/* =============================================================================
   6. dbo.usp_AdminUser_ChangePassword
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_AdminUser_ChangePassword
    @Id           INT,
    @PasswordHash NVARCHAR(500),
    @AdminUserId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.AdminUsers
    SET PasswordHash = @PasswordHash,
        PasswordChangedAt = SYSUTCDATETIME(),
        FailedLoginCount = 0,
        LockedOutUntil = NULL,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @AdminUserId
    WHERE Id = @Id AND IsDeleted = 0;

    SELECT CAST(1 AS BIT);
END;
GO
