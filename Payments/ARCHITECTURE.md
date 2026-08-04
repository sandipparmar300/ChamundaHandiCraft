# Module: Payments

**Admin module #:** 07
**API base paths:** `api/payments, api/refunds, api/settlements, api/disputes`

Payment transactions, gateway configuration, refunds, settlements, disputes and COD collection.

---

## Layer layout

This module follows the platform-wide vertical-slice layout. Nothing here references
another module project — cross-module reads go through the API layer or a shared
read model, never a direct project reference.

```
Payments/
├─ Domain/
│  ├─ Entities/        POCO entities mapped 1:1 to MSSQL tables
│  └─ IServices/       Repository contracts (I*Service) consumed by Application
├─ Application/
│  ├─ Services/        Orchestration, validation, mapping, business rules
│  ├─ Profiles/        AutoMapper Profile classes (Entity <-> ViewModel)
│  └─ Extentions/       PaymentsConfig.cs (DI) + PaymentsAutoMapperConfig.cs
└─ Infrastructure/
   └─ Repositories/    Dapper implementations calling stored procedures
```

## Domain/Entities

- `Payment.cs`
- `PaymentEvent.cs`
- `PaymentMethod.cs`
- `PaymentGateway.cs`
- `GatewayCredential.cs`
- `Refund.cs`
- `RefundApproval.cs`
- `Settlement.cs`
- `SettlementLine.cs`
- `Dispute.cs`
- `DisputeEvidence.cs`
- `PaymentLink.cs`
- `CodCollection.cs`

## Domain/IServices

- `IPaymentService.cs`
- `IRefundService.cs`
- `ISettlementService.cs`
- `IDisputeService.cs`
- `IPaymentGatewayService.cs`

## Application/Services

- `PaymentService.cs`
- `RefundService.cs`
- `SettlementService.cs`
- `DisputeService.cs`
- `PaymentGatewayService.cs`

## Infrastructure/Repositories

- `PaymentRepository.cs`
- `RefundRepository.cs`
- `SettlementRepository.cs`
- `DisputeRepository.cs`
- `PaymentGatewayRepository.cs`

## Application/Extentions

- `PaymentsConfig.cs` — exposes `services.AddPaymentsModule()`, registering each
  Application service and binding every `I*Service` contract to its Dapper repository.
- `PaymentsAutoMapperConfig.cs` — exposes `services.PaymentsAutoMapper()`, registering
  the profiles in this assembly.

Both are called from `ChamundaHandicraft.API/ServiceExtension.cs`.

## Admin surfaces

SCR-07-01..08 Transactions, Transaction Detail, Refunds, Refund Detail, Settlements, Disputes, Payment Gateways

## Storefront surfaces

Module 09 Payment

## Stored procedures

SQL lives in `DatabaseScripts/02-StoredProcedures/Payments/`. Naming convention:

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
