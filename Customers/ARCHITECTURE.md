# Module: Customers

**Admin module #:** 02
**API base paths:** `api/customers, api/segments, api/wishlist, api/rewards`

Storefront customer accounts, addresses, segments, reward points, wishlist and consent.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Customers/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       CustomersConfig.cs (DI) + CustomersAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Customer.cs`
- `CustomerAddress.cs`
- `CustomerNote.cs`
- `CustomerTag.cs`
- `Segment.cs`
- `SegmentRule.cs`
- `SegmentMember.cs`
- `RewardPoint.cs`
- `RewardPointTransaction.cs`
- `Wishlist.cs`
- `WishlistItem.cs`
- `ConsentLog.cs`
- `CustomerSession.cs`

## Domain/IServices

- `ICustomerService.cs`
- `ICustomerAddressService.cs`
- `ISegmentService.cs`
- `IRewardPointService.cs`
- `IWishlistService.cs`
- `IConsentService.cs`

## Application/Services

- `CustomerService.cs`
- `CustomerAddressService.cs`
- `SegmentService.cs`
- `RewardPointService.cs`
- `WishlistService.cs`
- `ConsentService.cs`

## Infrastructure/Repositories

- `CustomerRepository.cs`
- `CustomerAddressRepository.cs`
- `SegmentRepository.cs`
- `RewardPointRepository.cs`
- `WishlistRepository.cs`
- `ConsentRepository.cs`

## Application/Extentions

- `CustomersConfig.cs` — exposes `services.AddCustomersModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `CustomersAutoMapperConfig.cs` — exposes `services.CustomersAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-02-08..12 Customer List, Customer 360, Create/Edit, Segments, Segment Builder

## Storefront surfaces

Modules 01 Authentication, 06 Wishlist, 10 My Account, 16 Rewards

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Customers/`. Naming convention:

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
