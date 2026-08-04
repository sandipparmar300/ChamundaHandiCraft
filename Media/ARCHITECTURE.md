# Module: Media

**Admin module #:** --
**API base paths:** `api/media`

Central media library shared by products, categories, banners, CMS, blog and testimonials.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Media/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       MediaConfig.cs (DI) + MediaAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `MediaAsset.cs`
- `MediaFolder.cs`
- `MediaTag.cs`
- `MediaAssetTag.cs`
- `MediaUsage.cs`
- `MediaVariant.cs`

## Domain/IServices

- `IMediaAssetService.cs`
- `IMediaFolderService.cs`
- `IMediaUsageService.cs`

## Application/Services

- `MediaAssetService.cs`
- `MediaFolderService.cs`
- `MediaUsageService.cs`

## Infrastructure/Repositories

- `MediaAssetRepository.cs`
- `MediaFolderRepository.cs`
- `MediaUsageRepository.cs`

## Application/Extentions

- `MediaConfig.cs` — exposes `services.AddMediaModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `MediaAutoMapperConfig.cs` — exposes `services.MediaAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-MED-01 Media Library

## Storefront surfaces

Image delivery for every storefront surface

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Media/`. Naming convention:

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
