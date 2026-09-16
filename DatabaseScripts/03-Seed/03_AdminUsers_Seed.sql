/* =============================================================================
   03-Seed/03_AdminUsers_Seed.sql
   -----------------------------------------------------------------------------
   Seeds the five required Admin and Sub Admin accounts with initial password:
   Admin@123 (hashed using standard PBKDF2-HMAC-SHA256 Identity v3 format).
   
   Idempotent script: uses MERGE / IF NOT EXISTS.
   ============================================================================= */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @PasswordHash NVARCHAR(500) = N'AQAAAAEAAYagAAAAEHC3ObTe3dsSCi8WanWIe5OcQcRiZM5/9wSMUqOuqMx+6g836jzXVIRoTFepucHzog==';

DECLARE @Users TABLE
(
    FullName    NVARCHAR(200) NOT NULL,
    Email       NVARCHAR(256) NOT NULL,
    Phone       VARCHAR(24)   NOT NULL,
    RoleKey     VARCHAR(64)   NOT NULL
);

INSERT INTO @Users (FullName, Email, Phone, RoleKey) VALUES
    (N'Sandip Parmar',  N'sandipparmar300@gmail.com',         '9601781747', 'super-admin'),
    (N'Kajal Parmar',   N'sandipparmar300+kajal@gmail.com',   '8200169569', 'admin'),
    (N'Sanjay Parmar',  N'sandipparmar300+sanjay@gmail.com',  '9033109383', 'admin'),
    (N'Kalpana Parmar', N'sandipparmar300+kalpana@gmail.com', '7863028566', 'admin'),
    (N'Hiya Parmar',    N'sandipparmar300+hiya@gmail.com',    '9601781747', 'admin');

-- 1. Insert or update AdminUsers
MERGE dbo.AdminUsers AS tgt
USING @Users AS src
ON tgt.Email = src.Email
WHEN MATCHED THEN
    UPDATE SET
        FullName            = src.FullName,
        Phone               = src.Phone,
        PasswordHash        = @PasswordHash,
        MustChangePassword  = 0,
        FailedLoginCount    = 0,
        LockedOutUntil      = NULL,
        IsActive            = 1,
        IsDeleted           = 0,
        UpdatedAt           = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT
    (
        FullName,
        Email,
        Phone,
        PasswordHash,
        PasswordChangedAt,
        MustChangePassword,
        Timezone,
        TwoFactorEnabled,
        FailedLoginCount,
        CreatedAt,
        IsActive,
        IsDeleted
    )
    VALUES
    (
        src.FullName,
        src.Email,
        src.Phone,
        @PasswordHash,
        SYSUTCDATETIME(),
        0,
        N'India Standard Time',
        0,
        0,
        SYSUTCDATETIME(),
        1,
        0
    );

-- 2. Assign Primary Roles in dbo.AdminUserRoles
INSERT INTO dbo.AdminUserRoles (AdminUserId, RoleId, IsPrimary, CreatedAt)
SELECT u.Id, r.Id, 1, SYSUTCDATETIME()
FROM @Users AS s
INNER JOIN dbo.AdminUsers AS u ON u.Email = s.Email
INNER JOIN dbo.Roles AS r ON r.RoleKey = s.RoleKey
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.AdminUserRoles AS ur 
    WHERE ur.AdminUserId = u.Id AND ur.RoleId = r.Id
);

-- Sandip Parmar also gets Admin role in addition to Super Admin
INSERT INTO dbo.AdminUserRoles (AdminUserId, RoleId, IsPrimary, CreatedAt)
SELECT u.Id, r.Id, 0, SYSUTCDATETIME()
FROM dbo.AdminUsers AS u
CROSS JOIN dbo.Roles AS r
WHERE u.Email = N'sandipparmar300@gmail.com'
  AND r.RoleKey = 'admin'
  AND NOT EXISTS (
    SELECT 1 FROM dbo.AdminUserRoles AS ur 
    WHERE ur.AdminUserId = u.Id AND ur.RoleId = r.Id
  );

GO
