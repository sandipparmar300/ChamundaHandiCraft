# Module: Promotions

**Admin module #:** 09,10
**API base paths:** `api/coupons, api/offers`

Coupons and offers: conditions, applicability scope, tiers, combos, flash sales and redemption tracking.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Promotions/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       PromotionsConfig.cs (DI) + PromotionsAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Coupon.cs`
- `CouponCode.cs`
- `CouponCondition.cs`
- `CouponApplicability.cs`
- `CouponRedemption.cs`
- `Offer.cs`
- `OfferRule.cs`
- `OfferScope.cs`
- `OfferTier.cs`
- `Combo.cs`
- `ComboItem.cs`
- `FlashSale.cs`
- `OfferRedemption.cs`
- `PromotionCampaign.cs`

## Domain/IServices

- `ICouponService.cs`
- `ICouponRedemptionService.cs`
- `IOfferService.cs`
- `IComboService.cs`
- `IFlashSaleService.cs`

## Application/Services

- `CouponService.cs`
- `CouponRedemptionService.cs`
- `OfferService.cs`
- `ComboService.cs`
- `FlashSaleService.cs`

## Infrastructure/Repositories

- `CouponRepository.cs`
- `CouponRedemptionRepository.cs`
- `OfferRepository.cs`
- `ComboRepository.cs`
- `FlashSaleRepository.cs`

## Application/Extentions

- `PromotionsConfig.cs` — exposes `services.AddPromotionsModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `PromotionsAutoMapperConfig.cs` — exposes `services.PromotionsAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-09-01..06 Coupons, Coupon Editor, Performance, Redemption Log, Bulk Generator; SCR-10-01..08 Offers, Editor, Combo Builder, Flash Sales, Calendar, Conflict Checker

## Storefront surfaces

Price badges on PLP/PDP, coupon apply in Cart/Checkout

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Promotions/`. Naming convention:

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
