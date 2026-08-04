# Persistence

Holds the aggregate EF Core `DbContext` and its entity configurations. It is the only
project that references **all** module projects, which keeps the modules free of
references to each other.

Referenced by `ChamundaHandicraft.API` only.

---

## Why EF is here at all

Day-to-day reads and writes go through **Dapper + stored procedures** inside each
module's `Infrastructure/Repositories`. EF exists for three narrow jobs:

1. **Schema as code** — migrations generate and version the database.
2. **Reporting and admin tooling** — ad-hoc LINQ where a stored procedure would be
   overkill, such as the custom report builder.
3. **Seeding** — reference data and the first Super Admin.

Business logic never depends on EF change tracking.

---

## Folder layout

```
Persistence/
├─ Context/
│  ├─ ChamundaHandicraftDbContext.cs        DbSet<> for every module entity
│  └─ ChamundaHandicraftDbContext.Audit.cs  SaveChanges override stamping audit columns
├─ Configurations/    IEntityTypeConfiguration<T>, one file per entity, grouped by module
├─ Interceptors/      SoftDeleteInterceptor, AuditStampInterceptor
└─ Seed/              Roles, permission catalog, countries/states/cities, currencies,
                      tax classes, reason codes, default settings, Super Admin
```

---

## Global conventions applied in `OnModelCreating`

- Global query filter `!IsDeleted` on every entity implementing `ISoftDeletable`.
- `decimal(18,2)` for money, `decimal(18,4)` for rates and quantities.
- `datetime2` for all timestamps, stored in UTC.
- Every foreign key `DeleteBehavior.Restrict` — soft delete is the only delete.
- Unique indexes on the natural keys: `Product.ProductCode`, `ProductVariant.Sku`,
  `Category.Slug`, `Order.OrderNumber`, `Coupon.Code`, `Customer.Email`,
  `Customer.Mobile`, `CmsPage.Slug`, `BlogPost.Slug`.

## Audit columns on every entity

`CreatedAt`, `CreatedBy`, `UpdatedAt`, `UpdatedBy`, `IsActive`, `IsDeleted`.
Stamped by `AuditStampInterceptor` for EF writes and by the stored procedure's
`@LoggedInUserId` parameter for Dapper writes.
