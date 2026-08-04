# Module: Catalog

**Admin module #:** 03
**API base paths:** `api/products, api/brands, api/artisans, api/attributes`

Products, variants, options, media, attributes, brands, artisans and craft clusters. The heart of the handicraft catalog.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Catalog/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       CatalogConfig.cs (DI) + CatalogAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Product.cs`
- `ProductVariant.cs`
- `ProductOption.cs`
- `ProductOptionValue.cs`
- `ProductMedia.cs`
- `ProductVideo.cs`
- `ProductAttribute.cs`
- `AttributeSet.cs`
- `Attribute.cs`
- `AttributeValue.cs`
- `Brand.cs`
- `Artisan.cs`
- `CraftCluster.cs`
- `Tag.cs`
- `ProductTag.cs`
- `ProductRelation.cs`
- `ProductVersion.cs`
- `ProductImport.cs`
- `ProductPricing.cs`
- `ScheduledPriceChange.cs`

## Domain/IServices

- `IProductService.cs`
- `IProductVariantService.cs`
- `IProductMediaService.cs`
- `IAttributeService.cs`
- `IBrandService.cs`
- `IArtisanService.cs`
- `ICraftClusterService.cs`
- `IProductImportService.cs`
- `IPricingService.cs`

## Application/Services

- `ProductService.cs`
- `ProductVariantService.cs`
- `ProductMediaService.cs`
- `AttributeService.cs`
- `BrandService.cs`
- `ArtisanService.cs`
- `CraftClusterService.cs`
- `ProductImportService.cs`
- `PricingService.cs`

## Infrastructure/Repositories

- `ProductRepository.cs`
- `ProductVariantRepository.cs`
- `ProductMediaRepository.cs`
- `AttributeRepository.cs`
- `BrandRepository.cs`
- `ArtisanRepository.cs`
- `CraftClusterRepository.cs`
- `ProductImportRepository.cs`
- `PricingRepository.cs`

## Application/Extentions

- `CatalogConfig.cs` — exposes `services.AddCatalogModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `CatalogAutoMapperConfig.cs` — exposes `services.CatalogAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-03-01..14 Product List, Create Wizard, Tabbed Editor, Detail, Variant Manager, Media Manager, Bulk Import, Brands, Artisans, Attributes, Recycle Bin

## Storefront surfaces

Modules 03 Shop/PLP, 04 Product Details, 05 Compare, 13 Search, 20 AI Shopping

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Catalog/`. Naming convention:

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
