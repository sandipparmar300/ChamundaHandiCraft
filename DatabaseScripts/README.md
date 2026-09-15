# DatabaseScripts

All SQL for the Chamunda Handicraft platform. MSSQL. Scripts are numbered so a fresh
database can be built by running the folders in order.

```
DatabaseScripts/
├─ 01-Schema/              Tables, indexes, constraints — one file per module
├─ 02-StoredProcedures/    One folder per module project
├─ 03-Seed/                Reference data and the first Super Admin
├─ 04-Patches/            Dated, forward-only change scripts applied after go-live
└─ 05-Views/               Reporting views consumed by the Reports module
```

---

## Stored procedure naming

Every module's repository calls procedures following this convention, so a new module
needs no new decisions:

| Purpose | Name | Notes |
|---------|------|-------|
| Server-side grid | `GridList_<Entity>` | Takes `@SortColumn, @SortOrder, @PageSize, @PageIndex, @SearchText` plus module filters; returns rows and OUTPUTs `@TotalRecords`, `@TotalFilteredRecords` |
| Single record | `Get<Entity>ById` | `@Id` |
| Uniqueness check | `Is<Entity><Field>Exists` | `@<Field>, @Id`, OUTPUT `@IsExist` |
| Upsert | `Save<Entity>` | `@Id` INPUT/OUTPUT — inserts when 0, updates otherwise |
| Status toggle | `ActiveInactive<Entity>` | `@Id, @IsActive, @UpdatedBy` |
| Soft delete | `SoftDelete<Entity>` | `@Id, @UpdatedBy` — sets `IsDeleted = 1` |
| Dropdown source | `GetActive<Entity>List` | Id + Name pairs only |

Every write procedure takes `@LoggedInUserId` and stamps the audit columns.

---

## 01-Schema file order

Foreign keys mean these must run in dependency order:

```
01_Platform.sql        Settings, AuditLog, Approvals, Media
02_Locations.sql       Country, State, City, ZipCode, GeoZone
03_Masters.sql         Currency, TaxClass, HsnCode, ReasonCode, Material, Craft, SizeChart
04_Identity.sql        AdminUsers, Roles, Permissions, Pages, Sessions, LoginHistory
05_Customers.sql       Customers, Addresses, Segments, RewardPoints, Wishlists, Consent
06_Catalog.sql         Products, Variants, Options, Media, Attributes, Brands, Artisans
07_Categories.sql      Categories, ProductCategories, Menus
08_Inventory.sql       Inventory, Transactions, Purchases, Adjustments, Warehouses
09_Promotions.sql      Coupons, Offers, Combos, FlashSales
10_Cart.sql            Carts, CartItems, CheckoutSessions
11_Orders.sql          Orders, OrderItems, Returns, Exchanges, Invoices, AbandonedCarts
12_Payments.sql        Payments, Refunds, Settlements, Disputes, Gateways
13_Shipping.sql        Zones, Rates, Couriers, Shipments, TrackingEvents, Manifests
14_Content.sql         CmsPages, Faq, ContactSubmissions, Blog, Banners, Testimonials
15_Reviews.sql              Reviews, SubRatings, Media, Replies, AbuseReports, HelpfulVotes,
                            ModerationHistories, ReviewRequests, ProductRatingSummaries,
                            TestimonialMedia
16_Communications.sql       NotificationEvents, Templates, Notifications, DeliveryLogs,
                            Preferences, CustomerDevices, Subscribers, Segments,
                            Campaigns, CampaignRecipients, CampaignEvents
17_Support.sql              InquiryCategories, SupportTickets, TicketMessages,
                            TicketAttachments, TicketStatusHistories
18_Seo.sql                  SeoMetas, Redirects, NotFoundLogs, SitemapEntries, SitemapRuns,
                            RobotsRules, SeoAuditRuns/Findings, BrokenLinks, Keywords
19_Analytics.sql            SearchQueries/TermSummaries/Synonyms, PopularSearches,
                            ProductViewLogs, BannerEvents, VisitorSessions, PageViewLogs,
                            DailySalesSummaries, DailyTrafficSummaries, Report* config
20_Concurrency_And_Tax.sql  OrderItemTaxes, RefundTaxes, TaxRateHistories
                            + rowversion on 8 contended tables
```

Current totals: **179 tables, 7 views, 16 procedures, 483 indexes, 310 foreign keys.**
Full documentation lives in `docs/Database/`.

---

## Deployment

`Apply-Database.ps1` applies everything in dependency order
(`01-Schema` → `02-StoredProcedures` → `05-Views` → `03-Seed` → `04-Patches`),
tracking a SHA-256 per file in `dbo.SchemaHistory`. Safe to re-run; nothing is
ever dropped.

```powershell
.\Apply-Database.ps1                                   # default target
.\Apply-Database.ps1 -ServerInstance "x" -Database "y" # any environment
.\Apply-Database.ps1 -WhatIf                           # dry run
```

See `docs/Database/Database-Deployment.md`.

---

## 03-Seed contents

Applied (`03-Seed/01_Identity_And_Access.sql`, `02_Reference_Data.sql`) —
1,180 rows, verified idempotent across three consecutive runs:

- 9 roles from `docs/ui-ux/05-Roles-And-Permission-Matrix.md`
- 225 permission keys and 701 per-role grants
- One Super Admin account with a forced password change on first login
- 7 currencies, 6 GST tax classes with open rate-history windows
- 46 reason codes (cancel, return, adjustment, damage, review moderation, abuse, refund)
- 44 notification events, 14 inquiry categories, 9 robots rules
- 14 report definitions, 20 handicraft search synonyms
- 42 default platform settings across 10 sections

Still to load (data imports, not reference data):

- Countries / states / cities / pincodes (India first)
- HSN codes, admin sidebar pages, notification templates

---

## Rules

- Never edit a script in `01-Schema` after it has been applied to a shared environment.
  Add a dated file to `04-Patches` instead.
- Every procedure starts with `SET NOCOUNT ON;` and wraps multi-statement writes in a
  transaction with `TRY/CATCH`.
- No procedure returns `SELECT *`. Column lists are explicit so a schema change cannot
  silently break a grid.
