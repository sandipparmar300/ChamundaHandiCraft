using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace ChamundaHandicraft.Admin.Services;

/// <summary>
/// Design-phase data for the Admin panel, served through the same interface and the
/// same envelope the gateway will use — so the controllers, views and error paths
/// exercised now are the ones that ship.
///
/// Rows come from <see cref="DemoData"/> and deliberately mirror the storefront's own
/// catalogue: same slugs, SKUs, order numbers and artisans. Publishing
/// <c>jaipur-blue-pottery-vase</c> here is the record the customer site serves at
/// <c>/p/jaipur-blue-pottery-vase</c>.
///
/// Swap for <see cref="GatewayAdminClient"/> in Program.cs once the API exists.
/// </summary>
public class DemoAdminClient : IAdminClient
{
    private static ResponseViewModel<T> Ok<T>(T data) => ResponseViewModel<T>.Success(data);

    /// <summary>
    /// Pages and filters an in-memory list the way the API will, so the grid's paging
    /// and empty states are exercised rather than assumed.
    /// </summary>
    private static PagedResult<T> Page<T>(List<T> rows, DataTableRequest request)
    {
        if (!string.IsNullOrWhiteSpace(request.Search) && rows is List<IAdminGridRow> _)
        {
            // Handled by the typed overload below; kept simple here.
        }

        return new PagedResult<T>
        {
            Items = rows.Skip(request.Skip).Take(request.PageSize).ToList(),
            TotalCount = rows.Count,
            Page = request.Page,
            PageSize = request.PageSize
        };
    }

    #region Generic CRUD

    public Task<ResponseViewModel<PagedResult<T>>> GetGridAsync<T>(
        string endpoint, DataTableRequest request, CancellationToken ct = default)
    {
        var rows = DemoData.For<T>();

        // Search across the row's display name where the type opts in.
        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            rows = rows
                .Where(r => r is not IAdminGridRow row
                            || row.DisplayName.Contains(request.Search, StringComparison.OrdinalIgnoreCase))
                .ToList();
        }

        return Task.FromResult(Ok(Page(rows, request)));
    }

    public Task<ResponseViewModel<T>> GetByIdAsync<T>(string endpoint, int id, CancellationToken ct = default)
    {
        var rows = DemoData.For<T>();

        var match = rows.FirstOrDefault(r => r is IAdminGridRow row && row.Id == id)
                    ?? rows.FirstOrDefault();

        return Task.FromResult(match is null
            ? ResponseViewModel<T>.Fail("We couldn't find that record.", ApiStatusCode.NotFound)
            : Ok(match));
    }

    public Task<ResponseViewModel<int>> SaveAsync<TRequest>(
        string endpoint, TRequest payload, CancellationToken ct = default) =>
        Task.FromResult(ResponseViewModel<int>.Success(1, "Saved successfully."));

    public Task<ResponseViewModel<bool>> DeleteAsync(string endpoint, int id, CancellationToken ct = default) =>
        Task.FromResult(ResponseViewModel<bool>.Success(true, "Deleted successfully."));

    public Task<ResponseViewModel<bool>> UpdateStatusAsync(
        string endpoint, UpdateStatusRequest request, CancellationToken ct = default) =>
        Task.FromResult(ResponseViewModel<bool>.Success(true, "Status updated."));

    public Task<ResponseViewModel<List<IdNamePair>>> GetLookupAsync(
        string endpoint, IDictionary<string, string?>? filter = null, CancellationToken ct = default)
    {
        // Every dropdown the admin forms need, keyed off the endpoint they asked for.
        var options = endpoint switch
        {
            var e when e.Contains("Country", StringComparison.OrdinalIgnoreCase) =>
                DemoData.Countries().Select(c => new IdNamePair { Id = c.Id, Name = c.CountryName, IsActive = c.IsActive }),

            var e when e.Contains("State", StringComparison.OrdinalIgnoreCase) =>
                DemoData.States().Select(s => new IdNamePair { Id = s.Id, Name = s.StateName, ParentId = s.CountryId }),

            var e when e.Contains("City", StringComparison.OrdinalIgnoreCase) =>
                DemoData.Cities().Select(c => new IdNamePair { Id = c.Id, Name = c.CityName, ParentId = c.StateId }),

            var e when e.Contains("Category", StringComparison.OrdinalIgnoreCase) =>
                new[]
                {
                    new IdNamePair { Id = 1, Name = "Home Décor", Slug = "home-decor", Count = 428 },
                    new IdNamePair { Id = 2, Name = "Pottery & Ceramics", Slug = "pottery", Count = 216 },
                    new IdNamePair { Id = 3, Name = "Textiles", Slug = "textiles", Count = 384 },
                    new IdNamePair { Id = 4, Name = "Brass & Metal", Slug = "brassware", Count = 192 },
                    new IdNamePair { Id = 5, Name = "Jewellery", Slug = "jewellery", Count = 267 },
                    new IdNamePair { Id = 6, Name = "Gifting", Slug = "gifting", Count = 158 }
                }.AsEnumerable(),

            var e when e.Contains("Warehouse", StringComparison.OrdinalIgnoreCase) =>
                DemoData.Warehouses().Select(w => new IdNamePair { Id = w.Id, Name = w.WarehouseName }),

            var e when e.Contains("Courier", StringComparison.OrdinalIgnoreCase) =>
                DemoData.Couriers().Select(c => new IdNamePair { Id = c.Id, Name = c.CourierName }),

            var e when e.Contains("Supplier", StringComparison.OrdinalIgnoreCase) =>
                DemoData.Suppliers().Select(s => new IdNamePair { Id = s.Id, Name = s.SupplierName }),

            var e when e.Contains("Role", StringComparison.OrdinalIgnoreCase) =>
                DemoData.Roles().Select(r => new IdNamePair { Id = r.Id, Name = r.RoleName }),

            var e when e.Contains("Brand", StringComparison.OrdinalIgnoreCase) =>
                DemoData.Brands().Select(b => new IdNamePair { Id = b.Id, Name = b.BrandName }),

            var e when e.Contains("Artisan", StringComparison.OrdinalIgnoreCase) =>
                DemoData.Artisans().Select(a => new IdNamePair { Id = a.Id, Name = a.Name }),

            _ => Enumerable.Empty<IdNamePair>()
        };

        return Task.FromResult(Ok(options.ToList()));
    }

    #endregion

    #region Dashboard

    public Task<ResponseViewModel<AdminDashboardViewModel>> GetDashboardAsync(CancellationToken ct = default)
    {
        var products = ProductRows();

        return Task.FromResult(Ok(new AdminDashboardViewModel
        {
            TotalOrders = 1482,
            TodaysOrders = 23,
            PendingOrders = 8,
            ProcessingOrders = 14,
            PackedOrders = 6,
            ShippedOrders = 31,
            DeliveredOrders = 1394,
            CancelledOrders = 22,
            ReturnedOrders = 17,
            RefundPending = 1,
            TotalSales = 4_218_650m,
            AverageOrderValue = 2846m,
            LowStockCount = products.Count(p => p.StockQuantity is > 0 and <= 5),
            OutOfStockCount = products.Count(p => p.StockQuantity == 0),
            PendingReviewCount = 1,
            OpenTicketCount = DemoData.Tickets().Count(t => t.IsActive),
            AbandonedCartCount = 38,
            RecentOrders = DemoOrders().Take(5).ToList(),
            LowStockProducts = products.Where(p => p.StockQuantity <= 5).ToList()
        }));
    }

    #endregion

    #region Catalogue

    private static readonly (string Slug, string Name, string Sku, string Category, string Brand, decimal Price,
        decimal? Mrp, int Stock, ProductStatus Status)[] Catalogue =
    {
        ("jaipur-blue-pottery-vase", "Blue Pottery Vase — Jaipur Floral", "HC-POT-0421", "Home Décor", "Sanganer Blue", 1250, 1600, 3, ProductStatus.Published),
        ("kantha-cushion-cover-set", "Kantha Cushion Covers — Set of 2", "HC-TEX-0903", "Textiles", "Kantha Collective", 1890, 2400, 42, ProductStatus.Published),
        ("moradabad-brass-diya-set", "Moradabad Brass Diya Set of 6", "HC-BRS-1180", "Brass & Metal", "Moradabad Metals", 2150, null, 68, ProductStatus.Published),
        ("channapatna-lacquer-bowls", "Channapatna Lacquered Bowls — Trio", "HC-WOD-0288", "Home Décor", "Chamunda Originals", 1450, 1750, 24, ProductStatus.Published),
        ("silver-filigree-jhumka", "Silver Filigree Jhumkas — Cuttack", "HC-JWL-0655", "Jewellery", "Chamunda Originals", 3400, 4200, 11, ProductStatus.Published),
        ("sikki-grass-basket", "Sikki Grass Storage Basket", "HC-BSK-0117", "Home Décor", "Chamunda Originals", 980, null, 9, ProductStatus.Published),
        ("madhubani-wall-art", "Madhubani Painting — Tree of Life", "HC-ART-0042", "Home Décor", "Chamunda Originals", 4600, 5800, 2, ProductStatus.Published),
        ("terracotta-planter-tall", "Terracotta Planter — Tall Fluted", "HC-POT-0509", "Pottery & Ceramics", "Sanganer Blue", 1650, null, 0, ProductStatus.Published),
        ("brass-urli-bowl", "Brass Urli Bowl with Stand", "HC-BRS-1204", "Brass & Metal", "Moradabad Metals", 3250, 3900, 17, ProductStatus.Published),
        ("block-print-table-runner", "Bagru Block-Print Table Runner", "HC-TEX-0941", "Textiles", "Kantha Collective", 1120, null, 55, ProductStatus.Published),
        ("dhokra-figurine-musician", "Dhokra Figurine — Tribal Musician", "HC-MTL-0330", "Home Décor", "Chamunda Originals", 2750, null, 6, ProductStatus.Draft),
        ("marble-inlay-coaster-set", "Marble Inlay Coasters — Set of 4", "HC-GFT-0774", "Gifting", "Chamunda Originals", 1980, 2400, 31, ProductStatus.Unpublished)
    };

    private static List<ProductGridItem> ProductRows() =>
        Catalogue.Select((p, i) => new ProductGridItem
        {
            Id = i + 1,
            Name = p.Name,
            Sku = p.Sku,
            ProductCode = $"PC-{1000 + i}",
            Barcode = $"890{2000000 + i}",
            ImageUrl = "/assets/images/default-profile.png",
            CategoryName = p.Category,
            BrandName = p.Brand,
            Price = p.Price,
            Mrp = p.Mrp,
            DiscountPercent = Helper.CommonMethod.Money.DiscountPercent(p.Price, p.Mrp),
            StockQuantity = p.Stock,
            Status = p.Status,
            Visibility = ProductVisibility.Everywhere,
            IsFeatured = i < 3,
            IsBestseller = i is 0 or 2,

            // One unambiguous answer to "can a shopper see this right now".
            IsLiveOnStorefront = p.Status == ProductStatus.Published,

            StorefrontUrl = $"/p/{p.Slug}",
            CreatedOn = DateTime.Today.AddDays(-30 + i),
            CreatedBy = "Priya Nair"
        }).ToList();

    public Task<ResponseViewModel<PagedResult<ProductGridItem>>> GetProductsAsync(
        DataTableRequest request, CancellationToken ct = default)
    {
        var rows = ProductRows();

        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            rows = rows.Where(r =>
                r.Name.Contains(request.Search, StringComparison.OrdinalIgnoreCase) ||
                r.Sku.Contains(request.Search, StringComparison.OrdinalIgnoreCase) ||
                r.ProductCode.Contains(request.Search, StringComparison.OrdinalIgnoreCase)).ToList();
        }

        return Task.FromResult(Ok(Page(rows, request)));
    }

    public Task<ResponseViewModel<ProductSaveRequest>> GetProductAsync(int id, CancellationToken ct = default)
    {
        var index = Math.Clamp(id - 1, 0, Catalogue.Length - 1);
        var p = Catalogue[index];

        return Task.FromResult(Ok(new ProductSaveRequest
        {
            Id = id,
            Name = p.Name,
            Sku = p.Sku,
            Slug = p.Slug,
            ProductCode = $"PC-{1000 + index}",
            Barcode = $"890{2000000 + index}",
            Price = p.Price,
            Mrp = p.Mrp,
            Status = p.Status,
            ShortDescription = "Thrown from quartz clay and painted with natural cobalt oxide, then twice-fired.",
            FullDescription = "The body is a dough of quartz powder, powdered glass and fuller's earth — "
                              + "Jaipur blue pottery contains no clay at all.",
            ProductStory = "Ram Prasad Sharma learned the craft from his father at eleven, in the same "
                           + "courtyard he works in today.",
            CareInstructions = "Hand wash with a soft damp cloth. Not dishwasher, microwave or oven safe.",
            Material = "Quartz clay, cobalt oxide glaze",
            LengthCm = 12, WidthCm = 12, HeightCm = 24, WeightGrams = 850,
            LowStockThreshold = 5,
            MaxQuantityPerOrder = 3,
            ArtisanId = 1,
            CategoryId = 1
        }));
    }

    public Task<ResponseViewModel<int>> SaveProductAsync(ProductSaveRequest request, CancellationToken ct = default) =>
        Task.FromResult(ResponseViewModel<int>.Success(
            request.Id == 0 ? Catalogue.Length + 1 : request.Id,
            request.Status == ProductStatus.Published
                ? "Published. It is now live on the storefront."
                : "Saved successfully."));

    public Task<ResponseViewModel<bool>> UpdateProductStatusAsync(
        UpdateStatusRequest request, CancellationToken ct = default) =>
        Task.FromResult(ResponseViewModel<bool>.Success(
            true,
            (ProductStatus)request.Status == ProductStatus.Published
                ? "Published. It is now live on the storefront."
                : "Unpublished. It is no longer visible to shoppers."));

    public Task<ResponseViewModel<List<CategoryViewModel>>> GetCategoryTreeAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok(new List<CategoryViewModel>
        {
            new()
            {
                Id = 1, Slug = "home-decor", Name = "Home Décor", ProductCount = 428,
                IntroCopy = "Vases, wall art, lamps and figurines made by named artisans across India.",
                Children =
                {
                    new() { Id = 11, Slug = "vases", Name = "Vases & Planters", ParentId = 1, ProductCount = 84 },
                    new() { Id = 12, Slug = "wall-art", Name = "Wall Art", ParentId = 1, ProductCount = 102 },
                    new() { Id = 13, Slug = "lamps", Name = "Lamps & Lighting", ParentId = 1, ProductCount = 68 }
                }
            },
            new() { Id = 2, Slug = "pottery", Name = "Pottery & Ceramics", ProductCount = 216 },
            new() { Id = 3, Slug = "textiles", Name = "Textiles", ProductCount = 384 },
            new() { Id = 4, Slug = "brassware", Name = "Brass & Metal", ProductCount = 192 },
            new() { Id = 5, Slug = "jewellery", Name = "Jewellery", ProductCount = 267 },
            new() { Id = 6, Slug = "gifting", Name = "Gifting", ProductCount = 158 }
        }));

    public Task<ResponseViewModel<int>> SaveCategoryAsync(CategorySaveRequest request, CancellationToken ct = default) =>
        Task.FromResult(ResponseViewModel<int>.Success(request.Id == 0 ? 7 : request.Id, "Saved successfully."));

    public Task<ResponseViewModel<PagedResult<StockGridItem>>> GetStockAsync(
        DataTableRequest request, CancellationToken ct = default)
    {
        var rows = Catalogue.Select((p, i) => new StockGridItem
        {
            ProductId = i + 1,
            ProductName = p.Name,
            Sku = p.Sku,
            WarehouseName = "Jaipur Studio",
            OnHand = p.Stock,
            Reserved = p.Stock > 4 ? 2 : 0
        }).ToList();

        return Task.FromResult(Ok(Page(rows, request)));
    }

    #endregion

    #region Orders

    private static List<OrderGridItem> DemoOrders() => new()
    {
        new()
        {
            Id = 482, OrderNumber = "HC-2026-000482", PlacedOn = DateTime.Today.AddDays(-3),
            CustomerName = "Ananya Iyer", CustomerId = 1204, CustomerEmail = "ananya@example.com",
            CustomerPhone = "+91 98765 43210", Total = 5290, ItemCount = 3,
            PaymentMethod = PaymentMethod.Upi, PaymentStatus = PaymentStatus.Paid,
            Status = OrderStatus.OutForDelivery, Courier = "Delhivery", TrackingNumber = "DLV8842190237",
            DeliveryBy = DateTime.Today, ShipToCity = "Ahmedabad", ShipToPincode = "380015"
        },
        new()
        {
            Id = 488, OrderNumber = "HC-2026-000488", PlacedOn = DateTime.Today,
            CustomerName = "Kabir Menon", CustomerId = 1622, CustomerEmail = "kabir.m@example.com",
            Total = 2150, ItemCount = 1,
            PaymentMethod = PaymentMethod.Upi, PaymentStatus = PaymentStatus.Pending,
            Status = OrderStatus.PaymentPending, ShipToCity = "Kochi", ShipToPincode = "682016"
        },
        new()
        {
            Id = 476, OrderNumber = "HC-2026-000476", PlacedOn = DateTime.Today.AddDays(-5),
            CustomerName = "Fatima Khan", CustomerId = 1511, Total = 8940, ItemCount = 4,
            PaymentMethod = PaymentMethod.NetBanking, PaymentStatus = PaymentStatus.Paid,
            Status = OrderStatus.Packed, ShipToCity = "Bengaluru", ShipToPincode = "560038",
            DeliveryBy = DateTime.Today.AddDays(-1), IsBreachingSla = true
        },
        new()
        {
            Id = 391, OrderNumber = "HC-2026-000391", PlacedOn = DateTime.Today.AddDays(-24),
            CustomerName = "Ananya Iyer", CustomerId = 1204, Total = 3400, ItemCount = 1,
            PaymentMethod = PaymentMethod.Card, PaymentStatus = PaymentStatus.Paid,
            Status = OrderStatus.Delivered, Courier = "Blue Dart",
            ShipToCity = "Ahmedabad", ShipToPincode = "380015"
        },
        new()
        {
            Id = 287, OrderNumber = "HC-2026-000287", PlacedOn = DateTime.Today.AddDays(-62),
            CustomerName = "Rahul Sharma", CustomerId = 987, Total = 1650, ItemCount = 1,
            PaymentMethod = PaymentMethod.CashOnDelivery, PaymentStatus = PaymentStatus.Refunded,
            Status = OrderStatus.Refunded, HasReturnRequest = true,
            ShipToCity = "Pune", ShipToPincode = "411001"
        }
    };

    public Task<ResponseViewModel<PagedResult<OrderGridItem>>> GetOrdersAsync(
        DataTableRequest request, CancellationToken ct = default)
    {
        var rows = DemoOrders();

        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            rows = rows.Where(r =>
                r.OrderNumber.Contains(request.Search, StringComparison.OrdinalIgnoreCase) ||
                r.CustomerName.Contains(request.Search, StringComparison.OrdinalIgnoreCase)).ToList();
        }

        return Task.FromResult(Ok(Page(rows, request)));
    }

    public Task<ResponseViewModel<OrderDetailAdminViewModel>> GetOrderAsync(int id, CancellationToken ct = default)
    {
        var header = DemoOrders().FirstOrDefault(o => o.Id == id) ?? DemoOrders()[0];

        var lines = new List<CartLineViewModel>
        {
            new()
            {
                Slug = "jaipur-blue-pottery-vase", Name = "Blue Pottery Vase — Jaipur Floral",
                ImageUrl = "/assets/images/default-profile.png", Sku = "HC-POT-0421",
                VariantSummary = "Size: Medium · Colour: Cobalt", Price = 1250, Mrp = 1600, Quantity = 1,
                DeliveryBy = header.DeliveryBy
            },
            new()
            {
                Slug = "moradabad-brass-diya-set", Name = "Moradabad Brass Diya Set of 6",
                ImageUrl = "/assets/images/default-profile.png", Sku = "HC-BRS-1180",
                VariantSummary = "Finish: Antique", Price = 2150, Quantity = 2,
                DeliveryBy = header.DeliveryBy
            }
        };

        var summary = new OrderSummaryViewModel
        {
            Subtotal = lines.Sum(l => l.LineTotal),
            MrpTotal = lines.Sum(l => (l.Mrp ?? l.Price) * l.Quantity),
            CouponCode = "FESTIVE10",
            CouponDiscount = 555,
            Shipping = 0,
            ItemCount = lines.Sum(l => l.Quantity)
        };

        return Task.FromResult(Ok(new OrderDetailAdminViewModel
        {
            Header = header,
            Lines = lines,
            Summary = summary,
            ShippingAddress = new AddressViewModel
            {
                FullName = header.CustomerName, Phone = header.CustomerPhone ?? "+91 98765 43210",
                Line1 = "402, Sundar Residency", Line2 = "Nehru Nagar Road",
                Landmark = "Opposite Bal Bhavan", City = header.ShipToCity,
                State = "Gujarat", Pincode = header.ShipToPincode, IsDefault = true
            },
            PaymentReference = "pay_Nx8k2mQ",
            Timeline = new List<OrderTimelineStep>
            {
                new() { Title = "Order placed", Meta = "We received the order", At = header.PlacedOn.AddHours(11), Icon = "i-circle-check", State = "done" },
                new() { Title = "Packed", Meta = "Wrapped in recycled kraft with corner guards", At = header.PlacedOn.AddDays(1), Icon = "i-package-check", State = "done" },
                new() { Title = "Shipped", Meta = $"Picked up by {header.Courier ?? "courier"}", At = header.PlacedOn.AddDays(2), Icon = "i-truck", State = "done" },
                new() { Title = "Out for delivery", Meta = "Arriving today between 10am and 6pm", Icon = "i-bike", State = "current" },
                new() { Title = "Delivered", Icon = "i-home", State = "upcoming" }
            },
            Notes = new List<OrderNoteViewModel>
            {
                new() { Id = 1, Body = "Customer asked for delivery after 2pm.", Author = "Nikhil Desai", CreatedOn = header.PlacedOn.AddHours(14), IsInternal = false },
                new() { Id = 2, Body = "Fragile — double-boxed.", Author = "Vikram Singh", CreatedOn = header.PlacedOn.AddDays(1), IsInternal = true }
            },

            // Only the legal next steps, so an operator cannot skip Packed and jump to Delivered.
            AllowedNextStatuses = header.Status switch
            {
                OrderStatus.PaymentPending => new List<OrderStatus> { OrderStatus.Processing, OrderStatus.Cancelled },
                OrderStatus.Placed or OrderStatus.Processing => new List<OrderStatus> { OrderStatus.Packed, OrderStatus.Cancelled },
                OrderStatus.Packed => new List<OrderStatus> { OrderStatus.Shipped, OrderStatus.Cancelled },
                OrderStatus.Shipped => new List<OrderStatus> { OrderStatus.InTransit, OrderStatus.OutForDelivery },
                OrderStatus.InTransit => new List<OrderStatus> { OrderStatus.OutForDelivery },
                OrderStatus.OutForDelivery => new List<OrderStatus> { OrderStatus.Delivered },
                OrderStatus.Delivered => new List<OrderStatus> { OrderStatus.Completed },
                _ => new List<OrderStatus>()
            },
            InvoiceUrl = $"/Invoice/Details/{header.Id}"
        }));
    }

    public Task<ResponseViewModel<bool>> UpdateOrderStatusAsync(
        OrderStatusUpdateRequest request, CancellationToken ct = default) =>
        Task.FromResult(ResponseViewModel<bool>.Success(
            true,
            request.NotifyCustomer
                ? "Status updated. The customer has been notified."
                : "Status updated. No notification was sent."));

    private static List<ReturnRequestViewModel> DemoReturns() => new()
    {
        new()
        {
            Id = 119, RmaNumber = "RMA-2026-00119", OrderNumber = "HC-2026-000287",
            RequestedOn = DateTime.Today.AddDays(-58), Reason = ReturnReason.DamagedOrBroken,
            Resolution = ReturnResolution.Refund, RefundAmount = 1650, Status = OrderStatus.Refunded,
            CustomerNote = "Arrived with a hairline crack near the rim.",
            PickupScheduledOn = DateTime.Today.AddDays(-56),
            Lines = new List<ReturnLineViewModel>
            {
                new() { OrderLineId = 1, ProductName = "Terracotta Planter — Tall Fluted", Sku = "HC-POT-0509", ImageUrl = "/assets/images/default-profile.png", Quantity = 1, LineRefund = 1650 }
            }
        },
        new()
        {
            Id = 124, RmaNumber = "RMA-2026-00124", OrderNumber = "HC-2026-000391",
            RequestedOn = DateTime.Today.AddDays(-2), Reason = ReturnReason.SizeUnsuitable,
            Resolution = ReturnResolution.StoreCredit, RefundAmount = 3740, Status = OrderStatus.ReturnRequested,
            CustomerNote = "Lovely but too small for the shelf I had in mind.",
            Lines = new List<ReturnLineViewModel>
            {
                new() { OrderLineId = 2, ProductName = "Silver Filigree Jhumkas — Cuttack", Sku = "HC-JWL-0655", ImageUrl = "/assets/images/default-profile.png", Quantity = 1, LineRefund = 3400 }
            }
        }
    };

    public Task<ResponseViewModel<PagedResult<ReturnRequestViewModel>>> GetReturnsAsync(
        DataTableRequest request, CancellationToken ct = default) =>
        Task.FromResult(Ok(Page(DemoReturns(), request)));

    public Task<ResponseViewModel<ReturnRequestViewModel>> GetReturnAsync(int id, CancellationToken ct = default)
    {
        var match = DemoReturns().FirstOrDefault(r => r.Id == id) ?? DemoReturns()[0];
        return Task.FromResult(Ok(match));
    }

    #endregion

    #region Promotions & content

    public Task<ResponseViewModel<int>> SaveCouponAsync(CouponSaveRequest request, CancellationToken ct = default) =>
        Task.FromResult(ResponseViewModel<int>.Success(request.Id == 0 ? 6 : request.Id, "Saved successfully."));

    public Task<ResponseViewModel<int>> SaveBannerAsync(BannerSaveRequest request, CancellationToken ct = default) =>
        Task.FromResult(ResponseViewModel<int>.Success(request.Id == 0 ? 2 : request.Id, "Saved successfully."));

    public Task<ResponseViewModel<int>> SaveBlogPostAsync(BlogPostSaveRequest request, CancellationToken ct = default) =>
        Task.FromResult(ResponseViewModel<int>.Success(
            request.Id == 0 ? 5 : request.Id,
            request.Status == ContentStatus.Published
                ? "Published. It is now live on the storefront."
                : "Saved successfully."));

    #endregion

    #region Moderation

    private static List<ReviewModerationItem> DemoReviews() => new()
    {
        new()
        {
            Id = 901, ProductId = 1, ProductName = "Blue Pottery Vase — Jaipur Floral",
            ProductImageUrl = "/assets/images/default-profile.png",
            CustomerName = "Priya M.", Rating = 5, Title = "The glaze is even better in person",
            Body = "I ordered this for our living room and the cobalt is deeper than the photos suggest. "
                   + "You can see the brush strokes on the floral band, which is exactly what I wanted.",
            SubmittedOn = DateTime.Now.AddHours(-6), VerifiedPurchase = true,
            OrderNumber = "HC-2026-000391", Status = ModerationStatus.Pending
        },
        new()
        {
            Id = 902, ProductId = 3, ProductName = "Moradabad Brass Diya Set of 6",
            ProductImageUrl = "/assets/images/default-profile.png",
            CustomerName = "Arjun K.", Rating = 4, Title = "Heavier than expected, in a good way",
            Body = "Solid brass, not plated. Two of the six have slightly different rim etching but that is the point.",
            SubmittedOn = DateTime.Now.AddDays(-1), VerifiedPurchase = true,
            OrderNumber = "HC-2026-000476", Status = ModerationStatus.Pending
        },
        new()
        {
            Id = 903, ProductId = 1, ProductName = "Blue Pottery Vase — Jaipur Floral",
            ProductImageUrl = "/assets/images/default-profile.png",
            CustomerName = "Rahul S.", Rating = 4, Title = "Beautiful, slightly smaller than expected",
            Body = "Do check the dimensions carefully — at 24 cm it suits a console table rather than a floor corner.",
            SubmittedOn = DateTime.Now.AddDays(-19), VerifiedPurchase = true,
            Status = ModerationStatus.Approved
        }
    };

    public Task<ResponseViewModel<PagedResult<ReviewModerationItem>>> GetReviewQueueAsync(
        DataTableRequest request, CancellationToken ct = default) =>
        Task.FromResult(Ok(Page(DemoReviews(), request)));

    public Task<ResponseViewModel<ReviewModerationItem>> GetReviewAsync(int id, CancellationToken ct = default)
    {
        var match = DemoReviews().FirstOrDefault(r => r.Id == id) ?? DemoReviews()[0];
        return Task.FromResult(Ok(match));
    }

    public Task<ResponseViewModel<bool>> ModerateReviewAsync(
        int reviewId, bool approve, string? reason, CancellationToken ct = default) =>
        Task.FromResult(ResponseViewModel<bool>.Success(
            true,
            approve
                ? "Review approved and published."
                : "Review rejected. It stays hidden from the storefront."));

    #endregion

    #region Settings & permissions

    public Task<ResponseViewModel<Dictionary<string, string?>>> GetSettingsAsync(
        string section, CancellationToken ct = default)
    {
        // These are the figures the storefront quotes; changing one changes every cart.
        var values = section switch
        {
            SettingsSection.Shipping => new Dictionary<string, string?>
            {
                ["FreeShippingThreshold"] = "999",
                ["StandardShippingCost"] = "79",
                ["CodFee"] = "49",
                ["ExpressSurcharge"] = "199"
            },
            SettingsSection.Contact => new Dictionary<string, string?>
            {
                ["SupportPhone"] = "+91 98765 43210",
                ["SupportEmail"] = "care@chamundahandicraft.com",
                ["SupportWhatsApp"] = "919876543210",
                ["SupportHours"] = "Mon–Sat, 10am–7pm IST"
            },
            SettingsSection.Rewards => new Dictionary<string, string?>
            {
                ["PointsPerHundredSpent"] = "1",
                ["PointValue"] = "1",
                ["SilverTierAt"] = "2000",
                ["GoldTierAt"] = "6000"
            },
            SettingsSection.Legal => new Dictionary<string, string?>
            {
                ["LegalName"] = "Chamunda Handicraft Pvt. Ltd.",
                ["Gstin"] = "08AABCK1234M1Z5",
                ["Cin"] = "U52609RJ2024PTC091234"
            },
            _ => new Dictionary<string, string?>
            {
                ["FreeShippingThreshold"] = "999",
                ["StandardShippingCost"] = "79",
                ["CodFee"] = "49",
                ["GiftWrapCost"] = "99",
                ["ReturnWindowDays"] = "7",
                ["RefundWorkingDays"] = "5",
                ["CurrencyCode"] = "INR",
                ["RobotsIndexable"] = "false"
            }
        };

        return Task.FromResult(Ok(values));
    }

    public Task<ResponseViewModel<bool>> SaveSettingsAsync(
        SettingsSectionRequest request, CancellationToken ct = default) =>
        Task.FromResult(ResponseViewModel<bool>.Success(
            true, "Saved. These figures now apply across the storefront."));

    public Task<ResponseViewModel<List<SettingsHistoryItem>>> GetSettingsHistoryAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoData.SettingsHistory()));

    public Task<ResponseViewModel<List<PermissionMatrixItem>>> GetPermissionMatrixAsync(
        int? roleId, CancellationToken ct = default) =>
        Task.FromResult(Ok(DemoData.PermissionMatrix()));

    public Task<ResponseViewModel<AdminProfileViewModel>> GetProfileAsync(CancellationToken ct = default) =>
        Task.FromResult(Ok(new AdminProfileViewModel
        {
            Id = 1,
            FullName = "Sandip Parmar",
            Email = "sandip@chamundahandicraft.com",
            Phone = "+91 98250 11223",
            RoleName = "Super Admin",
            LastLoginOn = DateTime.Now.AddMinutes(-8),
            TwoFactorEnabled = true
        }));

    public Task<ResponseViewModel<bool>> SaveProfileAsync(
        AdminProfileViewModel request, CancellationToken ct = default) =>
        Task.FromResult(Ok(true));

    #endregion
}
