# Module: Locations

**Admin module #:** --
**API base paths:** `api/locations`

Geography masters used by customer addresses, shipping zones and serviceability.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Locations/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       LocationsConfig.cs (DI) + LocationsAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Country.cs`
- `State.cs`
- `City.cs`
- `ZipCode.cs`
- `GeoZone.cs`
- `ZoneZipCode.cs`

## Domain/IServices

- `ICountryService.cs`
- `IStateService.cs`
- `ICityService.cs`
- `IZipCodeService.cs`
- `IGeoZoneService.cs`

## Application/Services

- `CountryService.cs`
- `StateService.cs`
- `CityService.cs`
- `ZipCodeService.cs`
- `GeoZoneService.cs`

## Infrastructure/Repositories

- `CountryRepository.cs`
- `StateRepository.cs`
- `CityRepository.cs`
- `ZipCodeRepository.cs`
- `GeoZoneRepository.cs`

## Application/Extentions

- `LocationsConfig.cs` — exposes `services.AddLocationsModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `LocationsAutoMapperConfig.cs` — exposes `services.LocationsAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

Reference data screens under Masters

## Storefront surfaces

Address forms, pincode serviceability check

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Locations/`. Naming convention:

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
