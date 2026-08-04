# Module: Categories

**Admin module #:** 04
**API base paths:** `api/categories, api/menus`

Category tree, category-product mapping, category filters and storefront menus.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Categories/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       CategoriesConfig.cs (DI) + CategoriesAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Category.cs`
- `ProductCategory.cs`
- `CategoryMedia.cs`
- `CategoryFilter.cs`
- `Menu.cs`
- `MenuItem.cs`

## Domain/IServices

- `ICategoryService.cs`
- `ICategoryFilterService.cs`
- `IMenuService.cs`

## Application/Services

- `CategoryService.cs`
- `CategoryFilterService.cs`
- `MenuService.cs`

## Infrastructure/Repositories

- `CategoryRepository.cs`
- `CategoryFilterRepository.cs`
- `MenuRepository.cs`

## Application/Extentions

- `CategoriesConfig.cs` — exposes `services.AddCategoriesModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `CategoriesAutoMapperConfig.cs` — exposes `services.CategoriesAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-04-01..06 Category Manager, Create, Edit, Detail, Menu Order Manager, Import/Export

## Storefront surfaces

Mega menu, category landing pages, PLP breadcrumbs

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Categories/`. Naming convention:

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
