namespace ChamundaHandicraft.Helper.Constants;

/// <summary>
/// The single source of truth for every route the Admin panel and the Customer site
/// call. Neither MVC project may build a URL by hand.
///
/// The three prefixes match the Ocelot routes in
/// <c>ChamundaHandicraft.APIGateway/ocelot.json</c>:
///
///   <c>Admin/{everything}</c>  → API <c>/api/admin/{everything}</c>   (JWT, permission-checked)
///   <c>Shop/{everything}</c>   → API <c>/api/customer/{everything}</c> (customer cookie or guest token)
///   <c>Public/{everything}</c> → API <c>/api/public/{everything}</c>   (anonymous)
///
/// Read the pairs in <see cref="Product"/>, <see cref="Order"/> and friends together:
/// the Admin constant writes the data, the Shop constant reads it back. That pairing
/// is the whole integration contract, and <c>docs/INTEGRATION-MAP.md</c> spells out
/// which customer screen consumes each one.
/// </summary>
public static class ApiEndPoint
{
    public const string AdminPrefix = "Admin/";
    public const string ShopPrefix = "Shop/";
    public const string PublicPrefix = "Public/";

    /// <summary>
    /// The five routes every admin module exposes, built from its name.
    ///
    /// Most of the 60 admin modules are the same CRUD surface against a different
    /// entity, so naming 300 constants for them would be noise. The rich modules —
    /// orders, products, settings — keep their explicit constants below, because their
    /// routes carry meaning beyond "list" and "save".
    ///
    /// <code>ApiEndPoint.Crud.GridList("Country")  // -> Admin/Country/GridList</code>
    /// </summary>
    public static class Crud
    {
        public static string GridList(string module) => $"{AdminPrefix}{module}/GridList";
        public static string GetById(string module) => $"{AdminPrefix}{module}/GetById";
        public static string Save(string module) => $"{AdminPrefix}{module}/Save";
        public static string Delete(string module) => $"{AdminPrefix}{module}/Delete";
        public static string UpdateStatus(string module) => $"{AdminPrefix}{module}/UpdateStatus";
        public static string Lookup(string module) => $"{AdminPrefix}{module}/Lookup";
    }

    #region Auth — Identity module

    public static class Auth
    {
        // Admin
        public const string AdminLogin = AdminPrefix + "Auth/Login";
        public const string AdminRefreshToken = AdminPrefix + "Auth/RefreshToken";
        public const string AdminForgotPassword = AdminPrefix + "Auth/ForgotPassword";
        public const string AdminResetPassword = AdminPrefix + "Auth/ResetPassword";
        public const string AdminVerifyTwoFactor = AdminPrefix + "Auth/VerifyTwoFactor";
        public const string AdminLogout = AdminPrefix + "Auth/Logout";
        public const string AdminPermissionKeys = AdminPrefix + "Auth/PermissionKeys";

        /// <summary>The signed-in operator's own record — not the Users module.</summary>
        public const string AdminProfileGet = AdminPrefix + "Auth/Profile";
        public const string AdminProfileSave = AdminPrefix + "Auth/ProfileSave";

        // Customer
        public const string Register = ShopPrefix + "Auth/Register";
        public const string Login = ShopPrefix + "Auth/Login";
        public const string SendOtp = ShopPrefix + "Auth/SendOtp";
        public const string VerifyOtp = ShopPrefix + "Auth/VerifyOtp";
        public const string SocialLogin = ShopPrefix + "Auth/SocialLogin";
        public const string ForgotPassword = ShopPrefix + "Auth/ForgotPassword";
        public const string ResetPassword = ShopPrefix + "Auth/ResetPassword";
        public const string VerifyEmail = ShopPrefix + "Auth/VerifyEmail";
        public const string VerifyMobile = ShopPrefix + "Auth/VerifyMobile";
        public const string CompleteProfile = ShopPrefix + "Auth/CompleteProfile";
        public const string Logout = ShopPrefix + "Auth/Logout";

        /// <summary>Merges the anonymous guest cart into the customer cart on sign-in.</summary>
        public const string MergeGuestCart = ShopPrefix + "Auth/MergeGuestCart";
    }

    #endregion

    #region Product — Catalog module

    public static class Product
    {
        // Admin writes
        public const string GridList = AdminPrefix + "Product/GridList";
        public const string GetById = AdminPrefix + "Product/GetById";
        public const string Save = AdminPrefix + "Product/Save";
        public const string Delete = AdminPrefix + "Product/Delete";
        public const string Duplicate = AdminPrefix + "Product/Duplicate";
        public const string UpdateStatus = AdminPrefix + "Product/UpdateStatus";
        public const string BulkUpdateStatus = AdminPrefix + "Product/BulkUpdateStatus";
        public const string VariantList = AdminPrefix + "Product/VariantList";
        public const string VariantSave = AdminPrefix + "Product/VariantSave";
        public const string MediaSave = AdminPrefix + "Product/MediaSave";
        public const string MediaReorder = AdminPrefix + "Product/MediaReorder";
        public const string BulkImport = AdminPrefix + "Product/BulkImport";
        public const string Export = AdminPrefix + "Product/Export";
        public const string ActivityHistory = AdminPrefix + "Product/ActivityHistory";

        // Storefront reads
        public const string ShopList = ShopPrefix + "Product/List";
        public const string ShopDetail = ShopPrefix + "Product/Detail";
        public const string ShopQuickView = ShopPrefix + "Product/QuickView";
        public const string ShopRelated = ShopPrefix + "Product/Related";
        public const string ShopCompleteTheLook = ShopPrefix + "Product/CompleteTheLook";
        public const string ShopRecentlyViewed = ShopPrefix + "Product/RecentlyViewed";
        public const string ShopRecommended = ShopPrefix + "Product/Recommended";
        public const string ShopCompare = ShopPrefix + "Product/Compare";
        public const string ShopNotifyMe = ShopPrefix + "Product/NotifyMe";
        public const string ShopDeliveryEstimate = ShopPrefix + "Product/DeliveryEstimate";
    }

    #endregion

    #region Category — Categories module

    public static class Category
    {
        public const string GridList = AdminPrefix + "Category/GridList";
        public const string Tree = AdminPrefix + "Category/Tree";
        public const string GetById = AdminPrefix + "Category/GetById";
        public const string Save = AdminPrefix + "Category/Save";
        public const string Reorder = AdminPrefix + "Category/Reorder";
        public const string Delete = AdminPrefix + "Category/Delete";
        public const string UpdateStatus = AdminPrefix + "Category/UpdateStatus";

        // Storefront reads
        public const string ShopMegaMenu = ShopPrefix + "Category/MegaMenu";
        public const string ShopTree = ShopPrefix + "Category/Tree";
        public const string ShopDetail = ShopPrefix + "Category/Detail";
        public const string ShopFeatured = ShopPrefix + "Category/Featured";
    }

    #endregion

    #region Search — Catalog module

    public static class Search
    {
        public const string ShopQuery = ShopPrefix + "Search/Query";
        public const string ShopSuggestions = ShopPrefix + "Search/Suggestions";
        public const string ShopTrending = ShopPrefix + "Search/Trending";
        public const string ShopRecent = ShopPrefix + "Search/Recent";
        public const string ShopClearRecent = ShopPrefix + "Search/ClearRecent";
        public const string ShopFacets = ShopPrefix + "Search/Facets";

        /// <summary>Admin reads the zero-result log to fix merchandising gaps.</summary>
        public const string NoResultLog = AdminPrefix + "Search/NoResultLog";
        public const string SynonymSave = AdminPrefix + "Search/SynonymSave";
    }

    #endregion

    #region Inventory — Inventory module

    public static class Inventory
    {
        public const string StockGridList = AdminPrefix + "Inventory/StockGridList";
        public const string StockLedger = AdminPrefix + "Inventory/StockLedger";
        public const string AdjustmentSave = AdminPrefix + "Inventory/AdjustmentSave";
        public const string TransferSave = AdminPrefix + "Inventory/TransferSave";
        public const string StockTakeSave = AdminPrefix + "Inventory/StockTakeSave";
        public const string PurchaseEntrySave = AdminPrefix + "Inventory/PurchaseEntrySave";
        public const string LowStockAlerts = AdminPrefix + "Inventory/LowStockAlerts";
        public const string WarehouseList = AdminPrefix + "Inventory/WarehouseList";

        /// <summary>
        /// Live availability for a PDP or cart line. The only stock figure the
        /// storefront may quote — "Only 2 left" must never come from a cached list.
        /// </summary>
        public const string ShopAvailability = ShopPrefix + "Inventory/Availability";
    }

    #endregion

    #region Cart — Cart module

    public static class Cart
    {
        public const string ShopGet = ShopPrefix + "Cart/Get";
        public const string ShopAddItem = ShopPrefix + "Cart/AddItem";
        public const string ShopUpdateQuantity = ShopPrefix + "Cart/UpdateQuantity";
        public const string ShopRemoveItem = ShopPrefix + "Cart/RemoveItem";
        public const string ShopSaveForLater = ShopPrefix + "Cart/SaveForLater";
        public const string ShopMoveToCart = ShopPrefix + "Cart/MoveToCart";
        public const string ShopApplyCoupon = ShopPrefix + "Cart/ApplyCoupon";
        public const string ShopRemoveCoupon = ShopPrefix + "Cart/RemoveCoupon";
        public const string ShopApplyPoints = ShopPrefix + "Cart/ApplyPoints";
        public const string ShopSetGiftOptions = ShopPrefix + "Cart/SetGiftOptions";
        public const string ShopSummary = ShopPrefix + "Cart/Summary";

        /// <summary>Admin reads abandoned carts to trigger recovery flows.</summary>
        public const string AbandonedGridList = AdminPrefix + "Cart/AbandonedGridList";
    }

    #endregion

    #region Wishlist & Compare — Customers module

    public static class Wishlist
    {
        public const string ShopGet = ShopPrefix + "Wishlist/Get";
        public const string ShopToggle = ShopPrefix + "Wishlist/Toggle";
        public const string ShopRemove = ShopPrefix + "Wishlist/Remove";
        public const string ShopMoveToCart = ShopPrefix + "Wishlist/MoveToCart";
        public const string ShopShareLink = ShopPrefix + "Wishlist/ShareLink";
    }

    #endregion

    #region Checkout & Order — Orders module

    public static class Order
    {
        // Admin
        public const string GridList = AdminPrefix + "Order/GridList";
        public const string GetById = AdminPrefix + "Order/GetById";
        public const string UpdateStatus = AdminPrefix + "Order/UpdateStatus";
        public const string Cancel = AdminPrefix + "Order/Cancel";
        public const string AddNote = AdminPrefix + "Order/AddNote";
        public const string PickList = AdminPrefix + "Order/PickList";
        public const string DispatchManifest = AdminPrefix + "Order/DispatchManifest";
        public const string InvoiceGetById = AdminPrefix + "Order/InvoiceGetById";
        public const string ReturnGridList = AdminPrefix + "Order/ReturnGridList";
        public const string ReturnApprove = AdminPrefix + "Order/ReturnApprove";
        public const string ReturnReject = AdminPrefix + "Order/ReturnReject";
        public const string Export = AdminPrefix + "Order/Export";
        public const string Dashboard = AdminPrefix + "Order/Dashboard";

        // Storefront
        public const string ShopCheckoutInit = ShopPrefix + "Checkout/Init";
        public const string ShopSetAddress = ShopPrefix + "Checkout/SetAddress";
        public const string ShopSetDeliveryMethod = ShopPrefix + "Checkout/SetDeliveryMethod";
        public const string ShopPlaceOrder = ShopPrefix + "Checkout/PlaceOrder";
        public const string ShopMyOrders = ShopPrefix + "Order/MyOrders";
        public const string ShopOrderDetail = ShopPrefix + "Order/Detail";
        public const string ShopOrderInvoice = ShopPrefix + "Order/Invoice";
        public const string ShopCancelOrder = ShopPrefix + "Order/Cancel";
        public const string ShopRequestReturn = ShopPrefix + "Order/RequestReturn";
        public const string ShopReturnDetail = ShopPrefix + "Order/ReturnDetail";
        public const string ShopReorder = ShopPrefix + "Order/Reorder";
    }

    #endregion

    #region Payment — Payments module

    public static class Payment
    {
        public const string GridList = AdminPrefix + "Payment/GridList";
        public const string GetById = AdminPrefix + "Payment/GetById";
        public const string RefundInitiate = AdminPrefix + "Payment/RefundInitiate";
        public const string RefundApprove = AdminPrefix + "Payment/RefundApprove";
        public const string SettlementGridList = AdminPrefix + "Payment/SettlementGridList";
        public const string DisputeGridList = AdminPrefix + "Payment/DisputeGridList";

        public const string ShopMethods = ShopPrefix + "Payment/Methods";
        public const string ShopInitiate = ShopPrefix + "Payment/Initiate";
        public const string ShopVerify = ShopPrefix + "Payment/Verify";
        public const string ShopSavedCards = ShopPrefix + "Payment/SavedCards";
        public const string ShopRemoveSavedCard = ShopPrefix + "Payment/RemoveSavedCard";

        /// <summary>Gateway server-to-server callback. Never called by a browser.</summary>
        public const string Webhook = "Webhook/Payment";
    }

    #endregion

    #region Shipping — Shipping module

    public static class Shipping
    {
        public const string ZoneGridList = AdminPrefix + "Shipping/ZoneGridList";
        public const string RateSave = AdminPrefix + "Shipping/RateSave";
        public const string CourierList = AdminPrefix + "Shipping/CourierList";
        public const string ShipmentCreate = AdminPrefix + "Shipping/ShipmentCreate";
        public const string LabelGenerate = AdminPrefix + "Shipping/LabelGenerate";
        public const string ZipCodeGridList = AdminPrefix + "Shipping/ZipCodeGridList";

        /// <summary>PIN serviceability + the promised date shown on PDP, cart and checkout.</summary>
        public const string ShopCheckPincode = ShopPrefix + "Shipping/CheckPincode";
        public const string ShopMethods = ShopPrefix + "Shipping/Methods";
        public const string ShopTrack = ShopPrefix + "Shipping/Track";

        /// <summary>Guest tracking — order number plus the email or phone used at checkout.</summary>
        public const string PublicTrack = PublicPrefix + "Track";
        public const string PublicTrackShared = PublicPrefix + "TrackShared";
    }

    #endregion

    #region Promotions — Promotions module

    public static class Promotion
    {
        public const string CouponGridList = AdminPrefix + "Coupon/GridList";
        public const string CouponGetById = AdminPrefix + "Coupon/GetById";
        public const string CouponSave = AdminPrefix + "Coupon/Save";
        public const string CouponUpdateStatus = AdminPrefix + "Coupon/UpdateStatus";
        public const string OfferGridList = AdminPrefix + "Offer/GridList";
        public const string OfferSave = AdminPrefix + "Offer/Save";
        public const string FlashSaleList = AdminPrefix + "Offer/FlashSaleList";

        /// <summary>Coupons the signed-in shopper may actually use, with eligibility.</summary>
        public const string ShopMyCoupons = ShopPrefix + "Coupon/MyCoupons";
        public const string ShopValidateCoupon = ShopPrefix + "Coupon/Validate";
        public const string ShopActiveOffers = ShopPrefix + "Offer/Active";

        /// <summary>
        /// Server-time anchored sale window. The storefront countdown must render from
        /// this and remove itself at zero — never restart (CX principle 3).
        /// </summary>
        public const string ShopFlashSale = ShopPrefix + "Offer/FlashSale";
    }

    #endregion

    #region Banners — Banners module

    public static class Banner
    {
        public const string GridList = AdminPrefix + "Banner/GridList";
        public const string GetById = AdminPrefix + "Banner/GetById";
        public const string Save = AdminPrefix + "Banner/Save";
        public const string UpdateStatus = AdminPrefix + "Banner/UpdateStatus";
        public const string PlacementList = AdminPrefix + "Banner/PlacementList";

        /// <summary>Scheduled, published banners for one placement. Drives the home hero.</summary>
        public const string ShopByPlacement = ShopPrefix + "Banner/ByPlacement";
    }

    #endregion

    #region Content — Cms, Blog, Testimonials modules

    public static class Content
    {
        public const string CmsPageGridList = AdminPrefix + "CmsPage/GridList";
        public const string CmsPageSave = AdminPrefix + "CmsPage/Save";
        public const string FaqGridList = AdminPrefix + "Faq/GridList";
        public const string FaqSave = AdminPrefix + "Faq/Save";
        public const string MenuSave = AdminPrefix + "Menu/Save";

        public const string BlogGridList = AdminPrefix + "Blog/GridList";
        public const string BlogSave = AdminPrefix + "Blog/Save";
        public const string BlogUpdateStatus = AdminPrefix + "Blog/UpdateStatus";
        public const string BlogCommentModerate = AdminPrefix + "Blog/CommentModerate";

        public const string TestimonialGridList = AdminPrefix + "Testimonial/GridList";
        public const string TestimonialSave = AdminPrefix + "Testimonial/Save";

        public const string ArtisanGridList = AdminPrefix + "Artisan/GridList";
        public const string ArtisanSave = AdminPrefix + "Artisan/Save";

        // Storefront reads
        public const string ShopPage = ShopPrefix + "Page/BySlug";
        public const string ShopFaqs = ShopPrefix + "Page/Faqs";
        public const string ShopMenu = ShopPrefix + "Page/Menu";
        public const string ShopBlogList = ShopPrefix + "Blog/List";
        public const string ShopBlogDetail = ShopPrefix + "Blog/Detail";
        public const string ShopTestimonials = ShopPrefix + "Testimonial/List";
        public const string ShopArtisanList = ShopPrefix + "Artisan/List";
        public const string ShopArtisanDetail = ShopPrefix + "Artisan/Detail";
    }

    #endregion

    #region Reviews — Reviews module

    public static class Review
    {
        public const string Queue = AdminPrefix + "Review/Queue";
        public const string GetById = AdminPrefix + "Review/GetById";
        public const string Approve = AdminPrefix + "Review/Approve";
        public const string Reject = AdminPrefix + "Review/Reject";
        public const string Reply = AdminPrefix + "Review/Reply";

        /// <summary>Approved reviews only. The PDP summary and breakdown come from here.</summary>
        public const string ShopByProduct = ShopPrefix + "Review/ByProduct";
        public const string ShopSummary = ShopPrefix + "Review/Summary";
        public const string ShopSubmit = ShopPrefix + "Review/Submit";
        public const string ShopMyReviews = ShopPrefix + "Review/MyReviews";
        public const string ShopPendingForMe = ShopPrefix + "Review/PendingForMe";
        public const string ShopMarkHelpful = ShopPrefix + "Review/MarkHelpful";
    }

    #endregion

    #region Customer account — Customers module

    public static class Customer
    {
        public const string GridList = AdminPrefix + "Customer/GridList";
        public const string GetById = AdminPrefix + "Customer/GetById";
        public const string UpdateStatus = AdminPrefix + "Customer/UpdateStatus";
        public const string SegmentGridList = AdminPrefix + "Segment/GridList";

        public const string ShopDashboard = ShopPrefix + "Account/Dashboard";
        public const string ShopProfileGet = ShopPrefix + "Account/Profile";
        public const string ShopProfileSave = ShopPrefix + "Account/ProfileSave";
        public const string ShopAddressList = ShopPrefix + "Account/AddressList";
        public const string ShopAddressSave = ShopPrefix + "Account/AddressSave";
        public const string ShopAddressDelete = ShopPrefix + "Account/AddressDelete";
        public const string ShopSetDefaultAddress = ShopPrefix + "Account/SetDefaultAddress";
        public const string ShopPreferencesGet = ShopPrefix + "Account/Preferences";
        public const string ShopPreferencesSave = ShopPrefix + "Account/PreferencesSave";
        public const string ShopChangePassword = ShopPrefix + "Account/ChangePassword";
        public const string ShopSessions = ShopPrefix + "Account/Sessions";
        public const string ShopRevokeSession = ShopPrefix + "Account/RevokeSession";
        public const string ShopExportData = ShopPrefix + "Account/ExportData";
        public const string ShopDeleteAccount = ShopPrefix + "Account/DeleteAccount";
        public const string ShopReferrals = ShopPrefix + "Account/Referrals";
    }

    #endregion

    #region Rewards — Promotions module

    public static class Rewards
    {
        public const string LedgerGridList = AdminPrefix + "Rewards/LedgerGridList";
        public const string Adjust = AdminPrefix + "Rewards/Adjust";
        public const string TierSave = AdminPrefix + "Rewards/TierSave";

        public const string ShopBalance = ShopPrefix + "Rewards/Balance";
        public const string ShopLedger = ShopPrefix + "Rewards/Ledger";
        public const string ShopTiers = ShopPrefix + "Rewards/Tiers";
    }

    #endregion

    #region Support — Support module

    public static class Support
    {
        public const string TicketGridList = AdminPrefix + "Support/TicketGridList";
        public const string TicketGetById = AdminPrefix + "Support/TicketGetById";
        public const string TicketReply = AdminPrefix + "Support/TicketReply";
        public const string TicketUpdateStatus = AdminPrefix + "Support/TicketUpdateStatus";
        public const string ContactSubmissionGridList = AdminPrefix + "Support/ContactSubmissionGridList";

        public const string ShopMyTickets = ShopPrefix + "Support/MyTickets";
        public const string ShopTicketDetail = ShopPrefix + "Support/TicketDetail";
        public const string ShopCreateTicket = ShopPrefix + "Support/CreateTicket";
        public const string ShopReplyTicket = ShopPrefix + "Support/ReplyTicket";
        public const string ShopContactSubmit = ShopPrefix + "Support/ContactSubmit";
        public const string ShopHelpArticles = ShopPrefix + "Support/HelpArticles";
    }

    #endregion

    #region Notifications & Newsletter

    public static class Notification
    {
        public const string TemplateGridList = AdminPrefix + "Notification/TemplateGridList";
        public const string TemplateSave = AdminPrefix + "Notification/TemplateSave";
        public const string Send = AdminPrefix + "Notification/Send";
        public const string GetBell = AdminPrefix + "Notification/GetBell";
        public const string MarkRead = AdminPrefix + "Notification/MarkRead";

        public const string ShopList = ShopPrefix + "Notification/List";
        public const string ShopMarkRead = ShopPrefix + "Notification/MarkRead";
        public const string ShopMarkAllRead = ShopPrefix + "Notification/MarkAllRead";
        public const string ShopUnreadCount = ShopPrefix + "Notification/UnreadCount";
    }

    public static class Newsletter
    {
        public const string SubscriberGridList = AdminPrefix + "Newsletter/SubscriberGridList";
        public const string CampaignSave = AdminPrefix + "Newsletter/CampaignSave";
        public const string CampaignSend = AdminPrefix + "Newsletter/CampaignSend";
        public const string FlowSave = AdminPrefix + "Newsletter/FlowSave";
        public const string SuppressionList = AdminPrefix + "Newsletter/SuppressionList";

        public const string ShopSubscribe = ShopPrefix + "Newsletter/Subscribe";

        /// <summary>One click from any email. Never behind a sign-in (§8.1).</summary>
        public const string PublicUnsubscribe = PublicPrefix + "Newsletter/Unsubscribe";
    }

    #endregion

    #region Reports, SEO, Settings, Media, Locations

    public static class Report
    {
        public const string Dashboard = AdminPrefix + "Report/Dashboard";
        public const string Sales = AdminPrefix + "Report/Sales";
        public const string Products = AdminPrefix + "Report/Products";
        public const string InventoryReport = AdminPrefix + "Report/Inventory";
        public const string Tax = AdminPrefix + "Report/Tax";
        public const string SavedList = AdminPrefix + "Report/SavedList";
        public const string Export = AdminPrefix + "Report/Export";
    }

    public static class Seo
    {
        public const string MetaGridList = AdminPrefix + "Seo/MetaGridList";
        public const string MetaSave = AdminPrefix + "Seo/MetaSave";
        public const string RedirectGridList = AdminPrefix + "Seo/RedirectGridList";
        public const string RedirectSave = AdminPrefix + "Seo/RedirectSave";
        public const string NotFoundLog = AdminPrefix + "Seo/NotFoundLog";
        public const string SitemapRegenerate = AdminPrefix + "Seo/SitemapRegenerate";

        /// <summary>Meta, canonical, OG and JSON-LD for one storefront route.</summary>
        public const string ShopMetaForRoute = ShopPrefix + "Seo/MetaForRoute";
        public const string PublicSitemap = PublicPrefix + "Seo/Sitemap";
        public const string PublicRobots = PublicPrefix + "Seo/Robots";
    }

    public static class Settings
    {
        public const string GetSection = AdminPrefix + "Settings/GetSection";
        public const string SaveSection = AdminPrefix + "Settings/SaveSection";
        public const string History = AdminPrefix + "Settings/History";
        public const string IntegrationList = AdminPrefix + "Settings/IntegrationList";

        /// <summary>
        /// The storefront's runtime configuration: free-shipping threshold, COD fee,
        /// return window, contact details, currency and locale. Cached, but every
        /// figure the customer sees must originate here rather than being hard-coded.
        /// </summary>
        public const string ShopStorefrontConfig = ShopPrefix + "Settings/StorefrontConfig";
    }

    public static class Media
    {
        public const string GridList = AdminPrefix + "Media/GridList";
        public const string Upload = AdminPrefix + "Media/Upload";
        public const string Delete = AdminPrefix + "Media/Delete";
    }

    public static class Location
    {
        public const string CountryList = AdminPrefix + "Location/CountryList";
        public const string StateList = AdminPrefix + "Location/StateList";
        public const string CityList = AdminPrefix + "Location/CityList";

        /// <summary>PIN → city and state, so checkout autofills two fields.</summary>
        public const string ShopPincodeLookup = ShopPrefix + "Location/PincodeLookup";
        public const string ShopStateList = ShopPrefix + "Location/StateList";
    }

    #endregion

    #region AI — Module 20

    public static class Ai
    {
        public const string ShopAssistantMessage = ShopPrefix + "Ai/AssistantMessage";
        public const string ShopVisualSearch = ShopPrefix + "Ai/VisualSearch";
        public const string ShopReviewSummary = ShopPrefix + "Ai/ReviewSummary";
        public const string ShopClearConversation = ShopPrefix + "Ai/ClearConversation";
    }

    #endregion
}
