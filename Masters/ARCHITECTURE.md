# Module: Masters

**Admin module #:** --
**API base paths:** `api/masters`

Small reference-data masters shared across the platform.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Masters/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       MastersConfig.cs (DI) + MastersAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Currency.cs`
- `ExchangeRate.cs`
- `TaxClass.cs`
- `HsnCode.cs`
- `ReasonCode.cs`
- `UnitOfMeasure.cs`
- `Material.cs`
- `Craft.cs`
- `Occasion.cs`
- `Colour.cs`
- `SizeChart.cs`
- `PackagingType.cs`

## Domain/IServices

- `ICurrencyService.cs`
- `ITaxClassService.cs`
- `IHsnCodeService.cs`
- `IReasonCodeService.cs`
- `IMaterialService.cs`
- `ICraftService.cs`
- `ISizeChartService.cs`

## Application/Services

- `CurrencyService.cs`
- `TaxClassService.cs`
- `HsnCodeService.cs`
- `ReasonCodeService.cs`
- `MaterialService.cs`
- `CraftService.cs`
- `SizeChartService.cs`

## Infrastructure/Repositories

- `CurrencyRepository.cs`
- `TaxClassRepository.cs`
- `HsnCodeRepository.cs`
- `ReasonCodeRepository.cs`
- `MaterialRepository.cs`
- `CraftRepository.cs`
- `SizeChartRepository.cs`

## Application/Extentions

- `MastersConfig.cs` — exposes `services.AddMastersModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `MastersAutoMapperConfig.cs` — exposes `services.MastersAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

Reference data screens under Settings/Masters

## Storefront surfaces

Filter facets on PLP, size guide on PDP

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Masters/`. Naming convention:

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
