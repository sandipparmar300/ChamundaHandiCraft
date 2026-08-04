# Module: Orders

**Admin module #:** 06
**API base paths:** `api/orders, api/returns, api/invoices`

Orders, order items, fulfilment, status history, returns, exchanges, invoices and abandoned carts.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Orders/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       OrdersConfig.cs (DI) + OrdersAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Order.cs`
- `OrderItem.cs`
- `OrderItemFulfilment.cs`
- `OrderStatusHistory.cs`
- `OrderAddress.cs`
- `OrderDiscount.cs`
- `OrderTax.cs`
- `OrderTag.cs`
- `OrderNote.cs`
- `OrderCommunication.cs`
- `OrderAssignment.cs`
- `Return.cs`
- `ReturnItem.cs`
- `ReturnInspection.cs`
- `Exchange.cs`
- `AbandonedCart.cs`
- `Invoice.cs`
- `InvoiceSequence.cs`

## Domain/IServices

- `IOrderService.cs`
- `IOrderItemService.cs`
- `IFulfilmentService.cs`
- `IReturnService.cs`
- `IExchangeService.cs`
- `IInvoiceService.cs`
- `IAbandonedCartService.cs`

## Application/Services

- `OrderService.cs`
- `OrderItemService.cs`
- `FulfilmentService.cs`
- `ReturnService.cs`
- `ExchangeService.cs`
- `InvoiceService.cs`
- `AbandonedCartService.cs`

## Infrastructure/Repositories

- `OrderRepository.cs`
- `OrderItemRepository.cs`
- `FulfilmentRepository.cs`
- `ReturnRepository.cs`
- `ExchangeRepository.cs`
- `InvoiceRepository.cs`
- `AbandonedCartRepository.cs`

## Application/Extentions

- `OrdersConfig.cs` — exposes `services.AddOrdersModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `OrdersAutoMapperConfig.cs` — exposes `services.OrdersAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-06-01..14 Order Queue, Order Detail, Manual Create, Edit, Pick List, Packing Station, Dispatch Manifest, Returns, Invoices, Kanban Board, Abandoned Carts

## Storefront surfaces

Modules 11 Orders, 12 Order Tracking

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Orders/`. Naming convention:

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
