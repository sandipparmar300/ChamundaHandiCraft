# Module: Banners

**Admin module #:** 11
**API base paths:** `api/banners`

Homepage and placement banners, sliders, popups and their performance metrics.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Banners/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       BannersConfig.cs (DI) + BannersAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Banner.cs`
- `BannerCreative.cs`
- `BannerPlacement.cs`
- `PopupRule.cs`
- `BannerImpression.cs`
- `BannerClick.cs`

## Domain/IServices

- `IBannerService.cs`
- `IBannerPlacementService.cs`
- `IPopupRuleService.cs`

## Application/Services

- `BannerService.cs`
- `BannerPlacementService.cs`
- `PopupRuleService.cs`

## Infrastructure/Repositories

- `BannerRepository.cs`
- `BannerPlacementRepository.cs`
- `PopupRuleRepository.cs`

## Application/Extentions

- `BannersConfig.cs` — exposes `services.AddBannersModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `BannersAutoMapperConfig.cs` — exposes `services.BannersAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-11-01..06 Banners List, Editor, Slider Manager, Popup Manager, Performance, Placement Map

## Storefront surfaces

Home hero/rails, category banners, site-wide popups

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Banners/`. Naming convention:

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
