# Module: Audit

**Admin module #:** --
**API base paths:** `api/audit, api/approvals`

Cross-cutting audit trail and the approvals workflow used by guarded actions.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Audit/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       AuditConfig.cs (DI) + AuditAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `AuditLog.cs`
- `Approval.cs`
- `ApprovalStep.cs`
- `ApprovalRule.cs`

## Domain/IServices

- `IAuditLogService.cs`
- `IApprovalService.cs`

## Application/Services

- `AuditLogService.cs`
- `ApprovalService.cs`

## Infrastructure/Repositories

- `AuditLogRepository.cs`
- `ApprovalRepository.cs`

## Application/Extentions

- `AuditConfig.cs` — exposes `services.AddAuditModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `AuditAutoMapperConfig.cs` — exposes `services.AuditAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-AUD-01 Audit Log, SCR-APR-01 Approvals Queue

## Storefront surfaces

Not exposed

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Audit/`. Naming convention:

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
