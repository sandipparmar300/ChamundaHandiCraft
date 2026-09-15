# Database Entities

All **179 tables**, grouped by the schema file that creates them.
Every table has a reason; where the reason is not obvious from the name, it is stated.

Legend: **SD** = carries `IsDeleted` soft delete · **AO** = append-only (no soft delete, by design) · **RV** = has `rowversion` concurrency

---

## 01_Platform — 9 tables

| Table | PK | Purpose |
|---|---|---|
| `SchemaHistory` | INT | Deployment ledger: folder, filename, SHA-256, duration. Makes the runner re-runnable. |
| `Settings` | INT | **SD** Every figure the storefront quotes. Section + key, typed value, `IsSecret` for encrypted values. |
| `SettingHistories` | INT | **AO** Before/after for each settings change (Settings.txt §22). |
| `MediaFolders` | INT | **SD** Media library tree. |
| `MediaAssets` | INT | **SD** Every image/video. `AltText` is policy-mandatory for published products. |
| `AuditLogs` | BIGINT | **AO** One header row per create/update/status-change/delete, any entity. |
| `AuditLogDetails` | BIGINT | **AO** One row per changed field: old value, new value. |
| `ApprovalRequests` | INT | **SD** Guarded actions parked for approval; `PayloadJson` replays the change. |
| `Integrations` | INT | **SD** Third-party connections; credentials encrypted in `ConfigJson`. |
| `JobRuns` | BIGINT | **AO** Background job execution log. |

## 02_Locations — 5 tables

`Countries`, `States`, `Cities`, `ZipCodes`, `GeoZones` — all **SD**.
Address forms, pincode serviceability and shipping-zone membership.

## 03_Masters — 8 tables

| Table | Purpose |
|---|---|
| `MasterData` | Generic key/value lookup for small enumerations. |
| `Currencies` | Settings.txt §6. INR base + 6 others with exchange-rate placeholders. |
| `TaxClasses` | GST slabs. `RatePercent` is the total, split at order time. |
| `HsnCodes` | HSN classification — required on the GST invoice and GSTR-1. |
| `ReasonCodes` | One table, many `ReasonType` values (cancel, return, adjustment, damage, review moderation, review abuse, refund). Carries `RequiresPhoto`, `RequiresNote`, `IsOurFault`. |
| `Materials`, `Crafts` | Handicraft classification and PLP facets. |
| `SizeCharts` | Per-product size guide. |

## 04_Identity — 10 tables

| Table | Purpose |
|---|---|
| `Roles` | The nine roles from Users.txt §6. `IsSystem` protects Super Admin. |
| `Permissions` | 225 keys. `PermissionKey` is **computed**: `lower(Module + '.' + Entity + '.' + Action)`. |
| `RolePermissions` | M:N grants — 701 rows seeded. |
| `AdminPages` | Sidebar tree: name, key, controller, action, icon, order. |
| `RolePages` | Which role sees which page. |
| `AdminUsers` | **SD** PBKDF2 hash, lockout counters, 2FA fields. |
| `AdminUserRoles` | M:N; `IsPrimary` marks the main role. |
| `AdminSessions` | BIGINT. Active sessions, revocable. |
| `LoginHistories` | **AO** BIGINT. Every attempt, success or failure, with device and IP (Users.txt §8). |
| `PasswordHistories` | **AO** BIGINT. Blocks reuse. |

## 05_Customers — 10 tables

| Table | Purpose |
|---|---|
| `Customers` | **SD RV** Account, verification flags, denormalised lifetime figures, `GuestToken`. |
| `CustomerAddresses` | **SD** Multiple addresses with type and default flag. |
| `CustomerSegments` / `CustomerSegmentMembers` | Targeting groups for coupons and campaigns. |
| `RewardPointLedgers` | **AO** BIGINT. Earn/redeem/expire movements; balance is the running total. |
| `Wishlists` / `WishlistItems` | Wishlist.txt. Items are a plain link table — removal is a real delete. |
| `CustomerConsents` | **AO** GDPR-style consent grants and withdrawals with source and timestamp. |
| `CustomerSessions` | BIGINT. Storefront sessions. |
| `CustomerOtps` | BIGINT. OTP with expiry and attempt count. |

## 06_Catalog — 16 tables

| Table | Purpose |
|---|---|
| `Products` | **SD RV** The catalogue core. Status/visibility gate publishing; denormalised `AverageRating`, `ReviewCount`, `SoldCount`, `ViewCount`. |
| `ProductVariants` | **SD RV** Per-variant SKU, price, weight, image. |
| `ProductVariantOptions` | The option values that define a variant (Size=M, Colour=Brown). |
| `ProductMedia` | Images, video and 360° frames; `IsPrimary` picks the thumbnail. |
| `ProductAttributes` / `ProductAttributeValues` / `ProductAttributeMappings` | Configurable attribute system driving PLP facets. |
| `ProductSpecifications` | The PDP spec table. |
| `ProductFaqs` | Per-product Q&A. |
| `Tags` / `ProductTags` | Free tagging (Handmade, Eco-Friendly, Gift). |
| `ProductBadges` | Merchandising badges. |
| `ProductRelations` | Related / similar / frequently-bought-together / cross-sell / up-sell. |
| `Brands`, `Artisans` | **SD** Brand and maker. `Artisans` carries the craft story the PDP renders. |
| `Collections` | Curated groupings (Festival, New Collection). |

## 07_Categories — 4 tables

`Categories` (**SD**, self-referencing with `Depth` + `TreePath`), `ProductCategories`,
`CollectionProducts`, `Menus`.

## 08_Inventory — 12 tables

| Table | Purpose |
|---|---|
| `Warehouses` | **SD** Locations with address and contact. |
| `Suppliers` | **SD** Purchase sources. |
| `InventoryStocks` | **SD RV** BIGINT. `OnHand`, `Reserved`, `Incoming` per (product, variant, warehouse). `CK_InventoryStocks_Reserved` forbids over-reservation. |
| `InventoryTransactions` | **AO** BIGINT. The immutable ledger — every movement, with `QuantityChange` and `QuantityAfter`. |
| `PurchaseOrders` / `PurchaseOrderLines` | Supplier purchases with an approval step that increases stock. |
| `StockAdjustments` | Corrections with a mandatory reason. |
| `StockTakes` / `StockTakeLines` | Physical counts; `Variance` is **computed**. |
| `StockTransfers` / `StockTransferLines` | Inter-warehouse movement. |
| `StockNotifyRequests` | BIGINT. Back-in-stock waitlist. |

## 09_Promotions — 8 tables

`Coupons` (**SD RV**), `CouponProducts`, `CouponCategories`, `CouponSegments`,
`CouponRedemptions` (**AO**), `Offers` (**SD RV**), `OfferProducts`, `OfferCategories`.

Scoping tables are empty when a promotion applies catalogue-wide — that absence
*is* the "all products" rule, which is why there is no `AppliesToAll` flag.

## 10_Cart — 3 tables

`Carts` (**SD RV**, with `AbandonedAt` driving recovery), `CartItems`, `CheckoutSessions`.

## 11_Orders — 9 tables

| Table | Purpose |
|---|---|
| `Orders` | **SD RV** Full money breakdown, denormalised fulfilment summary, 16 statuses. |
| `OrderItems` | BIGINT. **Purchase-time snapshot** of name, SKU, slug, image, artisan, HSN, price, MRP, discount, tax. Per-line shipped/returned/cancelled counters. |
| `OrderAddresses` | BIGINT. Billing and shipping snapshots incl. `GstStateCode`. |
| `OrderStatusHistories` | **AO** BIGINT. Every transition — the timeline. |
| `OrderNotes` | BIGINT. Internal and customer-visible notes. |
| `ReturnRequests` / `ReturnLines` / `ReturnMedia` | RMA workflow with inspection and restock outcome. |
| `Invoices` | **SD** GST invoice with CGST/SGST/IGST/Cess header totals; credit notes self-reference. |

## 12_Payments — 7 tables

`PaymentGateways`, `GatewayCredentials` (encrypted), `Payments` (gateway refs +
raw response, **never** card data), `Refunds`, `Settlements`, `Disputes`,
`WebhookEvents` (**AO**, unique provider event id makes webhooks idempotent).

## 13_Shipping — 8 tables

`ShippingZones`, `ShippingZonePincodes`, `ShippingRates`, `Couriers`,
`Shipments`, `ShipmentItems`, `ShipmentTrackingEvents` (**AO**), `Manifests`.

## 14_Content — 11 tables

`CmsPages`, `Faqs`, `ContactSubmissions`, `BlogCategories`, `BlogAuthors`,
`BlogPosts`, `BlogPostTags`, `BlogPostProducts`, `BlogComments`, `Banners`,
`Testimonials` — all **SD**.

---

## 15_Reviews — 10 tables *(new)*

| Table | Purpose |
|---|---|
| `Reviews` | **SD** One opinion per customer per product (`UX_Reviews_CustomerProduct`). `IsVerifiedPurchase` requires an `OrderItemId`. Rejections require a reason. |
| `ReviewSubRatings` | Aspect ratings (Quality, Finish, ValueForMoney) as rows, so a new aspect needs no migration. |
| `ReviewMedia` | Customer photos and video. |
| `ReviewReplies` | Admin/seller replies; `ParentReplyId` allows future nesting. |
| `ReviewAbuseReports` | **SD** One per reporter — unique index stops one account inflating the count. |
| `ReviewHelpfulVotes` | One vote per customer *or* guest token. |
| `ReviewModerationHistories` | **AO** Every approve/reject/hide/restore. |
| `ReviewRequests` | Post-delivery invitations with a single-use token. |
| `ProductRatingSummaries` | **Cache.** The five-bar histogram, keyed on `ProductId`. Rebuilt by `usp_Review_RecalculateProductRating`. |
| `TestimonialMedia` | Video and gallery testimonials — `Testimonials` only had one photo column. |

## 16_Communications — 14 tables *(new)*

| Table | Purpose |
|---|---|
| `NotificationEvents` | 44 seeded triggers. `IsTransactional` decides whether promotional opt-out applies. |
| `NotificationTemplates` | Per channel and language; `{{Placeholders}}` documented in `VariablesJson`. |
| `NotificationEventTemplates` | Which template renders which event on which channel. |
| `Notifications` | BIGINT. **The outbox.** One row per recipient per channel. Rendered subject/body stored so a retry sends the same message. |
| `NotificationDeliveryLogs` | **AO** One row per send attempt with the raw provider response. |
| `NotificationPreferences` | Per (customer, channel, category). |
| `CustomerDevices` | **SD** Push tokens with validity. |
| `Subscribers` | **SD** Newsletter audience — *not* the same entity as a customer. Double opt-in tokens, unsubscribe token, bounce tracking. |
| `SubscriberTags` | Free tagging. |
| `NewsletterSegments` / `NewsletterSegmentMembers` | Static lists and rule-driven groups. |
| `Campaigns` | **SD** With denormalised open/click/bounce counters for the list view. |
| `CampaignRecipients` | Address snapshot; unique per campaign, so a retry cannot double-send. |
| `CampaignEvents` | **AO** Delivered/Open/Click/Bounce/Complaint/Unsubscribe in **one** table with an `EventType` discriminator, rather than the four near-identical tables the spec suggested. `ProviderEventId` is unique — redelivered webhooks cannot double-count. |

## 17_Support — 5 tables *(new)*

| Table | Purpose |
|---|---|
| `InquiryCategories` | **SD** The Contact.txt §5 subject list, each with its own SLA and routing. |
| `SupportTickets` | **SD** Quotable `TicketNumber`, SLA due timestamps stamped at creation, satisfaction rating. Closes the dangling `ContactSubmissions.SupportTicketId`. |
| `SupportTicketMessages` | **SD** BIGINT. Both directions plus internal notes — `IsInternalNote` is the only visibility switch, so the thread cannot fall out of order. |
| `SupportTicketAttachments` | **SD** BIGINT. Inbound and outbound files. |
| `SupportTicketStatusHistories` | **AO** BIGINT. Dwell time per state. |

## 18_Seo — 11 tables *(new)*

| Table | Purpose |
|---|---|
| `SeoMetas` | **SD** **Keyed on `RoutePath`**, not on an entity. One lookup answers "what are the meta tags for this URL?", including for routes that are not entities. |
| `Redirects` | **SD** 301/302 with hit counting, so stale rules can be retired. Named `dbo.Redirects` because `06_Catalog.sql` already referenced it by that name. |
| `NotFoundLogs` | Aggregated by path, not one row per hit — the value is "this path 404s 400×/week". |
| `SitemapEntries` / `SitemapRuns` | Materialised sitemap; sharded by `SitemapFile` for the 50,000-URL cap. |
| `RobotsRules` | **SD** robots.txt as data, so environments share it and it can be validated. |
| `SeoAuditRuns` / `SeoAuditFindings` | The §14 validation sweep, retained as a trend. |
| `SeoBrokenLinks` | Unique per (source, target). |
| `SeoKeywords` / `SeoKeywordRankings` | Search Console / Bing shape: clicks, impressions, CTR, position per day. |

## 19_Analytics — 15 tables *(new)*

| Table | Purpose |
|---|---|
| `SearchQueries` | **AO** BIGINT. Every search with result count, click and conversion. |
| `SearchTermSummaries` | **Cache.** Type-ahead fires per keystroke; a `GROUP BY` over the raw log cannot serve it. |
| `PopularSearches` | **SD** Editorially curated — kept apart so a nightly rebuild cannot erase a merchandiser's choice. |
| `SearchSynonyms` | **SD** 20 seeded handicraft synonyms (diya↔oil lamp, dhokra↔bell metal). |
| `ProductViewLogs` | **AO** BIGINT. Recently-viewed and most-viewed. |
| `BannerEvents` | **AO** BIGINT. Impression/Click/Dismiss in one table — CTR is a single scan. |
| `VisitorSessions` | **AO** BIGINT. Materialised so bounce and conversion are indexed counts, not self-joins. |
| `PageViewLogs` | **AO** BIGINT. Top pages, blog and CMS view counters. |
| `DailySalesSummaries` | **Cache**, PK `SummaryDate`. Justified in Database-Architecture.md §13. |
| `DailyTrafficSummaries` | **Cache**, PK `SummaryDate`. |
| `ReportDefinitions` | **SD** 14 seeded reports with `PermissionKey` and `SupportsAsync`. |
| `SavedReports` | **SD** Named filter sets, private or shared. |
| `ScheduledReports` / `ScheduledReportRecipients` | **SD** Daily→yearly, emailed. |
| `ReportRuns` | **AO** BIGINT. Async execution with file URL and expiry. |

## 20_Concurrency_And_Tax — 3 tables *(new)*

| Table | Purpose |
|---|---|
| `OrderItemTaxes` | **AO** BIGINT. One row per tax component per line, with rate, taxable value, HSN and place of supply **frozen at order time**. `CK_OrderItemTaxes_ComponentMatchesSupply` enforces GST law: inter-state ⇒ IGST, intra-state ⇒ CGST+SGST. |
| `RefundTaxes` | **AO** BIGINT. Mirrors the above on the way out, so credit notes reconcile. |
| `TaxRateHistories` | **AO** BIGINT. What the rate *was configured as* on a date, with a half-open validity window. `UX_TaxRateHistories_Current` allows one open row per class. |

Also adds `rowversion` to `Products`, `ProductVariants`, `InventoryStocks`,
`Orders`, `Coupons`, `Offers`, `Customers`, `Carts`, and
`CK_Coupons_WithinUsageLimit`.

---

## Entities considered and deliberately NOT created

Recorded so the absence reads as a decision, not an omission.

| Suggested by spec | Why not |
|---|---|
| `AbandonedCarts` | `Carts.AbandonedAt` + `LastActivityAt` already drive the recovery job. |
| `EmailOpenLogs`, `EmailClickLogs`, `EmailBounceLogs`, `EmailUnsubscribeLogs` | Column-identical. Collapsed into `CampaignEvents` with an `EventType` discriminator. |
| `BannerImpressions`, `BannerClicks` | Same reasoning → `BannerEvents`. |
| `RecentlyViewedProducts` | `TOP n` over `ProductViewLogs`, covered by `IX_ProductViewLogs_Customer`. |
| `MostWishlistedProducts` | `GROUP BY` over `WishlistItems`. |
| `BestSellerProducts`, `TrendingProducts`, `NewArrivalProducts`, `FeaturedProducts` | Flags already on `Products` (`IsFeatured`, `IsBestseller`, `IsTrending`) plus `SoldCount`/`PublishedAt`. Separate tables would need syncing. |
| `KpiSnapshots`, `BusinessMetrics` | Derivable from `DailySalesSummaries`. |
| `OrderTracking` | `OrderStatusHistories` + `ShipmentTrackingEvents` already cover it. |
| `CustomerProfiles` (separate from `Customers`) | A 1:1 split with no access-pattern difference is just an extra join. |
| `ProductPricing` (separate from `Products`) | Same — no tier or currency pricing in scope yet. |
| `NotificationChannels`, `NotificationTypes`, `NotificationQueue`, `NotificationRetryLogs` | Channel is an enum column; queue and retry state are columns on `Notifications`; attempts are `NotificationDeliveryLogs`. |
| `SystemSettings*`, `CompanySettings`, `GstSettings`, `EmailSettings`, … (18 tables) | One `Settings` table with `Section` + `SettingKey` covers all of them. 18 single-row tables would be a schema change per new setting. |
| `OfferAnalytics`, `CouponNotifications`, `ReviewAnalytics`, `TestimonialViews`, … | Aggregations over existing transactional tables. |
| `ShippingLabels` | `Shipments.LabelUrl`. |
| `DeliveryAttempts` | `Shipments.AttemptCount` + `ShipmentTrackingEvents`. |
