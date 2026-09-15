/* =============================================================================
   05-Views/01_Reporting_Views.sql
   -----------------------------------------------------------------------------
   Reporting views consumed by the Reports module (DatabaseScripts/README.md).

   These exist where the same join is written by several reports and getting it
   subtly different between them would produce two numbers for one question.
   They are NOT a second data model: no view here hides a business rule that the
   procedures do not also apply, and none is indexed (a materialised view would
   put write cost on the order path to save a read the rollups already serve).

   CREATE OR ALTER so the file is re-runnable, matching the procedure convention.
   ============================================================================= */

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------------
   vw_OrderRevenue - the single definition of "an order that counts as revenue".

   Dashboard.txt §18 and Reports.txt §20 both depend on this being consistent:
     * only Delivered (7) and Completed (8) count
     * refunds reduce it
     * tax is excluded from net
   Every sales, profit and customer report reads this rather than re-deciding.
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_OrderRevenue
AS
SELECT
    o.Id                AS OrderId,
    o.OrderNumber,
    o.CustomerId,
    o.PlacedOn,
    OrderDate           = CAST(o.PlacedOn AS DATE),
    o.Status,
    o.PaymentStatus,
    o.PaymentMethod,
    o.ItemCount,
    o.MrpTotal,
    o.SubTotal,
    o.CouponDiscount,
    o.OfferDiscount,
    o.PointsDiscount,
    DiscountTotal       = o.CouponDiscount + o.OfferDiscount + o.PointsDiscount,
    o.ShippingCost,
    o.CodFee,
    o.TaxTotal,
    o.Total,
    o.RefundedAmount,
    NetRevenue          = o.Total - o.TaxTotal - o.RefundedAmount,
    o.CurrencyCode,
    o.CouponCode,
    o.ShipToCity,
    o.ShipToPincode,
    o.SourceChannel,
    IsCod               = CAST(CASE WHEN o.PaymentMethod = 4 THEN 1 ELSE 0 END AS BIT)
FROM dbo.Orders AS o
WHERE o.Status IN (7, 8)
  AND o.IsDeleted = 0;
GO

/* ---------------------------------------------------------------------------
   vw_ProductStock - one row per product with stock summed across warehouses and
   the stock state resolved once.

   The state expression (In / Low / Out) appears on the admin grid, the PLP
   badge, the low-stock report and the reorder alert. Four copies would drift.
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_ProductStock
AS
SELECT
    p.Id                AS ProductId,
    p.Name              AS ProductName,
    p.Sku,
    p.ProductCode,
    p.Slug,
    p.Status,
    p.Price,
    p.Mrp,
    p.CostPrice,
    p.CategoryId,
    p.BrandId,
    p.ArtisanId,
    p.TrackInventory,
    OnHand              = ISNULL(s.OnHand, 0),
    Reserved            = ISNULL(s.Reserved, 0),
    Available           = ISNULL(s.Available, 0),
    Incoming            = ISNULL(s.Incoming, 0),
    LowStockThreshold   = ISNULL(s.LowStockThreshold, p.LowStockThreshold),
    WarehouseCount      = ISNULL(s.WarehouseCount, 0),
    StockValueAtCost    = ISNULL(s.OnHand, 0) * ISNULL(p.CostPrice, 0),
    StockValueAtPrice   = ISNULL(s.OnHand, 0) * p.Price,
    StockState          = CASE
                            WHEN p.TrackInventory = 0                       THEN 'NotTracked'
                            WHEN ISNULL(s.Available, 0) <= 0                THEN 'OutOfStock'
                            WHEN ISNULL(s.Available, 0)
                                 <= ISNULL(s.LowStockThreshold, p.LowStockThreshold) THEN 'LowStock'
                            ELSE 'InStock'
                          END
FROM dbo.Products AS p
LEFT JOIN (
    SELECT  ProductId,
            OnHand            = SUM(OnHand),
            Reserved          = SUM(Reserved),
            Available         = SUM(OnHand - Reserved),
            Incoming          = SUM(Incoming),
            LowStockThreshold = MAX(LowStockThreshold),
            WarehouseCount    = COUNT(DISTINCT WarehouseId)
    FROM    dbo.InventoryStocks
    WHERE   IsDeleted = 0
    GROUP   BY ProductId
) AS s ON s.ProductId = p.Id
WHERE p.IsDeleted = 0;
GO

/* ---------------------------------------------------------------------------
   vw_ProductSales - units and revenue per product, from the purchase-time
   snapshot on OrderItems.

   Deliberately reads oi.UnitPrice and oi.LineTotal, never p.Price: a product
   repriced last week must not restate last year's sales (prompt §21).
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_ProductSales
AS
SELECT
    oi.ProductId,
    ProductName         = MAX(oi.ProductName),
    Sku                 = MAX(oi.Sku),
    OrderCount          = COUNT(DISTINCT oi.OrderId),
    UnitsSold           = SUM(oi.Quantity - oi.QuantityCancelled),
    UnitsReturned       = SUM(oi.QuantityReturned),
    GrossRevenue        = SUM(oi.LineTotal),
    DiscountGiven       = SUM(oi.LineDiscount),
    TaxCollected        = SUM(oi.TaxAmount),
    NetRevenue          = SUM(oi.LineTotal - oi.TaxAmount),
    AverageSellingPrice = CASE WHEN SUM(oi.Quantity - oi.QuantityCancelled) > 0
                               THEN ROUND(SUM(oi.LineTotal) / SUM(oi.Quantity - oi.QuantityCancelled), 2)
                               ELSE 0 END,
    FirstSoldOn         = MIN(o.PlacedOn),
    LastSoldOn          = MAX(o.PlacedOn)
FROM dbo.OrderItems AS oi
JOIN dbo.vw_OrderRevenue AS o ON o.OrderId = oi.OrderId
GROUP BY oi.ProductId;
GO

/* ---------------------------------------------------------------------------
   vw_CustomerLifetime - the figures behind the customer report and CLV.
   Reads vw_OrderRevenue so "spend" means the same thing everywhere.
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_CustomerLifetime
AS
SELECT
    c.Id                AS CustomerId,
    c.FullName,
    c.Email,
    c.Phone,
    c.Status,
    c.RegisteredOn,
    c.LastLoginOn,
    c.RewardPointBalance,
    c.RewardTier,
    OrderCount          = ISNULL(o.OrderCount, 0),
    LifetimeValue       = ISNULL(o.NetRevenue, 0),
    AverageOrderValue   = CASE WHEN ISNULL(o.OrderCount, 0) > 0
                               THEN ROUND(o.NetRevenue / o.OrderCount, 2) ELSE 0 END,
    FirstOrderOn        = o.FirstOrderOn,
    LastOrderOn         = o.LastOrderOn,
    DaysSinceLastOrder  = CASE WHEN o.LastOrderOn IS NOT NULL
                               THEN DATEDIFF(DAY, o.LastOrderOn, SYSUTCDATETIME()) END,
    ReviewCount         = ISNULL(r.ReviewCount, 0),
    WishlistItemCount   = ISNULL(w.ItemCount, 0),
    OpenTicketCount     = ISNULL(t.OpenTickets, 0),
    /* Simple, explainable segmentation. Anything cleverer belongs in the
       Reports module where it can be tuned without a schema change. */
    Segment             = CASE
                            WHEN ISNULL(o.OrderCount, 0) = 0 THEN 'Registered'
                            WHEN o.LastOrderOn < DATEADD(DAY, -180, SYSUTCDATETIME()) THEN 'Lapsed'
                            WHEN o.OrderCount >= 5 OR o.NetRevenue >= 25000 THEN 'VIP'
                            WHEN o.OrderCount > 1 THEN 'Repeat'
                            ELSE 'New'
                          END
FROM dbo.Customers AS c
LEFT JOIN (
    SELECT  CustomerId,
            OrderCount   = COUNT(*),
            NetRevenue   = SUM(NetRevenue),
            FirstOrderOn = MIN(PlacedOn),
            LastOrderOn  = MAX(PlacedOn)
    FROM    dbo.vw_OrderRevenue
    WHERE   CustomerId IS NOT NULL
    GROUP   BY CustomerId
) AS o ON o.CustomerId = c.Id
LEFT JOIN (
    SELECT CustomerId, ReviewCount = COUNT(*)
    FROM   dbo.Reviews
    WHERE  IsDeleted = 0 AND CustomerId IS NOT NULL
    GROUP  BY CustomerId
) AS r ON r.CustomerId = c.Id
LEFT JOIN (
    SELECT wl.CustomerId, ItemCount = COUNT(wi.Id)
    FROM   dbo.Wishlists AS wl
    /* WishlistItems is a plain link table - it carries no soft-delete flag,
       because removing an item from a wishlist is a real delete. */
    LEFT JOIN dbo.WishlistItems AS wi ON wi.WishlistId = wl.Id
    WHERE  wl.IsDeleted = 0
    GROUP  BY wl.CustomerId
) AS w ON w.CustomerId = c.Id
LEFT JOIN (
    SELECT CustomerId, OpenTickets = COUNT(*)
    FROM   dbo.SupportTickets
    WHERE  IsDeleted = 0 AND Status IN (0,1,2,3,6) AND CustomerId IS NOT NULL
    GROUP  BY CustomerId
) AS t ON t.CustomerId = c.Id
WHERE c.IsDeleted = 0;
GO

/* ---------------------------------------------------------------------------
   vw_GstSummary - invoice-level GST, flattened from the per-line components.
   The GST filing report and the tax audit report both read this, so the
   CGST/SGST/IGST pivot is written once.
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_GstSummary
AS
SELECT
    t.OrderId,
    o.OrderNumber,
    OrderDate       = CAST(o.PlacedOn AS DATE),
    InvoiceNumber   = i.InvoiceNumber,
    InvoiceDate     = i.InvoiceDate,
    CustomerGstin   = i.CustomerGstin,
    PlaceOfSupply   = MAX(t.PlaceOfSupply),
    IsInterState    = MAX(CAST(t.IsInterState AS TINYINT)),
    HsnCode         = t.HsnCode,
    TaxableValue    = SUM(t.TaxableAmount),
    Cgst            = SUM(CASE WHEN t.TaxComponent = 'CGST' THEN t.TaxAmount ELSE 0 END),
    Sgst            = SUM(CASE WHEN t.TaxComponent IN ('SGST','UTGST') THEN t.TaxAmount ELSE 0 END),
    Igst            = SUM(CASE WHEN t.TaxComponent = 'IGST' THEN t.TaxAmount ELSE 0 END),
    Cess            = SUM(CASE WHEN t.TaxComponent = 'CESS' THEN t.TaxAmount ELSE 0 END),
    TotalTax        = SUM(t.TaxAmount)
FROM dbo.OrderItemTaxes AS t
JOIN dbo.Orders   AS o ON o.Id = t.OrderId
LEFT JOIN dbo.Invoices AS i ON i.Id = o.InvoiceId AND i.IsDeleted = 0
WHERE o.Status NOT IN (9, 14)
  AND o.IsDeleted = 0
GROUP BY t.OrderId, o.OrderNumber, CAST(o.PlacedOn AS DATE),
         i.InvoiceNumber, i.InvoiceDate, i.CustomerGstin, t.HsnCode;
GO

/* ---------------------------------------------------------------------------
   vw_LowStockAlert - what the low-stock job emails and the dashboard card
   counts. Inventory.txt §11: alert when Available <= threshold.
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_LowStockAlert
AS
SELECT
    s.ProductId,
    s.ProductName,
    s.Sku,
    s.Available,
    s.OnHand,
    s.Reserved,
    s.Incoming,
    s.LowStockThreshold,
    s.StockState,
    s.CategoryId,
    s.BrandId,
    UnitsShort      = CASE WHEN s.LowStockThreshold > s.Available
                           THEN s.LowStockThreshold - s.Available ELSE 0 END,
    /* Ordering signal: a fast seller that is out ranks a slow one that is low. */
    UnitsSold90Days = ISNULL(recent.Units, 0),
    Urgency         = CASE WHEN s.StockState = 'OutOfStock' AND ISNULL(recent.Units, 0) > 0 THEN 1
                           WHEN s.StockState = 'OutOfStock'                                 THEN 2
                           WHEN ISNULL(recent.Units, 0) > 0                                 THEN 3
                           ELSE 4 END
FROM dbo.vw_ProductStock AS s
LEFT JOIN (
    SELECT  oi.ProductId, Units = SUM(oi.Quantity - oi.QuantityCancelled)
    FROM    dbo.OrderItems AS oi
    JOIN    dbo.vw_OrderRevenue AS o ON o.OrderId = oi.OrderId
    WHERE   o.PlacedOn >= DATEADD(DAY, -90, SYSUTCDATETIME())
    GROUP   BY oi.ProductId
) AS recent ON recent.ProductId = s.ProductId
WHERE s.TrackInventory = 1
  AND s.Status = 1                       -- published products only
  AND s.StockState IN ('LowStock', 'OutOfStock');
GO

/* ---------------------------------------------------------------------------
   vw_ReviewModerationQueue - the review grid with the joins it always needs.
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_ReviewModerationQueue
AS
SELECT
    r.Id                AS ReviewId,
    r.ProductId,
    ProductName         = p.Name,
    ProductSlug         = p.Slug,
    r.CustomerId,
    r.AuthorName,
    r.Rating,
    r.Title,
    r.Body,
    r.IsVerifiedPurchase,
    r.IsAnonymous,
    r.Status,
    StatusName          = CASE r.Status WHEN 0 THEN 'Pending'
                                        WHEN 1 THEN 'Approved'
                                        WHEN 2 THEN 'Rejected'
                                        WHEN 3 THEN 'Hidden' END,
    r.AbuseReportCount,
    r.HelpfulCount,
    r.MediaCount,
    r.SubmittedOn,
    r.ModeratedOn,
    r.ModeratedByName,
    ModerationReason    = rc.Label,
    OrderNumber         = o.OrderNumber,
    HasReply            = CAST(CASE WHEN EXISTS (SELECT 1 FROM dbo.ReviewReplies AS rr
                                                 WHERE rr.ReviewId = r.Id AND rr.IsDeleted = 0)
                                    THEN 1 ELSE 0 END AS BIT),
    /* Review.txt §16 - a one-star review raises an admin alert. */
    NeedsAttention      = CAST(CASE WHEN r.Status = 0 OR r.AbuseReportCount > 0 OR r.Rating = 1
                                    THEN 1 ELSE 0 END AS BIT)
FROM dbo.Reviews AS r
JOIN dbo.Products AS p ON p.Id = r.ProductId
LEFT JOIN dbo.Orders AS o ON o.Id = r.OrderId
LEFT JOIN dbo.ReasonCodes AS rc ON rc.Id = r.ModerationReasonId
WHERE r.IsDeleted = 0;
GO
