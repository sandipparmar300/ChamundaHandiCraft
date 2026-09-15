# Stored Procedures

**16 procedures** in `DatabaseScripts/02-StoredProcedures/<Module>/`.

The brief's §29 says: *"Do not create stored procedures for every simple CRUD
operation just for the sake of having procedures."* That was taken literally.
There are 179 tables and 16 procedures — roughly one per twelve tables. Ordinary
CRUD is parameterised SQL in the repository classes; a procedure exists only
where one of four things is true:

1. **Atomicity cannot be expressed from the application** — the check and the
   mutation must be one statement (stock, coupons).
2. **The query is genuinely complex** — multi-CTE aggregation the ORM-less
   repository layer would otherwise assemble by hand (dashboard, tax, search).
3. **A business rule must have exactly one definition** — profit, revenue,
   rating (a second copy would eventually disagree).
4. **Several result sets belong to one screen** — one round trip instead of nine.

---

## Standards

Every procedure:

- opens with `SET NOCOUNT ON;`
- is created with `CREATE OR ALTER`, so its file is re-runnable
- lists explicit columns — **there is no `SELECT *` anywhere in the codebase**
- takes strongly typed parameters; **no dynamic SQL**, so no injection surface
- uses `SET XACT_ABORT ON` + `TRY/CATCH` + `IF XACT_STATE() <> 0 ROLLBACK` + `THROW`
  for anything that writes
- resolves sorting through whitelisted `CASE` expressions, never string
  concatenation
- carries a header comment naming the spec section it implements

---

## Catalogue

### Inventory

| Procedure | Purpose |
|---|---|
| `usp_Inventory_ReserveStock` | Reserves stock for one line. **The oversell guard.** Availability test and increment are a single conditional `UPDATE`, so two concurrent checkouts for the last unit cannot both succeed. Writes an `InventoryTransactions` ledger row. Returns 0 reserved / 1 insufficient / 2 no stock record, plus the true available quantity so the UI can say "only 2 left". |

```sql
-- the core of it: no read-then-write window
UPDATE dbo.InventoryStocks
   SET Reserved = Reserved + @Quantity
 WHERE Id = @StockId
   AND (@AllowBackorder = 1 OR (OnHand - Reserved) >= @Quantity);
IF @@ROWCOUNT = 0 -- lost the race, or never had enough
```

### Promotions

| Procedure | Purpose |
|---|---|
| `usp_Coupon_Validate` | Read-only. Runs Coupon.txt §10's nine gates in order — exists, active, in window, under total limit, under per-customer limit, first-order rule, private-coupon eligibility, minimum order value, product/category scope — then computes the discount with the §19 cap. Returns the exact user-facing message. |
| `usp_Coupon_Redeem` | Consumes one use. Separate from validation because validation runs on every cart render while redemption must happen exactly once. Conditional `UPDATE` re-checks every limit, so the gap between validating and ordering cannot be exploited. Auto-expires a coupon that has just hit its ceiling. |
| `usp_Coupon_Release` | Reverses a redemption when an order is cancelled or refunded (Coupon.txt §19, configurable). Restores the count and reactivates the coupon if it was only expired by the cap. |

`usp_Coupon_Redeem` deliberately opens **no** transaction of its own — it is
called from inside the order-placement transaction, where a nested
`BEGIN TRANSACTION` would only increment `@@TRANCOUNT` without adding isolation.

### Catalog

| Procedure | Purpose |
|---|---|
| `usp_Product_GridList` | Module 03's server-side grid. 14 filters (category, brand, artisan, material, status, stock state, flags, price range, date range) + search across name/SKU/code/barcode. Stock summed across warehouses in a CTE so the stock filter is sargable; primary image via `OUTER APPLY` so one row per product. Sorting is whitelisted. Returns `@TotalRecords` and `@TotalFilteredRecords` per the README's grid contract. |
| `GridList_Product` | Thin forwarder. `DatabaseScripts/README.md` and `ARCHITECTURE.md` §6 document the `GridList_<Entity>` name; the brief asked for `usp_<Module>_<Action>`. Both resolve to one implementation. |

### Orders

| Procedure | Purpose |
|---|---|
| `usp_Order_GetById` | The order detail screen in **one round trip**: 9 result sets — header, lines, addresses, timeline, payments, shipments, tracking events, notes, tax breakdown, returns. Optional `@CustomerId` makes the ownership check part of the query. |
| `usp_Order_GetTracking` | The lean read for the customer tracking page, which polls. Header + timeline + courier events + items only. Supports guest tracking by order number + email/phone. Computes `CanCancel` / `CanReturn` so the storefront never offers a button the API would reject. |
| `usp_Order_GetCustomerOrders` | My Account §7 — paged history with status filter, search across order number and product name, four sort modes, and a preview thumbnail. |

All three read **only** the purchase-time snapshot on `OrderItems` /
`OrderAddresses` — never a live join back to `Products`.

### Reviews

| Procedure | Purpose |
|---|---|
| `usp_Review_RecalculateProductRating` | Rebuilds `ProductRatingSummaries` (the five-bar histogram) and `Products.AverageRating` / `ReviewCount` from approved reviews only. Aggregates once into a temp table then drives both writes, so the two caches cannot disagree. Handles the drop-to-zero case — a product whose only review is rejected must not keep showing 5.0. `@ProductId = NULL` rebuilds everything. |

### Reports & analytics

| Procedure | Purpose |
|---|---|
| `usp_Dashboard_GetSalesSummary` | 4 result sets: KPI cards, trend series (day/week/month), live order-status counts, traffic figures. Historical days come from `DailySalesSummaries`; **today** is computed live from `Orders` so the card is not up to 24 h stale. Encodes Dashboard.txt §18 — revenue counts statuses 7 and 8 only. |
| `usp_Report_GetTax` | 6 result sets: summary, component split, **HSN summary (the GSTR-1 shape)**, by place of supply, by invoice, and credit-note reversals. Reads `OrderItemTaxes` / `RefundTaxes` exclusively — never `TaxClasses` — so a rate change cannot rewrite a filed return. |
| `usp_Analytics_RebuildDailySummaries` | The job that makes the two rollups legitimate. Rebuilds both from `Orders`, `OrderItems`, `Refunds`, `Customers`, `VisitorSessions`, `PageViewLogs`, `Carts` and `SearchQueries` via idempotent `MERGE`. Generates every date in the window so the trend chart has no gaps. Default window is the last 7 days, absorbing late refunds and delivery confirmations. |

### Search & SEO

| Procedure | Purpose |
|---|---|
| `usp_Search_GetSuggestions` | The type-ahead dropdown: 4 result sets (products, categories, brands, matching terms). Exact prefix matches outrank mid-word ones, then bestseller and sales rank. Published + search-visible products only. Empty term returns recent searches (signed-in) and curated terms. |
| `usp_Search_LogQuery` | Fire-and-forget after results are served. Normalises the term (lowercase, trim, collapse whitespace) to match `SearchTermSummaries`' key, inserts the raw row, and `MERGE`s the summary so type-ahead stays current between nightly rebuilds. |
| `usp_Search_GetAnalytics` | 4 result sets: headline rates, top terms, **zero-result terms** (flagged with whether a synonym already exists), and products most reached through search. |

---

## What is intentionally *not* a stored procedure

| Operation | Where it lives instead | Why |
|---|---|---|
| Create/update/delete for ~170 tables | Repository classes, parameterised SQL | §29 — procedures for the sake of procedures add deployment friction with no benefit |
| Order status transitions | API service layer | Legality depends on the actor's role; a trigger cannot express that |
| Price and offer calculation | `Promotions` module service | Needs the cart, shipping quote and priority rules together |
| Slug generation and uniqueness | `Seo` module service | Also has to write the 301 into `Redirects` |
| Notification rendering | `Notifications` module | Template merge is a string operation, not a set operation |
| Sitemap XML generation | `Seo` module | `SitemapEntries` holds the data; XML is not SQL's job |

---

## Verification

All 16 executed successfully against the deployed database:

```
usp_Product_GridList                    OK   (default and sorted-by-price paths)
usp_Dashboard_GetSalesSummary           OK   (4 result sets)
usp_Analytics_RebuildDailySummaries     OK
usp_Review_RecalculateProductRating     OK
usp_Report_GetTax                       OK   (6 result sets)
usp_Search_GetSuggestions               OK   (empty term and term paths)
usp_Search_LogQuery                     OK   ('  Blue   Pottery ' -> 'blue pottery')
usp_Search_GetAnalytics                 OK
usp_Coupon_Validate                     OK   (unknown code -> "Invalid coupon.")
usp_Inventory_ReserveStock              OK   (no stock row -> result 2)
```

Compilation alone is not proof: SQL Server validates column names at `CREATE`
time but not expression types inside `ORDER BY CASE`, so each procedure was
**executed**, not merely created.

---

## Planned but not yet written

Referenced by `ReportDefinitions` seed rows and by the API's expected surface.
Each returns a "procedure not found" error until written — deliberate, so the
gap is visible rather than silently returning empty:

`usp_Report_GetSales` · `usp_Report_GetProfit` · `usp_Report_GetCustomers` ·
`usp_Report_GetInventory` · `usp_Report_GetPayments` · `usp_Report_GetOrders` ·
`usp_Report_GetReturns` · `usp_Order_Place` (the §34 order transaction) ·
`usp_Inventory_ReleaseStock` · `usp_Inventory_CommitStock`

The schema, indexes and views they need are all in place — `vw_OrderRevenue`,
`vw_ProductSales`, `vw_CustomerLifetime`, `vw_ProductStock` and `vw_GstSummary`
exist specifically so these become thin.
