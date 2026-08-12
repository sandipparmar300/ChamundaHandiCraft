# ChamundaHandicraft.Customer

The customer website. ASP.NET Core MVC + Razor + Bootstrap 5 + jQuery, cookie
authentication for signed-in shoppers and a guest token for anonymous carts. Like the
Admin panel it has **no database access** — everything goes through the gateway.

Design source of truth: `docs/ui-ux-storefront/` (HCX-CXSPEC-001), 20 modules, 125 pages.

Mobile is the primary design target (390px first, then expanded).

---

## Folder layout

```
ChamundaHandicraft.Customer/
├─ Controllers/          StorefrontController (base) + one per module
├─ Models/               StorefrontModels.cs — view models, Money/BadgeStyle/StockStyle helpers
├─ Services/             DemoContent.cs — design-phase catalogue, replaced by gateway calls
├─ ViewComponents/       (reserved — shared surfaces are Razor partials during the design phase)
├─ TagHelpers/           (reserved — PriceTagHelper, ImageCdnTagHelper, SeoMetaTagHelper)
├─ Views/
│  ├─ Shared/            _Layout, _AuthLayout, _CheckoutLayout, _AccountLayout,
│  │                     _Icons, _Header, _MegaMenu, _SearchSuggest, _Footer,
│  │                     _MiniCart, _MobileDrawer, _BottomTabs, _Breadcrumb,
│  │                     _TrustBand, _ProductCard, _ProductCardList, _ProductRail,
│  │                     _VariationNotice, _FilterRail, _QuickView, _SkeletonGrid, Error
│  └─ <Module>/
├─ wwwroot/
│  ├─ assets/css/        tokens.css, base.css, components.css, storefront.css
│  ├─ assets/js/         storefront.js
│  ├─ assets/images/     logo, favicon, placeholders/
│  ├─ assets/fonts/
│  └─ lib/
├─ Program.cs
└─ appsettings.json
```

### The four CSS layers

Loaded in this order; each depends only on the ones above it.

| File | Contents |
|------|----------|
| `tokens.css` | Primitives (indigo, terracotta, brass, paper, status) + semantic tokens for light and dark. Nothing in it styles an element. |
| `base.css` | Reset, focus, typography scale, layout containers and the `SL-*` templates, utilities, icon sizing, reduced-motion and print rules. |
| `components.css` | Actions, navigation, search, forms, filters, feedback, overlays, indicators. |
| `storefront.css` | Product, media, commerce, orders, reviews, account, content and AI components. |

`_Icons.cshtml` renders a Lucide `<symbol>` sprite once per page; every icon is
`<svg class="ico"><use href="#i-name"></use></svg>`. Stroke width, size and colour come
from CSS, so one symbol serves every context.

Themes are switched by `data-theme` on `<html>`, applied before first paint by an inline
script in `_Layout` so the theme never flashes. `Chamunda.theme` in `storefront.js` is the
public API.

---

## Design-phase content

Every view binds to `Services/DemoContent.cs` — a realistic catalogue of Indian craft
products, artisans, orders, reviews and articles. It exists so each screen, state and
breakpoint can be reviewed with true-to-life copy and prices before the gateway is wired.
Replacing a `DemoContent` call with a gateway call does not change any view model.

---

## Routes → Controllers → Views

Routes come verbatim from `docs/ui-ux-storefront/00-Master-Index.md` §0.4.3 and are declared
with `[Route]` attributes on the action, so the slug shape lives next to what serves it.
`StorefrontController` is the base: it populates the header/footer state and provides
`Page()`, `Crumbs()`, `ActiveNav()` and `MinimalChrome()`.

| Route | Controller | Views folder | Spec module |
|-------|------------|--------------|-------------|
| `/` | `HomeController` | `Home` | 02 Home |
| `/login`, `/register`, `/signin/otp`, `/forgot-password`, `/reset-password`, `/verify-email`, `/verify-mobile`, `/complete-profile`, `/account-locked`, `/welcome` | `AuthController` | `Auth` | 01 Authentication |
| `/shop` | `ShopController` | `Shop` | 03 Shop / PLP |
| `/c/{category-slug}`, `/c/{category}/{sub}` | `ShopController` | `Shop` | 03 Shop / PLP |
| `/p/{product-slug}` | `ProductController` | `Product` | 04 Product Details |
| `/search?q=` | `SearchController` | `Search` | 13 Search |
| `/compare` | `CompareController` | `Compare` | 05 Compare |
| `/wishlist` | `WishlistController` | `Wishlist` | 06 Wishlist |
| `/cart` | `CartController` | `Cart` | 07 Cart |
| `/checkout`, `/checkout/success/{orderNumber}`, `/checkout/failed` | `CheckoutController` | `Checkout` | 08 Checkout |
| `/payment/processing` | `PaymentController` | `Payment` | 09 Payment |
| `/account`, `/account/profile`, `/account/addresses`, `/account/coupons`, `/account/payment-methods`, `/account/security`, `/account/preferences`, `/account/privacy`, `/account/referrals` | `AccountController` | `Account` | 10 My Account |
| `/account/orders`, `/account/orders/{orderNumber}`, `/account/orders/{n}/return`, `/account/returns` | `OrderController` | `Order` | 11 Orders |
| `/track`, `/track/{orderNumber}` | `TrackController` | `Track` | 12 Order Tracking |
| `/help`, `/help/tickets` | `SupportController` | `Support` | 14 Customer Support |
| `/reviews/write/{slug}`, `/account/reviews` | `ReviewController` | `Review` | 15 Reviews |
| `/account/rewards` | `RewardsController` | `Rewards` | 16 Rewards |
| `/account/notifications` | `NotificationController` | `Notification` | 17 Notifications |
| `/blog`, `/blog/{slug}` | `BlogController` | `Blog` | 18 Blog |
| `/pages/{slug}` | `PageController` | `Page` | 19 Static Pages |
| `/artisans`, `/artisans/{slug}` | `ArtisanController` | `Artisan` | 03/04 storytelling |
| `/assistant` | `AiController` | `Ai` | 20 AI Shopping |
| `/newsletter/subscribe` (POST) | `NewsletterController` | — | 16 (admin-side) |
| `/error`, `/maintenance`, `/offline`, `/sitemap` | `HomeController`, `SystemController` | `Shared`, `System` | System pages |

`UseStatusCodePagesWithReExecute` sends 404 and 500 to `/error`, so a wrong URL still
arrives at a page with the full header, footer and a route back into the catalogue.

### Chrome variants

| Layout | Used by | Why |
|--------|---------|-----|
| `_Layout` | Everything by default | Announcement bar, full header, mega menu, footer, mini cart, mobile drawer, bottom tabs |
| `_AuthLayout` | Module 01 | `SL-11` split with craft photography; no site navigation to distract from the form |
| `_CheckoutLayout` | Modules 08–09 | Logo (guarded), secure badge, help link only — every removed element is a documented source of checkout leakage |
| `_AccountLayout` | Modules 10, 11, 15–17 | `SL-05` sidebar and content, with the profile and points card at the top of the rail |

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
