# Module: Blog

**Admin module #:** 13
**API base paths:** `api/blog`

Blog posts, versions, categories, tags, authors and comment moderation.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Blog/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       BlogConfig.cs (DI) + BlogAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `BlogPost.cs`
- `BlogPostVersion.cs`
- `BlogCategory.cs`
- `BlogTag.cs`
- `BlogPostTag.cs`
- `BlogAuthor.cs`
- `BlogComment.cs`

## Domain/IServices

- `IBlogPostService.cs`
- `IBlogCategoryService.cs`
- `IBlogTagService.cs`
- `IBlogAuthorService.cs`
- `IBlogCommentService.cs`

## Application/Services

- `BlogPostService.cs`
- `BlogCategoryService.cs`
- `BlogTagService.cs`
- `BlogAuthorService.cs`
- `BlogCommentService.cs`

## Infrastructure/Repositories

- `BlogPostRepository.cs`
- `BlogCategoryRepository.cs`
- `BlogTagRepository.cs`
- `BlogAuthorRepository.cs`
- `BlogCommentRepository.cs`

## Application/Extentions

- `BlogConfig.cs` — exposes `services.AddBlogModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `BlogAutoMapperConfig.cs` — exposes `services.BlogAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-13-01..08 Posts List, Post Editor, Create, Categories, Tags, Authors, Comments Moderation, Content Calendar

## Storefront surfaces

Module 18 Blog

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Blog/`. Naming convention:

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
