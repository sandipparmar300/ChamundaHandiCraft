# ChamundaHandicraft.Admin

The back-office panel. ASP.NET Core MVC + Razor + Bootstrap 5 + jQuery, cookie
authentication, session-held JWT. It has **no database access and no module project
references** — every controller action calls `ApiService` against a constant from
`ApiEndPoint`.

Design source of truth: `docs/ui-ux/` (HCX-UXSPEC-001), 20 modules, 189 screens.

---

## Folder layout

```
ChamundaHandicraft.Admin/
├─ Controllers/          One per Views/ folder below
├─ Models/               ErrorViewModel and Admin-only presentation models
├─ Views/
│  ├─ Shared/            _Layout, _OuterLayout, _Header, _Sidebar, _Breadcrumb,
│  │                     _Footer, _Pagination, _ConfirmDialog, _EmptyState,
│  │                     _ValidationScriptsPartial, Error
│  └─ <Module>/          Index / Create / Edit / Details + _Partials per module
├─ wwwroot/
│  ├─ assets/css/scss/   variables, mixins, typography, global, style
│  ├─ assets/js/         common.js, grid.js, form.js, upload.js, permissions.js
│  ├─ assets/images/     logo, favicon, icons, empty-state illustrations
│  ├─ assets/fonts/
│  └─ lib/               bootstrap, jquery, jquery-validation, datatables, select2,
│                        toastr, ckeditor, chart.js, sortablejs, flatpickr
├─ Program.cs
└─ appsettings.json
```

---

## Views folders (one per controller)

| Group | View folders |
|-------|--------------|
| System | `Auth`, `Profile`, `Shared` |
| 01 Dashboard | `Dashboard` |
| 02 Users | `AdminUser`, `Role`, `Permission`, `Customer`, `Segment` |
| 03 Products | `Product`, `Brand`, `Artisan`, `Attribute` |
| 04 Categories | `Category`, `Menu` |
| 05 Inventory | `Inventory`, `Purchase`, `StockAdjustment`, `StockTransfer`, `StockTake`, `Warehouse`, `Supplier` |
| 06 Orders | `Order`, `Return`, `Invoice` |
| 07 Payments | `Payment`, `Refund`, `Settlement`, `Dispute` |
| 08 Shipping | `Shipping`, `Courier`, `Shipment` |
| 09/10 Promotions | `Coupon`, `Offer` |
| 11 Banners | `Banner` |
| 12 CMS | `CmsPage`, `Faq`, `ContactSubmission` |
| 13 Blog | `Blog`, `BlogCategory`, `BlogAuthor`, `BlogComment` |
| 14 Reviews | `Review` |
| 15 Testimonials | `Testimonial` |
| 16 Newsletter | `Subscriber`, `Campaign`, `Flow` |
| 17 Notifications | `NotificationTemplate`, `Notification` |
| 18 Reports | `Report` |
| 19 SEO | `Seo`, `Redirect` |
| 20 Settings | `Settings`, `Integration` |
| Cross-cutting | `Media`, `AuditLog`, `Approval`, `Support` |
| Reference data | `Country`, `State`, `City`, `ZipCode`, `Master` |

---

## Controller pattern

Every list-style controller follows the same six actions:

```
[PagePermission(IsView)]   Index()                 -> renders the grid shell
[HttpPost]                 GridList(DataTableRequestViewModel)  -> DataTables JSON
[PagePermission(IsAdd)]    Add()                   -> View("Create", new VM())
[PagePermission(IsEdit)]   Edit(int id)            -> View("Create", fetched VM)
[HttpPost] [IsAdd|IsEdit]  Save(VM model)          -> JSON { success, message }
[PagePermission(IsView)]   Details(int id)
[HttpPost]                 ActiveInactive(int id, bool status)
[HttpPost] [IsDelete]      Delete(int id)
```

`GridList` maps the DataTables column index to a sort column name, builds a
`PaginationViewModel`, and posts it to the API. No business logic in the controller.

Detail-heavy modules (Product, Order, Customer 360, Inventory) add tab actions that
return partials, so a tab loads without a full page render.

---

## Layout templates

The spec defines 15 canonical layouts (L-01 … L-15). They map to shared partials:

| Template | Use | Partial |
|----------|-----|---------|
| L-01 | List / grid page | `_ListLayout` |
| L-02 | Detail with tabs | `_TabbedDetailLayout` |
| L-03 | Settings form panel | `_SettingsLayout` |
| L-04 | Canvas / drag-and-drop | `_CanvasLayout` |
| L-05 | Single form card | `_FormLayout` |
| L-06 | Multi-step wizard | `_WizardLayout` |
| L-07 | Dashboard widget grid | `_DashboardLayout` |
| L-09 | Tree + detail split | `_TreeDetailLayout` |
| L-10 | Unauthenticated / system | `_OuterLayout` |

---

## Permission binding

- `[PagePermission(PermissionsTypes.IsView|IsAdd|IsEdit|IsDelete)]` gates the action.
- The role's permission key-set is loaded into session at login and re-fetched on miss.
- `_Sidebar.cshtml` renders only menu entries the key-set allows.
- A control the user cannot use is hidden, or disabled with a tooltip where hiding it
  would be confusing (Design Principle 8).

---

## Non-negotiable UX rules carried from the spec

- One filled primary button per view region.
- Unsaved-changes guard on every dirty form; long forms autosave a draft every 30s.
- Destructive actions: red button + consequence statement + typed verification.
- Every data surface designs loading, empty, filtered-empty, error and no-permission
  states. No blank screens.
- WCAG 2.1 AA is the floor.
