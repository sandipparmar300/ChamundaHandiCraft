# Module: Settings

**Admin module #:** 20
**API base paths:** `api/settings, api/integrations`

Platform settings across all sections, change history, integrations, security policy and backup/export jobs.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Settings/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       SettingsConfig.cs (DI) + SettingsAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Setting.cs`
- `SettingsHistory.cs`
- `Integration.cs`
- `IntegrationCredential.cs`
- `SecurityPolicy.cs`
- `IpAllowList.cs`
- `BackupJob.cs`
- `DataExportRequest.cs`
- `ExportJob.cs`
- `DashboardLayout.cs`
- `UserPreference.cs`
- `Festival.cs`
- `Target.cs`

## Domain/IServices

- `ISettingService.cs`
- `ISettingsHistoryService.cs`
- `IIntegrationService.cs`
- `ISecurityPolicyService.cs`
- `IBackupJobService.cs`
- `IDashboardLayoutService.cs`

## Application/Services

- `SettingService.cs`
- `SettingsHistoryService.cs`
- `IntegrationService.cs`
- `SecurityPolicyService.cs`
- `BackupJobService.cs`
- `DashboardLayoutService.cs`

## Infrastructure/Repositories

- `SettingRepository.cs`
- `SettingsHistoryRepository.cs`
- `IntegrationRepository.cs`
- `SecurityPolicyRepository.cs`
- `BackupJobRepository.cs`
- `DashboardLayoutRepository.cs`

## Application/Extentions

- `SettingsConfig.cs` — exposes `services.AddSettingsModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `SettingsAutoMapperConfig.cs` — exposes `services.SettingsAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-20-01..18 Settings Home, Company, Tax/GST, Currency, Email, SMS/WhatsApp, Gateways, Shipping, Social, Website, Localisation, Orders, Products, Customers, Security, Integrations, History, Backup

## Storefront surfaces

Maintenance mode, currency/locale, storefront theme values

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Settings/`. Naming convention:

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
