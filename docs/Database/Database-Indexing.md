# Database Indexing Strategy

**483 indexes:** 179 clustered (one per table) · 304 non-clustered · 152 filtered · 303 unique.

Every index below exists because a documented screen or report issues the query
next to it. The brief's §28 rule — *"Do not create excessive indexes"* — was
applied by refusing to index anything that only *might* be useful.

---

## 1. Principles

1. **Clustered = the surrogate PK.** `Id IDENTITY` is monotonically increasing,
   so inserts always append. No page splits, no fragmentation from insert order.
   The two daily rollups cluster on `SummaryDate`, which is also append-ordered.
2. **Filtered indexes for soft delete.** 152 of 304 non-clustered indexes carry
   `WHERE IsDeleted = 0` (and often a status predicate). Deleted and draft rows
   are the majority of what a mature catalogue accumulates and none of what a
   query wants, so keeping them out of the index keeps it small and the
   statistics honest.
3. **`INCLUDE` to cover, not to widen keys.** Grid queries select 10–20 columns;
   the filter columns go in the key, the display columns in `INCLUDE`.
4. **Write cost is real.** `Orders`, `OrderItems` and `InventoryStocks` sit on
   the checkout path. Indexes on them were added only where a *customer-facing*
   or *operationally critical* read needs them.
5. **Unique indexes enforce business rules**, not just performance — 303 of them.

---

## 2. Uniqueness — business rules enforced by indexes

| Table | Index | Rule | Spec |
|---|---|---|---|
| `Products` | `UX_Products_Sku` | SKU is unique | Product.txt §17 |
| `Products` | `UX_Products_ProductCode` | Product code is unique | Product.txt §17 |
| `Products` | `UX_Products_Slug` | SEO URL is unique | SEO.txt §21 |
| `Categories` | `UX_Categories_Slug` | Category URL is unique | Category.txt §20 |
| `Customers` | `UX_Customers_Email` / `_Phone` | Unique, nullable-aware | Authentication.txt §17 |
| `Orders` | `UQ_Orders_Number` | Order numbers unique | Orders.txt §23 |
| `Invoices` | `UQ_Invoices_Number` | Invoice numbers unique and sequential | Orders.txt §23 |
| `Coupons` | `UX_Coupons_Code` | Coupon codes unique | Coupon.txt §19 |
| `Reviews` | `UX_Reviews_CustomerProduct` | **One review per customer per product** | Review.txt §18 |
| `ReviewHelpfulVotes` | `UX_..._Customer` / `_Guest` | One vote per identity | Product Detail.txt §8 |
| `ReviewAbuseReports` | `UX_..._OnePerCustomer` | One report per reporter | Review.txt §9 |
| `ReviewRequests` | `UX_ReviewRequests_OrderItem` | One invitation per line — the job cannot re-send | Review.txt §2 |
| `InventoryStocks` | `UX_..._WithVariant` / `_NoVariant` | One stock row per (product, variant, warehouse) | Inventory.txt §4 |
| `Subscribers` | `UX_Subscribers_Email` | Email unique | NewsLetter.txt §20 |
| `CampaignRecipients` | `UQ_..._Unique` | One send per subscriber per campaign | NewsLetter.txt §20 |
| `CampaignEvents` | `UX_..._ProviderEvent` | **Webhook idempotency** — a redelivered open cannot double-count | NewsLetter.txt §11 |
| `SeoMetas` | `UX_SeoMetas_RoutePath` | One metadata row per URL | SEO.txt §21 |
| `Redirects` | `UX_Redirects_FromPath` | One active rule per source path | SEO.txt §9 |
| `SupportTickets` | `UQ_SupportTickets_Number` | Quotable reference number | Contact.txt §21 |
| `OrderItemTaxes` | `UQ_..._Component` | One row per component per line — recalculation replaces, never duplicates | — |
| `TaxRateHistories` | `UX_..._Current` | Only one open-ended rate per tax class | — |
| `Settings` | `UQ_Settings_SectionKey` | One value per section+key | Settings.txt |

---

## 3. Storefront read paths

| Table | Index | Columns | Expected query |
|---|---|---|---|
| `Products` | `IX_Products_Listing` | `Status, Visibility` INCLUDE slug, name, price, MRP, rating, review count, publish date | PLP: published, visible products with the card fields covered |
| `Products` | `UX_Products_Slug` | `Slug` filtered `IsDeleted=0` | PDP by URL — one seek |
| `Reviews` | `IX_Reviews_ProductApproved` | `ProductId, SubmittedOn DESC` INCLUDE rating, title, author, verified, helpful — filtered `Status=1` | PDP review list, newest first, covered |
| `ProductRatingSummaries` | `PK` on `ProductId` | — | PDP histogram — single row |
| `ProductViewLogs` | `IX_..._Customer` / `_Guest` | `CustomerId/GuestToken, ViewedAt DESC` INCLUDE `ProductId` | "Recently viewed" — `TOP 10`, covered |
| `SearchTermSummaries` | `IX_..._Popular` / `_Trending` | `SearchCount DESC` / `RecentSearchCount DESC` INCLUDE `DisplayTerm` | Type-ahead, fires per keystroke |
| `SeoMetas` | `UX_SeoMetas_RoutePath` | `RoutePath` | Meta tags for the current route |
| `SeoMetas` | `IX_SeoMetas_Sitemap` | `EntityType, RoutePath` INCLUDE freq, priority, updated — filtered indexable | Sitemap generation |
| `Redirects` | `IX_Redirects_Active` | `FromPath` filtered active | 404 handler lookup |
| `Categories` | `UX_Categories_Slug` | `Slug` | Category landing page |
| `Carts` | `IX_Carts_Abandoned` | `LastActivityAt` filtered | Abandoned-cart recovery job |

## 4. Admin grid paths

| Table | Index | Expected query |
|---|---|---|
| `Orders` | `IX_Orders_Status` | Order queue filtered by status, newest first |
| `Orders` | `IX_Orders_Customer` | Customer's order history |
| `OrderItems` | `IX_OrderItems_Order` | Order detail — all lines |
| `OrderItems` | `IX_OrderItems_Product` | "Which orders contained this product?" |
| `Reviews` | `IX_Reviews_Moderation` | Moderation queue: `Status, SubmittedOn DESC` |
| `Reviews` | `IX_Reviews_Reported` | Abuse queue, filtered `AbuseReportCount > 0` |
| `SupportTickets` | `IX_SupportTickets_Queue` | Open queue by status + priority + age, covered |
| `SupportTickets` | `IX_SupportTickets_SlaBreach` | Unanswered past due — filtered, tiny |
| `SupportTickets` | `IX_SupportTickets_Assignee` | An agent's own tickets |
| `Notifications` | `IX_Notifications_Dispatch` | **The dispatcher's hot path** — `Priority, ScheduledFor, Id` filtered to pending/queued/retrying |
| `Notifications` | `IX_Notifications_Retry` | Retry sweeper, filtered `Status=7` |
| `Notifications` | `IX_Notifications_Customer` | Customer notification centre, covered |
| `Notifications` | `IX_Notifications_ProviderMessage` | Webhook callback by provider id |
| `CampaignRecipients` | `IX_..._Pending` | Send loop — filtered `Status=0` |
| `AuditLogs` | `IX_AuditLogs_Entity` | "What happened to this record?" |
| `InventoryStocks` | `IX_InventoryStocks_Product` | Stock summed per product, covered |
| `ApprovalRequests` | `IX_..._Status` | Pending approvals |

## 5. Reporting paths

| Table | Index | Expected query |
|---|---|---|
| `OrderItemTaxes` | `IX_..._Hsn` | **GSTR-1**: `GROUP BY HsnCode, TaxComponent` over a period, covered |
| `OrderItemTaxes` | `IX_..._PlaceOfSupply` | Reports.txt §9 "Tax by State", covered |
| `OrderItemTaxes` | `IX_..._Order` | Invoice tax breakdown |
| `DailySalesSummaries` | clustered `SummaryDate` | Dashboard trend — range scan over ≤365 rows |
| `DailyTrafficSummaries` | clustered `SummaryDate` | Same, traffic side |
| `SearchQueries` | `IX_..._ZeroResult` | Zero-result report — filtered, so it holds only the rows that matter |
| `SearchQueries` | `IX_..._TermDate` | Nightly rollup |
| `VisitorSessions` | `IX_..._Started` | Bounce/conversion counts, covered |
| `BannerEvents` | `IX_..._BannerDate` | CTR per banner over a range |
| `ReportRuns` | `IX_ReportRuns_Queue` | Async report worker |
| `ScheduledReports` | `IX_..._NextRun` | Scheduler due-check, filtered active |

---

## 6. Indexes added post-deployment

`04-Patches/2026-08-12_01_ForeignKeyIndexes.sql` — four FK columns that back
documented screens on unbounded tables:

| Index | Query it serves |
|---|---|
| `IX_Payments_Customer` | Customer payment history (Users.txt, Payments.txt §11) |
| `IX_Notifications_Event` | Delivery/failure rate per event (Notification.txt §15) |
| `IX_CampaignEvents_Subscriber` | Per-subscriber engagement + suppression check |
| `IX_InventoryTransactions_Warehouse` | Warehouse ledger (Inventory.txt §13, §19) |

---

## 7. Foreign keys deliberately left unindexed

A post-deployment audit found **188 FK columns with no leading index**. That
number sounds alarming and mostly is not:

| Category | Example | Why no index |
|---|---|---|
| Audit provenance | `*.CreatedBy`, `*.UpdatedBy`, `Reviews.ModeratedBy` | Displayed, never filtered on |
| Reason lookups | `Orders.CancelReasonId`, `Reviews.ModerationReasonId` | Tiny parent table; the plan scans it regardless |
| 1:1 back-references | `Orders.InvoiceId` | Always reached from the other side |
| Diagnostic joins | `Orders.CartId`, `Orders.CheckoutSessionId` | Run by hand, not by a screen |
| Aggregate-only | `OrderItems.ArtisanId` | Artisan reports scan a date range anyway |
| Covered by a wider index | `OrderItems.VariantId` | `IX_OrderItems_Order` already narrows to one order first |

Each index costs write throughput on the hottest tables in the system. They
should be added when a real execution plan demands it, not pre-emptively.

**How to find the ones that start to matter:**

```sql
SELECT TOP 25
       DB_NAME(d.database_id)                    AS [Database],
       OBJECT_NAME(d.object_id)                  AS [Table],
       d.equality_columns, d.inequality_columns, d.included_columns,
       s.user_seeks, s.user_scans, s.avg_user_impact
FROM   sys.dm_db_missing_index_details d
JOIN   sys.dm_db_missing_index_groups  g ON g.index_handle = d.index_handle
JOIN   sys.dm_db_missing_index_group_stats s ON s.group_handle = g.index_group_handle
WHERE  d.database_id = DB_ID()
ORDER  BY s.avg_user_impact * (s.user_seeks + s.user_scans) DESC;
```

And the converse — indexes that cost writes and earn nothing:

```sql
SELECT OBJECT_NAME(i.object_id) AS [Table], i.name,
       s.user_seeks, s.user_scans, s.user_lookups, s.user_updates
FROM   sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s
       ON s.object_id = i.object_id AND s.index_id = i.index_id AND s.database_id = DB_ID()
WHERE  i.type_desc = 'NONCLUSTERED'
  AND  OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
  AND  ISNULL(s.user_seeks,0) + ISNULL(s.user_scans,0) + ISNULL(s.user_lookups,0) = 0
ORDER  BY ISNULL(s.user_updates,0) DESC;
```

Both return nothing meaningful on an empty database — run them after a few
weeks of production traffic.

---

## 8. Full-text search

Not configured. Search.txt §18 offers SQL Server Full-Text or Elasticsearch;
`usp_Search_GetSuggestions` currently uses `LIKE` with a prefix-first ranking,
which is correct and fast for a catalogue of this size because
`IX_Products_Listing` narrows to published products before the scan.

When the catalogue outgrows it:

```sql
CREATE FULLTEXT CATALOG ChamundaCatalog AS DEFAULT;
CREATE FULLTEXT INDEX ON dbo.Products (Name, ShortDescription, FullDescription)
    KEY INDEX PK_Products ON ChamundaCatalog WITH CHANGE_TRACKING AUTO;
```

`usp_Search_GetSuggestions` is the only procedure that would need rewriting —
which is why search goes through it rather than through inline SQL.

---

## 9. Maintenance

| Task | Frequency | Why |
|---|---|---|
| Rebuild/reorganise fragmented indexes (>30% rebuild, 5–30% reorganise) | Weekly | Filtered indexes on churny tables fragment fastest |
| Update statistics | Daily on `Orders`, `OrderItems`, `InventoryStocks` | Skew after bulk imports misleads the optimiser |
| Purge analytics tables beyond retention | Monthly | `PageViewLogs`, `SearchQueries`, `ProductViewLogs`, `BannerEvents` grow without bound |
| Review missing/unused index DMVs | Quarterly | Section 7 |

No partitioning yet — see Database-Architecture.md §13.6.
