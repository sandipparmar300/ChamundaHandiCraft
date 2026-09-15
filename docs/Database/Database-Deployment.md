# Database Deployment

**Runner:** `DatabaseScripts/Apply-Database.ps1`
**Target:** `Server=localhost\MSSQLSERVER01;Database=ChamundaHandicraft;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=True`

---

## 1. Quick start

```powershell
# default target (localhost\MSSQLSERVER01, ChamundaHandicraft)
.\DatabaseScripts\Apply-Database.ps1

# any other environment
.\DatabaseScripts\Apply-Database.ps1 -ServerInstance "localhost\MSSQLSERVER02" -Database "ChamundaHandicraft_Dev"

# dry run - lists what would execute, changes nothing
.\DatabaseScripts\Apply-Database.ps1 -WhatIf
```

The script creates the database if it does not exist, then applies everything in
dependency order. It is safe to run repeatedly.

---

## 2. Execution order

```
01-Schema/            00_Init … 20_Concurrency_And_Tax   (tables, constraints, indexes)
02-StoredProcedures/  <Module>/*.sql                      (CREATE OR ALTER)
05-Views/             *.sql                               (CREATE OR ALTER)
03-Seed/              *.sql                               (needs tables + procedures)
04-Patches/           <date>_<nn>_<name>.sql              (forward-only fixes)
```

Seed runs **after** views and procedures because seed rows reference objects
those files create (e.g. `ReportDefinitions.ProcedureName`).

Within `01-Schema` the numeric prefix is a hard dependency order — foreign keys
point backwards only. Two files close forward references left by earlier ones:

- `15_Reviews.sql` adds `FK_OrderItems_Reviews` (`OrderItems.ReviewId`, declared in `11_Orders.sql`)
- `17_Support.sql` adds `FK_ContactSubmissions_SupportTickets` (declared in `14_Content.sql`)

---

## 3. Re-run safety

Two independent mechanisms, either of which alone would be sufficient:

**a) Every script is internally idempotent.**

| Object | Guard |
|---|---|
| Tables | `IF OBJECT_ID(N'dbo.X', N'U') IS NULL BEGIN CREATE TABLE … END` |
| Columns | `IF COL_LENGTH(N'dbo.X', N'Col') IS NULL ALTER TABLE …` |
| Constraints | `IF OBJECT_ID(N'CK_…', N'C') IS NULL ALTER TABLE …` |
| Indexes | `IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = …)` |
| Procedures / views | `CREATE OR ALTER` |
| Seed | `MERGE` / `INSERT … WHERE NOT EXISTS`, matched on business keys |

**b) `dbo.SchemaHistory` tracks a SHA-256 per file.**

- Checksum unchanged → skipped.
- Checksum changed in `02-StoredProcedures`, `05-Views` or `03-Seed` → re-applied
  (these are safely re-runnable by construction).
- Checksum changed in `01-Schema` → **refused**, with a message telling you to
  add a `04-Patches` file instead. `-Force` overrides, for scratch databases only.

**Idempotency was verified, not assumed.** The seed files were executed three
times against a clean database; row counts were identical after each pass:

```
Roles=9  Perms=225  Grants=701  Admins=1  Reasons=46  Tax=6  Currencies=7
Events=44  Inquiry=14  Robots=9  Reports=14  Synonyms=20  Settings=42  TaxHist=6
```

Note `03-Seed/02_Reference_Data.sql`'s `Settings` merge has **no `WHEN MATCHED`
clause** — a re-run adds new keys but never overwrites a value an administrator
has changed through the Settings screen.

---

## 4. Nothing is ever destroyed

The pipeline contains no `DROP TABLE`, no `TRUNCATE`, and no unfiltered `DELETE`.
The runner cannot delete data even if invoked with `-Force`. `-Force` only
permits **re-applying** a changed script, and every script's guards mean
re-application is additive.

Business data is removed only by application-level soft delete
(`IsDeleted = 1`), recoverable through the Recycle Bin for 30 days.

---

## 5. Changing the schema after go-live

`01-Schema` is **append-only** once applied to any shared environment.

```
DatabaseScripts/04-Patches/2026-08-12_01_ForeignKeyIndexes.sql
                           └── date ──┘ └seq┘ └── description ──┘
```

Patches must be:

- **forward-only** — no down scripts; roll forward with another patch
- **idempotent** — same guards as everything else
- **additive** — add columns/indexes/constraints; do not rename or drop
- **nullable or defaulted** when adding a column to a populated table

To retire something, set `IsActive = 0` rather than deleting it — a removed
permission that is still granted would silently revoke access.

---

## 6. Verification

Run after every deployment. All should return the values shown.

```sql
-- Object counts
SELECT 'Tables',     COUNT(*) FROM sys.tables     WHERE is_ms_shipped = 0   -- 179
UNION ALL SELECT 'Views',      COUNT(*) FROM sys.views      WHERE is_ms_shipped = 0   -- 7
UNION ALL SELECT 'Procedures', COUNT(*) FROM sys.procedures WHERE is_ms_shipped = 0   -- 16
UNION ALL SELECT 'ForeignKeys',COUNT(*) FROM sys.foreign_keys                          -- 310
UNION ALL SELECT 'CheckCons',  COUNT(*) FROM sys.check_constraints;                    -- 91

-- Integrity: all three MUST return zero rows
SELECT name FROM sys.foreign_keys    WHERE is_not_trusted = 1 OR is_disabled = 1;
SELECT name FROM sys.check_constraints WHERE is_not_trusted = 1;
SELECT t.name FROM sys.tables t
WHERE t.is_ms_shipped = 0
  AND NOT EXISTS (SELECT 1 FROM sys.key_constraints k
                  WHERE k.parent_object_id = t.object_id AND k.type = 'PK');

-- Seed sanity
SELECT 'Roles', COUNT(*) FROM dbo.Roles                    -- 9
UNION ALL SELECT 'Permissions', COUNT(*) FROM dbo.Permissions      -- 225
UNION ALL SELECT 'RolePermissions', COUNT(*) FROM dbo.RolePermissions -- 701
UNION ALL SELECT 'SuperAdmins', COUNT(*) FROM dbo.AdminUsers u
    JOIN dbo.AdminUserRoles ur ON ur.AdminUserId = u.Id
    JOIN dbo.Roles r ON r.Id = ur.RoleId WHERE r.RoleKey = 'super-admin';  -- 1

-- Deployment ledger
SELECT ScriptFolder, ScriptName, AppliedAt, DurationMs
FROM   dbo.SchemaHistory ORDER BY ScriptFolder, ScriptName;
```

---

## 7. Post-deployment steps

Ordered. Steps 1 and 2 are **required before the site is reachable**.

1. **Change the Super Admin password.**
   Seeded as `admin@chamundahandicraft.com` / `ChangeMe@First1` with
   `MustChangePassword = 1`. The hash is real PBKDF2-HMAC-SHA256 (100,000
   iterations, per-user salt, ASP.NET Core Identity v3 format), so the account
   works — which is exactly why it must be rotated.

2. **Set `Jwt:JwtKey`** in `ChamundaHandicraft.API/appsettings.json` (or an
   environment secret). It is currently empty, and `Program.cs` skips registering
   the bearer handler entirely when it is — API authentication is silently off.

3. **Populate location data** — countries, states, cities, pincodes. Address
   forms and shipping-zone serviceability depend on it. Not seeded here because
   the full Indian pincode set is a data import, not reference data.

4. **Configure `Settings`** through the admin UI: company GSTIN, contact details,
   free-shipping threshold, COD limits, return window.

5. **Configure gateway and courier credentials** via `Integrations` /
   `GatewayCredentials` (encrypted by the service layer).

6. **Schedule the background jobs:**

   | Job | Cadence | Procedure |
   |---|---|---|
   | Report aggregation | Hourly | `usp_Analytics_RebuildDailySummaries` |
   | Rating recalculation | On review moderation | `usp_Review_RecalculateProductRating` |
   | Review requests | Daily | (pending — reads `ReviewRequests`) |
   | Low-stock alerts | Hourly | reads `vw_LowStockAlert` |
   | Abandoned-cart recovery | Hourly | reads `Carts.AbandonedAt` |
   | Sitemap regeneration | On publish + nightly | writes `SitemapEntries` |
   | Notification dispatch | Continuous | reads `IX_Notifications_Dispatch` |

7. **Enable backups.** See §9.

---

## 8. Environment promotion

Same scripts, different target. The runner is the only difference between
environments.

```powershell
.\Apply-Database.ps1 -ServerInstance "dev-sql"  -Database "ChamundaHandicraft_Dev"
.\Apply-Database.ps1 -ServerInstance "uat-sql"  -Database "ChamundaHandicraft_Uat"
.\Apply-Database.ps1 -ServerInstance "prod-sql" -Database "ChamundaHandicraft"
```

Environment-specific values live in `dbo.Settings`, not in the scripts, so no
script is ever edited per environment.

Take a backup before applying to production (§9). `SchemaHistory` tells you
exactly what a given environment already has:

```sql
SELECT ScriptFolder, ScriptName, AppliedAt FROM dbo.SchemaHistory ORDER BY AppliedAt;
```

---

## 9. Backup and rollback

**There is no down-script strategy, deliberately.** Reverse migrations on a
system with soft delete and financial history are a way to lose data. Recovery
is by backup or by a forward patch.

```sql
-- FULL recovery model in production
ALTER DATABASE ChamundaHandicraft SET RECOVERY FULL;

-- Pre-deployment backup
BACKUP DATABASE ChamundaHandicraft
TO DISK = 'D:\Backups\ChamundaHandicraft_predeploy.bak'
WITH INIT, COMPRESSION, CHECKSUM, STATS = 10;
```

Recommended: weekly full, daily differential, 15-minute log. Restore-test
quarterly — an untested backup is a hypothesis.

| Failure | Response |
|---|---|
| A script fails mid-run | The runner stops on the first error (`sqlcmd -b`) and records nothing for the failed file. Fix and re-run; completed files are skipped. |
| A patch is wrong | Write a corrective patch. Do not edit the applied one. |
| Data loss | Restore from backup; re-apply scripts (idempotent). |
| Deployment must be reversed | Restore the pre-deployment backup. |

---

## 10. Validation performed for this deployment

Before touching the target, the full pipeline was applied to a disposable
database (`ChamundaHandicraft_Validate` on `localhost\MSSQLSERVER02`), which has
the **same collation** (`SQL_Latin1_General_CP1_CI_AS`) so the run was
representative. Findings fixed there before the real deployment:

| Issue | Fix |
|---|---|
| `docs/Customer Flows/*.txt` in a header comment opened a **nested** T-SQL block comment, unterminating `18_Seo.sql` | Reworded the comment |
| `InventoryTransactions` columns assumed as `QuantityIn/Out`, `OpeningStock/ClosingStock`, `Notes` | Corrected to `QuantityChange`, `QuantityAfter`, `Note`; `TransactionType` is `VARCHAR`, not an enum |
| `Coupons` columns assumed as `UsageLimit`/`RedeemedCount` | Corrected to `TotalUsageLimit`/`UsageCount` |
| `CouponSegments` / `CustomerSegmentMembers` assumed `CustomerSegmentId` | Corrected to `SegmentId` |
| `OrderAddresses.AddressType`, `OrderNotes.Note`, `ReturnRequests.ReturnNumber` | Corrected to `AddressKind`, `Body`, `RmaNumber` |
| `Products` PK joined as `p.ProductId` | Corrected to `p.Id` |
| `Permissions.PermissionKey` is a **computed** column; the seed tried to insert it | Merge now matches on `(Module, Entity, Action)` |
| `WishlistItems` has no `IsDeleted` | Removed the predicate |
| Placeholder password hash was not a real PBKDF2 value | Generated a genuine Identity v3 hash and verified the byte layout |

The target database was inspected before deployment and found to exist but be
**completely empty** (0 tables, 0 rows), so nothing was overwritten.

**Result:** 34 scripts applied, 0 errors. 179 tables, 7 views, 16 procedures,
483 indexes, 310 foreign keys, 91 check constraints, 1,180 seed rows. All
foreign keys and check constraints trusted and enabled; every table has a
primary key.
