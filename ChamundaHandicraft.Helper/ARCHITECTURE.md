# ChamundaHandicraft.Helper

The only project referenced by **everything**. It holds the shared contract between the
API, the Admin panel and the Storefront: view models, constants, enums and the HTTP
client both web tiers use to reach the gateway.

It contains **no business logic** and **no data access**.

---

## Folder layout

```
ChamundaHandicraft.Helper/
├─ APICommonMethod/     ApiResponse<T>, ApiCommonLogic — uniform API envelope
├─ ApiService/          ApiService — static HTTP client used by Admin + Storefront
├─ Attributes/          Permission attributes + their action filters
├─ CommonMethod/        CommonLogic, EnumHelper, SessionExtension, PermissionHelper,
│                       StorageHelper, SlugHelper, PriceHelper, LocalizationHelper
├─ Constants/           ApiEndPoint, AppSetting, MessageConstant, CustomRegex,
│                       LengthConstant, DirectoryConstant, EmailSubjects, PermissionKeys
├─ Enums/               Enum.cs — every platform enum in one place
├─ Exceptions/          RepositoryException and friends
├─ Options/             Strongly-typed options classes bound from appsettings
└─ ViewModel/
   ├─ Common/           Pagination, DataTableRequest, GridListResponse, ResponseViewModel,
   │                    IdNamePair, ImageUpload, UpdateStatusRequest, AuditableViewModel
   ├─ Admin/            One folder-level file set per admin module
   └─ Storefront/       One folder-level file set per storefront module
```

---

## Constants/ApiEndPoint.cs

The single source of truth for every route the Admin panel and Storefront call.
Organised in `#region` blocks per module, mirroring the gateway prefixes:

```csharp
public const string Admin = "Admin/";       // -> API /api/admin/*
public const string Shop  = "Shop/";        // -> API /api/storefront/*
public const string Public = "Public/";     // -> API /api/public/*
```

Per-module regions to define:

| Region | Sample constants |
|--------|------------------|
| Auth | `Login`, `RefreshToken`, `ForgotPassword`, `ResetPassword`, `VerifyTwoFactor`, `Logout` |
| Product | `ProductGridList`, `ProductGetById`, `ProductSave`, `ProductDelete`, `ActiveInactiveProduct`, `ProductVariantList`, `ProductMediaSave`, `ProductBulkImport` |
| Category | `CategoryTree`, `CategoryGetById`, `CategorySave`, `CategoryReorder`, `CategoryDelete` |
| Inventory | `StockGridList`, `StockLedger`, `PurchaseEntrySave`, `StockAdjustmentSave`, `LowStockAlerts` |
| Order | `OrderGridList`, `OrderGetById`, `OrderUpdateStatus`, `OrderCancel`, `PickList`, `DispatchManifest`, `ReturnGridList`, `InvoiceGetById` |
| Payment | `PaymentGridList`, `RefundInitiate`, `RefundApprove`, `SettlementGridList`, `DisputeGridList` |
| Shipping | `ShippingZoneGridList`, `ShippingRateSave`, `CourierList`, `ShipmentCreate`, `TrackShipment` |
| Coupon / Offer | `CouponGridList`, `CouponSave`, `CouponValidate`, `OfferGridList`, `OfferSave`, `FlashSaleList` |
| Banner | `BannerGridList`, `BannerSave`, `BannerPlacementList` |
| Cms / Blog | `CmsPageGridList`, `CmsPageSave`, `FaqList`, `BlogPostGridList`, `BlogPostSave`, `BlogCommentModerate` |
| Review / Testimonial | `ReviewQueue`, `ReviewApprove`, `ReviewReject`, `TestimonialGridList`, `TestimonialSave` |
| Newsletter | `SubscriberGridList`, `CampaignSave`, `CampaignSend`, `FlowSave`, `SuppressionList` |
| Notification | `NotificationTemplateList`, `NotificationSend`, `GetBell`, `MarkRead` |
| Report | `SalesReport`, `ProductReport`, `InventoryReport`, `TaxReport`, `SavedReportList`, `ReportExport` |
| Seo | `SeoMetaGridList`, `RedirectSave`, `NotFoundLog`, `SitemapRegenerate` |
| Settings | `SettingsGetSection`, `SettingsSaveSection`, `SettingsHistory`, `IntegrationList` |
| Storefront | `ShopProductList`, `ShopProductDetail`, `ShopSearch`, `CartGet`, `CartAddItem`, `CheckoutInit`, `PlaceOrder`, `TrackOrder`, `WishlistToggle`, `SubmitReview` |

---

## Constants/PermissionKeys.cs

Key-based RBAC. Each admin action maps to a stable string key checked by
`[HasPermission]` on the API and `[PagePermission]` on the Admin panel.

Format: `<module>.<entity>.<action>` — for example `catalog.product.create`,
`orders.return.approve`, `finance.refund.approve`.

The 9 roles from `docs/ui-ux/05-Roles-And-Permission-Matrix.md` are granted sets of
these keys; the key set is cached server-side and loaded into the Admin session at login.

---

## ApiService/ApiService.cs

Static wrapper over `HttpClient` used by both web tiers.

- Prefixes the configured `APIGatewayBaseUrl`.
- Attaches the bearer token from session, refreshing it on `401`.
- Deserialises into `ResponseViewModel<T>` so callers get `Success`, `Message`, `Data`,
  `TotalRecord`, `TotalFilteredRecord` without touching raw JSON.

---

## Conventions

- View models never contain data-access attributes or EF annotations.
- Every list endpoint returns `ResponseViewModel<List<T>>` with total counts, so a
  DataTables-style grid can bind directly.
- Every user-facing string lives in `MessageConstant` — never inline in a controller.
