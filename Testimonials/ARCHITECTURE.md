# Module: Testimonials

**Admin module #:** 15
**API base paths:** `api/testimonials`

Curated customer testimonials with explicit consent tracking and placement control.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Testimonials/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       TestimonialsConfig.cs (DI) + TestimonialsAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Testimonial.cs`
- `TestimonialConsent.cs`
- `TestimonialPlacement.cs`
- `TestimonialSubmission.cs`

## Domain/IServices

- `ITestimonialService.cs`
- `ITestimonialConsentService.cs`
- `ITestimonialPlacementService.cs`

## Application/Services

- `TestimonialService.cs`
- `TestimonialConsentService.cs`
- `TestimonialPlacementService.cs`

## Infrastructure/Repositories

- `TestimonialRepository.cs`
- `TestimonialConsentRepository.cs`
- `TestimonialPlacementRepository.cs`

## Application/Extentions

- `TestimonialsConfig.cs` — exposes `services.AddTestimonialsModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `TestimonialsAutoMapperConfig.cs` — exposes `services.TestimonialsAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-15-01..05 Testimonials List, Editor, Submissions Queue, Placement Manager, Detail

## Storefront surfaces

Home and static-page testimonial bands

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Testimonials/`. Naming convention:

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
