# Chamunda Handicraft — Platform Architecture

**Product:** Enterprise Handicraft E-Commerce Platform
**Stack:** ASP.NET Core MVC (.NET 8) · Modular Monolith · Clean Architecture · MSSQL · Bootstrap 5 · jQuery
**Design specs:** `docs/ui-ux/` (Admin, HCX-UXSPEC-001) · `docs/ui-ux-storefront/` (Customer, HCX-CXSPEC-001)
**Flow specs:** `docs/Admin Flows/` (20 files) · `docs/Customer Flows/` (13 files)
**Status:** Architecture and folder structure only. No implementation code yet.

---

## 1. Architectural baseline

The solution follows a proven layering — gateway → API → module class libraries →
thin MVC front ends, Dapper over stored procedures, key-based RBAC, one DI extension
per module — applied to an e-commerce domain.

**The conventions this rests on:** the layering, the naming conventions, the
repository/service split, the `ResponseViewModel<T>` envelope, the DataTables grid
contract, the permission attributes, and the `ApiEndPoint` constants pattern.

---

## 2. Solution map

```
Solution/
│
├─ ChamundaHandicraft.sln
├─ Directory.Build.props            Shared TFM / nullable / version for all projects
├─ ARCHITECTURE.md                  ← this file
│
├─ ChamundaHandicraft.APIGateway/   Ocelot. The only host the web tiers may call
├─ ChamundaHandicraft.API/          The single backend. Owns DB, JWT, jobs, business ops
├─ ChamundaHandicraft.Admin/        Back-office MVC panel  (docs/ui-ux)
├─ ChamundaHandicraft.Customer/     Customer website MVC   (docs/ui-ux-storefront)
├─ ChamundaHandicraft.Helper/       Shared view models, constants, ApiService, attributes
├─ ChamundaHandicraft.Tests/        xUnit — unit + integration
│
├─ Modules/  (solution folder — 25 class libraries)
│  ├─ Identity/        Catalog/       Orders/       Promotions/    Reports/
│  ├─ Customers/       Categories/    Cart/         Banners/       Seo/
│  ├─ Media/           Inventory/     Payments/     Cms/           Settings/
│  ├─ Locations/       Masters/       Shipping/     Blog/          Support/
│  └─ Audit/                          Reviews/      Testimonials/  Newsletter/
│                                                   Notifications/
│
├─ DatabaseScripts/                 Schema, stored procedures, seed, patches, views
└─ docs/                            Design and flow specifications
```

---

## 3. Runtime topology

```
                      ┌──────────────────────────┐
   Browser (admin) ──▶│ ChamundaHandicraft.Admin │──────┐
                      └──────────────────────────┘      │  HTTPS + Bearer
                                                        │  (JWT from session)
                      ┌─────────────────────────────┐   │  ┌───────────────────────────────┐
   Browser (shop) ───▶│ ChamundaHandicraft.Customer │───┼─▶│ ChamundaHandicraft.APIGateway │
                      └─────────────────────────────┘   │  └───────────────┬───────────────┘
                                                        │                  │ Ocelot
   Gateways / couriers / email provider ────────────────┘                  ▼
                    (webhooks)                               ┌────────────────────────────┐
                                                             │  ChamundaHandicraft.API    │
                                                             │  Controllers → Module      │
                                                             │  Services → Repositories   │
                                                             └─────────────┬──────────────┘
                                                                           │ Dapper (stored procs)
                                                                           ▼
                                                                       ┌────────┐
                                                                       │ MSSQL  │
                                                                       └────────┘
```

**The rule that keeps this clean:** neither MVC project references a module project or
a connection string. If the Admin panel needs data, it calls a constant from
`ApiEndPoint` through `ApiService`. No exceptions.

| Host | Dev port | Auth |
|------|----------|------|
| Gateway | 7138 | none (pass-through) |
| API | 7139 | JWT bearer |
| Admin | 7140 | Cookie + JWT held in session |
| Customer | 7141 | Cookie (customer) or guest token |

---

## 4. Module anatomy

Every one of the 25 module libraries has the identical shape. Learn it once, apply it
everywhere:

```
<Module>/
├─ <Module>.csproj              → references ChamundaHandicraft.Helper only
├─ ARCHITECTURE.md              → this module's entities, services, screens, SPs
├─ Domain/
│  ├─ Entities/                 POCOs mapped 1:1 to tables
│  └─ IServices/                I<Name>Service — the repository contracts
├─ Application/
│  ├─ Services/                 <Name>Service — orchestration, rules, mapping
│  ├─ Profiles/                 AutoMapper profiles (Entity ↔ ViewModel)
│  └─ Extentions/               <Module>Config.cs + <Module>AutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/             <Name>Repository : I<Name>Service — Dapper + SPs
```

### Dependency direction

```
Domain  ←  Application  ←  Infrastructure
   ↑            ↑                ↑
   └────────────┴────────────────┴──── ChamundaHandicraft.Helper (view models, constants)
```

Domain knows nothing. Application depends on Domain. Infrastructure implements Domain
contracts. Nothing depends on Infrastructure except the DI wiring.

### Modules never reference each other

An order needs product data — it does **not** reference `Catalog`. It receives what it
needs in the request payload, or the API controller composes across two module services.
This is what stops the modular monolith degenerating into a tangle.

### Registration

Each module exposes two extension methods, both called from
`ChamundaHandicraft.API/ServiceExtension.cs`:

```csharp
services.AddCatalogModule();     // services + repository bindings
services.CatalogAutoMapper();    // profiles in that assembly
```

---

## 5. Module → spec mapping

| # | Module project | Admin module (docs/ui-ux) | Storefront module (docs/ui-ux-storefront) |
|---|----------------|---------------------------|-------------------------------------------|
| 1 | `Identity` | 02 User Management (admin side) | — |
| 2 | `Customers` | 02 User Management (customer side) | 01 Auth · 06 Wishlist · 10 My Account · 16 Rewards |
| 3 | `Catalog` | 03 Product Management | 03 Shop · 04 PDP · 05 Compare · 13 Search |
| 4 | `Categories` | 04 Category Management | Mega menu, category landing |
| 5 | `Inventory` | 05 Inventory | Stock state on PDP/PLP |
| 6 | `Orders` | 06 Order Management | 11 Orders · 12 Order Tracking |
| 7 | `Cart` | 06 (Abandoned Carts) | 07 Cart · 08 Checkout |
| 8 | `Payments` | 07 Payment Management | 09 Payment |
| 9 | `Shipping` | 08 Shipping | Delivery estimate · 12 Tracking |
| 10 | `Promotions` | 09 Coupons · 10 Offers | Price badges, coupon apply |
| 11 | `Banners` | 11 Banners | Home hero, rails, popups |
| 12 | `Cms` | 12 CMS | 19 Static Pages · Help |
| 13 | `Blog` | 13 Blog | 18 Blog |
| 14 | `Reviews` | 14 Reviews | 15 Reviews |
| 15 | `Testimonials` | 15 Testimonials | Testimonial bands |
| 16 | `Newsletter` | 16 Newsletter | Footer subscribe, lifecycle email |
| 17 | `Notifications` | 17 Notifications | 17 Notifications |
| 18 | `Reports` | 18 Reports · 01 Dashboard | — |
| 19 | `Seo` | 19 SEO | Every page head, sitemap, JSON-LD |
| 20 | `Settings` | 20 Settings | Maintenance mode, locale, theme values |
| 21 | `Media` | Cross-cutting (Media Library) | Image delivery |
| 22 | `Locations` | Reference data | Address forms, pincode check |
| 23 | `Masters` | Reference data | PLP facets, size guide |
| 24 | `Support` | Support queue | 14 Customer Support |
| 25 | `Audit` | Audit Log · Approvals | — |

> `Cart`, `Support` and `Audit` are additions beyond the 20 admin modules: the
> storefront needs cart/checkout state and a help desk, and audit/approvals are
> cross-cutting rather than owned by any one module.

---

## 6. Data access

**Dapper + stored procedures is the only data access path.** There is no ORM and no
change tracking. The schema, seed data and reporting views are authored as SQL under
`DatabaseScripts/` and applied in numbered order, which makes that folder the single
source of truth for the database.

Every repository follows this shape:

```csharp
public class ProductRepository : IProductService
{
    private readonly string _connectionString;
    // Per-operation connection. Dapper opens and closes it.
    private SqlConnection _dbConnection => new SqlConnection(_connectionString);

    Task<Tuple<List<ProductGridListResult>, int, int>> GridListAsync(...);  // GridList_Product
    Task<Product?> GetByIdAsync(int id);                                     // GetProductById
    Task<ResponseViewModel<bool>> IsCodeExistAsync(string code, int id);     // IsProductCodeExists
    Task<ResponseViewModel<bool>> SaveAsync(Product model, int userId);      // SaveProduct
    Task<bool> ActiveInactiveAsync(int id, bool status, int userId);         // ActiveInactiveProduct
    Task<(bool, string)> DeleteAsync(int id, int userId);                    // SoftDeleteProduct
}
```

Procedure naming and the schema run order are documented in
`DatabaseScripts/README.md`.

### Non-negotiables

- **Soft delete only.** `IsDeleted = 1`. Recycle Bin recovers within 30 days.
- **Audit columns everywhere**: `CreatedAt/By`, `UpdatedAt/By`, `IsActive`, `IsDeleted`.
- **Money is `decimal(18,2)`**, rates and quantities `decimal(18,4)`. Never `float`.
- **Timestamps are UTC `datetime2`**, converted at the presentation edge.
- **No `SELECT *`** in any procedure.

---

## 7. Cross-cutting concerns

| Concern | Where it lives |
|---------|----------------|
| Authentication | API issues JWT + refresh token; Admin/Customer hold it in session behind a cookie |
| Authorisation | Key-based RBAC. `[HasApiPermission("catalog.product.create")]` on the API, `[PagePermission(...)]` on the Admin panel. Key set cached server-side, loaded into session at login |
| Validation | Data annotations on view models, plus business rules in Application services. Exact user-facing messages come from the module chapter §22 in the design spec |
| Errors | `RepositoryException` → `ExceptionMiddleware` → `ResponseViewModel` envelope. No raw exception ever reaches a browser |
| Audit trail | `Audit` module. Every create/update/status-change/delete writes a field-level before/after record |
| Approvals | `Audit` module. Guarded actions (large refunds, high discounts, legal page publishes) route through an approval queue |
| File storage | `Media` module + `IStorageService`. S3 in production, local disk in development. The API holds the credentials — neither web tier does |
| Notifications | `Notifications` module fans out to email, SMS, WhatsApp, push and in-app from one event |
| Caching | `IMemoryCache` for permission key sets, settings and reference data. Invalidated on write |
| Logging | Serilog, correlation ID propagated from the gateway |
| Real-time | SignalR hubs on the API for the live dashboard, order queue and inventory alerts |

---

## 8. Request lifecycle (worked example)

Admin edits a product price:

```
1. Browser POST  →  ChamundaHandicraft.Admin  ProductController.Save(ProductViewModel)
2. [PagePermission(IsEdit)] passes against the session key set
3. ApiService.SendRequest(ApiEndPoint.ProductSave, json, POST)
4. Gateway  /Admin/Product/Save  →  API  /api/admin/Product/Save
5. API ProductController  [HasApiPermission("catalog.product.update")]
6. Catalog.Application.ProductService.SaveAsync
      → uniqueness check      → IsProductCodeExists
      → AutoMapper VM→Entity
      → ProductRepository     → SaveProduct
7. AuditLogService writes the field-level before/after rows
8. ResponseViewModel<bool> { Success, Code, Message } returns up the same chain
9. Admin controller returns JSON; the page shows a toast from MessageConstant
```

Every module works exactly this way. There is no second pattern to learn.

---

## 9. Delivery phasing

Taken from `docs/ui-ux/20-Appendix-Inventory-And-Handoff.md` §A8, mapped onto the
module projects:

| Phase | Goal | Modules to build |
|-------|------|------------------|
| **P0 Foundations** | Nothing ships without these | `Helper`, `Identity`, `Settings`, `Locations`, `Masters`, `Media`, `Audit` + `DatabaseScripts/01-Schema` + both app shells |
| **P1 Sell** | Take and fulfil an order | `Catalog`, `Categories`, `Inventory`, `Cart`, `Orders`, `Payments`, `Shipping` |
| **P2 Operate** | Visibility and delegation | `Customers`, `Reports` (sales/order/inventory), Dashboard |
| **P3 Grow** | Demand generation | `Promotions`, `Banners`, `Newsletter`, `Seo` |
| **P4 Tell** | Brand and trust | `Cms`, `Blog`, `Reviews`, `Testimonials` |
| **P5 Refine** | Depth and automation | `Notifications` (full matrix), `Reports` (full), `Support`, integrations |

---

## 10. What exists right now

Folder structure, project files, solution wiring and per-project `ARCHITECTURE.md`
documents. Layer folders contain `.gitkeep` placeholders.

**Deliberately not written yet:** entity classes, services, repositories, controllers,
views, `Program.cs`, `ServiceExtension.cs`, stored procedures. Those come next, module
by module, following the phasing in §9.

### Package note — AutoMapper

AutoMapper `14.0.0` carries a known high-severity advisory
(GHSA-rvv3-g6hj-g44x). There is no `14.0.x` patch; the fix lands in `15.0.0`. All
projects are therefore pinned to **`15.1.3`**.

Be aware that AutoMapper changed to a **commercial licence from v15** — free below a
revenue threshold, paid above it. If that licence is unacceptable, the alternative is
to drop the dependency and hand-write the `Entity ↔ ViewModel` mappers in each module's
`Application/Profiles/`. Decide this before writing the first profile, because it
changes every module identically.

### Before the first line of code

1. Confirm the `Cart` / `Support` / `Audit` additions in §5, and the AutoMapper
   licence decision above.
2. Resolve the open decisions in `docs/ui-ux/20-Appendix…` §A9 that change structure —
   particularly D-01 (multi-warehouse) and D-03 (B2B pricing).
3. Set the connection string and JWT key in `ChamundaHandicraft.API/appsettings.json`.
4. Write `01-Schema` and the P0 stored procedures.
