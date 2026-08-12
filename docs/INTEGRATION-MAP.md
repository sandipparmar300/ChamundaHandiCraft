# Admin → Customer Integration Map

**What this answers:** for every admin module, what it writes, which endpoint carries
it, which customer screen displays it, and what gates it from appearing.

Read it alongside:
- `ChamundaHandicraft.Helper/Constants/ApiEndPoint.cs` — the same map in code
- `ChamundaHandicraft.Helper/ViewModel/` — the shapes both tiers bind
- `ARCHITECTURE.md` §3 — the runtime topology

---

## 0. How the two tiers are connected

Neither MVC project references the other, and neither touches a database. They meet in
exactly two places:

| Meeting point | What it guarantees |
|---|---|
| `ChamundaHandicraft.Helper/ViewModel/` | Both tiers bind the **same C# types**. An admin cannot save a shape the storefront can't read. |
| `ChamundaHandicraft.Helper/Constants/ApiEndPoint.cs` | Both tiers call the **same route catalogue**. Neither builds a URL by hand. |

```
Admin panel                    Gateway                    Customer site
───────────                    ───────                    ─────────────
IAdminClient      ──▶  Admin/{everything}  ──┐
  GatewayAdminClient                          │      ┌── /api/admin/*
                                              ├─▶ API ┤
IStorefrontClient ──▶  Shop/{everything}   ──┘      └── /api/customer/*
  GatewayStorefrontClient
                                                            │
                                            both bind ChamundaHandicraft.Helper
```

Each tier has one interface with two implementations — a demo one serving local
content, and a gateway one calling the API. The switch is a single flag:

```jsonc
// appsettings.json, both projects
"Api": { "UseLiveGateway": false }
```

Everything below the interface is already written. What is missing is the API's own
controllers — see §12.

---

## 1. Catalog → Product listing, PDP, search

| Admin writes | Endpoint | Customer reads | Screen |
|---|---|---|---|
| `ProductSaveRequest` | `Product/Save` | — | — |
| — | `Shop/Product/List` | `ProductListingViewModel` | `/shop`, `/c/{slug}` |
| — | `Shop/Product/Detail` | `ProductDetailViewModel` | `/p/{slug}` |
| — | `Shop/Product/QuickView` | `ProductCardViewModel` | Quick View modal |
| — | `Shop/Search/Query` | `ProductListingViewModel` | `/search?q=` |

**Field-level bindings that matter**

| Admin field | Customer surface |
|---|---|
| `Slug` | The URL itself. Changing it **must** create a 301 in the Seo module, or every existing link breaks. |
| `Name` | Card title (2-line clamp), PDP `<h1>` (never truncates), cart line, order line, invoice |
| `ShortDescription` | Card list-view blurb, PDP lead paragraph, meta description fallback |
| `ProductStory` | The PDP craft band — the "how it's made" editorial |
| `Mrp` | Struck price and the `% OFF` badge. Inflating it to manufacture a discount is a policy breach (§8.1). |
| `ArtisanId` | Artisan chip on the card, PDP maker band, cart line, order detail, invoice |
| `Media[].AltText` | Required. A product with no alt text fails accessibility and cannot publish. |
| `LowStockThreshold` | Decides when "Only {n} left" appears — and it only appears when the real figure is ≤5 |
| `MaxQuantityPerOrder` | Caps the quantity stepper in cart and Quick View |
| `ManualBadges` | Only Handmade, Eco, GI Tagged and Limited. **Sale, Bestseller and New are computed by the API** from price, sales and publish date, so a badge cannot claim something untrue. |

### The publish gate

A product appears on the storefront only when **all** hold:

1. `Status == ProductStatus.Published`
2. `Visibility` is `Everywhere` or `CatalogOnly` (`SearchOnly` hides it from listings; `Hidden` hides it entirely)
3. Its category is active
4. `PublishOn` is null or in the past

The Admin grid collapses this into one **On Storefront** column — Live or Hidden — so an
operator never has to combine three columns to answer "can a shopper see this". The row's
Preview link opens the real customer URL.

---

## 2. Categories → mega menu, PLP, breadcrumbs

| Admin writes | Endpoint | Customer screen |
|---|---|---|
| `CategorySaveRequest` | `Category/Save` | — |
| — | `Shop/Category/MegaMenu` | Header mega menu, mobile drawer accordion |
| — | `Shop/Category/Featured` | Home "Shop by category" grid |
| — | `Shop/Category/Detail` | `/c/{slug}` heading, intro copy, breadcrumb |

`IntroCopy` is the 80–150 words rendered below the PLP grid — editorially controlled,
and one of the few SEO levers on a category page. `ShowInMegaMenu` and
`IsFeaturedOnHome` are independent of `IsActive`: a category can be live and reachable
without occupying menu space.

---

## 3. Inventory → stock indicators everywhere

| Admin writes | Endpoint | Customer surface |
|---|---|---|
| `AdjustmentSave`, `PurchaseEntrySave`, `StockTakeSave` | — | — |
| — | `Shop/Inventory/Availability` | Stock pill on card, PDP, cart line; quantity stepper max |

`StockGridItem.Available = OnHand − Reserved`, and `Reserved` counts carts and unshipped
orders. This is the **only** figure the storefront may quote. A cached list value must
never drive "Only 2 left" — that is how a shopper gets told something untrue.

`StockState` is computed once, server-side, and both tiers render the same enum.

---

## 4. Orders → order list, detail, tracking

This is the tightest coupling in the platform, and the one worth getting right.

| Admin action | Endpoint | Customer sees |
|---|---|---|
| Change status | `Order/UpdateStatus` | Status chip, timeline step, tracking page |
| Add tracking number | `Order/UpdateStatus` | Courier + tracking on `/track/{orderNumber}` |
| Approve return | `Order/ReturnApprove` | Return status and refund timeline |
| Generate invoice | `Order/InvoiceGetById` | Invoice download on order detail |

**One order, one set of numbers.** `OrderDetailAdminViewModel` and the customer's
`OrderDetailViewModel` deliberately share `CartLineViewModel`, `AddressViewModel` and
`OrderSummaryViewModel`. There is no separate admin total to reconcile against a
customer total.

**Legal transitions** come from `Orders.txt §2` and are enforced by the API. The admin
detail screen offers only `AllowedNextStatuses` rather than every enum value, so an
operator cannot skip Packed and jump straight to Delivered.

**Every transition notifies.** `OrderStatusUpdateRequest.NotifyCustomer` defaults to
true. Turning it off silently is what makes a tracking page go stale and generates the
support ticket.

**What the customer may still do** — `CanCancel`, `CanReturn`, `CanReview`, `CanTrack` —
is computed by the API from status plus the return window in Settings. The storefront
never decides this for itself, so the two tiers agree on what is still possible.

---

## 5. Promotions → coupons, offers, flash sale

| Admin writes | Endpoint | Customer screen |
|---|---|---|
| `CouponSaveRequest` | `Coupon/Save` | — |
| — | `Shop/Coupon/MyCoupons` | `/account/coupons`, cart coupon modal |
| — | `Shop/Coupon/Validate` | Applying a code in cart or checkout |
| `FlashSaleSaveRequest` | `Offer/Save` | — |
| — | `Shop/Offer/FlashSale` | Home flash-sale band and countdown |

`IsPublic = false` keeps a coupon out of "My Coupons" — it must be typed.

**The countdown is server-anchored.** `FlashSaleSaveRequest.EndsOn` is server time; the
storefront renders from it and **removes the band at zero rather than restarting**. A
front end that invents an end time is a fake countdown, which §8.1 prohibits.

Ineligible coupons still appear, with `IneligibleReason` stating the gap
("Add ₹4,710 more to use this") rather than silently refusing.

---

## 6. Banners → home hero and injected tiles

| Admin writes | Endpoint | Customer screen |
|---|---|---|
| `BannerSaveRequest` | `Banner/Save` | — |
| — | `Shop/Banner/ByPlacement` | Home hero, PLP injection, announcement bar, cart upsell |

`MobileImageUrl` is a **separate crop**, never a scaled desktop image — the hero has a
120 KB desktop / 70 KB mobile budget. `ImageAlt` is required: a banner without it
cannot publish, because campaign text baked into an image is invisible to a screen
reader and untranslatable.

---

## 7. Content → blog, static pages, artisans, testimonials

| Admin writes | Endpoint | Customer screen |
|---|---|---|
| `BlogPostSaveRequest` | `Blog/Save` | `/blog`, `/blog/{slug}` |
| `CmsPageSaveRequest` | `CmsPage/Save` | `/pages/{slug}` |
| `ArtisanSaveRequest` | `Artisan/Save` | `/artisans`, `/artisans/{slug}`, every artisan chip |
| `TestimonialSaveRequest` | `Testimonial/Save` | Home reviews band |
| FAQ entries | `Faq/Save` | `/help#faq`, PDP FAQ accordion |

`BlogPostSaveRequest.FeaturedProductIds` is what drives the "Shop this story" rail —
the link from editorial back into the catalogue.

All content shares `ContentStatus`; only `Published` reaches the storefront, and
`Scheduled` waits for its date.

---

## 8. Reviews → PDP rating summary

| Admin action | Endpoint | Customer effect |
|---|---|---|
| Approve | `Review/Approve` | Review publishes to the PDP; counts and average recalculate |
| Reject | `Review/Reject` | Stays hidden; reason is shown to the author |
| Reply | `Review/Reply` | Merchant reply renders beneath the review |

**Only verified purchases are published**, and the storefront states that promise
wherever reviews appear. Nothing in `ReviewModerationItem` lets an operator edit the
shopper's words, and rejecting a review for being negative is out of policy — the
rejection reason is shown to the author, which is what keeps that honest.

---

## 9. Settings → the figures the storefront quotes

| Admin writes | Endpoint | Customer surface |
|---|---|---|
| `SettingsSectionRequest` (`storefront`) | `Settings/SaveSection` | — |
| — | `Shop/Settings/StorefrontConfig` | `StorefrontConfigViewModel` |

Every number a shopper sees originates here:

| Setting | Appears in |
|---|---|
| `FreeShippingThreshold` | Free-shipping progress bar in cart and mini cart, "Add ₹X more" |
| `StandardShippingCost` | Cart and checkout summary |
| `CodFee` | Stated **on the COD payment option itself**, never revealed after selection |
| `ReturnWindowDays` | PDP trust row, return page, policy page, `CanReturn` |
| `SupportPhone` / `Email` / `WhatsApp` / `Hours` | Header help menu, footer, checkout header, help centre, every error state |
| `PointsPerHundredSpent`, `PointValue` | Rewards page, checkout points slider |
| `RobotsIndexable` | The `<meta name="robots">` tag — stays false until launch |

A hard-coded ₹999 in a Razor view is a defect: change the threshold in Admin and that
view lies.

---

## 10. Shipping → delivery dates

| Admin writes | Endpoint | Customer surface |
|---|---|---|
| Zones, rates, courier config | `Shipping/RateSave` | — |
| — | `Shop/Shipping/CheckPincode` | PDP PIN check, cart estimate, checkout methods |
| — | `Shop/Shipping/Track` | `/track/{orderNumber}` timeline |
| — | `Public/Track` | Guest tracking — no account needed |

The PIN is remembered for 30 days (`ch_pin`) and reused on PDP, cart, checkout and even
search cards. Delivery is always shown as a **date** — "Get it by Wed, 12 Aug" — never
"3–5 business days", because a shopper cannot plan around a range with no anchor.

---

## 11. Identity, cart and the guest→customer merge

The one flow that spans both tiers without an admin screen:

1. Anonymous shopper gets a `ch_guest` cookie; `ApiService` sends it as `X-Guest-Token`
2. Cart and wishlist accumulate against that token
3. On sign-in, `Shop/Auth/MergeGuestCart` folds it into the customer's own cart
4. The guest token is retired

The cookie is long-lived on purpose. Losing it loses the shopper's work, which
CX principle 11 forbids.

---

## 12. What is built, and what is not

| Layer | State |
|---|---|
| `ChamundaHandicraft.Helper` | ✅ Contract complete — enums, envelope, paging, `ApiEndPoint`, `ApiService`, view models for both tiers |
| `ChamundaHandicraft.Customer` | ✅ 24 controllers and 60 views bound to the contract via `IStorefrontClient` |
| `ChamundaHandicraft.Admin` | ✅ 63 controllers and all 173 views bound via `IAdminClient` |
| `ChamundaHandicraft.APIGateway` | ✅ Ocelot routes defined for Admin / Shop / Public / Webhooks |
| `ChamundaHandicraft.API` | ❌ **Empty.** No controllers, services or DI wiring. |
| 25 module libraries | ❌ **Empty.** `.csproj` and `ARCHITECTURE.md` only — no entities, services or repositories. |
| `DatabaseScripts` | ❌ No schema or stored procedures. |

### How the Admin panel is wired

Most of the 60 admin modules are the same four operations against a different entity, so
they derive from `AdminCrudController<TGrid, TSave>` (or `AdminListController<TGrid>` for
read-only queues) and declare only their module name and two types. Their routes are built
by `ApiEndPoint.Crud.*` rather than 300 hand-written constants.

Modules with behaviour beyond CRUD keep explicit controllers, because their semantics are
worth naming: **Dashboard** (composed tiles), **Product** (the publish gate), **Order**
(lifecycle transitions and notifications), **Category** (a tree, not a page), **Review**
(moderation), **Settings** (the figures the storefront quotes), **Permission**, **Profile**.

Three places make the Admin → Customer link visible in the UI itself:

| Screen | What it shows |
|---|---|
| Product grid | An **On Storefront** column — Live or Hidden, one answer instead of combining Status and Visibility — and a Preview link that opens the real `/p/{slug}` |
| Artisan / Blog / CMS grids | The same Preview link to `/artisans/{slug}`, `/blog/{slug}`, `/pages/{slug}` |
| Order detail | Only the **legal next statuses** in the transition dropdown, with *Notify the customer* ticked by default |

### The critical path from here

1. **Database** — schema and stored procedures for Catalog, Categories, Inventory, Orders, Cart
2. **Modules** — entities, repositories and services for those five, in the shape each module's `ARCHITECTURE.md` already specifies
3. **API** — `/api/customer/*` first: `Product/List`, `Product/Detail`, `Search/Query`, `Cart/*`. The storefront lights up the moment these exist.
4. **API admin side** — `/api/admin/*`. The generic CRUD shape means one controller pattern covers most of the 60 modules; only the eight named above need bespoke actions.
5. **Flip the flag** — set `Api:UseLiveGateway = true` in both projects. No other change.

Both web tiers are finished against the contract. What remains is entirely below the
gateway.

---

## 13. Rules that hold the contract together

| # | Rule |
|---|---|
| 1 | Neither MVC project references a module project or a connection string. |
| 2 | Neither builds a URL by hand — every call names a constant from `ApiEndPoint`. |
| 3 | A shape either lives in `Helper` or it is presentation-only. If both tiers need it, it moves to `Helper`. |
| 4 | Prices, discounts, stock states and "what can I still do" are computed **server-side**. A view formats; it does not decide. |
| 5 | Anything a shopper is told must be traceable to something an admin actually set, or to a real system fact. No figure is invented in a view. |
| 6 | Every admin action with a customer-visible effect says so in its confirmation — "Published. It is now live on the storefront", not "status updated". |
