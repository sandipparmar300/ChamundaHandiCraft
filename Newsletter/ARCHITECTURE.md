# Module: Newsletter

**Admin module #:** 16
**API base paths:** `api/newsletter`

Subscribers, lists and segments, email campaigns, automated flows, templates and suppressions.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Newsletter/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       NewsletterConfig.cs (DI) + NewsletterAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Subscriber.cs`
- `SubscriberConsent.cs`
- `SubscriberList.cs`
- `ListMember.cs`
- `EmailCampaign.cs`
- `CampaignRecipient.cs`
- `CampaignEvent.cs`
- `Flow.cs`
- `FlowStep.cs`
- `FlowEnrolment.cs`
- `Suppression.cs`
- `EmailTemplate.cs`

## Domain/IServices

- `ISubscriberService.cs`
- `IListService.cs`
- `ICampaignService.cs`
- `IFlowService.cs`
- `IEmailTemplateService.cs`
- `ISuppressionService.cs`

## Application/Services

- `SubscriberService.cs`
- `ListService.cs`
- `CampaignService.cs`
- `FlowService.cs`
- `EmailTemplateService.cs`
- `SuppressionService.cs`

## Infrastructure/Repositories

- `SubscriberRepository.cs`
- `ListRepository.cs`
- `CampaignRepository.cs`
- `FlowRepository.cs`
- `EmailTemplateRepository.cs`
- `SuppressionRepository.cs`

## Application/Extentions

- `NewsletterConfig.cs` — exposes `services.AddNewsletterModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `NewsletterAutoMapperConfig.cs` — exposes `services.NewsletterAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-16-01..11 Subscribers, Detail, Lists, Segment Builder, Campaigns, Campaign Builder, Report, Flows, Flow Builder, Templates, Suppressions

## Storefront surfaces

Footer subscribe, post-purchase and abandoned-cart emails

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Newsletter/`. Naming convention:

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
