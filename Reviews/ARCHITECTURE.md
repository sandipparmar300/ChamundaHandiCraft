# Module: Reviews

**Admin module #:** 14
**API base paths:** `api/reviews`

Product reviews, sub-ratings, media, replies, reports, votes and review request campaigns.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Reviews/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       ReviewsConfig.cs (DI) + ReviewsAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Review.cs`
- `ReviewSubRating.cs`
- `ReviewMedia.cs`
- `ReviewReply.cs`
- `ReviewReport.cs`
- `ReviewVote.cs`
- `ReviewModerationLog.cs`
- `ReviewRequest.cs`

## Domain/IServices

- `IReviewService.cs`
- `IReviewModerationService.cs`
- `IReviewRequestService.cs`

## Application/Services

- `ReviewService.cs`
- `ReviewModerationService.cs`
- `ReviewRequestService.cs`

## Infrastructure/Repositories

- `ReviewRepository.cs`
- `ReviewModerationRepository.cs`
- `ReviewRequestRepository.cs`

## Application/Extentions

- `ReviewsConfig.cs` — exposes `services.AddReviewsModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `ReviewsAutoMapperConfig.cs` — exposes `services.ReviewsAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-14-01..06 Reviews Queue, Review Detail, Reported Reviews, Analytics, Request Campaigns, Moderation Settings

## Storefront surfaces

Module 15 Reviews, rating aggregate on PDP/PLP

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Reviews/`. Naming convention:

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
