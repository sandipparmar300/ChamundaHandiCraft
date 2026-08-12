using ChamundaHandicraft.Helper.CommonMethod;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace ChamundaHandicraft.Customer.Services;

/// <summary>
/// Design-phase content source.
///
/// The storefront has no database access — production data arrives from the API
/// gateway (see ARCHITECTURE.md). Until those calls are wired, the views bind to
/// this catalogue so every screen, state and layout can be reviewed with realistic
/// copy, prices and Indian craft vocabulary rather than lorem ipsum.
///
/// Replace each method with a gateway call; the view models do not change.
/// </summary>
public static class DemoContent
{
    private const string Ph = "/assets/images/placeholders/";

    public static readonly ArtisanSummary RamPrasad = new()
    {
        Slug = "ram-prasad-sharma",
        Name = "Ram Prasad Sharma",
        Craft = "Blue Pottery",
        Cluster = "Jaipur, Rajasthan",
        PhotoUrl = Ph + "artisan-1.svg"
    };

    public static readonly ArtisanSummary Meenakshi = new()
    {
        Slug = "meenakshi-devi",
        Name = "Meenakshi Devi",
        Craft = "Kantha Embroidery",
        Cluster = "Bolpur, West Bengal",
        PhotoUrl = Ph + "artisan-2.svg"
    };

    public static readonly ArtisanSummary Iqbal = new()
    {
        Slug = "iqbal-hussain",
        Name = "Iqbal Hussain",
        Craft = "Brass Casting",
        Cluster = "Moradabad, Uttar Pradesh",
        PhotoUrl = Ph + "artisan-3.svg"
    };

    public static readonly ArtisanSummary Lakshmi = new()
    {
        Slug = "lakshmi-narayanan",
        Name = "Lakshmi Narayanan",
        Craft = "Channapatna Woodcraft",
        Cluster = "Channapatna, Karnataka",
        PhotoUrl = Ph + "artisan-4.svg"
    };

    public static List<ArtisanSummary> Artisans() => new() { RamPrasad, Meenakshi, Iqbal, Lakshmi };

    public static List<CategoryViewModel> Categories() => new()
    {
        new() { Slug = "home-decor", Name = "Home Décor", ImageUrl = Ph + "category.svg", ProductCount = 428 },
        new() { Slug = "pottery", Name = "Pottery & Ceramics", ImageUrl = Ph + "category-5.svg", ProductCount = 216 },
        new() { Slug = "textiles", Name = "Textiles", ImageUrl = Ph + "category-3.svg", ProductCount = 384 },
        new() { Slug = "brassware", Name = "Brass & Metal", ImageUrl = Ph + "category-2.svg", ProductCount = 192 },
        new() { Slug = "jewellery", Name = "Jewellery", ImageUrl = Ph + "category-4.svg", ProductCount = 267 },
        new() { Slug = "gifting", Name = "Gifting", ImageUrl = Ph + "category-6.svg", ProductCount = 158 }
    };

    /// <summary>The full demo catalogue. Cards are built from this by every listing surface.</summary>
    public static List<ProductCardViewModel> AllProducts() => new()
    {
        new()
        {
            Slug = "jaipur-blue-pottery-vase",
            Name = "Blue Pottery Vase — Jaipur Floral",
            CategoryName = "Home Décor", CategorySlug = "home-decor",
            ImageUrl = Ph + "pottery.svg", HoverImageUrl = Ph + "decor.svg",
            ImageAlt = "Hand-painted blue pottery vase with cobalt floral motif, 24 cm tall",
            Price = 1250, Mrp = 1600, Rating = 4.6m, ReviewCount = 128,
            Artisan = RamPrasad, Badges = { ProductBadge.Sale, ProductBadge.Bestseller },
            Stock = StockState.LowStock, StockCount = 3,
            ShortDescription = "Thrown from quartz clay and painted with natural cobalt oxide, then twice-fired in a wood kiln.",
            Material = "Quartz clay, cobalt oxide glaze", Dimensions = "12 × 12 × 24 cm"
        },
        new()
        {
            Slug = "kantha-cushion-cover-set",
            Name = "Kantha Cushion Covers — Set of 2",
            CategoryName = "Textiles", CategorySlug = "textiles",
            ImageUrl = Ph + "textile.svg", HoverImageUrl = Ph + "lifestyle.svg",
            ImageAlt = "Pair of indigo kantha-stitched cotton cushion covers with running-stitch detail",
            Price = 1890, Mrp = 2400, Rating = 4.8m, ReviewCount = 246,
            Artisan = Meenakshi, Badges = { ProductBadge.Sale, ProductBadge.Handmade },
            RequiresOptions = true,
            ShortDescription = "Recycled cotton saree layers held by hand running-stitch — no two covers repeat.",
            Material = "Recycled cotton", Dimensions = "40 × 40 cm each"
        },
        new()
        {
            Slug = "moradabad-brass-diya-set",
            Name = "Moradabad Brass Diya Set of 6",
            CategoryName = "Brass & Metal", CategorySlug = "brassware",
            ImageUrl = Ph + "brass.svg", HoverImageUrl = Ph + "lamp.svg",
            ImageAlt = "Six hand-cast brass diyas with etched lotus rims on a wooden surface",
            Price = 2150, Rating = 4.7m, ReviewCount = 89,
            Artisan = Iqbal, Badges = { ProductBadge.Bestseller },
            ShortDescription = "Sand-cast in solid brass and hand-etched, each diya holds a full teaspoon of oil.",
            Material = "Solid brass", Dimensions = "7 × 7 × 2 cm each"
        },
        new()
        {
            Slug = "channapatna-lacquer-bowls",
            Name = "Channapatna Lacquered Bowls — Trio",
            CategoryName = "Home Décor", CategorySlug = "home-decor",
            ImageUrl = Ph + "wood.svg",
            ImageAlt = "Three turned ivory-wood bowls finished in natural lac, in ochre, rose and teal",
            Price = 1450, Mrp = 1750, Rating = 4.5m, ReviewCount = 64,
            Artisan = Lakshmi, Badges = { ProductBadge.Sale, ProductBadge.Eco },
            ShortDescription = "Turned from sustainably farmed ivory wood and coloured with food-safe vegetable lac.",
            Material = "Ivory wood, vegetable lac", Dimensions = "14 cm diameter"
        },
        new()
        {
            Slug = "silver-filigree-jhumka",
            Name = "Silver Filigree Jhumkas — Cuttack",
            CategoryName = "Jewellery", CategorySlug = "jewellery",
            ImageUrl = Ph + "jewellery.svg",
            ImageAlt = "Pair of Cuttack silver filigree jhumka earrings with fine wire lattice work",
            Price = 3400, Mrp = 4200, Rating = 4.9m, ReviewCount = 172,
            Badges = { ProductBadge.Sale, ProductBadge.GiTagged },
            ShortDescription = "Drawn silver wire, hand-twisted into tarakasi lattice — nine hours per pair.",
            Material = "92.5 sterling silver", Dimensions = "4.5 cm drop"
        },
        new()
        {
            Slug = "sikki-grass-basket",
            Name = "Sikki Grass Storage Basket",
            CategoryName = "Home Décor", CategorySlug = "home-decor",
            ImageUrl = Ph + "basket.svg",
            ImageAlt = "Golden sikki grass basket coiled with a fitted lid and geometric banding",
            Price = 980, Rating = 4.4m, ReviewCount = 41,
            Badges = { ProductBadge.New, ProductBadge.Eco },
            ShortDescription = "Coiled from golden sikki grass harvested after the Bihar monsoon.",
            Material = "Sikki grass", Dimensions = "24 × 24 × 18 cm"
        },
        new()
        {
            Slug = "madhubani-wall-art",
            Name = "Madhubani Painting — Tree of Life",
            CategoryName = "Home Décor", CategorySlug = "home-decor",
            ImageUrl = Ph + "art.svg",
            ImageAlt = "Madhubani painting of the tree of life in natural pigments on handmade paper",
            Price = 4600, Mrp = 5800, Rating = 4.8m, ReviewCount = 57,
            Badges = { ProductBadge.Sale, ProductBadge.Limited },
            Stock = StockState.LowStock, StockCount = 2,
            ShortDescription = "Painted in natural pigments on handmade paper, signed by the artist.",
            Material = "Handmade paper, natural pigment", Dimensions = "45 × 60 cm"
        },
        new()
        {
            Slug = "terracotta-planter-tall",
            Name = "Terracotta Planter — Tall Fluted",
            CategoryName = "Pottery & Ceramics", CategorySlug = "pottery",
            ImageUrl = Ph + "decor.svg",
            ImageAlt = "Tall fluted terracotta planter in unglazed clay with a drainage base",
            Price = 1650, Rating = 4.3m, ReviewCount = 33,
            Artisan = RamPrasad,
            Stock = StockState.OutOfStock,
            ShortDescription = "Wheel-thrown and open-fired, left unglazed so roots breathe.",
            Material = "Terracotta", Dimensions = "22 × 22 × 40 cm"
        },
        new()
        {
            Slug = "brass-urli-bowl",
            Name = "Brass Urli Bowl with Stand",
            CategoryName = "Brass & Metal", CategorySlug = "brassware",
            ImageUrl = Ph + "lamp.svg",
            ImageAlt = "Wide brass urli bowl on a three-legged stand, hand-beaten with a hammered finish",
            Price = 3250, Mrp = 3900, Rating = 4.6m, ReviewCount = 78,
            Artisan = Iqbal, Badges = { ProductBadge.Sale },
            ShortDescription = "Hand-beaten from a single brass sheet — the hammer marks are the maker's signature.",
            Material = "Solid brass", Dimensions = "30 cm diameter"
        },
        new()
        {
            Slug = "block-print-table-runner",
            Name = "Bagru Block-Print Table Runner",
            CategoryName = "Textiles", CategorySlug = "textiles",
            ImageUrl = Ph + "textile.svg",
            ImageAlt = "Cotton table runner block-printed in madder red with a repeating buti motif",
            Price = 1120, Rating = 4.5m, ReviewCount = 96,
            Artisan = Meenakshi, Badges = { ProductBadge.New },
            RequiresOptions = true,
            ShortDescription = "Hand-blocked in madder and indigo, washed in river water and sun-dried.",
            Material = "Cotton, natural dye", Dimensions = "180 × 40 cm"
        },
        new()
        {
            Slug = "dhokra-figurine-musician",
            Name = "Dhokra Figurine — Tribal Musician",
            CategoryName = "Home Décor", CategorySlug = "home-decor",
            ImageUrl = Ph + "craft.svg",
            ImageAlt = "Dhokra lost-wax bronze figurine of a seated tribal musician with a drum",
            Price = 2750, Rating = 4.7m, ReviewCount = 52,
            Badges = { ProductBadge.Handmade, ProductBadge.GiTagged },
            ShortDescription = "Cast by the 4,000-year-old lost-wax method — the mould breaks with every piece.",
            Material = "Bell metal", Dimensions = "10 × 8 × 18 cm"
        },
        new()
        {
            Slug = "marble-inlay-coaster-set",
            Name = "Marble Inlay Coasters — Set of 4",
            CategoryName = "Gifting", CategorySlug = "gifting",
            ImageUrl = Ph + "craft.svg",
            ImageAlt = "Four white marble coasters inlaid with semi-precious stone floral patterns",
            Price = 1980, Mrp = 2400, Rating = 4.6m, ReviewCount = 118,
            Badges = { ProductBadge.Sale, ProductBadge.Bestseller },
            ShortDescription = "Makrana marble hand-chiselled and inlaid with malachite and carnelian.",
            Material = "Makrana marble, semi-precious stone", Dimensions = "10 × 10 cm each"
        }
    };

    public static List<ProductCardViewModel> Products(int count, int skip = 0) =>
        Enumerable.Range(0, count)
            .Select(i => AllProducts()[(skip + i) % AllProducts().Count])
            .ToList();

    public static ProductCardViewModel Product(string slug) =>
        AllProducts().FirstOrDefault(p => p.Slug == slug) ?? AllProducts()[0];

    public static List<CartLineViewModel> CartLines() => new()
    {
        new()
        {
            Slug = "jaipur-blue-pottery-vase",
            Name = "Blue Pottery Vase — Jaipur Floral",
            ImageUrl = Ph + "pottery.svg",
            ImageAlt = "Hand-painted blue pottery vase with cobalt floral motif",
            VariantSummary = "Size: Medium · Colour: Cobalt",
            Sku = "HC-POT-0421",
            Price = 1250, Mrp = 1600, Quantity = 1, MaxQuantity = 3,
            Stock = StockState.LowStock, StockCount = 3,
            Artisan = RamPrasad, DeliveryBy = DateTime.Today.AddDays(6)
        },
        new()
        {
            Slug = "moradabad-brass-diya-set",
            Name = "Moradabad Brass Diya Set of 6",
            ImageUrl = Ph + "brass.svg",
            ImageAlt = "Six hand-cast brass diyas with etched lotus rims",
            VariantSummary = "Finish: Antique",
            Sku = "HC-BRS-1180",
            Price = 2150, Quantity = 2, MaxQuantity = 10,
            Artisan = Iqbal, DeliveryBy = DateTime.Today.AddDays(5)
        },
        new()
        {
            Slug = "kantha-cushion-cover-set",
            Name = "Kantha Cushion Covers — Set of 2",
            ImageUrl = Ph + "textile.svg",
            ImageAlt = "Pair of indigo kantha-stitched cotton cushion covers",
            VariantSummary = "Colour: Indigo · Size: 40 × 40 cm",
            Sku = "HC-TEX-0903",
            Price = 1890, Mrp = 2400, Quantity = 1, MaxQuantity = 8,
            Artisan = Meenakshi, DeliveryBy = DateTime.Today.AddDays(7)
        }
    };

    public static OrderSummaryViewModel Summary(IEnumerable<CartLineViewModel> lines, string? coupon = "FESTIVE10")
    {
        var list = lines.ToList();
        var subtotal = list.Sum(l => l.LineTotal);
        var mrpTotal = list.Sum(l => (l.Mrp ?? l.Price) * l.Quantity);

        return new OrderSummaryViewModel
        {
            Subtotal = subtotal,
            MrpTotal = mrpTotal,
            CouponCode = coupon,
            CouponDiscount = coupon is null ? 0 : Math.Round(subtotal * 0.10m),
            Shipping = subtotal >= 999 ? 0 : 79,
            ItemCount = list.Sum(l => l.Quantity)
        };
    }

    public static List<AddressViewModel> Addresses() => new()
    {
        new()
        {
            Id = 1, Label = AddressType.Home, FullName = "Ananya Iyer", Phone = "+91 98765 43210",
            Line1 = "402, Sundar Residency", Line2 = "Nehru Nagar Road",
            Landmark = "Opposite Bal Bhavan", City = "Ahmedabad", State = "Gujarat",
            Pincode = "380015", IsDefault = true
        },
        new()
        {
            Id = 2, Label = AddressType.Work, FullName = "Ananya Iyer", Phone = "+91 98765 43210",
            Line1 = "Tower B, 7th Floor, Sakar IX", Landmark = "Near Ashram Road",
            City = "Ahmedabad", State = "Gujarat", Pincode = "380009"
        }
    };

    public static List<OrderSummaryCardViewModel> Orders() => new()
    {
        new()
        {
            OrderNumber = "HC-2026-000482", PlacedOn = DateTime.Today.AddDays(-3),
            Status = OrderStatus.Shipped, Total = 5290, ItemCount = 3,
            Thumbnails = { Ph + "pottery.svg", Ph + "brass.svg", Ph + "textile.svg" },
            PrimaryItemName = "Blue Pottery Vase — Jaipur Floral",
            DeliveryBy = DateTime.Today.AddDays(3), Courier = "Delhivery",
            TrackingNumber = "DLV8842190237", CanCancel = true
        },
        new()
        {
            OrderNumber = "HC-2026-000391", PlacedOn = DateTime.Today.AddDays(-24),
            Status = OrderStatus.Delivered, Total = 3400, ItemCount = 1,
            Thumbnails = { Ph + "jewellery.svg" },
            PrimaryItemName = "Silver Filigree Jhumkas — Cuttack",
            DeliveredOn = DateTime.Today.AddDays(-18), Courier = "Blue Dart",
            CanReview = true, CanReturn = false
        },
        new()
        {
            OrderNumber = "HC-2026-000287", PlacedOn = DateTime.Today.AddDays(-62),
            Status = OrderStatus.Refunded, Total = 1650, ItemCount = 1,
            Thumbnails = { Ph + "decor.svg" },
            PrimaryItemName = "Terracotta Planter — Tall Fluted"
        }
    };

    public static List<OrderTimelineStep> Timeline() => new()
    {
        new() { Title = "Order placed", Meta = "We received your order", At = DateTime.Today.AddDays(-3).AddHours(11), Icon = "i-circle-check", State = "done" },
        new() { Title = "Packed", Meta = "Wrapped in recycled kraft with corner guards", At = DateTime.Today.AddDays(-2).AddHours(16), Icon = "i-package-check", State = "done" },
        new() { Title = "Shipped", Meta = "Picked up by Delhivery", Location = "Jaipur, Rajasthan", At = DateTime.Today.AddDays(-1).AddHours(9), Icon = "i-truck", State = "done" },
        new() { Title = "Out for delivery", Meta = "Arriving today between 10am and 6pm", Location = "Ahmedabad, Gujarat", Icon = "i-bike", State = "current" },
        new() { Title = "Delivered", Meta = "Expected " + Money.DeliveryDate(DateTime.Today.AddDays(3)), Icon = "i-home", State = "upcoming" }
    };

    public static List<ReviewViewModel> Reviews() => new()
    {
        new()
        {
            Author = "Priya M.", Rating = 5, Title = "The glaze is even better in person",
            Body = "I ordered this for our living room and the cobalt is deeper than the photos suggest. You can see the brush strokes on the floral band, which is exactly what I wanted — it looks made, not printed. Packed in three layers with corner guards.",
            PostedOn = DateTime.Today.AddDays(-6), HelpfulCount = 24,
            Photos = { Ph + "pottery.svg", Ph + "lifestyle.svg" }, VariantPurchased = "Medium · Cobalt"
        },
        new()
        {
            Author = "Rahul S.", Rating = 4, Title = "Beautiful, slightly smaller than expected",
            Body = "Lovely piece and clearly handmade. Do check the dimensions carefully — at 24 cm it suits a console table rather than a floor corner. Delivery was two days ahead of the estimate.",
            PostedOn = DateTime.Today.AddDays(-19), HelpfulCount = 11, VariantPurchased = "Medium · Cobalt"
        },
        new()
        {
            Author = "Fatima K.", Rating = 5, Title = "Bought a second one",
            Body = "The first one has been on our dining table for a year with no chipping. Ordered a second for my sister's housewarming and the pair sit together well even though the motifs differ slightly.",
            PostedOn = DateTime.Today.AddDays(-45), HelpfulCount = 38, Photos = { Ph + "decor.svg" }
        }
    };

    public static List<ArticleCardViewModel> Articles() => new()
    {
        new()
        {
            Slug = "how-blue-pottery-is-made", Title = "How Jaipur blue pottery is made — from quartz to kiln",
            Excerpt = "There is no clay in blue pottery. We spent three days in Ram Prasad Sharma's workshop watching quartz powder become a vase.",
            CoverUrl = Ph + "blog.svg", Category = "Craft Stories", Author = "Nandini Rao",
            PublishedOn = DateTime.Today.AddDays(-8), ReadMinutes = 7
        },
        new()
        {
            Slug = "styling-brass-in-modern-homes", Title = "Styling brass in a modern Indian home",
            Excerpt = "Brass reads as heritage or as contemporary depending entirely on what sits beside it. Six pairings that work.",
            CoverUrl = Ph + "blog-2.svg", Category = "Living", Author = "Kabir Menon",
            PublishedOn = DateTime.Today.AddDays(-16), ReadMinutes = 5
        },
        new()
        {
            Slug = "kantha-the-thrift-that-became-art", Title = "Kantha: the thrift that became an art form",
            Excerpt = "Bengali grandmothers layered worn sarees and stitched them into quilts. A century later the running stitch is a signature.",
            CoverUrl = Ph + "blog-3.svg", Category = "Craft Stories", Author = "Nandini Rao",
            PublishedOn = DateTime.Today.AddDays(-27), ReadMinutes = 6
        }
    };

    public static List<FaqItem> ShippingFaqs() => new()
    {
        new() { Question = "When will my order arrive?", Answer = "Most orders leave our Jaipur studio within 48 hours and reach metro PIN codes in 4–6 days. Your delivery date is shown on the product page once you enter a PIN code, and again in your cart before you pay." },
        new() { Question = "Do you charge for shipping?", Answer = "Shipping is free on orders above ₹999. Below that it is a flat ₹79 anywhere in India. Cash on delivery adds ₹49, and both are shown in your cart before you reach payment." },
        new() { Question = "My item is handmade — will it look exactly like the photo?", Answer = "It will be recognisably the same piece, but not identical. Colour, finish and size vary slightly because a person made it. We photograph a representative piece and describe the range of variation on every product page." },
        new() { Question = "How do returns work?", Answer = "You have 7 days from delivery to start a return for any reason. We arrange a free pickup and refund to your original payment method within 5 working days of the item reaching us." },
        new() { Question = "Do you deliver outside India?", Answer = "Not yet. We ship across India today and are working on international delivery for 2026. Join the newsletter and we'll tell you when it opens." }
    };

    /// <summary>
    /// Coupons written by the Admin Promotions module. Eligibility is decided server
    /// side — an ineligible coupon still appears, with the gap stated plainly.
    /// </summary>
    public static List<CouponViewModel> Coupons() => new()
    {
        new()
        {
            Code = "FESTIVE10", Title = "10% off, up to ₹500", Detail = "Valid on everything.",
            DiscountType = DiscountType.Percentage, DiscountValue = 10, MaxDiscount = 500,
            ExpiresOn = DateTime.Today.AddDays(25), IsEligible = true
        },
        new()
        {
            Code = "WELCOME200", Title = "₹200 off your first order", Detail = "Minimum order ₹1,500.",
            DiscountType = DiscountType.FixedAmount, DiscountValue = 200, MinimumOrderValue = 1500,
            ExpiresOn = DateTime.Today.AddDays(60), IsEligible = true
        },
        new()
        {
            Code = "BRASS15", Title = "15% off brass and metal", Detail = "Applies to Brass & Metal only.",
            DiscountType = DiscountType.Percentage, DiscountValue = 15,
            ExpiresOn = DateTime.Today.AddDays(12), IsEligible = true
        },
        new()
        {
            Code = "BULK25", Title = "25% off orders above ₹10,000", Detail = "Bulk and corporate orders.",
            DiscountType = DiscountType.Percentage, DiscountValue = 25, MinimumOrderValue = 10000,
            ExpiresOn = DateTime.Today.AddDays(90), IsEligible = false,
            IneligibleReason = "Add ₹4,710 more to your cart to use this."
        }
    };

    /// <summary>Every notification is actionable — each carries the URL that resolves it.</summary>
    public static List<NotificationViewModel> Notifications() => new()
    {
        new()
        {
            Title = "Out for delivery",
            Body = "Order HC-2026-000482 is with the courier and arrives today between 10am and 6pm.",
            CreatedOn = DateTime.Now.AddHours(-2), IsRead = false,
            Icon = "i-bike", ActionUrl = "/track/HC-2026-000482", ActionLabel = "Track"
        },
        new()
        {
            Title = "A saved piece dropped in price",
            Body = "Madhubani Painting — Tree of Life is now ₹4,600, down from ₹5,800.",
            CreatedOn = DateTime.Now.AddHours(-9), IsRead = false,
            Icon = "i-percent", ActionUrl = "/wishlist", ActionLabel = "View wishlist"
        },
        new()
        {
            Title = "How was your order?",
            Body = "The Cuttack jhumkas arrived 18 days ago. A review takes two minutes and earns 50 points.",
            CreatedOn = DateTime.Now.AddDays(-2), IsRead = true,
            Icon = "i-star", ActionUrl = "/reviews/write/silver-filigree-jhumka", ActionLabel = "Write a review"
        },
        new()
        {
            Title = "Shipped",
            Body = "Order HC-2026-000482 left our Jaipur studio with Delhivery.",
            CreatedOn = DateTime.Now.AddDays(-1), IsRead = true,
            Icon = "i-truck", ActionUrl = "/track/HC-2026-000482", ActionLabel = "Track"
        },
        new()
        {
            Title = "200 points added",
            Body = "R••••l M. used your referral code and their order has shipped.",
            CreatedOn = DateTime.Now.AddDays(-9), IsRead = true,
            Icon = "i-gem", ActionUrl = "/account/rewards", ActionLabel = "View rewards"
        }
    };
}
