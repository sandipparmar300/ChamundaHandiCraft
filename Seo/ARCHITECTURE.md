# Module: Seo

**Admin module #:** 19
**API base paths:** `api/seo`

Meta tags and templates, redirects, 404 monitoring, sitemap, robots.txt, structured data and keyword tracking.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Seo/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       SeoConfig.cs (DI) + SeoAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `SeoMeta.cs`
- `SeoMetaTemplate.cs`
- `UrlRedirect.cs`
- `NotFoundLog.cs`
- `SitemapConfig.cs`
- `RobotsTxt.cs`
- `SchemaConfig.cs`
- `TrackedKeyword.cs`
- `KeywordPosition.cs`
- `HreflangMapping.cs`

## Domain/IServices

- `ISeoMetaService.cs`
- `IRedirectService.cs`
- `INotFoundLogService.cs`
- `ISitemapService.cs`
- `ISchemaConfigService.cs`
- `IKeywordService.cs`

## Application/Services

- `SeoMetaService.cs`
- `RedirectService.cs`
- `NotFoundLogService.cs`
- `SitemapService.cs`
- `SchemaConfigService.cs`
- `KeywordService.cs`

## Infrastructure/Repositories

- `SeoMetaRepository.cs`
- `RedirectRepository.cs`
- `NotFoundLogRepository.cs`
- `SitemapRepository.cs`
- `SchemaConfigRepository.cs`
- `KeywordRepository.cs`

## Application/Extentions

- `SeoConfig.cs` — exposes `services.AddSeoModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `SeoAutoMapperConfig.cs` — exposes `services.SeoAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-19-01..10 SEO Dashboard, Meta Manager, Sitemap, Robots.txt, Redirects, 404 Monitor, Structured Data, Global Settings, Search Performance, Keywords

## Storefront surfaces

Every storefront page head, sitemap.xml, robots.txt, JSON-LD

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Seo/`. Naming convention:

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
