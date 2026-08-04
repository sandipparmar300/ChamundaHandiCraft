# Module: Notifications

**Admin module #:** 17
**API base paths:** `api/notifications`

Notification templates, event triggers, channels (email/SMS/WhatsApp/push/in-app), delivery log and escalations.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Notifications/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       NotificationsConfig.cs (DI) + NotificationsAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `NotificationTemplate.cs`
- `NotificationEvent.cs`
- `NotificationChannel.cs`
- `NotificationLog.cs`
- `InAppNotification.cs`
- `PushSubscription.cs`
- `EscalationRule.cs`
- `NotificationPreference.cs`

## Domain/IServices

- `INotificationTemplateService.cs`
- `INotificationEventService.cs`
- `INotificationChannelService.cs`
- `INotificationLogService.cs`
- `IInAppNotificationService.cs`
- `IPushSubscriptionService.cs`

## Application/Services

- `NotificationTemplateService.cs`
- `NotificationEventService.cs`
- `NotificationChannelService.cs`
- `NotificationLogService.cs`
- `InAppNotificationService.cs`
- `PushSubscriptionService.cs`

## Infrastructure/Repositories

- `NotificationTemplateRepository.cs`
- `NotificationEventRepository.cs`
- `NotificationChannelRepository.cs`
- `NotificationLogRepository.cs`
- `InAppNotificationRepository.cs`
- `PushSubscriptionRepository.cs`

## Application/Extentions

- `NotificationsConfig.cs` — exposes `services.AddNotificationsModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `NotificationsAutoMapperConfig.cs` — exposes `services.NotificationsAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-17-01..10 Templates, Editor, Event Trigger Matrix, Channel Settings, Delivery Log, In-App Inbox, Preferences, Push Composer, Analytics, Escalation Rules

## Storefront surfaces

Module 17 Notifications, order/shipping transactional messages

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Notifications/`. Naming convention:

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
