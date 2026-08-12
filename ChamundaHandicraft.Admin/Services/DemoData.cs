using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace ChamundaHandicraft.Admin.Services;

/// <summary>
/// Design-phase rows for every admin grid.
///
/// They deliberately mirror the storefront's own demo catalogue — same slugs, SKUs,
/// order numbers and artisans — so the connection is visible before the API exists.
/// Publishing <c>jaipur-blue-pottery-vase</c> here is the record the customer site
/// serves at <c>/p/jaipur-blue-pottery-vase</c>.
///
/// <see cref="For{T}"/> is the single lookup the generic client uses; adding a module
/// means adding one case, not a new client method.
/// </summary>
public static class DemoData
{
    private static readonly DateTime Today = DateTime.Today;

    /// <summary>Rows for a grid of <typeparamref name="T"/>, or empty when none are seeded.</summary>
    public static List<T> For<T>()
    {
        object rows = typeof(T).Name switch
        {
            nameof(CountryGridItem) => Countries(),
            nameof(StateGridItem) => States(),
            nameof(CityGridItem) => Cities(),
            nameof(ZipCodeGridItem) => ZipCodes(),
            nameof(BrandGridItem) => Brands(),
            nameof(AttributeGridItem) => Attributes(),
            nameof(MasterGridItem) => Masters(),
            nameof(WarehouseGridItem) => Warehouses(),
            nameof(SupplierGridItem) => Suppliers(),
            nameof(CourierGridItem) => Couriers(),
            nameof(MenuGridItem) => Menus(),
            nameof(FaqGridItem) => Faqs(),
            nameof(BlogCategoryGridItem) => BlogCategories(),
            nameof(BlogAuthorGridItem) => BlogAuthors(),

            nameof(PaymentGridItem) => Payments(),
            nameof(RefundGridItem) => Refunds(),
            nameof(SettlementGridItem) => Settlements(),
            nameof(DisputeGridItem) => Disputes(),
            nameof(InvoiceGridItem) => Invoices(),
            nameof(ShipmentGridItem) => Shipments(),
            nameof(ShippingZoneGridItem) => ShippingZones(),
            nameof(PurchaseOrderGridItem) => PurchaseOrders(),
            nameof(StockAdjustmentGridItem) => StockAdjustments(),
            nameof(StockTakeGridItem) => StockTakes(),
            nameof(StockTransferGridItem) => StockTransfers(),

            nameof(CouponGridItem) => Coupons(),
            nameof(OfferGridItem) => Offers(),
            nameof(CampaignGridItem) => Campaigns(),
            nameof(FlowGridItem) => Flows(),
            nameof(SubscriberGridItem) => Subscribers(),
            nameof(SegmentGridItem) => Segments(),
            nameof(NotificationTemplateGridItem) => NotificationTemplates(),
            nameof(NotificationLogGridItem) => NotificationLogs(),

            nameof(BlogGridItem) => BlogPosts(),
            nameof(BlogCommentGridItem) => BlogComments(),
            nameof(CmsPageGridItem) => CmsPages(),
            nameof(TestimonialGridItem) => Testimonials(),
            nameof(ArtisanGridItem) => Artisans(),
            nameof(MediaGridItem) => MediaLibrary(),
            nameof(SeoMetaGridItem) => SeoMeta(),
            nameof(RedirectGridItem) => Redirects(),

            nameof(AdminUserGridItem) => AdminUsers(),
            nameof(RoleGridItem) => Roles(),
            nameof(CustomerGridItem) => Customers(),
            nameof(SupportTicketGridItem) => Tickets(),
            nameof(ContactSubmissionGridItem) => ContactSubmissions(),
            nameof(ApprovalGridItem) => Approvals(),
            nameof(AuditLogGridItem) => AuditLogs(),
            nameof(IntegrationGridItem) => Integrations(),
            nameof(SavedReportGridItem) => SavedReports(),

            // Shapes the edit forms post. Seeded so an Edit round-trip renders with the
            // record filled in rather than redirecting as "not found".
            nameof(ArtisanSaveRequest) => ArtisanSaves(),
            nameof(BannerSaveRequest) => BannerSaves(),
            nameof(BlogPostSaveRequest) => BlogSaves(),
            nameof(CategorySaveRequest) => CategorySaves(),
            nameof(CmsPageSaveRequest) => CmsPageSaves(),
            nameof(CouponSaveRequest) => CouponSaves(),
            nameof(FlashSaleSaveRequest) => FlashSaleSaves(),
            nameof(TestimonialSaveRequest) => TestimonialSaves(),

            // Read models the detail screens bind.
            nameof(BannerViewModel) => Banners(),
            nameof(CategoryViewModel) => CategoriesFlat(),
            nameof(StockGridItem) => Stock(),
            nameof(ReturnRequestViewModel) => Returns(),

            _ => new List<T>()
        };

        return rows as List<T> ?? new List<T>();
    }

    #region Reference data

    public static List<CountryGridItem> Countries() => new()
    {
        new() { Id = 1, CountryName = "India", IsoCode = "IN", DialCode = "+91", Currency = "INR", StateCount = 36, CreatedOn = Today.AddYears(-2), CreatedBy = "System" },
        new() { Id = 2, CountryName = "United States", IsoCode = "US", DialCode = "+1", Currency = "USD", StateCount = 50, IsActive = false, CreatedOn = Today.AddYears(-2), CreatedBy = "System" },
        new() { Id = 3, CountryName = "United Kingdom", IsoCode = "GB", DialCode = "+44", Currency = "GBP", StateCount = 4, IsActive = false, CreatedOn = Today.AddYears(-2), CreatedBy = "System" },
        new() { Id = 4, CountryName = "United Arab Emirates", IsoCode = "AE", DialCode = "+971", Currency = "AED", StateCount = 7, IsActive = false, CreatedOn = Today.AddYears(-1), CreatedBy = "System" }
    };

    public static List<StateGridItem> States() => new()
    {
        new() { Id = 1, StateName = "Rajasthan", StateCode = "RJ", CountryId = 1, CountryName = "India", GstStateCode = "08", CityCount = 33, CreatedOn = Today.AddYears(-2) },
        new() { Id = 2, StateName = "Gujarat", StateCode = "GJ", CountryId = 1, CountryName = "India", GstStateCode = "24", CityCount = 33, CreatedOn = Today.AddYears(-2) },
        new() { Id = 3, StateName = "Karnataka", StateCode = "KA", CountryId = 1, CountryName = "India", GstStateCode = "29", CityCount = 31, CreatedOn = Today.AddYears(-2) },
        new() { Id = 4, StateName = "West Bengal", StateCode = "WB", CountryId = 1, CountryName = "India", GstStateCode = "19", CityCount = 23, CreatedOn = Today.AddYears(-2) },
        new() { Id = 5, StateName = "Uttar Pradesh", StateCode = "UP", CountryId = 1, CountryName = "India", GstStateCode = "09", CityCount = 75, CreatedOn = Today.AddYears(-2) },
        new() { Id = 6, StateName = "Maharashtra", StateCode = "MH", CountryId = 1, CountryName = "India", GstStateCode = "27", CityCount = 36, CreatedOn = Today.AddYears(-2) }
    };

    public static List<CityGridItem> Cities() => new()
    {
        new() { Id = 1, CityName = "Jaipur", StateId = 1, StateName = "Rajasthan", CountryName = "India", IsMetro = true, ZipCodeCount = 84, CreatedOn = Today.AddYears(-2) },
        new() { Id = 2, CityName = "Ahmedabad", StateId = 2, StateName = "Gujarat", CountryName = "India", IsMetro = true, ZipCodeCount = 62, CreatedOn = Today.AddYears(-2) },
        new() { Id = 3, CityName = "Bengaluru", StateId = 3, StateName = "Karnataka", CountryName = "India", IsMetro = true, ZipCodeCount = 118, CreatedOn = Today.AddYears(-2) },
        new() { Id = 4, CityName = "Bolpur", StateId = 4, StateName = "West Bengal", CountryName = "India", ZipCodeCount = 9, CreatedOn = Today.AddYears(-1) },
        new() { Id = 5, CityName = "Moradabad", StateId = 5, StateName = "Uttar Pradesh", CountryName = "India", ZipCodeCount = 14, CreatedOn = Today.AddYears(-1) },
        new() { Id = 6, CityName = "Pune", StateId = 6, StateName = "Maharashtra", CountryName = "India", IsMetro = true, ZipCodeCount = 71, CreatedOn = Today.AddYears(-2) }
    };

    public static List<ZipCodeGridItem> ZipCodes() => new()
    {
        new() { Id = 1, Pincode = "302029", CityName = "Jaipur", StateName = "Rajasthan", StandardDeliveryDays = 2, ExpressDeliveryDays = 1, ZoneName = "Zone A — Local", CreatedOn = Today.AddYears(-2) },
        new() { Id = 2, Pincode = "380015", CityName = "Ahmedabad", StateName = "Gujarat", StandardDeliveryDays = 4, ExpressDeliveryDays = 2, ZoneName = "Zone B — West", CreatedOn = Today.AddYears(-2) },
        new() { Id = 3, Pincode = "560038", CityName = "Bengaluru", StateName = "Karnataka", StandardDeliveryDays = 6, ExpressDeliveryDays = 3, ZoneName = "Zone C — South", CreatedOn = Today.AddYears(-2) },
        new() { Id = 4, Pincode = "411001", CityName = "Pune", StateName = "Maharashtra", StandardDeliveryDays = 5, ExpressDeliveryDays = 3, ZoneName = "Zone B — West", CreatedOn = Today.AddYears(-2) },
        new() { Id = 5, Pincode = "744101", CityName = "Port Blair", StateName = "Andaman & Nicobar", IsServiceable = false, CodAvailable = false, StandardDeliveryDays = 0, ZoneName = "Not serviced", CreatedOn = Today.AddMonths(-8) }
    };

    public static List<BrandGridItem> Brands() => new()
    {
        new() { Id = 1, BrandName = "Chamunda Originals", Slug = "chamunda-originals", ProductCount = 486, IsFeatured = true, Description = "Our own studio line.", CreatedOn = Today.AddYears(-2) },
        new() { Id = 2, BrandName = "Sanganer Blue", Slug = "sanganer-blue", ProductCount = 128, IsFeatured = true, Description = "Blue pottery from the Sanganer cluster.", CreatedOn = Today.AddMonths(-18) },
        new() { Id = 3, BrandName = "Kantha Collective", Slug = "kantha-collective", ProductCount = 214, Description = "A women's cooperative in Bolpur.", CreatedOn = Today.AddMonths(-14) },
        new() { Id = 4, BrandName = "Moradabad Metals", Slug = "moradabad-metals", ProductCount = 176, CreatedOn = Today.AddMonths(-11) }
    };

    public static List<AttributeGridItem> Attributes() => new()
    {
        new() { Id = 1, AttributeName = "Colour", AttributeCode = "colour", DisplayType = "Swatch", IsFilterable = true, IsRequired = true, ValueCount = 18, UsedByProductCount = 842, CreatedOn = Today.AddYears(-2) },
        new() { Id = 2, AttributeName = "Size", AttributeCode = "size", DisplayType = "Pill", IsFilterable = true, IsRequired = true, ValueCount = 6, UsedByProductCount = 391, CreatedOn = Today.AddYears(-2) },
        new() { Id = 3, AttributeName = "Material", AttributeCode = "material", DisplayType = "Dropdown", IsFilterable = true, ValueCount = 14, UsedByProductCount = 1204, CreatedOn = Today.AddYears(-2) },
        new() { Id = 4, AttributeName = "Craft Technique", AttributeCode = "technique", DisplayType = "Text", IsFilterable = false, ValueCount = 22, UsedByProductCount = 1204, CreatedOn = Today.AddMonths(-20) },
        new() { Id = 5, AttributeName = "Occasion", AttributeCode = "occasion", DisplayType = "Pill", IsFilterable = true, ValueCount = 8, UsedByProductCount = 318, CreatedOn = Today.AddMonths(-9) }
    };

    public static List<MasterGridItem> Masters() => new()
    {
        new() { Id = 1, MasterType = "Return Reason", Name = "Arrived damaged or broken", Code = "DAMAGED", SortOrder = 1, IsSystem = true, CreatedOn = Today.AddYears(-2) },
        new() { Id = 2, MasterType = "Return Reason", Name = "Wrong item received", Code = "WRONG_ITEM", SortOrder = 2, IsSystem = true, CreatedOn = Today.AddYears(-2) },
        new() { Id = 3, MasterType = "Return Reason", Name = "I changed my mind", Code = "CHANGED_MIND", SortOrder = 6, IsSystem = true, CreatedOn = Today.AddYears(-2) },
        new() { Id = 4, MasterType = "Stock Adjustment Reason", Name = "Damaged in storage", Code = "DAMAGE", SortOrder = 1, CreatedOn = Today.AddMonths(-16) },
        new() { Id = 5, MasterType = "Stock Adjustment Reason", Name = "Kiln loss", Code = "KILN_LOSS", SortOrder = 2, Description = "Pieces lost during firing — expected at roughly one in six.", CreatedOn = Today.AddMonths(-16) },
        new() { Id = 6, MasterType = "Craft Cluster", Name = "Sanganer, Jaipur", Code = "SANGANER", SortOrder = 1, CreatedOn = Today.AddYears(-2) }
    };

    public static List<WarehouseGridItem> Warehouses() => new()
    {
        new() { Id = 1, WarehouseName = "Jaipur Studio", Code = "JAI-01", City = "Jaipur", State = "Rajasthan", Pincode = "302029", ContactPerson = "Vikram Singh", Phone = "+91 98290 11223", SkuCount = 1204, IsDefault = true, CreatedOn = Today.AddYears(-2) },
        new() { Id = 2, WarehouseName = "Bengaluru Hub", Code = "BLR-01", City = "Bengaluru", State = "Karnataka", Pincode = "560038", ContactPerson = "Deepa Rao", Phone = "+91 98450 44556", SkuCount = 486, CreatedOn = Today.AddMonths(-10) }
    };

    public static List<SupplierGridItem> Suppliers() => new()
    {
        new() { Id = 1, SupplierName = "Sharma Pottery Works", Code = "SUP-001", ContactPerson = "Ram Prasad Sharma", Phone = "+91 98290 33445", Email = "rpsharma@example.com", Gstin = "08AABCS1234M1Z5", City = "Jaipur", OutstandingAmount = 48200, PurchaseOrderCount = 34, CreatedOn = Today.AddYears(-2) },
        new() { Id = 2, SupplierName = "Bolpur Kantha Cooperative", Code = "SUP-002", ContactPerson = "Meenakshi Devi", Phone = "+91 90730 55667", Gstin = "19AABCB5678M1Z2", City = "Bolpur", OutstandingAmount = 0, PurchaseOrderCount = 21, CreatedOn = Today.AddMonths(-18) },
        new() { Id = 3, SupplierName = "Hussain Brass Casting", Code = "SUP-003", ContactPerson = "Iqbal Hussain", Phone = "+91 94120 77889", Gstin = "09AABCH9012M1Z8", City = "Moradabad", OutstandingAmount = 126400, PurchaseOrderCount = 28, CreatedOn = Today.AddMonths(-16) }
    };

    public static List<CourierGridItem> Couriers() => new()
    {
        new() { Id = 1, CourierName = "Delhivery", Code = "DLV", SupportsCod = true, SupportsReversePickup = true, TrackingUrlTemplate = "https://www.delhivery.com/track/package/{awb}", ActiveShipmentCount = 42, OnTimePercent = 94.2m, CreatedOn = Today.AddYears(-2) },
        new() { Id = 2, CourierName = "Blue Dart", Code = "BD", SupportsCod = false, SupportsReversePickup = true, ActiveShipmentCount = 18, OnTimePercent = 97.8m, CreatedOn = Today.AddYears(-2) },
        new() { Id = 3, CourierName = "India Post", Code = "IP", SupportsCod = true, SupportsReversePickup = false, ActiveShipmentCount = 7, OnTimePercent = 81.4m, CreatedOn = Today.AddMonths(-14) }
    };

    public static List<MenuGridItem> Menus() => new()
    {
        new() { Id = 1, Title = "Shop", Location = "MegaMenu", Url = "/shop", SortOrder = 1, ChildCount = 6, CreatedOn = Today.AddYears(-1) },
        new() { Id = 2, Title = "New Arrivals", Location = "Header", Url = "/c/new-arrivals", SortOrder = 2, CreatedOn = Today.AddYears(-1) },
        new() { Id = 3, Title = "Festive", Location = "MegaMenu", Url = "/c/festive", SortOrder = 3, ChildCount = 4, CreatedOn = Today.AddMonths(-4) },
        new() { Id = 4, Title = "Artisans", Location = "Header", Url = "/artisans", SortOrder = 5, CreatedOn = Today.AddYears(-1) },
        new() { Id = 5, Title = "Return Policy", Location = "Footer", Url = "/pages/return-policy", SortOrder = 4, CreatedOn = Today.AddYears(-1) }
    };

    public static List<FaqGridItem> Faqs() => new()
    {
        new() { Id = 1, Question = "When will my order arrive?", Answer = "Most orders leave our Jaipur studio within 48 hours and reach metro PIN codes in 4–6 days.", Topic = "Delivery", SortOrder = 1, HelpfulCount = 284, NotHelpfulCount = 12, CreatedOn = Today.AddYears(-1) },
        new() { Id = 2, Question = "Do you charge for shipping?", Answer = "Free above ₹999. Below that it is a flat ₹79 anywhere in India.", Topic = "Delivery", SortOrder = 2, HelpfulCount = 196, NotHelpfulCount = 8, CreatedOn = Today.AddYears(-1) },
        new() { Id = 3, Question = "My item is handmade — will it look exactly like the photo?", Answer = "Recognisably the same piece, but not identical. Colour, finish and size vary slightly because a person made it.", Topic = "Handmade", SortOrder = 1, HelpfulCount = 412, NotHelpfulCount = 6, CreatedOn = Today.AddYears(-1) },
        new() { Id = 4, Question = "How do returns work?", Answer = "7 days from delivery, any reason. We book the courier and pay for it.", Topic = "Returns", SortOrder = 1, HelpfulCount = 331, NotHelpfulCount = 14, CreatedOn = Today.AddYears(-1) }
    };

    public static List<BlogCategoryGridItem> BlogCategories() => new()
    {
        new() { Id = 1, Name = "Craft Stories", Slug = "craft-stories", PostCount = 18, Description = "How things are made, and who makes them.", CreatedOn = Today.AddYears(-1) },
        new() { Id = 2, Name = "Living", Slug = "living", PostCount = 12, CreatedOn = Today.AddYears(-1) },
        new() { Id = 3, Name = "Meet the Makers", Slug = "meet-the-makers", PostCount = 9, CreatedOn = Today.AddMonths(-10) },
        new() { Id = 4, Name = "Materials", Slug = "materials", PostCount = 3, CreatedOn = Today.AddMonths(-5) }
    };

    public static List<BlogAuthorGridItem> BlogAuthors() => new()
    {
        new() { Id = 1, Name = "Nandini Rao", Slug = "nandini-rao", Email = "nandini@chamundahandicraft.com", PostCount = 24, Bio = "Writes about craft, materials and the people who work with them.", CreatedOn = Today.AddYears(-1) },
        new() { Id = 2, Name = "Kabir Menon", Slug = "kabir-menon", Email = "kabir@chamundahandicraft.com", PostCount = 14, Bio = "Interiors and styling.", CreatedOn = Today.AddMonths(-9) }
    };

    #endregion

    #region Finance & fulfilment

    public static List<PaymentGridItem> Payments() => new()
    {
        new() { Id = 1, TransactionId = "TXN-88421903", OrderNumber = "HC-2026-000482", CustomerName = "Ananya Iyer", Amount = 5290, Method = PaymentMethod.Upi, Status = PaymentStatus.Paid, GatewayName = "Razorpay", GatewayReference = "pay_Nx8k2mQ", PaidOn = Today.AddDays(-3), GatewayFee = 62.42m },
        new() { Id = 2, TransactionId = "TXN-88419772", OrderNumber = "HC-2026-000476", CustomerName = "Fatima Khan", Amount = 8940, Method = PaymentMethod.NetBanking, Status = PaymentStatus.Paid, GatewayName = "Razorpay", PaidOn = Today.AddDays(-5), GatewayFee = 105.49m },
        new() { Id = 3, TransactionId = "TXN-88422540", OrderNumber = "HC-2026-000488", CustomerName = "Kabir Menon", Amount = 2150, Method = PaymentMethod.Upi, Status = PaymentStatus.Pending, GatewayName = "Razorpay", PaidOn = Today },
        new() { Id = 4, TransactionId = "TXN-88401115", OrderNumber = "HC-2026-000287", CustomerName = "Rahul Sharma", Amount = 1650, Method = PaymentMethod.CashOnDelivery, Status = PaymentStatus.Refunded, PaidOn = Today.AddDays(-62) }
    };

    public static List<RefundGridItem> Refunds() => new()
    {
        new() { Id = 1, RefundNumber = "RFD-8842190", OrderNumber = "HC-2026-000287", RmaNumber = "RMA-2026-00119", CustomerName = "Rahul Sharma", Amount = 1650, OriginalMethod = PaymentMethod.CashOnDelivery, Status = "Completed", Reason = "Arrived with a hairline crack", RequestedOn = Today.AddDays(-58), CompletedOn = Today.AddDays(-51), GatewayReference = "rfnd_Nx2p9Lk" },
        new() { Id = 2, RefundNumber = "RFD-8844021", OrderNumber = "HC-2026-000455", CustomerName = "Sara Thomas", Amount = 3400, OriginalMethod = PaymentMethod.Card, Status = "Pending", Reason = "Order cancelled before dispatch", RequestedOn = Today.AddDays(-1), RequiresApproval = true }
    };

    public static List<SettlementGridItem> Settlements() => new()
    {
        new() { Id = 1, SettlementId = "STL-2026-0442", SettledOn = Today.AddDays(-2), GrossAmount = 184200, Fees = 2174, Refunds = 1650, NetAmount = 180376, TransactionCount = 63, BankReference = "HDFC/NEFT/8842190", Status = "Settled" },
        new() { Id = 2, SettlementId = "STL-2026-0441", SettledOn = Today.AddDays(-9), GrossAmount = 226840, Fees = 2677, Refunds = 0, NetAmount = 224163, TransactionCount = 81, BankReference = "HDFC/NEFT/8839221", Status = "Settled" }
    };

    public static List<DisputeGridItem> Disputes() => new()
    {
        new() { Id = 1, DisputeId = "DSP-000112", OrderNumber = "HC-2026-000318", CustomerName = "Anonymous", Amount = 4600, Reason = "Cardholder does not recognise the transaction", Status = "Open", RaisedOn = Today.AddDays(-4), EvidenceDueOn = Today.AddDays(1) },
        new() { Id = 2, DisputeId = "DSP-000108", OrderNumber = "HC-2026-000201", CustomerName = "Anonymous", Amount = 2150, Reason = "Item not received", Status = "Won", RaisedOn = Today.AddDays(-42), EvidenceDueOn = Today.AddDays(-35) }
    };

    public static List<InvoiceGridItem> Invoices() => new()
    {
        new() { Id = 1, InvoiceNumber = "INV-2026-000482", OrderNumber = "HC-2026-000482", CustomerName = "Ananya Iyer", InvoiceDate = Today.AddDays(-3), TaxableValue = 4482, Igst = 808, Total = 5290, PlaceOfSupply = "24 — Gujarat" },
        new() { Id = 2, InvoiceNumber = "INV-2026-000476", OrderNumber = "HC-2026-000476", CustomerName = "Fatima Khan", CustomerGstin = "29AABCF1234M1Z9", InvoiceDate = Today.AddDays(-5), TaxableValue = 7576, Igst = 1364, Total = 8940, PlaceOfSupply = "29 — Karnataka" },
        new() { Id = 3, InvoiceNumber = "INV-2026-000391", OrderNumber = "HC-2026-000391", CustomerName = "Ananya Iyer", InvoiceDate = Today.AddDays(-24), TaxableValue = 2881, Igst = 519, Total = 3400, PlaceOfSupply = "24 — Gujarat" }
    };

    public static List<ShipmentGridItem> Shipments() => new()
    {
        new() { Id = 1, AwbNumber = "DLV8842190237", OrderNumber = "HC-2026-000482", CustomerName = "Ananya Iyer", CourierName = "Delhivery", Status = ShipmentStatus.OutForDelivery, PickedUpOn = Today.AddDays(-1), PromisedBy = Today, DestinationCity = "Ahmedabad", DestinationPincode = "380015", WeightKg = 2.4m, ShippingCost = 118 },
        new() { Id = 2, AwbNumber = "BD5521907741", OrderNumber = "HC-2026-000391", CustomerName = "Ananya Iyer", CourierName = "Blue Dart", Status = ShipmentStatus.Delivered, PickedUpOn = Today.AddDays(-22), DeliveredOn = Today.AddDays(-18), PromisedBy = Today.AddDays(-17), DestinationCity = "Ahmedabad", DestinationPincode = "380015", WeightKg = 0.3m, ShippingCost = 64 },
        new() { Id = 3, AwbNumber = "DLV8842206611", OrderNumber = "HC-2026-000476", CustomerName = "Fatima Khan", CourierName = "Delhivery", Status = ShipmentStatus.InTransit, PickedUpOn = Today.AddDays(-3), PromisedBy = Today.AddDays(-1), DestinationCity = "Bengaluru", DestinationPincode = "560038", WeightKg = 5.1m, ShippingCost = 214 }
    };

    public static List<ShippingZoneGridItem> ShippingZones() => new()
    {
        new() { Id = 1, ZoneName = "Zone A — Local", Coverage = "Rajasthan", BaseRate = 49, PerKgRate = 18, FreeAboveAmount = 999, StandardDays = 2, ExpressDays = 1, ExpressSurcharge = 120, CodFee = 49, PincodeCount = 842, CreatedOn = Today.AddYears(-2) },
        new() { Id = 2, ZoneName = "Zone B — West & North", Coverage = "Gujarat, Maharashtra, Delhi NCR, Punjab", BaseRate = 79, PerKgRate = 24, FreeAboveAmount = 999, StandardDays = 4, ExpressDays = 2, ExpressSurcharge = 199, CodFee = 49, PincodeCount = 4211, CreatedOn = Today.AddYears(-2) },
        new() { Id = 3, ZoneName = "Zone C — South & East", Coverage = "Karnataka, Tamil Nadu, Kerala, West Bengal", BaseRate = 99, PerKgRate = 28, FreeAboveAmount = 999, StandardDays = 6, ExpressDays = 3, ExpressSurcharge = 249, CodFee = 49, PincodeCount = 5188, CreatedOn = Today.AddYears(-2) },
        new() { Id = 4, ZoneName = "Zone D — North East & Islands", Coverage = "Assam, Manipur, Andaman & Nicobar", BaseRate = 149, PerKgRate = 42, FreeAboveAmount = 2500, StandardDays = 9, CodAvailable = false, CodFee = 0, PincodeCount = 918, CreatedOn = Today.AddMonths(-14) }
    };

    public static List<PurchaseOrderGridItem> PurchaseOrders() => new()
    {
        new() { Id = 1, PoNumber = "PO-2026-0188", SupplierName = "Sharma Pottery Works", OrderedOn = Today.AddDays(-12), ExpectedOn = Today.AddDays(-2), ReceivedOn = Today.AddDays(-2), LineCount = 6, QuantityOrdered = 180, QuantityReceived = 174, TotalValue = 118400, Status = "Received", WarehouseName = "Jaipur Studio" },
        new() { Id = 2, PoNumber = "PO-2026-0191", SupplierName = "Hussain Brass Casting", OrderedOn = Today.AddDays(-6), ExpectedOn = Today.AddDays(4), LineCount = 4, QuantityOrdered = 240, QuantityReceived = 0, TotalValue = 186200, Status = "Open", WarehouseName = "Jaipur Studio" },
        new() { Id = 3, PoNumber = "PO-2026-0193", SupplierName = "Bolpur Kantha Cooperative", OrderedOn = Today.AddDays(-1), ExpectedOn = Today.AddDays(11), LineCount = 3, QuantityOrdered = 120, QuantityReceived = 0, TotalValue = 94800, Status = "Draft", WarehouseName = "Jaipur Studio" }
    };

    public static List<StockAdjustmentGridItem> StockAdjustments() => new()
    {
        new() { Id = 1, AdjustmentNumber = "ADJ-2026-0412", ProductName = "Blue Pottery Vase — Jaipur Floral", Sku = "HC-POT-0421", WarehouseName = "Jaipur Studio", QuantityBefore = 9, QuantityChange = -6, QuantityAfter = 3, Reason = "Kiln loss", Note = "Six pieces cracked in the 14 Aug firing.", AdjustedOn = Today.AddDays(-4), CreatedBy = "Vikram (Inventory)" },
        new() { Id = 2, AdjustmentNumber = "ADJ-2026-0410", ProductName = "Terracotta Planter — Tall Fluted", Sku = "HC-POT-0509", WarehouseName = "Jaipur Studio", QuantityBefore = 4, QuantityChange = -4, QuantityAfter = 0, Reason = "Damaged in storage", AdjustedOn = Today.AddDays(-9), CreatedBy = "Vikram (Inventory)" },
        new() { Id = 3, AdjustmentNumber = "ADJ-2026-0408", ProductName = "Sikki Grass Storage Basket", Sku = "HC-BSK-0117", WarehouseName = "Jaipur Studio", QuantityBefore = 3, QuantityChange = 6, QuantityAfter = 9, Reason = "Stock take correction", AdjustedOn = Today.AddDays(-14), CreatedBy = "Deepa (Inventory)" }
    };

    public static List<StockTakeGridItem> StockTakes() => new()
    {
        new() { Id = 1, StockTakeNumber = "STK-2026-014", WarehouseName = "Jaipur Studio", StartedOn = Today.AddDays(-15), CompletedOn = Today.AddDays(-14), SkusCounted = 1204, DiscrepancyCount = 11, DiscrepancyValue = -18400, Status = "Completed" },
        new() { Id = 2, StockTakeNumber = "STK-2026-015", WarehouseName = "Bengaluru Hub", StartedOn = Today.AddDays(-1), SkusCounted = 212, DiscrepancyCount = 2, DiscrepancyValue = -2100, Status = "In Progress" }
    };

    public static List<StockTransferGridItem> StockTransfers() => new()
    {
        new() { Id = 1, TransferNumber = "TRF-2026-0071", FromWarehouse = "Jaipur Studio", ToWarehouse = "Bengaluru Hub", SkuCount = 14, TotalQuantity = 186, InitiatedOn = Today.AddDays(-4), Status = "In Transit" },
        new() { Id = 2, TransferNumber = "TRF-2026-0068", FromWarehouse = "Jaipur Studio", ToWarehouse = "Bengaluru Hub", SkuCount = 9, TotalQuantity = 94, InitiatedOn = Today.AddDays(-21), ReceivedOn = Today.AddDays(-17), Status = "Received" }
    };

    #endregion

    #region Marketing

    public static List<CouponGridItem> Coupons() => new()
    {
        new() { Id = 1, Code = "FESTIVE10", Title = "10% off, up to ₹500", DiscountType = DiscountType.Percentage, DiscountValue = 10, StartsOn = Today.AddDays(-10), ExpiresOn = Today.AddDays(25), UsageCount = 184, TotalUsageLimit = 1000, TotalDiscountGiven = 68420, Status = CouponStatus.Active, CreatedOn = Today.AddDays(-12) },
        new() { Id = 2, Code = "WELCOME200", Title = "₹200 off your first order", DiscountType = DiscountType.FixedAmount, DiscountValue = 200, MinimumOrderValue = 1500, StartsOn = Today.AddYears(-1), UsageCount = 612, TotalDiscountGiven = 122400, Status = CouponStatus.Active, CreatedOn = Today.AddYears(-1) },
        new() { Id = 3, Code = "BRASS15", Title = "15% off brass and metal", DiscountType = DiscountType.Percentage, DiscountValue = 15, StartsOn = Today.AddDays(-4), ExpiresOn = Today.AddDays(12), UsageCount = 31, TotalUsageLimit = 200, TotalDiscountGiven = 14280, Status = CouponStatus.Active, CreatedOn = Today.AddDays(-5) },
        new() { Id = 4, Code = "DIWALI25", Title = "25% off festive", DiscountType = DiscountType.Percentage, DiscountValue = 25, StartsOn = Today.AddDays(-120), ExpiresOn = Today.AddDays(-60), UsageCount = 418, TotalDiscountGiven = 284600, Status = CouponStatus.Expired, CreatedOn = Today.AddDays(-125) },
        new() { Id = 5, Code = "BULK25", Title = "25% off orders above ₹10,000", DiscountType = DiscountType.Percentage, DiscountValue = 25, MinimumOrderValue = 10000, StartsOn = Today.AddDays(-30), ExpiresOn = Today.AddDays(90), UsageCount = 6, IsPublic = false, TotalDiscountGiven = 42800, Status = CouponStatus.Active, CreatedOn = Today.AddDays(-31) }
    };

    public static List<OfferGridItem> Offers() => new()
    {
        new() { Id = 1, Name = "Festive Flash Sale", OfferType = "Flash Sale", DiscountPercent = 20, StartsOn = Today.AddDays(-1), EndsOn = Today.AddDays(1).AddHours(20), ProductCount = 24, OrdersInfluenced = 86, RevenueInfluenced = 184200, IsActive = true, CreatedOn = Today.AddDays(-3) },
        new() { Id = 2, Name = "Clearance — Monsoon", OfferType = "Category Offer", DiscountPercent = 30, StartsOn = Today.AddDays(-60), EndsOn = Today.AddDays(-30), ProductCount = 48, OrdersInfluenced = 142, RevenueInfluenced = 218400, IsActive = false, CreatedOn = Today.AddDays(-62) }
    };

    public static List<CampaignGridItem> Campaigns() => new()
    {
        new() { Id = 1, Name = "Diwali collection launch", Subject = "The festive collection is here", Channel = "Email", SegmentName = "All subscribers", SentOn = Today.AddDays(-6), Recipients = 8420, Delivered = 8288, Opened = 3104, Clicked = 742, Unsubscribed = 18, Status = "Sent", CreatedOn = Today.AddDays(-8) },
        new() { Id = 2, Name = "Blue pottery story", Subject = "There is no clay in blue pottery", Channel = "Email", SegmentName = "Engaged readers", SentOn = Today.AddDays(-20), Recipients = 3140, Delivered = 3102, Opened = 1488, Clicked = 402, Unsubscribed = 4, Status = "Sent", CreatedOn = Today.AddDays(-22) },
        new() { Id = 3, Name = "Republic Day preview", Subject = "Early access opens Friday", Channel = "Email", SegmentName = "Repeat customers", ScheduledOn = Today.AddDays(3), Recipients = 2180, Status = "Scheduled", CreatedOn = Today.AddDays(-1) }
    };

    public static List<FlowGridItem> Flows() => new()
    {
        new() { Id = 1, Name = "Welcome series", TriggerEvent = "Subscriber created", StepCount = 3, EnrolledCount = 1842, CompletedCount = 1204, RevenueAttributed = 486200, IsActive = true, CreatedOn = Today.AddYears(-1) },
        new() { Id = 2, Name = "Abandoned cart recovery", TriggerEvent = "Cart abandoned 4h", StepCount = 2, EnrolledCount = 3204, CompletedCount = 486, RevenueAttributed = 1284600, IsActive = true, CreatedOn = Today.AddMonths(-10) },
        new() { Id = 3, Name = "Post-delivery review request", TriggerEvent = "Order delivered + 7d", StepCount = 2, EnrolledCount = 1394, CompletedCount = 248, RevenueAttributed = 0, IsActive = true, CreatedOn = Today.AddMonths(-8) }
    };

    public static List<SubscriberGridItem> Subscribers() => new()
    {
        new() { Id = 1, Email = "ananya@example.com", Name = "Ananya Iyer", Source = "Footer", SubscribedOn = Today.AddMonths(-8), HasMarketingConsent = true },
        new() { Id = 2, Email = "rahul.s@example.com", Name = "Rahul Sharma", Source = "Checkout", SubscribedOn = Today.AddMonths(-14), HasMarketingConsent = true },
        new() { Id = 3, Email = "priya.m@example.com", Source = "Popup", SubscribedOn = Today.AddDays(-40), UnsubscribedOn = Today.AddDays(-12), HasMarketingConsent = false },
        new() { Id = 4, Email = "bounced@example.com", Source = "Footer", SubscribedOn = Today.AddMonths(-3), HasMarketingConsent = true, IsSuppressed = true, SuppressionReason = "Hard bounce" }
    };

    public static List<SegmentGridItem> Segments() => new()
    {
        new() { Id = 1, Name = "Repeat customers", RuleSummary = "Order count ≥ 2", CustomerCount = 842, LastEvaluatedOn = Today.AddHours(-6), CreatedOn = Today.AddYears(-1) },
        new() { Id = 2, Name = "High value", RuleSummary = "Lifetime value ≥ ₹25,000", CustomerCount = 186, LastEvaluatedOn = Today.AddHours(-6), CreatedOn = Today.AddMonths(-11) },
        new() { Id = 3, Name = "Lapsed", RuleSummary = "No order in 180 days", CustomerCount = 1204, LastEvaluatedOn = Today.AddHours(-6), CreatedOn = Today.AddMonths(-7) }
    };

    public static List<NotificationTemplateGridItem> NotificationTemplates() => new()
    {
        new() { Id = 1, TemplateKey = "order.placed", Name = "Order confirmation", Channel = NotificationChannel.Email, Subject = "Your order {{order_number}} is confirmed", TriggerEvent = "Order placed", SentLast30Days = 486, IsSystem = true, CreatedOn = Today.AddYears(-1) },
        new() { Id = 2, TemplateKey = "order.shipped", Name = "Order shipped", Channel = NotificationChannel.Email, Subject = "Order {{order_number}} is on its way", TriggerEvent = "Status → Shipped", SentLast30Days = 442, IsSystem = true, CreatedOn = Today.AddYears(-1) },
        new() { Id = 3, TemplateKey = "order.out_for_delivery", Name = "Out for delivery", Channel = NotificationChannel.Sms, TriggerEvent = "Status → Out for delivery", SentLast30Days = 418, IsSystem = true, CreatedOn = Today.AddYears(-1) },
        new() { Id = 4, TemplateKey = "review.request", Name = "How was your order?", Channel = NotificationChannel.Email, Subject = "How was your order?", TriggerEvent = "Delivered + 7 days", SentLast30Days = 388, CreatedOn = Today.AddMonths(-8) },
        new() { Id = 5, TemplateKey = "stock.back_in_stock", Name = "Back in stock", Channel = NotificationChannel.Email, Subject = "{{product_name}} is back", TriggerEvent = "Stock > 0 with waitlist", SentLast30Days = 62, CreatedOn = Today.AddMonths(-6) }
    };

    public static List<NotificationLogGridItem> NotificationLogs() => new()
    {
        new() { Id = 1, Title = "Out for delivery", Body = "Order HC-2026-000482 arrives today.", Channel = NotificationChannel.Sms, Recipient = "+91 98765 43210", Status = "Sent", SentOn = DateTime.Now.AddHours(-2), ReadOn = DateTime.Now.AddHours(-1) },
        new() { Id = 2, Title = "Order shipped", Body = "Order HC-2026-000482 left our Jaipur studio.", Channel = NotificationChannel.Email, Recipient = "ananya@example.com", Status = "Sent", SentOn = DateTime.Now.AddDays(-1) },
        new() { Id = 3, Title = "Order confirmation", Channel = NotificationChannel.Email, Recipient = "bounced@example.com", Status = "Failed", SentOn = DateTime.Now.AddDays(-2), FailureReason = "Hard bounce — mailbox does not exist" }
    };

    #endregion

    #region Content

    public static List<BlogGridItem> BlogPosts() => new()
    {
        new() { Id = 1, Title = "How Jaipur blue pottery is made — from quartz to kiln", Slug = "how-blue-pottery-is-made", CategoryName = "Craft Stories", AuthorName = "Nandini Rao", PublishedOn = Today.AddDays(-8), ReadMinutes = 7, ViewCount = 4820, CommentCount = 14, FeaturedProductCount = 4, Status = ContentStatus.Published, CreatedOn = Today.AddDays(-12) },
        new() { Id = 2, Title = "Styling brass in a modern Indian home", Slug = "styling-brass-in-modern-homes", CategoryName = "Living", AuthorName = "Kabir Menon", PublishedOn = Today.AddDays(-16), ReadMinutes = 5, ViewCount = 3140, CommentCount = 8, FeaturedProductCount = 6, Status = ContentStatus.Published, CreatedOn = Today.AddDays(-19) },
        new() { Id = 3, Title = "Kantha: the thrift that became an art form", Slug = "kantha-the-thrift-that-became-art", CategoryName = "Craft Stories", AuthorName = "Nandini Rao", PublishedOn = Today.AddDays(-27), ReadMinutes = 6, ViewCount = 2488, CommentCount = 11, FeaturedProductCount = 3, Status = ContentStatus.Published, CreatedOn = Today.AddDays(-30) },
        new() { Id = 4, Title = "Inside a Channapatna lacquer workshop", Slug = "inside-a-channapatna-workshop", CategoryName = "Meet the Makers", AuthorName = "Nandini Rao", ReadMinutes = 8, Status = ContentStatus.Draft, CreatedOn = Today.AddDays(-2) }
    };

    public static List<BlogCommentGridItem> BlogComments() => new()
    {
        new() { Id = 1, PostTitle = "How Jaipur blue pottery is made", AuthorName = "Sunita R.", AuthorEmail = "sunita@example.com", Body = "I had no idea there was no clay in it. Fascinating read.", SubmittedOn = DateTime.Now.AddHours(-5), Status = ModerationStatus.Pending },
        new() { Id = 2, PostTitle = "Styling brass in a modern Indian home", AuthorName = "Arjun K.", Body = "The pairing suggestions actually work — tried the third one.", SubmittedOn = DateTime.Now.AddDays(-2), Status = ModerationStatus.Approved },
        new() { Id = 3, PostTitle = "How Jaipur blue pottery is made", AuthorName = "spam-bot", Body = "Visit my site for cheap deals!!!", SubmittedOn = DateTime.Now.AddDays(-1), Status = ModerationStatus.Spam }
    };

    public static List<CmsPageGridItem> CmsPages() => new()
    {
        new() { Id = 1, Title = "Our story", Slug = "about", Template = "Editorial", PublishedOn = Today.AddYears(-1), Status = ContentStatus.Published, CreatedOn = Today.AddYears(-1) },
        new() { Id = 2, Title = "Privacy policy", Slug = "privacy-policy", Template = "Policy", PublishedOn = Today.AddYears(-1), Status = ContentStatus.Published, IsSystemPage = true, CreatedOn = Today.AddYears(-1) },
        new() { Id = 3, Title = "Return policy", Slug = "return-policy", Template = "Policy", PublishedOn = Today.AddDays(-34), Status = ContentStatus.Published, IsSystemPage = true, CreatedOn = Today.AddYears(-1) },
        new() { Id = 4, Title = "Terms & conditions", Slug = "terms", Template = "Policy", PublishedOn = Today.AddYears(-1), Status = ContentStatus.Published, IsSystemPage = true, CreatedOn = Today.AddYears(-1) },
        new() { Id = 5, Title = "Sustainability", Slug = "sustainability", Template = "Editorial", Status = ContentStatus.Draft, CreatedOn = Today.AddDays(-6) }
    };

    public static List<TestimonialGridItem> Testimonials() => new()
    {
        new() { Id = 1, CustomerName = "Meera N.", Location = "Chennai", Quote = "The colours are richer than the photographs suggest, and the packing was faultless.", Rating = 5, ShowOnHome = true, SortOrder = 1, Status = ContentStatus.Published, CreatedOn = Today.AddDays(-40) },
        new() { Id = 2, CustomerName = "Arjun K.", Location = "Mumbai", Quote = "Gifted this to my mother and she asked where the workshop was so she could visit.", Rating = 5, ShowOnHome = true, SortOrder = 2, Status = ContentStatus.Published, CreatedOn = Today.AddDays(-62) },
        new() { Id = 3, CustomerName = "Sara T.", Location = "Delhi", Quote = "Beautiful work. Slightly smaller than I pictured — check the dimensions.", Rating = 4, SortOrder = 3, Status = ContentStatus.Draft, CreatedOn = Today.AddDays(-8) }
    };

    public static List<ArtisanGridItem> Artisans() => new()
    {
        new() { Id = 1, Name = "Ram Prasad Sharma", Slug = "ram-prasad-sharma", Craft = "Blue Pottery", Cluster = "Jaipur, Rajasthan", ProductCount = 212, AverageRating = 4.8m, WorkingSinceYear = 2008, IsGiTagged = true, CreatedOn = Today.AddYears(-2) },
        new() { Id = 2, Name = "Meenakshi Devi", Slug = "meenakshi-devi", Craft = "Kantha Embroidery", Cluster = "Bolpur, West Bengal", ProductCount = 168, AverageRating = 4.9m, WorkingSinceYear = 2004, CreatedOn = Today.AddMonths(-18) },
        new() { Id = 3, Name = "Iqbal Hussain", Slug = "iqbal-hussain", Craft = "Brass Casting", Cluster = "Moradabad, Uttar Pradesh", ProductCount = 176, AverageRating = 4.7m, WorkingSinceYear = 1998, CreatedOn = Today.AddMonths(-16) },
        new() { Id = 4, Name = "Lakshmi Narayanan", Slug = "lakshmi-narayanan", Craft = "Channapatna Woodcraft", Cluster = "Channapatna, Karnataka", ProductCount = 94, AverageRating = 4.6m, WorkingSinceYear = 2012, IsGiTagged = true, CreatedOn = Today.AddMonths(-11) }
    };

    public static List<MediaGridItem> MediaLibrary() => new()
    {
        new() { Id = 1, FileName = "blue-pottery-vase-01.jpg", Url = "/assets/images/default-profile.png", MediaType = ProductMediaType.Image, AltText = "Hand-painted blue pottery vase with cobalt floral motif, 24 cm tall", SizeBytes = 184320, Width = 900, Height = 900, Folder = "products", UsedInCount = 3, CreatedOn = Today.AddDays(-30) },
        new() { Id = 2, FileName = "blue-pottery-detail.jpg", Url = "/assets/images/default-profile.png", MediaType = ProductMediaType.Image, AltText = "Close macro of the hand-painted floral band showing brush strokes", SizeBytes = 212992, Width = 900, Height = 900, Folder = "products", UsedInCount = 1, CreatedOn = Today.AddDays(-30) },
        new() { Id = 3, FileName = "hero-diwali-2026.jpg", Url = "/assets/images/default-profile.png", MediaType = ProductMediaType.Image, AltText = "", SizeBytes = 118784, Width = 2400, Height = 1000, Folder = "banners", UsedInCount = 1, CreatedOn = Today.AddDays(-12) },
        new() { Id = 4, FileName = "craft-process.mp4", Url = "/assets/images/default-profile.png", MediaType = ProductMediaType.Video, AltText = "Ram Prasad Sharma shaping a vase", SizeBytes = 8912896, Folder = "video", UsedInCount = 2, CreatedOn = Today.AddDays(-45) }
    };

    public static List<SeoMetaGridItem> SeoMeta() => new()
    {
        new() { Id = 1, RoutePath = "/", EntityType = "Home", MetaTitle = "Chamunda Handicraft — Handmade by Indian artisans", MetaDescription = "Handmade décor, textiles, brass and jewellery bought direct from Indian artisans.", CreatedOn = Today.AddYears(-1) },
        new() { Id = 2, RoutePath = "/c/home-decor", EntityType = "Category", MetaTitle = "Handmade Home Décor — Chamunda Handicraft", MetaDescription = "Vases, wall art, lamps and figurines made by named artisans across India.", CreatedOn = Today.AddYears(-1) },
        new() { Id = 3, RoutePath = "/p/jaipur-blue-pottery-vase", EntityType = "Product", MetaTitle = "Blue Pottery Vase — Jaipur Floral | Hand-painted quartz clay, 24 cm | Chamunda", MetaDescription = "Thrown from quartz clay and painted with natural cobalt oxide.", CreatedOn = Today.AddDays(-30) },
        new() { Id = 4, RoutePath = "/c/gifting", EntityType = "Category", MetaTitle = "Gifting", CreatedOn = Today.AddMonths(-6) }
    };

    public static List<RedirectGridItem> Redirects() => new()
    {
        new() { Id = 1, FromPath = "/products/blue-vase", ToPath = "/p/jaipur-blue-pottery-vase", StatusCode = 301, HitCount = 482, LastHitOn = Today.AddDays(-1), CreatedOn = Today.AddMonths(-8) },
        new() { Id = 2, FromPath = "/category/decor", ToPath = "/c/home-decor", StatusCode = 301, HitCount = 1204, LastHitOn = Today, CreatedOn = Today.AddMonths(-8) },
        new() { Id = 3, FromPath = "/sale-2025", ToPath = "/c/sale", StatusCode = 302, HitCount = 34, LastHitOn = Today.AddDays(-22), CreatedOn = Today.AddMonths(-3) }
    };

    #endregion

    #region People & system

    public static List<AdminUserGridItem> AdminUsers() => new()
    {
        new() { Id = 1, FullName = "Sandip Parmar", Email = "sandip@chamundahandicraft.com", Phone = "+91 98250 11223", RoleName = "Super Admin", LastLoginOn = DateTime.Now.AddMinutes(-8), TwoFactorEnabled = true, CreatedOn = Today.AddYears(-2) },
        new() { Id = 2, FullName = "Priya Nair", Email = "priya@chamundahandicraft.com", RoleName = "Catalogue Manager", LastLoginOn = DateTime.Now.AddHours(-3), CreatedOn = Today.AddYears(-1) },
        new() { Id = 3, FullName = "Vikram Singh", Email = "vikram@chamundahandicraft.com", RoleName = "Inventory Manager", LastLoginOn = DateTime.Now.AddHours(-1), CreatedOn = Today.AddMonths(-14) },
        new() { Id = 4, FullName = "Nikhil Desai", Email = "nikhil@chamundahandicraft.com", RoleName = "Support Agent", LastLoginOn = DateTime.Now.AddMinutes(-40), CreatedOn = Today.AddMonths(-9) },
        new() { Id = 5, FullName = "Anjali Mehta", Email = "anjali@chamundahandicraft.com", RoleName = "Finance", LastLoginOn = DateTime.Now.AddDays(-4), IsActive = false, CreatedOn = Today.AddMonths(-20) }
    };

    public static List<RoleGridItem> Roles() => new()
    {
        new() { Id = 1, RoleName = "Super Admin", Description = "Full access, including settings and permissions.", PermissionCount = 214, UserCount = 1, IsSystem = true, CreatedOn = Today.AddYears(-2) },
        new() { Id = 2, RoleName = "Catalogue Manager", Description = "Products, categories, media and SEO.", PermissionCount = 48, UserCount = 1, CreatedOn = Today.AddYears(-2) },
        new() { Id = 3, RoleName = "Order Manager", Description = "Orders, shipments, returns.", PermissionCount = 36, UserCount = 0, CreatedOn = Today.AddYears(-2) },
        new() { Id = 4, RoleName = "Inventory Manager", Description = "Stock, purchases, warehouses.", PermissionCount = 28, UserCount = 1, CreatedOn = Today.AddYears(-2) },
        new() { Id = 5, RoleName = "Support Agent", Description = "Tickets, customers, order lookup. No pricing.", PermissionCount = 22, UserCount = 1, CreatedOn = Today.AddMonths(-14) },
        new() { Id = 6, RoleName = "Finance", Description = "Payments, refunds, settlements, tax reports.", PermissionCount = 24, UserCount = 1, CreatedOn = Today.AddMonths(-20) }
    };

    public static List<CustomerGridItem> Customers() => new()
    {
        new() { Id = 1204, FullName = "Ananya Iyer", Email = "ananya@example.com", Phone = "+91 98765 43210", EmailVerified = true, OrderCount = 7, LifetimeValue = 28460, AverageOrderValue = 4066, LastOrderOn = Today.AddDays(-3), RewardPoints = 1840, SegmentName = "Repeat customers", Status = CustomerStatus.Active, CreatedOn = Today.AddMonths(-14) },
        new() { Id = 987, FullName = "Rahul Sharma", Email = "rahul.s@example.com", Phone = "+91 99887 66554", EmailVerified = true, MobileVerified = true, OrderCount = 3, LifetimeValue = 9840, AverageOrderValue = 3280, LastOrderOn = Today.AddDays(-62), RewardPoints = 98, Status = CustomerStatus.Active, CreatedOn = Today.AddMonths(-20) },
        new() { Id = 1511, FullName = "Fatima Khan", Email = "fatima.k@example.com", EmailVerified = true, OrderCount = 12, LifetimeValue = 64200, AverageOrderValue = 5350, LastOrderOn = Today.AddDays(-5), RewardPoints = 3420, SegmentName = "High value", Status = CustomerStatus.Active, CreatedOn = Today.AddMonths(-24) },
        new() { Id = 1622, FullName = "Kabir Menon", Email = "kabir.m@example.com", OrderCount = 1, LifetimeValue = 2150, AverageOrderValue = 2150, LastOrderOn = Today, RewardPoints = 21, Status = CustomerStatus.Active, CreatedOn = Today.AddDays(-1) },
        new() { Id = 402, FullName = "Blocked Account", Email = "fraud@example.com", OrderCount = 0, LifetimeValue = 0, Status = CustomerStatus.Blocked, CreatedOn = Today.AddMonths(-6) }
    };

    public static List<SupportTicketGridItem> Tickets() => new()
    {
        new() { Id = 1, TicketNumber = "SR-2026-0412", Subject = "Parcel shows delivered but I haven't received it", Topic = "Delivery", CustomerName = "Ananya Iyer", OrderNumber = "HC-2026-000482", Status = TicketStatus.AwaitingAgent, Priority = "High", AssignedTo = "Nikhil Desai", OpenedOn = DateTime.Now.AddDays(-2), LastReplyOn = DateTime.Now.AddHours(-3), MessageCount = 4 },
        new() { Id = 2, TicketNumber = "SR-2026-0410", Subject = "Can I change the delivery address?", Topic = "Delivery", CustomerName = "Fatima Khan", OrderNumber = "HC-2026-000476", Status = TicketStatus.AwaitingCustomer, AssignedTo = "Nikhil Desai", OpenedOn = DateTime.Now.AddDays(-1), LastReplyOn = DateTime.Now.AddHours(-6), MessageCount = 2 },
        new() { Id = 3, TicketNumber = "SR-2026-0387", Subject = "Planter arrived with a hairline crack", Topic = "Damaged item", CustomerName = "Rahul Sharma", OrderNumber = "HC-2026-000287", Status = TicketStatus.Resolved, AssignedTo = "Nikhil Desai", OpenedOn = DateTime.Now.AddDays(-58), LastReplyOn = DateTime.Now.AddDays(-51), MessageCount = 6 },
        new() { Id = 4, TicketNumber = "SR-2026-0413", Subject = "Bulk order for 40 diya sets", Topic = "Bulk order", CustomerName = "Kabir Menon", Status = TicketStatus.Open, Priority = "Normal", OpenedOn = DateTime.Now.AddDays(-3), MessageCount = 1 }
    };

    public static List<ContactSubmissionGridItem> ContactSubmissions() => new()
    {
        new() { Id = 1, Name = "Divya Menon", Email = "divya@example.com", Phone = "+91 98470 22110", Subject = "Bulk order enquiry", Message = "We need 60 marble coaster sets for a corporate gifting programme in December.", SubmittedOn = DateTime.Now.AddHours(-4) },
        new() { Id = 2, Name = "Rohan Gupta", Email = "rohan@example.com", Subject = "Press enquiry", Message = "Writing a piece on craft-direct retail for a design magazine.", SubmittedOn = DateTime.Now.AddDays(-2), IsHandled = true, HandledBy = "Nikhil Desai" },
        new() { Id = 3, Name = "Shabnam Ali", Email = "shabnam@example.com", Subject = "I am an artisan", Message = "I do Lucknow chikankari and would like to supply.", SubmittedOn = DateTime.Now.AddDays(-6) }
    };

    public static List<ApprovalGridItem> Approvals() => new()
    {
        new() { Id = 1, EntityType = "Refund", EntityName = "RFD-8844021 — ₹3,400", RequestedAction = "Approve refund", RequestedBy = "Nikhil Desai", RequestedOn = DateTime.Now.AddHours(-8), Status = "Pending", Reason = "Order cancelled before dispatch" },
        new() { Id = 2, EntityType = "Product", EntityName = "Madhubani Painting — Tree of Life", RequestedAction = "Price change ₹5,800 → ₹4,600", RequestedBy = "Priya Nair", RequestedOn = DateTime.Now.AddDays(-1), Status = "Pending" },
        new() { Id = 3, EntityType = "Coupon", EntityName = "BULK25", RequestedAction = "Create coupon", RequestedBy = "Priya Nair", RequestedOn = DateTime.Now.AddDays(-31), Status = "Approved", DecidedBy = "Sandip Parmar", DecidedOn = DateTime.Now.AddDays(-31) }
    };

    public static List<AuditLogGridItem> AuditLogs() => new()
    {
        new() { Id = 1, Action = "Published", EntityType = "Product", EntityName = "Blue Pottery Vase — Jaipur Floral", EntityId = 1, PerformedBy = "Priya Nair", IpAddress = "103.21.58.14", PerformedOn = DateTime.Now.AddHours(-2), ChangeSummary = "Status: Draft → Published" },
        new() { Id = 2, Action = "Updated", EntityType = "Settings", EntityName = "storefront.FreeShippingThreshold", PerformedBy = "Sandip Parmar", IpAddress = "103.21.58.14", PerformedOn = DateTime.Now.AddHours(-6), ChangeSummary = "899 → 999" },
        new() { Id = 3, Action = "Status changed", EntityType = "Order", EntityName = "HC-2026-000482", EntityId = 482, PerformedBy = "Vikram Singh", IpAddress = "49.36.12.88", PerformedOn = DateTime.Now.AddDays(-1), ChangeSummary = "Packed → Shipped; AWB DLV8842190237" },
        new() { Id = 4, Action = "Approved", EntityType = "Review", EntityName = "Review #901 on Blue Pottery Vase", EntityId = 901, PerformedBy = "Nikhil Desai", PerformedOn = DateTime.Now.AddDays(-2), ChangeSummary = "Pending → Approved" }
    };

    public static List<IntegrationGridItem> Integrations() => new()
    {
        new() { Id = 1, Name = "Razorpay", Category = "Payment", Provider = "Razorpay", IsConnected = true, LastSyncOn = DateTime.Now.AddMinutes(-12), LastSyncStatus = "Success", CreatedOn = Today.AddYears(-2) },
        new() { Id = 2, Name = "Delhivery", Category = "Shipping", Provider = "Delhivery", IsConnected = true, LastSyncOn = DateTime.Now.AddMinutes(-30), LastSyncStatus = "Success", CreatedOn = Today.AddYears(-2) },
        new() { Id = 3, Name = "Blue Dart", Category = "Shipping", Provider = "Blue Dart", IsConnected = true, LastSyncOn = DateTime.Now.AddHours(-2), LastSyncStatus = "Success", CreatedOn = Today.AddMonths(-14) },
        new() { Id = 4, Name = "Transactional email", Category = "Communication", Provider = "Amazon SES", IsConnected = true, LastSyncOn = DateTime.Now.AddMinutes(-5), LastSyncStatus = "Success", CreatedOn = Today.AddYears(-1) },
        new() { Id = 5, Name = "WhatsApp Business", Category = "Communication", Provider = "Meta", IsConnected = false, LastSyncStatus = "Failed", ErrorMessage = "Access token expired on " + Today.AddDays(-3).ToString("dd MMM yyyy"), CreatedOn = Today.AddMonths(-8) },
        new() { Id = 6, Name = "Google Analytics 4", Category = "Analytics", Provider = "Google", IsConnected = true, LastSyncOn = DateTime.Now.AddHours(-1), LastSyncStatus = "Success", CreatedOn = Today.AddYears(-1) }
    };

    public static List<SavedReportGridItem> SavedReports() => new()
    {
        new() { Id = 1, Name = "Daily sales summary", ReportType = "Sales", DateRange = "Yesterday", Schedule = "Daily 08:00", LastRunOn = DateTime.Now.AddHours(-9), Recipients = "sandip@, anjali@", CreatedOn = Today.AddYears(-1) },
        new() { Id = 2, Name = "Low stock alert", ReportType = "Inventory", DateRange = "Live", Schedule = "Daily 09:00", LastRunOn = DateTime.Now.AddHours(-8), Recipients = "vikram@", CreatedOn = Today.AddMonths(-11) },
        new() { Id = 3, Name = "Monthly GST summary", ReportType = "Tax", DateRange = "Last month", Schedule = "Monthly 1st", LastRunOn = Today.AddDays(-14), Recipients = "anjali@", CreatedOn = Today.AddMonths(-20) }
    };

    /// <summary>
    /// Live availability. Reserved is held by carts and unshipped orders, so Available
    /// — not OnHand — is the figure the storefront may quote.
    /// </summary>
    public static List<StockGridItem> Stock() => new()
    {
        new() { ProductId = 1, ProductName = "Blue Pottery Vase — Jaipur Floral", Sku = "HC-POT-0421", WarehouseName = "Jaipur Studio", OnHand = 5, Reserved = 2 },
        new() { ProductId = 2, ProductName = "Kantha Cushion Covers — Set of 2", Sku = "HC-TEX-0903", WarehouseName = "Jaipur Studio", OnHand = 44, Reserved = 2 },
        new() { ProductId = 3, ProductName = "Moradabad Brass Diya Set of 6", Sku = "HC-BRS-1180", WarehouseName = "Jaipur Studio", OnHand = 70, Reserved = 2 },
        new() { ProductId = 7, ProductName = "Madhubani Painting — Tree of Life", Sku = "HC-ART-0042", WarehouseName = "Jaipur Studio", OnHand = 2, Reserved = 0 },
        new() { ProductId = 8, ProductName = "Terracotta Planter — Tall Fluted", Sku = "HC-POT-0509", WarehouseName = "Jaipur Studio", OnHand = 0, Reserved = 0 }
    };

    public static List<ReturnRequestViewModel> Returns() => new()
    {
        new()
        {
            Id = 119, RmaNumber = "RMA-2026-00119", OrderNumber = "HC-2026-000287",
            RequestedOn = Today.AddDays(-58), Reason = ReturnReason.DamagedOrBroken,
            Resolution = ReturnResolution.Refund, RefundAmount = 1650, Status = OrderStatus.Refunded,
            CustomerNote = "Arrived with a hairline crack near the rim.",
            PickupScheduledOn = Today.AddDays(-56),
            Lines = { new ReturnLineViewModel { OrderLineId = 1, ProductName = "Terracotta Planter — Tall Fluted", Sku = "HC-POT-0509", ImageUrl = "/assets/images/default-profile.png", Quantity = 1, LineRefund = 1650 } }
        },
        new()
        {
            Id = 124, RmaNumber = "RMA-2026-00124", OrderNumber = "HC-2026-000391",
            RequestedOn = Today.AddDays(-2), Reason = ReturnReason.SizeUnsuitable,
            Resolution = ReturnResolution.StoreCredit, RefundAmount = 3740, Status = OrderStatus.ReturnRequested,
            CustomerNote = "Lovely but too small for the shelf I had in mind.",
            Lines = { new ReturnLineViewModel { OrderLineId = 2, ProductName = "Silver Filigree Jhumkas — Cuttack", Sku = "HC-JWL-0655", ImageUrl = "/assets/images/default-profile.png", Quantity = 1, LineRefund = 3400 } }
        }
    };

    #endregion

    #region Edit-form payloads

    public static List<ArtisanSaveRequest> ArtisanSaves() =>
        Artisans().Select(a => new ArtisanSaveRequest
        {
            Id = a.Id, Name = a.Name, Slug = a.Slug, Craft = a.Craft, Cluster = a.Cluster,
            PhotoUrl = a.PhotoUrl, WorkingSinceYear = a.WorkingSinceYear,
            IsGiTagged = a.IsGiTagged, IsActive = a.IsActive,
            Story = "Third-generation potter working with quartz clay and natural cobalt oxide."
        }).ToList();

    public static List<BannerViewModel> Banners() => new()
    {
        new()
        {
            Id = 1, Placement = BannerPlacement.HomeHero,
            Eyebrow = "Handmade for Diwali",
            Heading = "Light your home with pieces made by hand",
            SubHeading = "Brass diyas, blue pottery and festive décor from artisans across India.",
            ImageUrl = "/assets/images/default-profile.png",
            MobileImageUrl = "/assets/images/default-profile.png",
            ImageAlt = "Brass diyas glowing in a row on a dark wooden surface",
            PrimaryCtaLabel = "Shop the Collection", PrimaryCtaUrl = "/c/festive",
            SecondaryCtaLabel = "Meet the Makers", SecondaryCtaUrl = "/artisans",
            SortOrder = 1
        },
        new()
        {
            Id = 2, Placement = BannerPlacement.PlpInjection,
            Heading = "Festive 2026",
            ImageUrl = "/assets/images/default-profile.png",
            // Deliberately blank: the grid flags this as unpublishable.
            ImageAlt = "",
            PrimaryCtaLabel = "Shop Festive", PrimaryCtaUrl = "/c/festive",
            SortOrder = 2
        }
    };

    public static List<BannerSaveRequest> BannerSaves() =>
        Banners().Select(b => new BannerSaveRequest
        {
            Id = b.Id, Placement = b.Placement, Eyebrow = b.Eyebrow, Heading = b.Heading,
            SubHeading = b.SubHeading, ImageUrl = b.ImageUrl, MobileImageUrl = b.MobileImageUrl,
            ImageAlt = b.ImageAlt, PrimaryCtaLabel = b.PrimaryCtaLabel, PrimaryCtaUrl = b.PrimaryCtaUrl,
            SecondaryCtaLabel = b.SecondaryCtaLabel, SecondaryCtaUrl = b.SecondaryCtaUrl,
            SortOrder = b.SortOrder, Status = ContentStatus.Published
        }).ToList();

    public static List<BlogPostSaveRequest> BlogSaves() =>
        BlogPosts().Select(p => new BlogPostSaveRequest
        {
            Id = p.Id, Title = p.Title, Slug = p.Slug, ReadMinutes = p.ReadMinutes,
            Status = p.Status, PublishOn = p.PublishedOn,
            Excerpt = "There is no clay in blue pottery. We spent three days in the workshop watching quartz powder become a vase.",
            CoverAlt = "Blue pottery vases drying on a workshop shelf"
        }).ToList();

    /// <summary>Parent and child categories in one flat list, for the edit form and detail screen.</summary>
    public static List<CategoryViewModel> CategoriesFlat() => new()
    {
        new() { Id = 1, Slug = "home-decor", Name = "Home Décor", ProductCount = 428,
                IntroCopy = "Vases, wall art, lamps and figurines made by named artisans across India." },
        new() { Id = 2, Slug = "pottery", Name = "Pottery & Ceramics", ProductCount = 216 },
        new() { Id = 3, Slug = "textiles", Name = "Textiles", ProductCount = 384 },
        new() { Id = 4, Slug = "brassware", Name = "Brass & Metal", ProductCount = 192 },
        new() { Id = 5, Slug = "jewellery", Name = "Jewellery", ProductCount = 267 },
        new() { Id = 6, Slug = "gifting", Name = "Gifting", ProductCount = 158 },
        new() { Id = 11, Slug = "vases", Name = "Vases & Planters", ParentId = 1, ProductCount = 84 },
        new() { Id = 12, Slug = "wall-art", Name = "Wall Art", ParentId = 1, ProductCount = 102 }
    };

    public static List<CategorySaveRequest> CategorySaves() =>
        CategoriesFlat().Select(c => new CategorySaveRequest
        {
            Id = c.Id, Name = c.Name, Slug = c.Slug, ParentId = c.ParentId,
            IntroCopy = c.IntroCopy, ImageUrl = c.ImageUrl, IsActive = true
        }).ToList();

    public static List<CmsPageSaveRequest> CmsPageSaves() =>
        CmsPages().Select(p => new CmsPageSaveRequest
        {
            Id = p.Id, Title = p.Title, Slug = p.Slug, Template = p.Template, Status = p.Status,
            BodyHtml = "<p>Written in the Admin CMS module and served at /pages/" + p.Slug + ".</p>"
        }).ToList();

    public static List<CouponSaveRequest> CouponSaves() =>
        Coupons().Select(c => new CouponSaveRequest
        {
            Id = c.Id, Code = c.Code, Title = c.Title, DiscountType = c.DiscountType,
            DiscountValue = c.DiscountValue, MinimumOrderValue = c.MinimumOrderValue,
            StartsOn = c.StartsOn, ExpiresOn = c.ExpiresOn, TotalUsageLimit = c.TotalUsageLimit,
            IsPublic = c.IsPublic, Status = c.Status,
            Description = "Applies at checkout. One coupon per order."
        }).ToList();

    public static List<FlashSaleSaveRequest> FlashSaleSaves() =>
        Offers().Select(o => new FlashSaleSaveRequest
        {
            Id = o.Id, Name = o.Name, StartsOn = o.StartsOn, EndsOn = o.EndsOn,
            DiscountPercent = o.DiscountPercent, IsActive = o.IsActive
        }).ToList();

    public static List<TestimonialSaveRequest> TestimonialSaves() =>
        Testimonials().Select(t => new TestimonialSaveRequest
        {
            Id = t.Id, CustomerName = t.CustomerName, Location = t.Location, Quote = t.Quote,
            Rating = t.Rating, PhotoUrl = t.PhotoUrl, ShowOnHome = t.ShowOnHome,
            SortOrder = t.SortOrder, Status = t.Status
        }).ToList();

    #endregion

    #region System

    public static List<SettingsHistoryItem> SettingsHistory() => new()
    {
        new() { Id = 1, Section = "storefront", SettingKey = "FreeShippingThreshold", OldValue = "899", NewValue = "999", ChangedBy = "Sandip Parmar", ChangedOn = DateTime.Now.AddHours(-6), ChangeNote = "Margin review — courier rates up 11%." },
        new() { Id = 2, Section = "shipping", SettingKey = "CodFee", OldValue = "39", NewValue = "49", ChangedBy = "Anjali Mehta", ChangedOn = DateTime.Now.AddDays(-18) },
        new() { Id = 3, Section = "storefront", SettingKey = "ReturnWindowDays", OldValue = "5", NewValue = "7", ChangedBy = "Sandip Parmar", ChangedOn = DateTime.Now.AddMonths(-4), ChangeNote = "Matching the promise we make on the PDP." }
    };

    public static List<PermissionMatrixItem> PermissionMatrix() => new()
    {
        new() { Module = "catalog", Entity = "product", Action = "view", Description = "See the product list and detail", IsGranted = true },
        new() { Module = "catalog", Entity = "product", Action = "create", Description = "Add a new product", IsGranted = true },
        new() { Module = "catalog", Entity = "product", Action = "publish", Description = "Make a product visible on the storefront", IsGranted = true },
        new() { Module = "catalog", Entity = "product", Action = "delete", Description = "Soft-delete a product", IsGranted = false },
        new() { Module = "catalog", Entity = "category", Action = "manage", Description = "Create and reorder categories", IsGranted = true },
        new() { Module = "orders", Entity = "order", Action = "view", Description = "See orders and their detail", IsGranted = true },
        new() { Module = "orders", Entity = "order", Action = "updatestatus", Description = "Move an order through the lifecycle", IsGranted = false },
        new() { Module = "orders", Entity = "return", Action = "approve", Description = "Approve a return request", IsGranted = false },
        new() { Module = "finance", Entity = "refund", Action = "approve", Description = "Approve and release a refund", IsGranted = false },
        new() { Module = "content", Entity = "review", Action = "moderate", Description = "Approve or reject customer reviews", IsGranted = true },
        new() { Module = "settings", Entity = "storefront", Action = "edit", Description = "Change the figures the storefront quotes", IsGranted = false }
    };

    #endregion
}
