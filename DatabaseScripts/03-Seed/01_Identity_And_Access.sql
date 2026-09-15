/* =============================================================================
   03-Seed/01_Identity_And_Access.sql
   -----------------------------------------------------------------------------
   Roles, the permission key catalogue, role grants, and the first Super Admin.

   Specs:
     Users.txt §6   the nine roles
     Users.txt §7   permission types and the module list
     Users.txt      "Super Admin has unrestricted access and cannot be deleted."
     DatabaseScripts/README.md  03-Seed contents

   IDEMPOTENCY (prompt §32)
   ------------------------
   Every statement is MERGE or INSERT ... WHERE NOT EXISTS, matched on the
   business key (RoleKey, PermissionKey, Email) rather than on an identity value.
   Running this file ten times produces exactly the same rows as running it once.

   Nothing is ever deleted here. A permission removed from this file stays in the
   database; retire it by setting IsActive = 0 in a 04-Patches script, so an
   existing grant is never silently revoked.
   ============================================================================= */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ---------------------------------------------------------------------------
   1. Roles - Users.txt §6
   --------------------------------------------------------------------------- */
MERGE dbo.Roles AS tgt
USING (VALUES
    (N'Super Admin',       'super-admin',       N'Unrestricted access. Cannot be deleted or demoted.', 1, 1,  1),
    (N'Admin',             'admin',             N'Full operational access except system settings.',    1, 1,  2),
    (N'Product Manager',   'product-manager',   N'Catalogue, categories, media and SEO.',              1, 0,  3),
    (N'Inventory Manager', 'inventory-manager', N'Stock, warehouses, purchases and adjustments.',      1, 0,  4),
    (N'Sales Manager',     'sales-manager',     N'Orders, shipments, returns and customers.',          1, 0,  5),
    (N'Customer Support',  'customer-support',  N'Tickets, enquiries, order lookup and reviews.',      1, 0,  6),
    (N'Finance Manager',   'finance-manager',   N'Payments, refunds, settlements, tax and reports.',   1, 1,  7),
    (N'Marketing Manager', 'marketing-manager', N'Coupons, offers, banners, campaigns and newsletter.',1, 0,  8),
    (N'Content Manager',   'content-manager',   N'CMS pages, blog, FAQs and testimonials.',            1, 0,  9)
) AS src (RoleName, RoleKey, Description, IsSystem, RequiresTwoFactor, SortOrder)
   ON tgt.RoleKey = src.RoleKey
WHEN MATCHED THEN
    UPDATE SET RoleName          = src.RoleName,
               Description       = src.Description,
               IsSystem          = src.IsSystem,
               RequiresTwoFactor = src.RequiresTwoFactor,
               SortOrder         = src.SortOrder,
               UpdatedAt         = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (RoleName, RoleKey, Description, IsSystem, RequiresTwoFactor, SortOrder)
    VALUES (src.RoleName, src.RoleKey, src.Description, src.IsSystem, src.RequiresTwoFactor, src.SortOrder);
GO

/* ---------------------------------------------------------------------------
   2. Permission catalogue.

   Key shape: <module>.<entity>.<action> - the same string the API checks with
   [HasApiPermission("catalog.product.create")] (ARCHITECTURE.md §7).

   Built by cross-joining a module/entity list with the actions each supports,
   rather than writing ~400 literals by hand. The action set per entity is
   declared once, which is what stops "view" existing for one entity and
   "read" for another.
   --------------------------------------------------------------------------- */
DECLARE @Entities TABLE
(
    Module      VARCHAR(48)  NOT NULL,
    Entity      VARCHAR(48)  NOT NULL,
    Actions     VARCHAR(300) NOT NULL,   -- comma-separated
    SortOrder   INT          NOT NULL
);

INSERT INTO @Entities (Module, Entity, Actions, SortOrder) VALUES
    ('dashboard',    'dashboard',    'view,export',                                        1),
    ('dashboard',    'revenue',      'view',                                               2),
    ('identity',     'adminuser',    'view,create,update,delete,export',                   10),
    ('identity',     'role',         'view,create,update,delete',                          11),
    ('identity',     'permission',   'view,update',                                        12),
    ('identity',     'loginhistory', 'view,export',                                        13),
    ('catalog',      'product',      'view,create,update,delete,publish,import,export',    20),
    ('catalog',      'variant',      'view,create,update,delete',                          21),
    ('catalog',      'brand',        'view,create,update,delete',                          22),
    ('catalog',      'artisan',      'view,create,update,delete',                          23),
    ('catalog',      'attribute',    'view,create,update,delete',                          24),
    ('catalog',      'collection',   'view,create,update,delete',                          25),
    ('category',     'category',     'view,create,update,delete,publish,import,export',    30),
    ('category',     'menu',         'view,update',                                        31),
    ('inventory',    'stock',        'view,update,export',                                 40),
    ('inventory',    'warehouse',    'view,create,update,delete',                          41),
    ('inventory',    'purchase',     'view,create,update,delete,approve',                  42),
    ('inventory',    'adjustment',   'view,create,approve',                                43),
    ('inventory',    'transfer',     'view,create,approve',                                44),
    ('inventory',    'stocktake',    'view,create,approve',                                45),
    ('order',        'order',        'view,update,delete,export',                          50),
    ('order',        'orderstatus',  'update',                                             51),
    ('order',        'invoice',      'view,create,export',                                 52),
    ('order',        'return',       'view,update,approve',                                53),
    ('order',        'refund',       'view,create,approve',                                54),
    ('customer',     'customer',     'view,create,update,delete,export',                   60),
    ('customer',     'segment',      'view,create,update,delete',                          61),
    ('customer',     'reward',       'view,update',                                        62),
    ('payment',      'payment',      'view,export',                                        70),
    ('payment',      'gateway',      'view,update',                                        71),
    ('payment',      'settlement',   'view,export',                                        72),
    ('payment',      'dispute',      'view,update',                                        73),
    ('shipping',     'shipment',     'view,create,update,export',                          80),
    ('shipping',     'courier',      'view,create,update,delete',                          81),
    ('shipping',     'zone',         'view,create,update,delete',                          82),
    ('shipping',     'rate',         'view,create,update,delete',                          83),
    ('promotion',    'coupon',       'view,create,update,delete,export',                   90),
    ('promotion',    'offer',        'view,create,update,delete,export',                   91),
    ('marketing',    'banner',       'view,create,update,delete,publish',                  100),
    ('marketing',    'campaign',     'view,create,update,delete',                          101),
    ('marketing',    'subscriber',   'view,create,update,delete,export',                   102),
    ('content',      'cmspage',      'view,create,update,delete,publish',                  110),
    ('content',      'faq',          'view,create,update,delete',                          111),
    ('content',      'blog',         'view,create,update,delete,publish',                  112),
    ('content',      'blogcomment',  'view,update,delete,approve',                         113),
    ('content',      'testimonial',  'view,create,update,delete,approve',                  114),
    ('review',       'review',       'view,update,delete,approve,export',                  120),
    ('review',       'abusereport',  'view,update',                                        121),
    ('support',      'ticket',       'view,create,update,delete',                          130),
    ('support',      'contact',      'view,update,export',                                 131),
    ('notification', 'template',     'view,create,update,delete',                          140),
    ('notification', 'notification', 'view,create,export',                                 141),
    ('seo',          'meta',         'view,update',                                        150),
    ('seo',          'redirect',     'view,create,update,delete',                          151),
    ('seo',          'sitemap',      'view,update',                                        152),
    ('report',       'sales',        'view,export',                                        160),
    ('report',       'profit',       'view,export',                                        161),
    ('report',       'customer',     'view,export',                                        162),
    ('report',       'inventory',    'view,export',                                        163),
    ('report',       'tax',          'view,export',                                        164),
    ('report',       'payment',      'view,export',                                        165),
    ('report',       'return',       'view,export',                                        166),
    ('settings',     'settings',     'view,update',                                        170),
    ('settings',     'integration',  'view,update',                                        171),
    ('settings',     'feature',      'view,update',                                        172),
    ('audit',        'auditlog',     'view,export',                                        180),
    ('audit',        'approval',     'view,approve',                                       181),
    ('media',        'media',        'view,create,delete',                                 190);

;WITH Expanded AS
(
    SELECT  e.Module,
            e.Entity,
            Action = LTRIM(RTRIM(s.value)),
            e.SortOrder
    FROM    @Entities AS e
    CROSS APPLY STRING_SPLIT(e.Actions, ',') AS s
)
/* dbo.Permissions.PermissionKey is a COMPUTED column:
       lower(Module + '.' + Entity + '.' + Action)
   so it is never written, and the merge matches on the three source columns
   that produce it. */
MERGE dbo.Permissions AS tgt
USING (
    SELECT  Module,
            Entity,
            Action,
            Description = CONCAT(UPPER(LEFT(Action,1)), SUBSTRING(Action,2,50),
                                 ' ', Entity, ' (', Module, ')'),
            SortOrder
    FROM    Expanded
) AS src
   ON tgt.Module = src.Module
  AND tgt.Entity = src.Entity
  AND tgt.Action = src.Action
WHEN MATCHED THEN
    UPDATE SET Description = src.Description,
               SortOrder   = src.SortOrder,
               IsSystem    = 1,
               UpdatedAt   = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Module, Entity, Action, Description, SortOrder, IsSystem)
    VALUES (src.Module, src.Entity, src.Action, src.Description, src.SortOrder, 1);
GO

/* ---------------------------------------------------------------------------
   3. Role grants.

   Super Admin is handled as "everything", so a permission added later is
   automatically granted - a role that must never be able to lock itself out of
   a new screen cannot rely on a static list.

   The other roles are granted by module prefix, which keeps the intent readable
   and survives new entities appearing inside a module they already own.
   --------------------------------------------------------------------------- */
DECLARE @Grants TABLE
(
    RoleKey     VARCHAR(48)  NOT NULL,
    Pattern     VARCHAR(100) NOT NULL,   -- LIKE pattern over PermissionKey
    ExcludeAction VARCHAR(100) NULL      -- comma-separated actions to withhold
);

INSERT INTO @Grants (RoleKey, Pattern, ExcludeAction) VALUES
    -- Admin: everything except the settings and identity modules
    ('admin',             'dashboard.%',    NULL),
    ('admin',             'catalog.%',      NULL),
    ('admin',             'category.%',     NULL),
    ('admin',             'inventory.%',    NULL),
    ('admin',             'order.%',        NULL),
    ('admin',             'customer.%',     NULL),
    ('admin',             'payment.%',      NULL),
    ('admin',             'shipping.%',     NULL),
    ('admin',             'promotion.%',    NULL),
    ('admin',             'marketing.%',    NULL),
    ('admin',             'content.%',      NULL),
    ('admin',             'review.%',       NULL),
    ('admin',             'support.%',      NULL),
    ('admin',             'notification.%', NULL),
    ('admin',             'seo.%',          NULL),
    ('admin',             'report.%',       NULL),
    ('admin',             'audit.%',        NULL),
    ('admin',             'media.%',        NULL),
    ('admin',             'settings.%',     'update'),

    ('product-manager',   'dashboard.dashboard.view', NULL),
    ('product-manager',   'catalog.%',      NULL),
    ('product-manager',   'category.%',     NULL),
    ('product-manager',   'media.%',        NULL),
    ('product-manager',   'seo.%',          NULL),
    ('product-manager',   'inventory.stock.view', NULL),
    ('product-manager',   'report.inventory.%', NULL),

    ('inventory-manager', 'dashboard.dashboard.view', NULL),
    ('inventory-manager', 'inventory.%',    NULL),
    ('inventory-manager', 'catalog.product.view', NULL),
    ('inventory-manager', 'report.inventory.%', NULL),

    ('sales-manager',     'dashboard.%',    NULL),
    ('sales-manager',     'order.%',        NULL),
    ('sales-manager',     'shipping.%',     NULL),
    ('sales-manager',     'customer.%',     NULL),
    ('sales-manager',     'catalog.product.view', NULL),
    ('sales-manager',     'inventory.stock.view', NULL),
    ('sales-manager',     'report.sales.%', NULL),
    ('sales-manager',     'report.return.%', NULL),

    ('customer-support',  'dashboard.dashboard.view', NULL),
    ('customer-support',  'support.%',      NULL),
    ('customer-support',  'review.%',       NULL),
    ('customer-support',  'order.order.view', NULL),
    ('customer-support',  'order.return.%', NULL),
    ('customer-support',  'customer.customer.view', NULL),
    ('customer-support',  'shipping.shipment.view', NULL),

    ('finance-manager',   'dashboard.%',    NULL),
    ('finance-manager',   'payment.%',      NULL),
    ('finance-manager',   'order.invoice.%',NULL),
    ('finance-manager',   'order.refund.%', NULL),
    ('finance-manager',   'order.order.view', NULL),
    ('finance-manager',   'report.%',       NULL),
    ('finance-manager',   'audit.%',        NULL),

    ('marketing-manager', 'dashboard.dashboard.view', NULL),
    ('marketing-manager', 'promotion.%',    NULL),
    ('marketing-manager', 'marketing.%',    NULL),
    ('marketing-manager', 'notification.%', NULL),
    ('marketing-manager', 'seo.%',          NULL),
    ('marketing-manager', 'media.%',        NULL),
    ('marketing-manager', 'catalog.product.view', NULL),
    ('marketing-manager', 'customer.segment.%', NULL),

    ('content-manager',   'dashboard.dashboard.view', NULL),
    ('content-manager',   'content.%',      NULL),
    ('content-manager',   'media.%',        NULL),
    ('content-manager',   'seo.%',          NULL),
    ('content-manager',   'review.review.view', NULL);

/* Super Admin: every permission that exists. */
INSERT INTO dbo.RolePermissions (RoleId, PermissionId, CreatedAt)
SELECT r.Id, p.Id, SYSUTCDATETIME()
FROM   dbo.Roles AS r
CROSS JOIN dbo.Permissions AS p
WHERE  r.RoleKey = 'super-admin'
  AND  NOT EXISTS (SELECT 1 FROM dbo.RolePermissions AS rp
                   WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id);

/* Everyone else, by pattern. */
INSERT INTO dbo.RolePermissions (RoleId, PermissionId, CreatedAt)
SELECT DISTINCT r.Id, p.Id, SYSUTCDATETIME()
FROM   @Grants AS g
JOIN   dbo.Roles AS r ON r.RoleKey = g.RoleKey
JOIN   dbo.Permissions AS p ON p.PermissionKey LIKE g.Pattern
WHERE  (g.ExcludeAction IS NULL
        OR p.Action NOT IN (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(g.ExcludeAction, ',')))
  AND  NOT EXISTS (SELECT 1 FROM dbo.RolePermissions AS rp
                   WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id);
GO

/* ---------------------------------------------------------------------------
   4. The first Super Admin.

   SECURITY (prompt §33)
   ---------------------
   PasswordHash below is a real ASP.NET Core Identity v3 hash, in the exact
   binary layout PasswordHasher<TUser> produces and verifies:

       byte  0      0x01                 version marker
       bytes 1-4    0x00000001           PRF = HMACSHA256
       bytes 5-8    0x000186A0           100,000 iterations
       bytes 9-12   0x00000010           16-byte salt
       bytes 13-28  salt                 cryptographically random, per user
       bytes 29-60  subkey               PBKDF2 output, 32 bytes

   Plaintext:  ChangeMe@First1
   It is stored nowhere - only the derived subkey above.

   MustChangePassword = 1, so this credential cannot survive first login.
   Rotate or disable this account before the site is reachable publicly.
   --------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM dbo.AdminUsers WHERE Email = N'admin@chamundahandicraft.com')
BEGIN
    INSERT INTO dbo.AdminUsers
    (
        FullName, Email, Phone, PasswordHash, PasswordChangedAt,
        MustChangePassword, Timezone, TwoFactorEnabled,
        FailedLoginCount, CreatedAt, IsActive, IsDeleted
    )
    VALUES
    (
        N'Super Admin',
        N'admin@chamundahandicraft.com',
        NULL,
        N'AQAAAAEAAYagAAAAENoLv29odJcwR/INpk+ZJwvMhVvqcmYGO1NB2mfgkzKJpgce6bm32KJZQUpPfKnFrA==',
        SYSUTCDATETIME(),
        1,                                  -- forced password change on first login
        N'India Standard Time',
        0,
        0,
        SYSUTCDATETIME(),
        1,
        0
    );
END
GO

/* Give it the Super Admin role. */
INSERT INTO dbo.AdminUserRoles (AdminUserId, RoleId, IsPrimary, CreatedAt)
SELECT u.Id, r.Id, 1, SYSUTCDATETIME()
FROM   dbo.AdminUsers AS u
CROSS JOIN dbo.Roles AS r
WHERE  u.Email  = N'admin@chamundahandicraft.com'
  AND  r.RoleKey = 'super-admin'
  AND  NOT EXISTS (SELECT 1 FROM dbo.AdminUserRoles AS ur
                   WHERE ur.AdminUserId = u.Id AND ur.RoleId = r.Id);
GO
