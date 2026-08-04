# ChamundaHandicraft.API

The single backend. It owns the database connection, JWT issuance, permission
enforcement, background jobs and every business operation. Neither the Admin panel nor
the Customer site has database access — both reach the data only through this project,
via the gateway.

---

## Folder layout

```
ChamundaHandicraft.API/
├─ Controllers/
│  ├─ Admin/         Authenticated back-office endpoints  -> /api/admin/*
│  ├─ Customer/      Customer endpoints (JWT or guest token) -> /api/customer/*
│  ├─ Public/        Anonymous endpoints -> /api/public/*
│  └─ Webhooks/      Inbound gateway/courier/email callbacks -> /api/webhooks/*
├─ Attributes/       HasApiPermissionAttribute + HasApiPermissionFilter
├─ BackgroundServices/  Hosted services (see below)
├─ Middleware/       ExceptionMiddleware, RequestLoggingMiddleware
├─ Services/         PermissionMemoryCache, TokenService, StorageService
├─ Hubs/             SignalR hubs for live dashboard / order / inventory updates
├─ Properties/
├─ wwwroot/
│  ├─ templates/email/     Transactional email HTML templates
│  ├─ templates/invoice/   Invoice / packing slip templates
│  └─ uploads/             Local storage fallback when Storage:Provider = Local
├─ Program.cs
└─ ServiceExtension.cs    AddServiceModule() — wires every module
```

---

## Controllers/Admin

One controller per admin surface. Each inherits `BaseController` (which exposes the
JWT `claim` object and the request language) and carries
`[HasApiPermission("<key>")]` per action.

| Controller | Module project |
|------------|----------------|
| `AuthController` | Identity |
| `AdminUserController`, `RoleController`, `PermissionController` | Identity |
| `CustomerController`, `SegmentController` | Customers |
| `ProductController`, `BrandController`, `ArtisanController`, `AttributeController` | Catalog |
| `CategoryController`, `MenuController` | Categories |
| `InventoryController`, `PurchaseController`, `StockAdjustmentController`, `WarehouseController`, `SupplierController` | Inventory |
| `OrderController`, `ReturnController`, `InvoiceController` | Orders |
| `PaymentController`, `RefundController`, `SettlementController`, `DisputeController` | Payments |
| `ShippingController`, `CourierController`, `ShipmentController` | Shipping |
| `CouponController`, `OfferController` | Promotions |
| `BannerController` | Banners |
| `CmsPageController`, `FaqController`, `ContactSubmissionController` | Cms |
| `BlogController`, `BlogCommentController` | Blog |
| `ReviewController` | Reviews |
| `TestimonialController` | Testimonials |
| `SubscriberController`, `CampaignController`, `FlowController` | Newsletter |
| `NotificationController` | Notifications |
| `ReportController` | Reports |
| `SeoController`, `RedirectController` | Seo |
| `SettingsController`, `IntegrationController` | Settings |
| `MediaController`, `UploadController` | Media |
| `LocationController`, `MasterController` | Locations, Masters |
| `SupportController` | Support |
| `AuditLogController`, `ApprovalController` | Audit |
| `DashboardController` | Reports + cross-module |

## Controllers/Customer

| Controller | Serves |
|------------|--------|
| `ShopAuthController` | Register, login, OTP, social, forgot/reset |
| `ShopCatalogController` | PLP, facets, PDP, related, recently viewed |
| `ShopSearchController` | Autosuggest, results, zero-result recovery |
| `ShopCartController` | Cart CRUD, coupon apply, shipping estimate |
| `ShopCheckoutController` | Address, delivery option, order placement |
| `ShopPaymentController` | Initiate, verify, retry, COD |
| `ShopOrderController` | Order history, detail, invoice, cancel, return request |
| `ShopAccountController` | Profile, addresses, preferences, consent |
| `ShopWishlistController`, `ShopCompareController` | Save and compare |
| `ShopReviewController` | Submit, media upload, vote, report |
| `ShopRewardController` | Balance, ledger, redemption |
| `ShopSupportController` | Tickets, contact form, help articles |
| `ShopContentController` | Blog, static pages, artisan profiles |
| `ShopNotificationController` | In-app inbox, push subscription |

## Controllers/Public

`SitemapController`, `RobotsController`, `TrackController` (order tracking by token),
`NewsletterSubscribeController`, `HealthController`.

## Controllers/Webhooks

`PaymentWebhookController`, `CourierWebhookController`, `EmailWebhookController`.
Every webhook verifies its provider signature before doing anything.

---

## BackgroundServices

| Service | Job |
|---------|-----|
| `AbandonedCartRecoveryJob` | Emails / WhatsApp for carts idle past the threshold |
| `LowStockAlertJob` | Raises alerts and notifications when stock crosses reorder level |
| `OrderStatusSyncJob` | Polls couriers for tracking updates when webhooks are unavailable |
| `ReportAggregationJob` | Builds the nightly Daily*Summary tables |
| `SitemapRegenerationJob` | Rebuilds sitemap.xml after catalog or content changes |
| `ReviewRequestJob` | Sends post-delivery review requests |
| `CampaignDispatchJob` | Sends scheduled newsletter campaigns and flow steps |
| `ScheduledPriceChangeJob` | Applies price changes at their scheduled time |
| `ExportJob` | Runs scheduled report exports and large data exports |

---

## ServiceExtension.cs

One file registering everything.

```
#region Connection Configuration
   AddScoped<SqlConnection>(...)                    // Dapper for all SP calls
#endregion

#region Services      -> services.AddCatalogModule(); AddOrdersModule(); ... (25 calls)
#region Auto Mapper   -> services.CatalogAutoMapper(); OrdersAutoMapper(); ...
#region Cross-cutting -> AddMemoryCache(); IPermissionCache; IStorageService; IEmailService
```

## Program.cs pipeline

```
AddControllers / AddHttpClient / AddSwaggerGen / AddServiceModule / AddHttpContextAccessor
AddAuthentication(JwtBearer)  -> issuer, audience, key from Jwt:*
AddHostedService x N          -> only when its BackgroundJobs:* flag is true
---
UseSwagger / UseSwaggerUI
UseHttpsRedirection
UseAuthentication
UseMiddleware<ExceptionMiddleware>
UseAuthorization
MapControllers
MapHub<...>
```

---

## Response contract

Every action returns `ResponseViewModel<T>`:

```
Success, Code, Message, Data, TotalRecord, TotalFilteredRecord
```

Exceptions never escape: `ExceptionMiddleware` converts `RepositoryException` and
unhandled errors into the same envelope with the right status code.
