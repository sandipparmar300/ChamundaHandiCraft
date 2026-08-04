# Module: Cms

**Admin module #:** 12
**API base paths:** `api/cms, api/faq, api/contact`

Static pages, page versions, reusable blocks, FAQ and contact form submissions.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Cms/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       CmsConfig.cs (DI) + CmsAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `CmsPage.cs`
- `CmsPageVersion.cs`
- `CmsBlock.cs`
- `CmsTemplate.cs`
- `FaqCategory.cs`
- `FaqItem.cs`
- `ContactSubmission.cs`

## Domain/IServices

- `ICmsPageService.cs`
- `ICmsBlockService.cs`
- `IFaqService.cs`
- `IContactSubmissionService.cs`

## Application/Services

- `CmsPageService.cs`
- `CmsBlockService.cs`
- `FaqService.cs`
- `ContactSubmissionService.cs`

## Infrastructure/Repositories

- `CmsPageRepository.cs`
- `CmsBlockRepository.cs`
- `FaqRepository.cs`
- `ContactSubmissionRepository.cs`

## Application/Extentions

- `CmsConfig.cs` — exposes `services.AddCmsModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `CmsAutoMapperConfig.cs` — exposes `services.CmsAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-12-01..06 Pages List, Page Editor, Create, FAQ Manager, Contact Submissions, Menu Builder

## Storefront surfaces

Module 19 Static Pages, Help Centre, Contact

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Cms/`. Naming convention:

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
