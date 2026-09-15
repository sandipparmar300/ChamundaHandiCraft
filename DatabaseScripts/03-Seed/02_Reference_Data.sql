/* =============================================================================
   03-Seed/02_Reference_Data.sql
   -----------------------------------------------------------------------------
   Master and reference data the platform cannot start without.

   Specs:
     Settings.txt §6, §7  currencies, GST and tax classes
     Orders.txt   §10,§11 cancellation and return reasons
     Inventory.txt §7,§9  adjustment and damage reasons
     Review.txt   §7, §9  moderation and abuse reasons
     Contact.txt  §5      inquiry categories
     Notification.txt §6,§7  event catalogue
     SEO.txt      §6      default robots rules
     Reports.txt  §25     report definitions
     Search.txt   §23     synonyms

   All statements are MERGE / NOT EXISTS on a business key (prompt §32) - running
   this file repeatedly cannot create duplicate master data.
   ============================================================================= */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ---------------------------------------------------------------------------
   Currencies - Settings.txt §6. INR is the base; the rest carry placeholder
   rates until an FX feed is wired up.
   --------------------------------------------------------------------------- */
MERGE dbo.Currencies AS tgt
USING (VALUES
    ('INR', N'Indian Rupee',        N'Rs.', 1.0000,  2, 1),
    ('USD', N'US Dollar',           N'$',   0.0120,  2, 0),
    ('EUR', N'Euro',                N'EUR', 0.0110,  2, 0),
    ('GBP', N'Pound Sterling',      N'GBP', 0.0095,  2, 0),
    ('AED', N'UAE Dirham',          N'AED', 0.0441,  2, 0),
    ('AUD', N'Australian Dollar',   N'A$',  0.0182,  2, 0),
    ('CAD', N'Canadian Dollar',     N'C$',  0.0164,  2, 0)
) AS src (CurrencyCode, CurrencyName, Symbol, ExchangeRate, DecimalPlaces, IsBaseCurrency)
   ON tgt.CurrencyCode = src.CurrencyCode
WHEN MATCHED THEN
    UPDATE SET CurrencyName   = src.CurrencyName,
               Symbol         = src.Symbol,
               DecimalPlaces  = src.DecimalPlaces,
               IsBaseCurrency = src.IsBaseCurrency,
               UpdatedAt      = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (CurrencyCode, CurrencyName, Symbol, ExchangeRate, DecimalPlaces, IsBaseCurrency)
    VALUES (src.CurrencyCode, src.CurrencyName, src.Symbol, src.ExchangeRate, src.DecimalPlaces, src.IsBaseCurrency);
GO

/* ---------------------------------------------------------------------------
   GST tax classes. These are the slabs that actually apply to Indian
   handicrafts; the rate here is the TOTAL, split into CGST+SGST intra-state or
   charged as IGST inter-state at order time.
   --------------------------------------------------------------------------- */
MERGE dbo.TaxClasses AS tgt
USING (VALUES
    (N'GST 0%',  'GST0',  0.0000,  0.0000, N'Exempt - unworked raw materials and certain handlooms.', 0),
    (N'GST 3%',  'GST3',  3.0000,  0.0000, N'Precious metal and stone articles.',                     0),
    (N'GST 5%',  'GST5',  5.0000,  0.0000, N'Most handicraft items and handmade textiles.',           1),
    (N'GST 12%', 'GST12', 12.0000, 0.0000, N'Wooden, brass and metal decorative articles.',           0),
    (N'GST 18%', 'GST18', 18.0000, 0.0000, N'Furniture, packaged goods and services.',                0),
    (N'GST 28%', 'GST28', 28.0000, 0.0000, N'Luxury goods.',                                          0)
) AS src (ClassName, Code, RatePercent, CessPercent, Description, IsDefault)
   ON tgt.Code = src.Code
WHEN MATCHED THEN
    UPDATE SET ClassName   = src.ClassName,
               RatePercent = src.RatePercent,
               CessPercent = src.CessPercent,
               Description = src.Description,
               IsDefault   = src.IsDefault,
               UpdatedAt   = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ClassName, Code, RatePercent, CessPercent, Description, IsDefault)
    VALUES (src.ClassName, src.Code, src.RatePercent, src.CessPercent, src.Description, src.IsDefault);
GO

/* Open the rate-history window for each class so a tax audit can prove which
   rate was configured from go-live onward (20_Concurrency_And_Tax.sql). */
INSERT INTO dbo.TaxRateHistories
    (TaxClassId, TaxClassName, TotalRate, CgstRate, SgstRate, IgstRate, CessRate,
     EffectiveFrom, EffectiveTo, ChangeNote, ChangedOn)
SELECT t.Id,
       t.ClassName,
       t.RatePercent,
       t.RatePercent / 2.0,
       t.RatePercent / 2.0,
       t.RatePercent,
       t.CessPercent,
       SYSUTCDATETIME(),
       NULL,
       N'Initial seed.',
       SYSUTCDATETIME()
FROM   dbo.TaxClasses AS t
WHERE  NOT EXISTS (SELECT 1 FROM dbo.TaxRateHistories AS h
                   WHERE h.TaxClassId = t.Id AND h.EffectiveTo IS NULL);
GO

/* ---------------------------------------------------------------------------
   Reason codes. One table, several ReasonType values - the enum-per-workflow
   pattern the schema already established.
   --------------------------------------------------------------------------- */
MERGE dbo.ReasonCodes AS tgt
USING (VALUES
    -- Order cancellation - Orders.txt §10 / Order Tracking.txt §10
    ('OrderCancel',      'CUSTOMER_REQUEST',   N'Customer request',            0, 0, 1, 0,  1),
    ('OrderCancel',      'PAYMENT_FAILURE',    N'Payment failure',             0, 0, 0, 1,  2),
    ('OrderCancel',      'OUT_OF_STOCK',       N'Out of stock',                0, 0, 1, 1,  3),
    ('OrderCancel',      'DUPLICATE_ORDER',    N'Duplicate order',             0, 0, 0, 0,  4),
    ('OrderCancel',      'FRAUD_SUSPECTED',    N'Fraud detection',             0, 1, 1, 0,  5),
    ('OrderCancel',      'ORDERED_BY_MISTAKE', N'Ordered by mistake',          0, 0, 0, 0,  6),
    ('OrderCancel',      'FOUND_BETTER_PRICE', N'Found a better price',        0, 0, 0, 0,  7),
    ('OrderCancel',      'DELIVERY_DELAY',     N'Delivery taking too long',    0, 0, 0, 1,  8),
    ('OrderCancel',      'ADMIN_CANCELLED',    N'Cancelled by administrator',  0, 0, 1, 0,  9),
    -- Returns - Orders.txt §11
    ('Return',           'DAMAGED',            N'Product arrived damaged',     0, 1, 1, 1,  1),
    ('Return',           'WRONG_PRODUCT',      N'Wrong product delivered',     0, 1, 1, 1,  2),
    ('Return',           'MISSING_ITEM',       N'Item missing from parcel',    0, 1, 1, 1,  3),
    ('Return',           'QUALITY_ISSUE',      N'Quality not as expected',     0, 1, 1, 1,  4),
    ('Return',           'CHANGED_MIND',       N'Changed my mind',             0, 0, 1, 0,  5),
    ('Return',           'NOT_AS_DESCRIBED',   N'Not as described on site',    0, 1, 1, 1,  6),
    ('Return',           'SIZE_ISSUE',         N'Size or dimensions unsuitable',0,0, 1, 0,  7),
    ('Return',           'OTHER',              N'Other',                       0, 0, 1, 0,  8),
    -- Stock adjustment - Inventory.txt §7
    ('StockAdjustment',  'MANUAL_CORRECTION',  N'Manual correction',           0, 0, 1, 0,  1),
    ('StockAdjustment',  'PHYSICAL_COUNT',     N'Physical verification',       0, 0, 1, 0,  2),
    ('StockAdjustment',  'COUNTING_ERROR',     N'Counting error',              0, 0, 1, 0,  3),
    ('StockAdjustment',  'LOST_STOCK',         N'Lost stock',                  0, 0, 1, 0,  4),
    ('StockAdjustment',  'EXTRA_STOCK',        N'Extra stock found',           0, 0, 1, 0,  5),
    ('StockAdjustment',  'SYSTEM_CORRECTION',  N'System correction',           0, 0, 1, 0,  6),
    -- Damage - Inventory.txt §9
    ('Damage',           'BROKEN',             N'Broken',                      0, 1, 1, 0,  1),
    ('Damage',           'WATER_DAMAGE',       N'Water damage',                0, 1, 1, 0,  2),
    ('Damage',           'MANUFACTURING',      N'Manufacturing defect',        0, 1, 1, 0,  3),
    ('Damage',           'CUSTOMER_DAMAGE',    N'Customer damage',             0, 1, 1, 0,  4),
    ('Damage',           'TRANSPORT',          N'Transportation damage',       0, 1, 1, 1,  5),
    -- Review moderation - Review.txt §7
    ('ReviewModeration', 'SPAM',               N'Spam',                        0, 0, 0, 0,  1),
    ('ReviewModeration', 'OFFENSIVE',          N'Offensive language',          0, 0, 0, 0,  2),
    ('ReviewModeration', 'FAKE',               N'Fake review',                 0, 0, 1, 0,  3),
    ('ReviewModeration', 'DUPLICATE',          N'Duplicate',                   0, 0, 0, 0,  4),
    ('ReviewModeration', 'IRRELEVANT',         N'Irrelevant to the product',   0, 0, 0, 0,  5),
    ('ReviewModeration', 'ABUSE',              N'Abusive content',             0, 0, 0, 0,  6),
    -- Review abuse reports - Review.txt §9
    ('ReviewAbuse',      'SPAM',               N'Spam',                        0, 0, 0, 0,  1),
    ('ReviewAbuse',      'FAKE_REVIEW',        N'Fake review',                 0, 0, 0, 0,  2),
    ('ReviewAbuse',      'OFFENSIVE_CONTENT',  N'Offensive content',           0, 0, 0, 0,  3),
    ('ReviewAbuse',      'HARASSMENT',         N'Harassment',                  0, 0, 1, 0,  4),
    ('ReviewAbuse',      'DUPLICATE_REVIEW',   N'Duplicate review',            0, 0, 0, 0,  5),
    ('ReviewAbuse',      'MISLEADING',         N'Misleading information',      0, 0, 1, 0,  6),
    -- Refunds - Payments.txt §8
    ('Refund',           'ORDER_CANCELLED',    N'Order cancelled',             0, 0, 0, 0,  1),
    ('Refund',           'RETURN_APPROVED',    N'Return approved',             0, 0, 0, 0,  2),
    ('Refund',           'GOODWILL',           N'Goodwill gesture',            0, 0, 1, 1,  3),
    ('Refund',           'PRICE_ADJUSTMENT',   N'Price adjustment',            0, 0, 1, 0,  4),
    ('Refund',           'DUPLICATE_PAYMENT',  N'Duplicate payment',           0, 0, 1, 1,  5),
    ('Refund',           'FAILED_DELIVERY',    N'Delivery failed',             0, 0, 0, 1,  6)
) AS src (ReasonType, Code, Label, EnumValue, RequiresPhoto, RequiresNote, IsOurFault, SortOrder)
   ON tgt.ReasonType = src.ReasonType AND tgt.Code = src.Code
WHEN MATCHED THEN
    UPDATE SET Label         = src.Label,
               RequiresPhoto = src.RequiresPhoto,
               RequiresNote  = src.RequiresNote,
               IsOurFault    = src.IsOurFault,
               SortOrder     = src.SortOrder,
               IsSystem      = 1,
               UpdatedAt     = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ReasonType, Code, Label, EnumValue, RequiresPhoto, RequiresNote, IsOurFault, SortOrder, IsSystem)
    VALUES (src.ReasonType, src.Code, src.Label, src.EnumValue, src.RequiresPhoto,
            src.RequiresNote, src.IsOurFault, src.SortOrder, 1);
GO

/* ---------------------------------------------------------------------------
   Inquiry categories - Contact.txt §5, with per-category SLA (Contact.txt §14).
   --------------------------------------------------------------------------- */
MERGE dbo.InquiryCategories AS tgt
USING (VALUES
    ('GENERAL',        N'General inquiry',            24, 72, 1, 1,  1),
    ('PRODUCT',        N'Product inquiry',            24, 72, 1, 1,  2),
    ('ORDER_SUPPORT',  N'Order support',              12, 48, 0, 1,  3),
    ('RETURN',         N'Return request',             12, 48, 0, 1,  4),
    ('REFUND',         N'Refund',                     12, 48, 0, 1,  5),
    ('WHOLESALE',      N'Wholesale inquiry',          24, 96, 1, 1,  6),
    ('BULK_ORDER',     N'Bulk order',                 24, 96, 1, 1,  7),
    ('CUSTOM_PRODUCT', N'Custom handmade product',    24, 120,1, 1,  8),
    ('EXPORT',         N'Export inquiry',             48, 120,1, 1,  9),
    ('PARTNERSHIP',    N'Partnership',                48, 168,2, 1, 10),
    ('FEEDBACK',       N'Feedback',                   48, 168,2, 1, 11),
    ('COMPLAINT',      N'Complaint',                   4, 24, 0, 1, 12),
    ('OTHER',          N'Other',                      24, 72, 1, 1, 13),
    ('INTERNAL',       N'Internal escalation',         8, 24, 0, 0, 14)
) AS src (CategoryCode, Name, FirstResponseSlaHours, ResolutionSlaHours, DefaultPriority, IsPublic, SortOrder)
   ON tgt.CategoryCode = src.CategoryCode
WHEN MATCHED THEN
    UPDATE SET Name                  = src.Name,
               FirstResponseSlaHours = src.FirstResponseSlaHours,
               ResolutionSlaHours    = src.ResolutionSlaHours,
               DefaultPriority       = src.DefaultPriority,
               IsPublic              = src.IsPublic,
               SortOrder             = src.SortOrder,
               IsSystem              = 1,
               UpdatedAt             = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (CategoryCode, Name, FirstResponseSlaHours, ResolutionSlaHours,
            DefaultPriority, IsPublic, SortOrder, IsSystem)
    VALUES (src.CategoryCode, src.Name, src.FirstResponseSlaHours, src.ResolutionSlaHours,
            src.DefaultPriority, src.IsPublic, src.SortOrder, 1);
GO

/* ---------------------------------------------------------------------------
   Notification events - Notification.txt §6 categories and §7 triggers.
   DefaultChannels holds channel numbers: 0 Email, 1 Sms, 2 WhatsApp, 3 Push, 4 InApp.
   IsTransactional = 1 means promotional opt-out does not suppress it (§17).
   --------------------------------------------------------------------------- */
MERGE dbo.NotificationEvents AS tgt
USING (VALUES
    -- Authentication
    ('OtpRequested',        N'OTP requested',              'Authentication', 1, '1',     'Customer'),
    ('PasswordReset',       N'Password reset requested',   'Authentication', 1, '0',     'Customer'),
    ('PasswordChanged',     N'Password changed',           'Authentication', 1, '0',     'Customer'),
    ('AccountLocked',       N'Account locked',             'Authentication', 1, '0',     'Customer'),
    -- Customer lifecycle
    ('CustomerRegistered',  N'Welcome / registration',     'Customer',       1, '0,1',   'Customer'),
    ('EmailVerification',   N'Verify email address',       'Customer',       1, '0',     'Customer'),
    -- Orders
    ('OrderPlaced',         N'Order confirmation',         'Orders',         1, '0,1,2', 'Customer'),
    ('OrderProcessing',     N'Order processing',           'Orders',         1, '0',     'Customer'),
    ('OrderPacked',         N'Order packed',               'Orders',         1, '0',     'Customer'),
    ('OrderShipped',        N'Order shipped',              'Orders',         1, '0,1,2', 'Customer'),
    ('OutForDelivery',      N'Out for delivery',           'Orders',         1, '1,2',   'Customer'),
    ('OrderDelivered',      N'Order delivered',            'Orders',         1, '0,1',   'Customer'),
    ('OrderCancelled',      N'Order cancelled',            'Orders',         1, '0,1',   'Customer'),
    ('ReturnApproved',      N'Return approved',            'Orders',         1, '0,1',   'Customer'),
    -- Payments
    ('PaymentSuccess',      N'Payment received',           'Payments',       1, '0,1',   'Customer'),
    ('PaymentFailed',       N'Payment failed',             'Payments',       1, '0,1',   'Customer'),
    ('CodConfirmation',     N'Cash on delivery confirmed', 'Payments',       1, '1',     'Customer'),
    ('RefundInitiated',     N'Refund initiated',           'Payments',       1, '0',     'Customer'),
    ('RefundCompleted',     N'Refund completed',           'Payments',       1, '0,1',   'Customer'),
    -- Shipping
    ('ShipmentInTransit',   N'Shipment in transit',        'Shipping',       1, '0',     'Customer'),
    ('DeliveryFailed',      N'Delivery attempt failed',    'Shipping',       1, '0,1',   'Customer'),
    -- Reviews
    ('ReviewRequest',       N'How was your order?',        'Reviews',        0, '0',     'Customer'),
    ('ReviewApproved',      N'Your review is live',        'Reviews',        0, '0',     'Customer'),
    ('ReviewRejected',      N'Review not published',       'Reviews',        0, '0',     'Customer'),
    ('ReviewReplied',       N'We replied to your review',  'Reviews',        0, '0',     'Customer'),
    -- Inventory / wishlist
    ('BackInStock',         N'Back in stock',              'Inventory',      0, '0,3',   'Customer'),
    ('PriceDrop',           N'Price drop on your wishlist','Inventory',      0, '0,3',   'Customer'),
    -- Marketing
    ('AbandonedCart',       N'You left something behind',  'Marketing',      0, '0',     'Customer'),
    ('NewsletterWelcome',   N'Newsletter subscription',    'Marketing',      0, '0',     'Customer'),
    ('CouponAvailable',     N'A coupon for you',           'Marketing',      0, '0,3',   'Customer'),
    ('FlashSaleStarted',    N'Flash sale is live',         'Marketing',      0, '0,3',   'Customer'),
    -- Support
    ('TicketCreated',       N'We received your enquiry',   'Support',        1, '0',     'Customer'),
    ('TicketReplied',       N'Reply to your enquiry',      'Support',        1, '0',     'Customer'),
    ('TicketResolved',      N'Your enquiry is resolved',   'Support',        1, '0',     'Customer'),
    -- Admin-facing
    ('AdminNewOrder',       N'New order received',         'Admin',          1, '0,4',   'Admin'),
    ('AdminPaymentFailed',  N'Payment failure',            'Admin',          1, '0,4',   'Admin'),
    ('AdminLowStock',       N'Low stock alert',            'Admin',          1, '0,4',   'Admin'),
    ('AdminOutOfStock',     N'Out of stock alert',         'Admin',          1, '0,4',   'Admin'),
    ('AdminNewReview',      N'New review submitted',       'Admin',          0, '4',     'Admin'),
    ('AdminLowRating',      N'One-star review received',   'Admin',          1, '0,4',   'Admin'),
    ('AdminAbuseReport',    N'Review reported',            'Admin',          1, '4',     'Admin'),
    ('AdminNewTicket',      N'New support ticket',         'Admin',          1, '0,4',   'Admin'),
    ('AdminCouponExpiring', N'Coupon expiring soon',       'Admin',          0, '4',     'Admin'),
    ('AdminRefundRequest',  N'Refund awaiting approval',   'Admin',          1, '0,4',   'Admin')
) AS src (EventKey, Name, Category, IsTransactional, DefaultChannels, Audience)
   ON tgt.EventKey = src.EventKey
WHEN MATCHED THEN
    UPDATE SET Name            = src.Name,
               Category        = src.Category,
               IsTransactional = src.IsTransactional,
               DefaultChannels = src.DefaultChannels,
               Audience        = src.Audience,
               IsSystem        = 1,
               UpdatedAt       = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (EventKey, Name, Category, IsTransactional, DefaultChannels, Audience, IsSystem)
    VALUES (src.EventKey, src.Name, src.Category, src.IsTransactional,
            src.DefaultChannels, src.Audience, 1);
GO

/* ---------------------------------------------------------------------------
   robots.txt defaults - SEO.txt §6 and §21. These four Disallow rules are
   required: admin, auth, checkout and cart must never be indexed.
   --------------------------------------------------------------------------- */
MERGE dbo.RobotsRules AS tgt
USING (VALUES
    ('*', 'Allow',    N'/',            1, 1),
    ('*', 'Disallow', N'/admin/',      2, 1),
    ('*', 'Disallow', N'/checkout/',   3, 1),
    ('*', 'Disallow', N'/cart/',       4, 1),
    ('*', 'Disallow', N'/account/',    5, 1),
    ('*', 'Disallow', N'/auth/',       6, 1),
    ('*', 'Disallow', N'/search?',     7, 1),
    ('*', 'Disallow', N'/wishlist/',   8, 1),
    ('*', 'Sitemap',  N'/sitemap.xml', 9, 1)
) AS src (UserAgent, Directive, Value, SortOrder, IsSystem)
   ON tgt.UserAgent = src.UserAgent AND tgt.Directive = src.Directive AND tgt.Value = src.Value
WHEN MATCHED THEN
    UPDATE SET SortOrder = src.SortOrder, IsSystem = src.IsSystem, UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (UserAgent, Directive, Value, SortOrder, IsSystem)
    VALUES (src.UserAgent, src.Directive, src.Value, src.SortOrder, src.IsSystem);
GO

/* ---------------------------------------------------------------------------
   Report catalogue - Reports.txt §4-§12. PermissionKey ties each report to the
   key set seeded in 01_Identity_And_Access.sql (Reports.txt §20).
   --------------------------------------------------------------------------- */
MERGE dbo.ReportDefinitions AS tgt
USING (VALUES
    ('SALES_SUMMARY',    N'Sales summary',       'Sales',     'usp_Report_GetSales',     'report.sales.view',     0,  1),
    ('SALES_BY_PRODUCT', N'Sales by product',    'Sales',     'usp_Report_GetSales',     'report.sales.view',     1,  2),
    ('SALES_BY_CATEGORY',N'Sales by category',   'Sales',     'usp_Report_GetSales',     'report.sales.view',     1,  3),
    ('PROFIT_SUMMARY',   N'Profit and margin',   'Profit',    'usp_Report_GetProfit',    'report.profit.view',    1,  4),
    ('CUSTOMER_SUMMARY', N'Customer report',     'Customer',  'usp_Report_GetCustomers', 'report.customer.view',  1,  5),
    ('INVENTORY_STOCK',  N'Stock report',        'Inventory', 'usp_Report_GetInventory', 'report.inventory.view', 0,  6),
    ('INVENTORY_VALUE',  N'Inventory valuation', 'Inventory', 'usp_Report_GetInventory', 'report.inventory.view', 1,  7),
    ('LOW_STOCK',        N'Low stock',           'Inventory', 'usp_Report_GetInventory', 'report.inventory.view', 0,  8),
    ('TAX_GST',          N'GST / tax report',    'Tax',       'usp_Report_GetTax',       'report.tax.view',       1,  9),
    ('TAX_HSN_SUMMARY',  N'HSN summary (GSTR-1)','Tax',       'usp_Report_GetTax',       'report.tax.view',       1, 10),
    ('PAYMENT_SUMMARY',  N'Payment report',      'Payment',   'usp_Report_GetPayments',  'report.payment.view',   1, 11),
    ('ORDER_SUMMARY',    N'Order report',        'Order',     'usp_Report_GetOrders',    'report.sales.view',     1, 12),
    ('RETURN_SUMMARY',   N'Return report',       'Return',    'usp_Report_GetReturns',   'report.return.view',    1, 13),
    ('SEARCH_ANALYTICS', N'Search analytics',    'Search',    'usp_Search_GetAnalytics', 'report.sales.view',     0, 14)
) AS src (ReportCode, Name, Category, ProcedureName, PermissionKey, SupportsAsync, SortOrder)
   ON tgt.ReportCode = src.ReportCode
WHEN MATCHED THEN
    UPDATE SET Name          = src.Name,
               Category      = src.Category,
               ProcedureName = src.ProcedureName,
               PermissionKey = src.PermissionKey,
               SupportsAsync = src.SupportsAsync,
               SortOrder     = src.SortOrder,
               IsSystem      = 1,
               UpdatedAt     = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ReportCode, Name, Category, ProcedureName, PermissionKey, SupportsAsync, SortOrder, IsSystem)
    VALUES (src.ReportCode, src.Name, src.Category, src.ProcedureName,
            src.PermissionKey, src.SupportsAsync, src.SortOrder, 1);
GO

/* ---------------------------------------------------------------------------
   Search synonyms - Search.txt §23. Handicraft vocabulary where the shopper's
   word and the catalogue's word genuinely differ. Without these the zero-result
   rate on a craft catalogue is high from day one.
   --------------------------------------------------------------------------- */
MERGE dbo.SearchSynonyms AS tgt
USING (VALUES
    (N'diya',       N'oil lamp',      1),
    (N'diya',       N'deepak',        1),
    (N'urli',       N'bowl',          1),
    (N'thali',      N'plate',         1),
    (N'matka',      N'pot',           1),
    (N'jhula',      N'swing',         1),
    (N'toran',      N'door hanging',  1),
    (N'rangoli',    N'floor art',     1),
    (N'idol',       N'murti',         1),
    (N'idol',       N'statue',        1),
    (N'wall decor', N'wall hanging',  1),
    (N'planter',    N'pot',           1),
    (N'brass',      N'pital',         1),
    (N'wooden',     N'wood',          1),
    (N'handmade',   N'handcrafted',   1),
    (N'blue pottery', N'jaipur pottery', 1),
    (N'dhokra',     N'bell metal',    1),
    (N'madhubani',  N'mithila',       1),
    (N'warli',      N'tribal art',    1),
    (N'coaster',    N'mat',           0)
) AS src (Term, Synonym, IsBidirectional)
   ON tgt.Term = src.Term AND tgt.Synonym = src.Synonym
WHEN MATCHED THEN
    UPDATE SET IsBidirectional = src.IsBidirectional, UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Term, Synonym, IsBidirectional)
    VALUES (src.Term, src.Synonym, src.IsBidirectional);
GO

/* ---------------------------------------------------------------------------
   Platform settings - Settings.txt. Every figure the storefront quotes
   originates here rather than in appsettings.json (Settings.txt §29).
   IsSecret rows are encrypted by the service before storage and are never
   returned to a grid.
   --------------------------------------------------------------------------- */
MERGE dbo.Settings AS tgt
USING (VALUES
    -- storefront
    ('storefront', 'SiteName',              N'Chamunda Handicraft',      'string',  N'Site name',                 1, 0),
    ('storefront', 'DefaultCurrency',       N'INR',                      'string',  N'Default currency',          2, 0),
    ('storefront', 'DefaultTimezone',       N'India Standard Time',      'string',  N'Timezone',                  3, 0),
    ('storefront', 'ProductsPerPage',       N'24',                       'int',     N'Products per page',         4, 0),
    ('storefront', 'ShowOutOfStock',        N'true',                     'bool',    N'Show out-of-stock products',5, 0),
    ('storefront', 'GuestCheckoutEnabled',  N'true',                     'bool',    N'Allow guest checkout',      6, 0),
    -- shipping
    ('shipping',   'FreeShippingThreshold', N'1000.00',                  'decimal', N'Free shipping above',       1, 0),
    ('shipping',   'DefaultShippingCharge', N'80.00',                    'decimal', N'Default shipping charge',   2, 0),
    ('shipping',   'DefaultDeliveryDays',   N'5',                        'int',     N'Estimated delivery days',   3, 0),
    -- payment
    ('payment',    'CodEnabled',            N'true',                     'bool',    N'Cash on delivery enabled',  1, 0),
    ('payment',    'CodFee',                N'50.00',                    'decimal', N'COD handling fee',          2, 0),
    ('payment',    'CodMaxOrderValue',      N'20000.00',                 'decimal', N'Maximum COD order value',   3, 0),
    -- tax
    ('tax',        'PricesIncludeTax',      N'true',                     'bool',    N'Prices are tax inclusive',  1, 0),
    ('tax',        'DefaultTaxClassCode',   N'GST5',                     'string',  N'Default tax class',         2, 0),
    ('tax',        'CompanyGstin',          N'',                         'string',  N'Company GSTIN',             3, 0),
    ('tax',        'CompanyStateCode',      N'24',                       'string',  N'Home state GST code',       4, 0),
    ('tax',        'InvoicePrefix',         N'CHX/INV/',                 'string',  N'Invoice number prefix',     5, 0),
    -- orders
    ('orders',     'ReturnWindowDays',      N'7',                        'int',     N'Return window (days)',      1, 0),
    ('orders',     'CancelAllowedTillStatus',N'3',                       'int',     N'Cancel allowed until status',2,0),
    ('orders',     'OrderNumberPrefix',     N'CHX',                      'string',  N'Order number prefix',       3, 0),
    -- rewards
    ('rewards',    'RewardsEnabled',        N'true',                     'bool',    N'Reward points enabled',     1, 0),
    ('rewards',    'PointsPerCurrencyUnit', N'0.01',                     'decimal', N'Points earned per rupee',   2, 0),
    ('rewards',    'PointValue',            N'1.00',                     'decimal', N'Rupee value of one point',  3, 0),
    -- reviews
    ('reviews',    'AutoApproveReviews',    N'false',                    'bool',    N'Auto-approve reviews',      1, 0),
    ('reviews',    'VerifiedPurchaseOnly',  N'true',                     'bool',    N'Only buyers may review',    2, 0),
    ('reviews',    'ReviewRequestDelayDays',N'3',                        'int',     N'Days after delivery to ask',3, 0),
    -- notifications
    ('notifications','MaxRetryAttempts',    N'3',                        'int',     N'Notification retry limit',  1, 0),
    ('notifications','RetryIntervalMinutes',N'15',                       'int',     N'Retry interval (minutes)',  2, 0),
    ('notifications','DoubleOptInEnabled',  N'true',                     'bool',    N'Newsletter double opt-in',  3, 0),
    -- seo
    ('seo',        'DefaultMetaTitle',      N'Chamunda Handicraft',      'string',  N'Default meta title',        1, 0),
    ('seo',        'DefaultMetaDescription',N'Authentic Indian handicrafts, handmade by master artisans.', 'string', N'Default meta description', 2, 0),
    ('seo',        'SitemapAutoGenerate',   N'true',                     'bool',    N'Regenerate sitemap on publish', 3, 0),
    ('seo',        'GoogleAnalyticsId',     N'',                         'string',  N'Google Analytics ID',       4, 0),
    -- security
    ('security',   'MaxFailedLoginAttempts',N'5',                        'int',     N'Failed logins before lockout',1,0),
    ('security',   'LockoutMinutes',        N'15',                       'int',     N'Lockout duration (minutes)',2, 0),
    ('security',   'PasswordExpiryDays',    N'90',                       'int',     N'Password expiry (days)',    3, 0),
    ('security',   'SessionTimeoutMinutes', N'30',                       'int',     N'Session idle timeout',      4, 0),
    ('security',   'OtpExpiryMinutes',      N'5',                        'int',     N'OTP validity (minutes)',    5, 0),
    -- contact
    ('contact',    'SupportEmail',          N'support@chamundahandicraft.com', 'string', N'Support email',        1, 0),
    ('contact',    'SupportPhone',          N'',                         'string',  N'Support phone',             2, 0),
    ('contact',    'WhatsAppNumber',        N'',                         'string',  N'WhatsApp number',           3, 0),
    ('contact',    'BusinessHours',         N'Mon-Sat 10:00-18:00 IST',  'string',  N'Business hours',            4, 0)
) AS src (Section, SettingKey, SettingValue, DataType, DisplayName, SortOrder, IsSecret)
   ON tgt.Section = src.Section AND tgt.SettingKey = src.SettingKey
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Section, SettingKey, SettingValue, DataType, DisplayName, SortOrder, IsSystem, IsSecret)
    VALUES (src.Section, src.SettingKey, src.SettingValue, src.DataType,
            src.DisplayName, src.SortOrder, 1, src.IsSecret);
/* Deliberately no WHEN MATCHED clause: a re-run must never overwrite a value an
   administrator has since changed through the Settings screen. New keys are
   added; existing ones are left exactly as configured. */
GO
