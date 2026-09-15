/* =============================================================================
   usp_Order_GetById  /  usp_Order_GetTracking  /  usp_Order_GetCustomerOrders
   -----------------------------------------------------------------------------
   The order detail page, the customer tracking timeline, and order history.

   Specs:
     Orders.txt §15         order detail sections
     Orders.txt §16         the timeline
     Order Tracking.txt §5  the customer-facing timeline stages
     My Account.txt §7      order history with filters and sorting

   Every column served here comes from the purchase-time snapshot on
   dbo.OrderItems and dbo.OrderAddresses, never from a live join back to
   Products or CustomerAddresses. That is what makes an old order still render
   correctly after a rename, a re-price or a product deletion
   (prompt §21, Orders.txt §23).
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Order_GetById
    @OrderId        INT             = NULL,
    @OrderNumber    VARCHAR(32)     = NULL,
    /* When supplied, the order must belong to this customer. Order Tracking.txt
       §17: "Customers can only view their own orders." Passing it makes the
       ownership check part of the query rather than a caller responsibility. */
    @CustomerId     INT             = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @OrderId IS NULL AND @OrderNumber IS NULL
        RETURN;

    DECLARE @Id INT;

    SELECT @Id = o.Id
    FROM   dbo.Orders AS o
    WHERE  (@OrderId     IS NULL OR o.Id          = @OrderId)
      AND  (@OrderNumber IS NULL OR o.OrderNumber = @OrderNumber)
      AND  (@CustomerId  IS NULL OR o.CustomerId  = @CustomerId)
      AND  o.IsDeleted = 0;

    IF @Id IS NULL
        RETURN;

    -- 1. Header
    SELECT
        o.Id, o.OrderNumber, o.CustomerId, o.PlacedOn,
        o.CustomerName, o.CustomerEmail, o.CustomerPhone,
        o.Status, o.PaymentStatus, o.PaymentMethod,
        o.SubTotal, o.MrpTotal, o.CouponCode, o.CouponDiscount, o.OfferDiscount,
        o.PointsRedeemed, o.PointsDiscount, o.ShippingCost, o.CodFee,
        o.GiftWrapCost, o.TaxTotal, o.IsTaxInclusive, o.Total,
        o.RefundedAmount, o.CurrencyCode, o.ItemCount, o.PointsEarned,
        o.GiftWrapSelected, o.GiftMessage, o.CustomerNote,
        o.ShipToCity, o.ShipToPincode, o.CourierName, o.TrackingNumber,
        o.DeliveryBy, o.ShippedOn, o.DeliveredOn, o.CancelledOn, o.CancelNote,
        o.HasReturnRequest, o.InvoiceId, o.SourceChannel,
        o.CreatedAt, o.UpdatedAt,
        InvoiceNumber = i.InvoiceNumber,
        InvoicePdfUrl = i.PdfUrl,
        TotalSavings  = (o.MrpTotal - o.SubTotal) + o.CouponDiscount + o.OfferDiscount + o.PointsDiscount
    FROM   dbo.Orders AS o
    LEFT JOIN dbo.Invoices AS i ON i.Id = o.InvoiceId
    WHERE  o.Id = @Id;

    -- 2. Lines - snapshot columns only
    SELECT
        oi.Id, oi.ProductId, oi.VariantId,
        oi.ProductName, oi.Sku, oi.Slug, oi.VariantSummary,
        oi.ImageUrl, oi.ImageAlt, oi.ArtisanName, oi.HsnCode,
        oi.Quantity, oi.UnitPrice, oi.UnitMrp, oi.LineDiscount,
        oi.TaxPercent, oi.TaxAmount, oi.LineTotal,
        oi.QuantityShipped, oi.QuantityReturned, oi.QuantityCancelled,
        oi.ReviewRequestedAt, oi.ReviewId,
        /* Product Detail.txt: "Write Review (After Delivery)" - the button is
           enabled only once delivered and not already reviewed. */
        CanReview = CASE WHEN oi.ReviewId IS NULL
                          AND EXISTS (SELECT 1 FROM dbo.Orders x
                                      WHERE x.Id = oi.OrderId AND x.Status IN (7,8))
                         THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
    FROM   dbo.OrderItems AS oi
    WHERE  oi.OrderId = @Id
    ORDER  BY oi.Id;

    -- 3. Addresses (billing + shipping snapshots)
    SELECT
        oa.Id, oa.AddressKind, oa.LabelType, oa.FullName, oa.Phone, oa.AlternatePhone,
        oa.Line1, oa.Line2, oa.Landmark, oa.CityName, oa.StateName,
        oa.CountryName, oa.Pincode, oa.GstStateCode, oa.Gstin
    FROM   dbo.OrderAddresses AS oa
    WHERE  oa.OrderId = @Id
    ORDER  BY oa.AddressKind;

    -- 4. Timeline - Orders.txt §16, Order Tracking.txt §5
    SELECT
        h.Id, h.FromStatus, h.ToStatus, h.Note, h.Location,
        h.CourierName, h.TrackingNumber, h.EstimatedDelivery,
        h.CustomerNotified, h.IsSystemGenerated,
        h.ChangedByName, h.ChangedAt
    FROM   dbo.OrderStatusHistories AS h
    WHERE  h.OrderId = @Id
    ORDER  BY h.ChangedAt, h.Id;

    -- 5. Payments
    SELECT
        p.Id, p.TransactionId, p.GatewayName, p.GatewayReference,
        p.Amount, p.CurrencyCode, p.Method, p.Status,
        p.InstrumentLabel, p.Bank, p.FailureReason,
        p.AuthorisedOn, p.PaidOn, p.RefundedAmount, p.CreatedAt
    FROM   dbo.Payments AS p
    WHERE  p.OrderId = @Id
      AND  p.IsDeleted = 0
    ORDER  BY p.CreatedAt DESC;

    -- 6. Shipments and their tracking events
    SELECT
        s.Id, s.AwbNumber, s.CourierName, s.Status, s.ServiceLevel,
        s.DestinationCity, s.DestinationPincode, s.WeightKg,
        s.ShippingCost, s.CodAmount, s.LabelUrl,
        s.PromisedBy, s.PickedUpOn, s.DeliveredOn,
        s.FailureReason, s.AttemptCount, s.IsReversePickup
    FROM   dbo.Shipments AS s
    WHERE  s.OrderId = @Id
      AND  s.IsDeleted = 0
    ORDER  BY s.CreatedAt;

    SELECT
        e.Id, e.ShipmentId, e.Status, e.StatusText,
        e.Location, e.Remarks, e.OccurredAt
    FROM   dbo.ShipmentTrackingEvents AS e
    JOIN   dbo.Shipments AS s ON s.Id = e.ShipmentId
    WHERE  s.OrderId = @Id
    ORDER  BY e.OccurredAt DESC, e.Id DESC;

    -- 7. Internal + customer notes - Orders.txt §15
    SELECT
        n.Id, n.Body, n.IsInternal, n.AuthorName, n.CreatedAt
    FROM   dbo.OrderNotes AS n
    WHERE  n.OrderId = @Id
      AND  n.IsDeleted = 0
    ORDER  BY n.CreatedAt DESC;

    -- 8. Tax breakdown by component - Reports.txt §9, invoice rendering
    SELECT
        t.TaxComponent,
        TaxRate       = MAX(t.TaxRate),
        TaxableAmount = SUM(t.TaxableAmount),
        TaxAmount     = SUM(t.TaxAmount),
        PlaceOfSupply = MAX(t.PlaceOfSupply),
        IsInterState  = MAX(CAST(t.IsInterState AS TINYINT))
    FROM   dbo.OrderItemTaxes AS t
    WHERE  t.OrderId = @Id
    GROUP  BY t.TaxComponent
    ORDER  BY t.TaxComponent;

    -- 9. Returns raised against this order
    SELECT
        r.Id, r.RmaNumber, r.Status, r.RequestedOn,
        r.ReasonCodeId, r.Reason, r.Resolution, r.CustomerNote,
        r.RefundAmount, r.PickupScheduledOn, r.PickedUpOn, r.ReceivedOn,
        r.IsRestocked, r.RejectionReason
    FROM   dbo.ReturnRequests AS r
    WHERE  r.OrderId = @Id
      AND  r.IsDeleted = 0
    ORDER  BY r.RequestedOn DESC;
END
GO


/* =============================================================================
   usp_Order_GetTracking
   -----------------------------------------------------------------------------
   The lean read behind Order Tracking.txt: the timeline and courier details
   only. Kept separate from usp_Order_GetById because the tracking page polls,
   and it must not drag nine result sets across the wire each time.

   Accessible either by (OrderNumber + CustomerId) for a signed-in shopper, or by
   (OrderNumber + Email/Phone) for a guest - the guest path is why the ownership
   test is inside the procedure.
   ============================================================================= */
GO

CREATE OR ALTER PROCEDURE dbo.usp_Order_GetTracking
    @OrderNumber    VARCHAR(32),
    @CustomerId     INT             = NULL,
    @ContactValue   NVARCHAR(256)   = NULL   -- email or phone, for guest tracking
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Id INT;

    SELECT @Id = o.Id
    FROM   dbo.Orders AS o
    WHERE  o.OrderNumber = @OrderNumber
      AND  o.IsDeleted = 0
      AND  (
             (@CustomerId IS NOT NULL AND o.CustomerId = @CustomerId)
             OR
             (@CustomerId IS NULL AND @ContactValue IS NOT NULL
              AND (o.CustomerEmail = @ContactValue OR o.CustomerPhone = @ContactValue))
           );

    IF @Id IS NULL
        RETURN;   -- not found, or not theirs: the caller renders the same message either way

    SELECT
        o.OrderNumber, o.PlacedOn, o.Status, o.PaymentStatus, o.PaymentMethod,
        o.Total, o.CurrencyCode, o.ItemCount,
        o.CourierName, o.TrackingNumber, o.DeliveryBy,
        o.ShippedOn, o.DeliveredOn, o.CancelledOn,
        o.ShipToCity, o.ShipToPincode,
        InvoiceNumber = i.InvoiceNumber,
        InvoicePdfUrl = i.PdfUrl,
        /* Order Tracking.txt §10: cancellation is allowed before dispatch. The
           storefront must not offer a button the API would reject. */
        CanCancel     = CASE WHEN o.Status IN (0,1,2,3) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
        CanReturn     = CASE WHEN o.Status = 7 AND o.HasReturnRequest = 0
                             THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
    FROM   dbo.Orders AS o
    LEFT JOIN dbo.Invoices AS i ON i.Id = o.InvoiceId
    WHERE  o.Id = @Id;

    SELECT
        h.FromStatus, h.ToStatus, h.Note, h.Location,
        h.CourierName, h.TrackingNumber, h.EstimatedDelivery, h.ChangedAt
    FROM   dbo.OrderStatusHistories AS h
    WHERE  h.OrderId = @Id
      /* Internal-only transitions are not shown to the shopper. */
      AND  h.ToStatus NOT IN (1, 14)
    ORDER  BY h.ChangedAt, h.Id;

    SELECT
        e.Status, e.StatusText, e.Location, e.Remarks, e.OccurredAt,
        s.AwbNumber, s.CourierName
    FROM   dbo.ShipmentTrackingEvents AS e
    JOIN   dbo.Shipments AS s ON s.Id = e.ShipmentId
    WHERE  s.OrderId = @Id
      AND  s.IsDeleted = 0
    ORDER  BY e.OccurredAt DESC, e.Id DESC;

    SELECT
        oi.ProductName, oi.Sku, oi.Slug, oi.VariantSummary, oi.ImageUrl, oi.ImageAlt,
        oi.Quantity, oi.UnitPrice, oi.LineDiscount, oi.LineTotal,
        oi.QuantityShipped, oi.QuantityReturned,
        CanReview = CASE WHEN oi.ReviewId IS NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
    FROM   dbo.OrderItems AS oi
    WHERE  oi.OrderId = @Id
    ORDER  BY oi.Id;
END
GO


/* =============================================================================
   usp_Order_GetCustomerOrders
   -----------------------------------------------------------------------------
   My Account.txt §7 - paged order history with status filter, search and sort.
   ============================================================================= */
GO

CREATE OR ALTER PROCEDURE dbo.usp_Order_GetCustomerOrders
    @CustomerId     INT,
    @StatusFilter   VARCHAR(24)     = NULL,   -- All|Processing|Packed|Shipped|Delivered|Cancelled|Returned
    @SearchText     NVARCHAR(300)   = NULL,   -- order number or product name
    @SortBy         VARCHAR(24)     = 'Latest',
    @PageSize       INT             = 10,
    @PageIndex      INT             = 1,
    @TotalRecords   INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageSize  IS NULL OR @PageSize  < 1 SET @PageSize  = 10;
    IF @PageIndex IS NULL OR @PageIndex < 1 SET @PageIndex = 1;
    SET @SearchText = NULLIF(LTRIM(RTRIM(ISNULL(@SearchText, N''))), N'');

    DECLARE @Matching TABLE (OrderId INT PRIMARY KEY);

    INSERT INTO @Matching (OrderId)
    SELECT o.Id
    FROM   dbo.Orders AS o
    WHERE  o.CustomerId = @CustomerId
      AND  o.IsDeleted = 0
      AND  (@StatusFilter IS NULL OR @StatusFilter = 'All'
            OR (@StatusFilter = 'Processing' AND o.Status IN (0,1,2))
            OR (@StatusFilter = 'Packed'     AND o.Status = 3)
            OR (@StatusFilter = 'Shipped'    AND o.Status IN (4,5,6))
            OR (@StatusFilter = 'Delivered'  AND o.Status IN (7,8))
            OR (@StatusFilter = 'Cancelled'  AND o.Status = 9)
            OR (@StatusFilter = 'Returned'   AND o.Status IN (10,11,12,13)))
      AND  (@SearchText IS NULL
            OR o.OrderNumber LIKE N'%' + @SearchText + N'%'
            OR EXISTS (SELECT 1 FROM dbo.OrderItems AS oi
                       WHERE oi.OrderId = o.Id
                         AND oi.ProductName LIKE N'%' + @SearchText + N'%'));

    SELECT @TotalRecords = COUNT(*) FROM @Matching;

    SELECT
        o.Id, o.OrderNumber, o.PlacedOn, o.Status, o.PaymentStatus,
        o.PaymentMethod, o.Total, o.CurrencyCode, o.ItemCount,
        o.CourierName, o.TrackingNumber, o.DeliveryBy, o.DeliveredOn,
        InvoiceNumber = i.InvoiceNumber,
        InvoicePdfUrl = i.PdfUrl,
        CanCancel     = CASE WHEN o.Status IN (0,1,2,3) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
        CanReturn     = CASE WHEN o.Status = 7 AND o.HasReturnRequest = 0
                             THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
        /* Thumbnail strip on the order card. */
        PreviewImageUrl = pv.ImageUrl,
        FirstProductName = pv.ProductName
    FROM   dbo.Orders AS o
    JOIN   @Matching AS m ON m.OrderId = o.Id
    LEFT JOIN dbo.Invoices AS i ON i.Id = o.InvoiceId
    OUTER APPLY (
        SELECT TOP (1) oi.ImageUrl, oi.ProductName
        FROM   dbo.OrderItems AS oi
        WHERE  oi.OrderId = o.Id
        ORDER  BY oi.Id
    ) AS pv
    ORDER BY
        CASE WHEN @SortBy = 'Oldest'      THEN o.PlacedOn END ASC,
        CASE WHEN @SortBy = 'HighestValue' THEN o.Total    END DESC,
        CASE WHEN @SortBy = 'LowestValue'  THEN o.Total    END ASC,
        CASE WHEN @SortBy NOT IN ('Oldest','HighestValue','LowestValue') THEN o.PlacedOn END DESC,
        o.Id DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
