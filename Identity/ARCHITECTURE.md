# Module: Identity

**Admin module #:** 02
**API base paths:** `api/admin-users, api/roles, api/permissions, api/auth`

Admin users, roles, permissions, sessions and login history. Owns authentication identity for the Admin panel.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Identity/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       IdentityConfig.cs (DI) + IdentityAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `AdminUser.cs`
- `Role.cs`
- `Permission.cs`
- `RolePermission.cs`
- `UserRole.cs`
- `UserPermissionOverride.cs`
- `UserSession.cs`
- `LoginHistory.cs`
- `Invitation.cs`
- `Department.cs`
- `RefreshToken.cs`
- `ForgotPasswordToken.cs`
- `Page.cs`
- `PagePermission.cs`

## Domain/IServices

- `IAdminUserService.cs`
- `IRoleService.cs`
- `IPermissionService.cs`
- `ISessionService.cs`
- `ILoginHistoryService.cs`
- `IPasswordService.cs`

## Application/Services

- `AdminUserService.cs`
- `RoleService.cs`
- `PermissionService.cs`
- `SessionService.cs`
- `LoginHistoryService.cs`
- `PasswordService.cs`

## Infrastructure/Repositories

- `AdminUserRepository.cs`
- `RoleRepository.cs`
- `PermissionRepository.cs`
- `SessionRepository.cs`
- `LoginHistoryRepository.cs`
- `PasswordRepository.cs`

## Application/Extentions

- `IdentityConfig.cs` — exposes `services.AddIdentityModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `IdentityAutoMapperConfig.cs` — exposes `services.IdentityAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-02-01..07 Admin User List/Create/Detail/Edit, Roles, Role Permission Matrix, Login History

## Storefront surfaces

Not exposed. Storefront identity lives in Customers.

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Identity/`. Naming convention:

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
