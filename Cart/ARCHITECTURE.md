# Module: Cart

**Admin module #:** --
**API base paths:** `api/cart, api/checkout`

Storefront cart and checkout session state, including guest carts and coupon application.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Cart/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       CartConfig.cs (DI) + CartAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Cart.cs`
- `CartItem.cs`
- `CartCoupon.cs`
- `CartAddress.cs`
- `CheckoutSession.cs`
- `GuestToken.cs`
- `SavedForLater.cs`

## Domain/IServices

- `ICartService.cs`
- `ICheckoutSessionService.cs`

## Application/Services

- `CartService.cs`
- `CheckoutSessionService.cs`

## Infrastructure/Repositories

- `CartRepository.cs`
- `CheckoutSessionRepository.cs`

## Application/Extentions

- `CartConfig.cs` — exposes `services.AddCartModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `CartAutoMapperConfig.cs` — exposes `services.CartAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

Read-only visibility via Abandoned Carts (SCR-06-14)

## Storefront surfaces

Modules 07 Cart, 08 Checkout

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Cart/`. Naming convention:

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
