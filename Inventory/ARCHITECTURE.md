# Module: Inventory

**Admin module #:** 05
**API base paths:** `api/inventory, api/warehouses, api/suppliers`

Stock levels, purchase entries, adjustments, transfers, stock takes, warehouses and suppliers.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Inventory/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       InventoryConfig.cs (DI) + InventoryAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Inventory.cs`
- `InventoryTransaction.cs`
- `PurchaseEntry.cs`
- `PurchaseEntryLine.cs`
- `StockAdjustment.cs`
- `DamageRecord.cs`
- `StockTransfer.cs`
- `StockTake.cs`
- `StockTakeLine.cs`
- `Warehouse.cs`
- `WarehouseBin.cs`
- `Supplier.cs`
- `LowStockAlert.cs`

## Domain/IServices

- `IInventoryService.cs`
- `IPurchaseEntryService.cs`
- `IStockAdjustmentService.cs`
- `IStockTransferService.cs`
- `IStockTakeService.cs`
- `IWarehouseService.cs`
- `ISupplierService.cs`

## Application/Services

- `InventoryService.cs`
- `PurchaseEntryService.cs`
- `StockAdjustmentService.cs`
- `StockTransferService.cs`
- `StockTakeService.cs`
- `WarehouseService.cs`
- `SupplierService.cs`

## Infrastructure/Repositories

- `InventoryRepository.cs`
- `PurchaseEntryRepository.cs`
- `StockAdjustmentRepository.cs`
- `StockTransferRepository.cs`
- `StockTakeRepository.cs`
- `WarehouseRepository.cs`
- `SupplierRepository.cs`

## Application/Extentions

- `InventoryConfig.cs` — exposes `services.AddInventoryModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `InventoryAutoMapperConfig.cs` — exposes `services.InventoryAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-05-01..14 Inventory Dashboard, Stock List/Ledger, Purchases, Adjustments, Damage Register, Transfers, Stock Take, Warehouses, Alerts, Barcodes

## Storefront surfaces

Stock badges on PDP/PLP, notify-me when out of stock

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Inventory/`. Naming convention:

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
