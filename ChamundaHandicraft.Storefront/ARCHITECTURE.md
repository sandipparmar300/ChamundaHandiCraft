# ChamundaHandicraft.Storefront

The customer website. ASP.NET Core MVC + Razor + Bootstrap 5 + jQuery, cookie
authentication for signed-in shoppers and a guest token for anonymous carts. Like the
Admin panel it has **no database access** — everything goes through the gateway.

Design source of truth: `docs/ui-ux-storefront/` (HCX-CXSPEC-001), 20 modules, 125 pages.

Mobile is the primary design target (390px first, then expanded).

---

## Folder layout

```
ChamundaHandicraft.Storefront/
├─ Controllers/
├─ Models/
├─ ViewComponents/       ProductCard, ProductRail, MiniCart, MegaMenu, FacetPanel,
│                        TrustBand, ReviewSummary, BreadcrumbSchema, RecentlyViewed
├─ TagHelpers/           PriceTagHelper, ImageCdnTagHelper, SeoMetaTagHelper
├─ Views/
│  ├─ Shared/            _Layout, _Header, _MegaMenu, _Footer, _MiniCart,
│  │                     _Breadcrumb, _Toast, _EmptyState, _SkeletonCard, Error
│  └─ <Module>/
├─ wwwroot/
│  ├─ assets/css/scss/   Storefront semantic layer over the shared primitives
│  ├─ assets/js/         cart.js, plp.js, pdp.js, checkout.js, search.js
│  ├─ assets/images/
│  ├─ assets/fonts/
│  └─ lib/
├─ Program.cs
└─ appsettings.json
```

---

## Routes → Controllers → Views

Routes come verbatim from `docs/ui-ux-storefront/00-Master-Index.md` §0.4.3.

| Route | Controller | Views folder | Spec module |
|-------|------------|--------------|-------------|
| `/` | `HomeController` | `Home` | 02 Home |
| `/login`, `/register`, `/forgot-password` | `AuthController` | `Auth` | 01 Authentication |
| `/shop` | `ShopController` | `Shop` | 03 Shop / PLP |
| `/c/{category-slug}`, `/c/{category}/{sub}` | `ShopController` | `Shop` | 03 Shop / PLP |
| `/p/{product-slug}` | `ProductController` | `Product` | 04 Product Details |
| `/search?q=` | `SearchController` | `Search` | 13 Search |
| `/compare` | `CompareController` | `Compare` | 05 Compare |
| `/wishlist` | `WishlistController` | `Wishlist` | 06 Wishlist |
| `/cart` | `CartController` | `Cart` | 07 Cart |
| `/checkout` | `CheckoutController` | `Checkout` | 08 Checkout |
| `/checkout/success/{orderNumber}` | `CheckoutController` | `Checkout` | 08 Checkout |
| payment redirect / callback | `PaymentController` | `Payment` | 09 Payment |
| `/account` | `AccountController` | `Account` | 10 My Account |
| `/account/orders/{orderNumber}` | `OrderController` | `Order` | 11 Orders |
| `/track/{orderNumber}` | `TrackController` | `Track` | 12 Order Tracking |
| `/help` | `SupportController` | `Support` | 14 Customer Support |
| review submission / listing | `ReviewController` | `Review` | 15 Reviews |
| `/account/rewards` | `RewardsController` | `Rewards` | 16 Rewards |
| `/account/notifications` | `NotificationController` | `Notification` | 17 Notifications |
| `/blog`, `/blog/{slug}` | `BlogController` | `Blog` | 18 Blog |
| `/pages/{slug}` | `PageController` | `Page` | 19 Static Pages |
| `/artisans/{slug}` | `ArtisanController` | `Artisan` | 03/04 storytelling |
| AI assistant endpoints | `AiController` | `Ai` | 20 AI Shopping |
| footer subscribe | `NewsletterController` | `Newsletter` | 16 (admin-side) |

---

## Shared components that carry the brand

| Component | Rule from the spec |
|-----------|--------------------|
| `TrustBand` | Authenticity, returns, secure payment, artisan-made — shown before any urgency device (CX principle 2) |
| Variation Notice | **Mandatory** on PDP, cart and order confirmation. Prevents the top return reason (CX principle 4) |
| `ProductCard` | Imagery-led, artisan credit visible, honest badges only |
| `MiniCart` | Right-side drawer; opening it never loses page state |
| Scarcity indicators | Rendered only when literally true, removed when not (CX principle 3) |

---

## State that must survive navigation, refresh and session expiry

Cart contents, applied filters, form input and scroll position (CX principle 11).
Anonymous carts are keyed by a guest cookie (`Session:CartCookieDays`) and merged into
the customer's cart on sign-in.

---

## SEO surface

- `SeoMetaTagHelper` renders title, description, canonical, OG and Twitter tags from
  the Seo module for every route.
- JSON-LD: `Product`, `BreadcrumbList`, `Organization`, `Article`, `FAQPage`, `Review`.
- `sitemap.xml` and `robots.txt` are served from the API's Public controllers, not here.
- `Seo:RobotsIndexable` stays `false` until launch.

---

## Performance budget

LCP ≤ 2.5s on 4G. Product imagery capped per `Performance:ProductImageMaxKb`, served
in modern formats from the CDN base URL. Design decisions that break the budget get
redesigned, not excused (CX principle 9).
