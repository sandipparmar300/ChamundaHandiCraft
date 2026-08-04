# Module: Support

**Admin module #:** --
**API base paths:** `api/support`

Customer support tickets raised from the storefront help centre and resolved by Support agents.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Support/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       SupportConfig.cs (DI) + SupportAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `SupportTicket.cs`
- `TicketMessage.cs`
- `TicketAttachment.cs`
- `TicketCategory.cs`
- `TicketSlaRule.cs`

## Domain/IServices

- `ISupportTicketService.cs`
- `ITicketMessageService.cs`
- `ITicketCategoryService.cs`

## Application/Services

- `SupportTicketService.cs`
- `TicketMessageService.cs`
- `TicketCategoryService.cs`

## Infrastructure/Repositories

- `SupportTicketRepository.cs`
- `TicketMessageRepository.cs`
- `TicketCategoryRepository.cs`

## Application/Extentions

- `SupportConfig.cs` — exposes `services.AddSupportModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `SupportAutoMapperConfig.cs` — exposes `services.SupportAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

Support queue, ticket detail (Support role)

## Storefront surfaces

Module 14 Customer Support

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Support/`. Naming convention:

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
