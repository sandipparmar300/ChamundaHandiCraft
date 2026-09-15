/* =============================================================================
   2026-08-12_01_ForeignKeyIndexes.sql
   -----------------------------------------------------------------------------
   Adds four missing indexes on foreign-key columns that back documented queries.

   Why a patch and not an edit to 01-Schema
   ----------------------------------------
   DatabaseScripts/README.md: "Never edit a script in 01-Schema after it has been
   applied to a shared environment. Add a dated file to 04-Patches instead."
   The schema has now been applied, so this is the correct place.

   Why only four
   -------------
   A post-deployment audit found 188 foreign-key columns with no leading index.
   Indexing all of them would violate the "do not create excessive indexes"
   rule: most are audit-style parents (CreatedBy, ModeratedBy, ReasonId) or
   lookups that are only ever traversed parent-to-child, where the child's
   existing indexes already serve the join. Every index also costs write
   throughput on the order path, which is the hottest path in the system.

   These four are different: each one is the driving predicate of a screen or
   report named in the specs, and each sits on a table that grows without bound.

   Deliberately NOT indexed, with reasons:
     Orders.CouponId          Coupon redemption history reads dbo.CouponRedemptions,
                              which already has its own covering index.
     OrderItems.ArtisanId     Artisan sales reporting aggregates over a date range,
                              so it scans regardless; the index would not be seeked.
     Orders.InvoiceId         1:1 and always reached from the Orders side.
     Orders.CartId /
       CheckoutSessionId      Diagnostic joins only, run by hand, never in a screen.
     *.CreatedBy / UpdatedBy  Audit provenance. Displayed, never filtered on.
   ============================================================================= */

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------------
   1. Payments.CustomerId
      Users.txt "Customer Profile" shows the customer's payment history, and
      Payments.txt §11 allows searching transactions by customer.
      dbo.Payments grows one row per payment attempt, so this is unbounded.
   --------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Payments_Customer' AND object_id = OBJECT_ID(N'dbo.Payments'))
BEGIN
    CREATE INDEX IX_Payments_Customer ON dbo.Payments (CustomerId, CreatedAt DESC)
        INCLUDE (OrderId, Amount, Status, Method, PaidOn)
        WHERE CustomerId IS NOT NULL AND IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   2. Notifications.NotificationEventId
      Notification.txt §15 reports delivery and failure rates per event
      ("Most Used Template", "Channel Performance"). dbo.Notifications is the
      highest-volume table in the communications module - one row per recipient
      per channel per event.
   --------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Notifications_Event' AND object_id = OBJECT_ID(N'dbo.Notifications'))
BEGIN
    CREATE INDEX IX_Notifications_Event ON dbo.Notifications (NotificationEventId, CreatedAt DESC)
        INCLUDE (Channel, Status)
        WHERE NotificationEventId IS NOT NULL AND IsDeleted = 0;
END
GO

/* ---------------------------------------------------------------------------
   3. CampaignEvents.SubscriberId
      NewsLetter.txt §11 reports per-subscriber engagement, and the suppression
      logic checks whether an address has complained or hard-bounced before.
      One row per open, click and bounce - the fastest-growing table here.
   --------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CampaignEvents_Subscriber' AND object_id = OBJECT_ID(N'dbo.CampaignEvents'))
BEGIN
    CREATE INDEX IX_CampaignEvents_Subscriber ON dbo.CampaignEvents (SubscriberId, EventType, OccurredAt DESC)
        WHERE SubscriberId IS NOT NULL;
END
GO

/* ---------------------------------------------------------------------------
   4. InventoryTransactions.WarehouseId
      Inventory.txt §13 - the inventory ledger is filtered by warehouse, and
      §19 produces a per-warehouse stock movement report. Every stock movement
      writes a row here, so it grows faster than any other inventory table.
   --------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_InventoryTransactions_Warehouse' AND object_id = OBJECT_ID(N'dbo.InventoryTransactions'))
BEGIN
    CREATE INDEX IX_InventoryTransactions_Warehouse ON dbo.InventoryTransactions (WarehouseId, CreatedAt DESC)
        INCLUDE (ProductId, VariantId, TransactionType, QuantityChange, QuantityAfter);
END
GO
