# Chamunda Handicraft — Database Architecture

**Database:** `ChamundaHandicraft` · Microsoft SQL Server 2022 · collation `SQL_Latin1_General_CP1_CI_AS`
**Scripts:** `DatabaseScripts/` · **Runner:** `DatabaseScripts/Apply-Database.ps1`
**Derived from:** `docs/Admin Flows/` (20 modules) · `docs/Customer Flows/` (13 modules)
**Status:** deployed and verified — 179 tables, 7 views, 16 procedures, 483 indexes, 310 foreign keys.

---

## 1. Overview

The database backs two front ends — the back-office Admin panel and the customer
storefront — through a single ASP.NET Core 8 API. It is one physical database
organised into module-aligned script files, matching the Modular Monolith
structure in `ARCHITECTURE.md`.

| Layer | Count | Where |
|---|---|---|
| Tables | 179 | `01-Schema/01…20` |
| Views | 7 | `05-Views/` |
| Stored procedures | 16 | `02-StoredProcedures/<Module>/` |
| Indexes | 483 (179 clustered, 304 non-clustered, 152 filtered) | inline with tables |
| Foreign keys | 310 | inline |
| Check constraints | 91 | inline |
| Unique constraints / indexes | 78 / 303 | inline |
| Seed rows | 1,180 | `03-Seed/` |

### Scope note

Files `01_Platform` → `14_Content` (121 tables) pre-existed this work and were
validated, not rewritten. Files `15_Reviews` → `20_Concurrency_And_Tax`
(58 tables) were added to close the gaps found when auditing the flow specs
against the schema. See §11.

---

## 2. Data access strategy

**Dapper over stored procedures and views. No ORM, no change tracking.**

This follows `ARCHITECTURE.md` §6, which is the repository's own documented
standard. The task brief mentioned "EF Core + Dapper where appropriate"; where
the brief and the repository disagreed, the repository won, per the instruction
to follow existing repository documentation. That decision is recorded here
because it is the single most structural assumption in the design.

Consequences:

- Every write path is an explicit `INSERT`/`UPDATE`, so concurrency control is
  visible in SQL rather than inferred from a change tracker.
- Stored procedures exist only where they earn their place (§8). Simple CRUD is
  parameterised SQL in the repository classes.
- Reporting reads views and procedures, never entity graphs.

---

## 3. Naming conventions

| Object | Convention | Example |
|---|---|---|
| Table | PascalCase, **plural** | `OrderItems`, `SeoMetas` |
| Column | PascalCase, singular | `CustomerId`, `PlacedOn` |
| Primary key | `PK_<Table>` | `PK_Orders` |
| Foreign key | `FK_<Table>_<Referenced>` | `FK_OrderItems_Products` |
| Unique constraint | `UQ_<Table>_<Purpose>` | `UQ_Settings_SectionKey` |
| Unique index | `UX_<Table>_<Purpose>` | `UX_Products_Slug` |
| Non-unique index | `IX_<Table>_<Purpose>` | `IX_Orders_Status` |
| Check constraint | `CK_<Table>_<Rule>` | `CK_Reviews_Rating` |
| Default constraint | `DF_<Table>_<Column>` | `DF_Orders_PlacedOn` |
| Stored procedure | `usp_<Module>_<Action>` | `usp_Report_GetTax` |
| Grid procedure (legacy) | `GridList_<Entity>` | `GridList_Product` |
| View | `vw_<Subject>` | `vw_OrderRevenue` |

Both procedure conventions exist deliberately: `DatabaseScripts/README.md` and
the repository contracts in `ARCHITECTURE.md` §6 document `GridList_<Entity>`,
while the brief asked for `usp_<Module>_<Action>`. `usp_Product_GridList` is the
implementation; `GridList_Product` is a thin forwarding procedure so both names
resolve to one body.

---

## 4. Primary key strategy

Every table has a single-column surrogate `Id IDENTITY` clustered primary key.
No GUIDs, no composite primary keys, no natural keys as PKs.

| Type | Used for | Count |
|---|---|---|
| `INT IDENTITY` | Entities bounded by business scale — products, orders, customers, coupons, categories | 95 |
| `BIGINT IDENTITY` | Rows generated per-event or per-line, which grow without a business ceiling — order lines, ledger entries, logs, notifications, analytics events | 81 |
| Natural PK | The two daily rollups, keyed on `SummaryDate` — one row per day by definition, and a surrogate would allow duplicates | 2 |

The `INT`/`BIGINT` split is by **growth shape**, not by table size today.
`Orders` is `INT` because order count is bounded by the business; `OrderItems`
is `BIGINT` because it grows as a multiple of orders. `AuditLogs`,
`InventoryTransactions`, `SearchQueries`, `PageViewLogs` and `Notifications` are
all `BIGINT` for the same reason.

Business identifiers (`OrderNumber`, `InvoiceNumber`, `RmaNumber`,
`TicketNumber`, `Sku`, `Slug`, `Code`) are separate columns with unique indexes.
They are the values humans quote; they are never foreign keys.

---

## 5. Audit and soft-delete strategy

Standard business entities carry:

```
CreatedAt  DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
CreatedBy  INT NULL
UpdatedAt  DATETIME2(3) NULL
UpdatedBy  INT NULL
IsActive   BIT NOT NULL DEFAULT 1
IsDeleted  BIT NOT NULL DEFAULT 0
```

`IsActive` and `IsDeleted` are distinct: *inactive* is an editorial choice
(hidden but intact), *deleted* is a removal that preserves referential history.

**Soft delete is not applied blindly.** It is decided per entity, per the brief's
§23. Tables that deliberately have **no** `IsDeleted`:

| Table | Why |
|---|---|
| `AuditLogs`, `AuditLogDetails` | An audit record that can be deleted is not an audit record. |
| `OrderStatusHistories`, `SupportTicketStatusHistories`, `ReviewModerationHistories` | Append-only transition logs. Deleting one would falsify a timeline. |
| `InventoryTransactions` | The stock ledger. Inventory.txt §21 requires an immutable movement history. |
| `CouponRedemptions` | Deleting a redemption would silently restore a used coupon. Release is an explicit reversal (`usp_Coupon_Release`). |
| `CampaignEvents`, `NotificationDeliveryLogs` | Provider facts. A webhook event is not editable. |
| `SearchQueries`, `ProductViewLogs`, `PageViewLogs`, `BannerEvents` | Analytics facts, purged by retention policy rather than flagged. |
| `DailySalesSummaries`, `DailyTrafficSummaries` | Caches. Rebuilt wholesale, never flagged. |
| `WishlistItems`, `ReviewHelpfulVotes` | Removing one is a genuine delete with no downstream meaning. |

---

## 6. Status strategy

Statuses are `TINYINT` columns holding values from the enums in
`ChamundaHandicraft.Helper/Enums/Enum.cs`, **not** free-text strings and not
lookup tables.

Rationale: a status participates in `WHERE` clauses on the hottest queries in
the system. A `TINYINT` compares in one byte and indexes tightly; a lookup table
adds a join to every order query to retrieve a label the presentation layer
already knows. The trade — that the value's meaning lives in code — is mitigated
by documenting the enum inline above every status column and by `CHECK`
constraints that reject out-of-range values.

Where a status genuinely needs business-editable metadata, it *is* a table:
`ReasonCodes` carries `RequiresPhoto`, `RequiresNote` and `IsOurFault` per
reason, which is data the business changes without a deployment.

Key status sets:

| Domain | Values |
|---|---|
| Order | 0 Placed, 1 PaymentPending, 2 Processing, 3 Packed, 4 Shipped, 5 InTransit, 6 OutForDelivery, 7 Delivered, 8 Completed, 9 Cancelled, 10 ReturnRequested, 11 ReturnApproved, 12 ReturnPickedUp, 13 Refunded, 14 PaymentFailed, 15 Closed |
| Payment | 0 Pending, 1 Authorised, 2 Paid, 3 Failed, 4 Refunded, 5 PartiallyRefunded, 6 CodPending |
| Product | 0 Draft, 1 Published, 2 Unpublished, 3 Archived |
| Review | 0 Pending, 1 Approved, 2 Rejected, 3 Hidden |
| Support ticket | 0 Submitted, 1 Assigned, 2 InProgress, 3 WaitingOnCustomer, 4 Resolved, 5 Closed, 6 Reopened, 7 Cancelled |
| Notification | 0 Pending, 1 Queued, 2 Processing, 3 Sent, 4 Delivered, 5 Failed, 6 Cancelled, 7 Retrying |
| Subscriber | 0 PendingVerification, 1 Active, 2 Unsubscribed, 3 Blocked, 4 Bounced |
| Campaign | 0 Draft, 1 Scheduled, 2 Sending, 3 Completed, 4 Cancelled, 5 Failed |

Order status **transitions** are validated in the API against Orders.txt §2 —
the admin screen only offers legal next steps. They are not enforced by a
database trigger, because a trigger cannot express "this transition is legal for
a Finance Manager but not a Support agent".

---

## 7. Historical accuracy and snapshots

The brief's §21 requirement — historical records must stay correct when
products, prices, taxes, addresses and coupons change — is met by snapshotting
at the point of sale rather than joining live.

| Snapshot | Where | Protects against |
|---|---|---|
| Product name, SKU, slug, image, variant summary, artisan, HSN | `OrderItems` | Rename, re-slug, image change, product deletion |
| Unit price, MRP, line discount, tax percent, tax amount | `OrderItems` | Re-pricing, discount changes |
| CGST/SGST/IGST/CESS rate + taxable value + place of supply | `OrderItemTaxes` | GST rate changes; enables historical GST filing |
| Full billing and shipping address | `OrderAddresses` | Customer editing or deleting an address |
| Coupon code + discount amount | `Orders`, `CouponRedemptions` | Coupon edit, expiry, deletion |
| Shipping cost, COD fee, gift-wrap cost, totals | `Orders` | Rate-card changes |
| Customer name, email, phone | `Orders` | Profile edit, account deletion |
| Configured tax rate with validity window | `TaxRateHistories` | Proving which rate was lawful on a given date |
| Subscriber email at send time | `CampaignRecipients` | Address change or unsubscribe after the send |
| Review author name | `Reviews` | Profile rename, anonymisation |

**No report joins a historical row back to a master table for a price or a rate.**

---

## 8. Stored procedure standards

Every procedure:

- begins `SET NOCOUNT ON;`
- uses `CREATE OR ALTER`, so the file is re-runnable
- names explicit columns — **no `SELECT *` anywhere**
- takes typed parameters; no dynamic SQL, so no injection surface
- wraps multi-statement writes in `BEGIN TRANSACTION` with `TRY/CATCH`,
  `SET XACT_ABORT ON`, and `IF XACT_STATE() <> 0 ROLLBACK` before `THROW`
- documents its source spec section in a header comment

Sorting in grid procedures is resolved with whitelisted `CASE` expressions
rather than dynamic SQL, so `@SortColumn` never reaches the engine as text.

Procedures were written only where they add value beyond CRUD — see
`Database-Stored-Procedures.md` for the full list and the justification for each.

---

## 9. Transaction strategy

| Operation | Transaction boundary |
|---|---|
| Order placement | One transaction: order header → lines → tax lines → inventory reservation → coupon redemption → payment record → status history. Any failure rolls back the whole thing. |
| Stock reservation | Single conditional `UPDATE` (see §10). Composable inside the order transaction. |
| Coupon redemption | Single conditional `UPDATE` + history insert. Called inside the order transaction; deliberately opens no nested transaction of its own. |
| Payment webhook | Idempotent by `WebhookEvents` / `ProviderEventId` unique keys — a redelivered webhook cannot double-apply. |
| Refund | Refund row + tax reversal + order totals, one transaction. |
| Rating recalculation | One transaction, aggregate-once-then-write, so the summary and `Products` cannot disagree. |
| Daily rollup rebuild | One transaction per run; fully idempotent `MERGE`. |

---

## 10. Concurrency strategy

Two mechanisms, chosen per contention shape.

**a) `rowversion` optimistic concurrency** on eight aggregates that two operators
can edit simultaneously: `Products`, `ProductVariants`, `InventoryStocks`,
`Orders`, `Coupons`, `Offers`, `Customers`, `Carts`.

Repositories append `AND [RowVersion] = @RowVersion` to their `UPDATE` and treat
zero affected rows as a conflict. `rowversion` is preferred over an `INT Version`
column because SQL Server maintains it automatically — application code cannot
forget to increment it.

**b) Conditional `UPDATE` for counters that must never overshoot.** Optimistic
concurrency detects a conflict only *after* losing the race, which for the last
unit of stock means a retry loop under load. Instead the test and the mutation
are one statement, so the row lock makes them indivisible:

```sql
-- oversell is impossible: the availability test is inside the UPDATE
UPDATE dbo.InventoryStocks
   SET Reserved = Reserved + @Quantity
 WHERE Id = @StockId
   AND (OnHand - Reserved) >= @Quantity;
-- @@ROWCOUNT = 0  =>  insufficient stock, reject

-- coupon over-redemption is impossible for the same reason
UPDATE dbo.Coupons
   SET UsageCount = UsageCount + 1
 WHERE Id = @CouponId
   AND (TotalUsageLimit IS NULL OR UsageCount < TotalUsageLimit);
```

Backed by `CHECK` constraints as a last line of defence:
`CK_InventoryStocks_Reserved` (`Reserved <= OnHand`) and
`CK_Coupons_WithinUsageLimit` (`UsageCount <= TotalUsageLimit`).

---

## 11. Module → script mapping

| File | Tables | Module |
|---|---|---|
| `01_Platform` | 9 | Settings, media library, audit trail, approvals, integrations, jobs |
| `02_Locations` | 5 | Country, state, city, zip, geo zone |
| `03_Masters` | 8 | Currency, tax class, HSN, reason codes, material, craft, size chart |
| `04_Identity` | 10 | Admin users, roles, permissions, pages, sessions, login history |
| `05_Customers` | 10 | Customers, addresses, segments, rewards, wishlists, consent, OTP |
| `06_Catalog` | 16 | Products, variants, media, attributes, brands, artisans, tags |
| `07_Categories` | 4 | Categories, product-category map, collections, menus |
| `08_Inventory` | 12 | Stock, ledger, purchases, adjustments, transfers, stock takes |
| `09_Promotions` | 8 | Coupons, offers and their scoping tables |
| `10_Cart` | 3 | Carts, cart items, checkout sessions |
| `11_Orders` | 9 | Orders, items, addresses, history, notes, returns, invoices |
| `12_Payments` | 7 | Gateways, payments, refunds, settlements, disputes, webhooks |
| `13_Shipping` | 8 | Zones, rates, couriers, shipments, tracking, manifests |
| `14_Content` | 11 | CMS pages, FAQs, contact, blog, banners, testimonials |
| **`15_Reviews`** | **10** | **Reviews, sub-ratings, media, replies, abuse, votes, moderation history, invitations, rating summaries, testimonial media** |
| **`16_Communications`** | **14** | **Notification events, templates, outbox, delivery logs, preferences, devices, subscribers, segments, campaigns, engagement events** |
| **`17_Support`** | **5** | **Inquiry categories, tickets, messages, attachments, status history** |
| **`18_Seo`** | **11** | **SEO metadata, redirects, 404 log, sitemap, robots, audits, broken links, keywords** |
| **`19_Analytics`** | **15** | **Search log + summaries + synonyms, product views, banner events, sessions, page views, daily rollups, report config** |
| **`20_Concurrency_And_Tax`** | **3** | **Line-level GST, refund tax reversal, tax rate history (+ rowversion on 8 tables)** |

Bold rows are new. They were identified by diffing the flow specs against the
existing schema; two of them were already anticipated by dangling foreign-key
columns (`OrderItems.ReviewId`, `ContactSubmissions.SupportTicketId`) that
pointed at tables which did not yet exist.

---

## 12. Security considerations

| Concern | Implementation |
|---|---|
| Passwords | ASP.NET Core Identity v3 format: PBKDF2-HMAC-SHA256, 100,000 iterations, 16-byte per-user random salt, 32-byte subkey. `AdminUsers.PasswordHash` / `Customers.PasswordHash`. **No plaintext, no reversible encryption.** |
| Password reuse | `PasswordHistories` blocks reuse of recent passwords. |
| Lockout | `AdminUsers.FailedLoginCount` / `LockedOutUntil`; thresholds in `Settings` (`security.MaxFailedLoginAttempts`, `security.LockoutMinutes`). |
| OTP | `CustomerOtps` with expiry and attempt count; Authentication.txt §6 — 6 digits, 5 minutes, max 5 attempts. |
| Sessions / refresh tokens | `AdminSessions`, `CustomerSessions` with expiry and revocation. |
| Secrets | `Settings.IsSecret` and `GatewayCredentials` / `Integrations.ConfigJson` are encrypted by the service layer before storage and never returned to a grid. |
| Card data | **Never stored.** `Payments` holds gateway references, an instrument label (e.g. "Visa ••4242") and the raw gateway response — no PAN, no CVV. |
| Audit | `AuditLogs` + `AuditLogDetails` record field-level before/after for every create, update, status change and delete. |
| Approvals | `ApprovalRequests` gates large refunds, high discounts and legal-page publishes. |
| Injection | No dynamic SQL in any procedure; all parameters typed. |
| Least privilege | Key-based RBAC — 225 permission keys, 701 role grants; sensitive reports gated by `ReportDefinitions.PermissionKey`. |

---

## 13. Known approximations and accepted trade-offs

Recorded deliberately rather than left for someone to discover:

1. **COGS uses the current product cost.** `usp_Analytics_RebuildDailySummaries`
   computes cost of goods sold by joining `Products.CostPrice`, because
   `OrderItems` snapshots the *selling* price but not the cost. If supplier costs
   change materially, historical profit figures will shift. Fixing this properly
   means adding `UnitCostPrice` to `OrderItems` and populating it at order time —
   a one-column patch, deliberately not applied without your decision because it
   changes the order-write path.

2. **Two summary tables are caches.** `DailySalesSummaries` and
   `DailyTrafficSummaries` duplicate information derivable from transactional
   tables. They exist because the dashboard auto-refreshes for every signed-in
   administrator and the trend chart spans months. Both are fully rebuildable
   (`usp_Analytics_RebuildDailySummaries`) and neither is a source of truth.
   `ProductRatingSummaries` and `SearchTermSummaries` are the same pattern for
   the PDP histogram and the type-ahead path.

3. **Statuses live in code, not lookup tables.** See §6. The trade is
   deliberate; the mitigation is inline documentation plus `CHECK` constraints.

4. **188 foreign-key columns have no leading index.** Most are audit provenance
   (`CreatedBy`, `ModeratedBy`) or lookups traversed only parent-to-child. Four
   that back documented screens were indexed in
   `04-Patches/2026-08-12_01_ForeignKeyIndexes.sql`; the rest are listed there
   with reasons for leaving them alone. Revisit under real query load.

5. **Guest carts and wishlists key on `GuestToken`.** A shopper who clears
   cookies loses them. Accepted — the alternative is device fingerprinting.

6. **No table partitioning.** At handicraft-business volume the analytics tables
   will not need it for years. When `PageViewLogs` or `SearchQueries` become
   unwieldy, partition by month on the existing date columns — the schema does
   not need to change first.

---

## 14. Migration and deployment strategy

See `Database-Deployment.md` for the full procedure. In short:

- `Apply-Database.ps1` walks `01-Schema` → `02-StoredProcedures` → `05-Views` →
  `03-Seed` → `04-Patches`.
- `dbo.SchemaHistory` records folder, filename, SHA-256 and duration.
  Unchanged files are skipped; changed files are re-run only where safe
  (procedures, views, seed) and refused for `01-Schema`.
- `01-Schema` is **append-only** once applied to a shared environment. Changes go
  into a dated `04-Patches` file.
- Every script is independently idempotent, so the runner and the scripts are
  two separate safety nets.
- Nothing in the pipeline drops or truncates anything.

---

## 15. Related documents

| Document | Contents |
|---|---|
| `Database-Entities.md` | Every table, grouped by module, with purpose |
| `Database-Relationships.md` | Relationship map, cascade rules, ERD |
| `Database-Indexing.md` | Every significant index with its expected query |
| `Database-Stored-Procedures.md` | Procedure catalogue and standards |
| `Database-Deployment.md` | Deployment, verification and rollback |
