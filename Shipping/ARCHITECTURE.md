# Module: Shipping

**Admin module #:** 08
**API base paths:** `api/shipping, api/couriers, api/shipments`

Shipping zones and rates, couriers, shipments, tracking events, exceptions and manifests.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Shipping/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       ShippingConfig.cs (DI) + ShippingAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Shipment.cs`
- `ShipmentPackage.cs`
- `TrackingEvent.cs`
- `DeliveryException.cs`
- `Manifest.cs`
- `ShippingZone.cs`
- `ZoneRegion.cs`
- `ZonePinRange.cs`
- `ShippingRate.cs`
- `Courier.cs`
- `CourierService.cs`
- `CourierServiceability.cs`
- `BoxType.cs`

## Domain/IServices

- `IShipmentService.cs`
- `IShippingZoneService.cs`
- `IShippingRateService.cs`
- `ICourierService.cs`
- `IManifestService.cs`
- `ITrackingService.cs`

## Application/Services

- `ShipmentService.cs`
- `ShippingZoneService.cs`
- `ShippingRateService.cs`
- `CourierService.cs`
- `ManifestService.cs`
- `TrackingService.cs`

## Infrastructure/Repositories

- `ShipmentRepository.cs`
- `ShippingZoneRepository.cs`
- `ShippingRateRepository.cs`
- `CourierRepository.cs`
- `ManifestRepository.cs`
- `TrackingRepository.cs`

## Application/Extentions

- `ShippingConfig.cs` — exposes `services.AddShippingModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `ShippingAutoMapperConfig.cs` — exposes `services.ShippingAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-08-01..10 Shipping Overview, Zones, Zone Editor, Couriers, Courier Config, Shipments, Shipment Detail, Exceptions, Manifests, Packaging Master

## Storefront surfaces

Delivery estimate on PDP/Cart/Checkout, Module 12 Order Tracking

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Shipping/`. Naming convention:

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
