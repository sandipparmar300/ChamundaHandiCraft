# Module: Reports

**Admin module #:** 18
**API base paths:** `api/reports`

Pre-aggregated analytics summaries, saved reports, scheduled exports and the custom report builder.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Reports/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       ReportsConfig.cs (DI) + ReportsAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `DailySalesSummary.cs`
- `DailyProductSummary.cs`
- `DailyInventorySummary.cs`
- `DailyCustomerSummary.cs`
- `MonthlyTaxSummary.cs`
- `OrderProfitability.cs`
- `ProductCostHistory.cs`
- `SavedReport.cs`
- `ReportSchedule.cs`
- `ReportAnnotation.cs`
- `AnalyticsSession.cs`

## Domain/IServices

- `ISalesReportService.cs`
- `IProductReportService.cs`
- `IInventoryReportService.cs`
- `ICustomerReportService.cs`
- `ITaxReportService.cs`
- `ISavedReportService.cs`
- `IReportScheduleService.cs`

## Application/Services

- `SalesReportService.cs`
- `ProductReportService.cs`
- `InventoryReportService.cs`
- `CustomerReportService.cs`
- `TaxReportService.cs`
- `SavedReportService.cs`
- `ReportScheduleService.cs`

## Infrastructure/Repositories

- `SalesReportRepository.cs`
- `ProductReportRepository.cs`
- `InventoryReportRepository.cs`
- `CustomerReportRepository.cs`
- `TaxReportRepository.cs`
- `SavedReportRepository.cs`
- `ReportScheduleRepository.cs`

## Application/Extentions

- `ReportsConfig.cs` — exposes `services.AddReportsModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `ReportsAutoMapperConfig.cs` — exposes `services.ReportsAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-18-01..14 Reports Home, Sales, Profit, Customers, Inventory, Products, Tax/GST, Payments, Orders, Returns, Artisan Performance, Builder, Saved, Schedules

## Storefront surfaces

Feeds Dashboard widgets only

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Reports/`. Naming convention:

| Purpose | Procedure |
|---------|-----------|
| Server-side grid | `GridList_<Entity>` |
| Single record | `Get<Entity>ById` |
| Uniqueness check | `Is<Entity><Field>Exists` |
| Upsert | `Save<Entity>` |
| Status toggle | `ActiveInactive<Entity>` |
| Soft delete | `SoftDelete<Entity>` |
| Dropdown source | `GetActive<Entity>List` |

## Conventions

- All entities carry the audit columns `CreatedAt`, `CreatedBy`, `UpdatedAt`,
  `UpdatedBy`, `IsActive`, `IsDeleted`.
- Deletes are always soft.
- Repositories open a per-operation `SqlConnection`; never share one across calls.
- Repositories throw `RepositoryException`; the API's `ExceptionMiddleware` renders it.
- View models live in `ChamundaHandicraft.Helper/ViewModel/`, never in this project.
