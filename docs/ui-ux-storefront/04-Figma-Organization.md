# 04 — Figma Organization & Developer Handoff (Storefront)

Enterprise Handicraft E-Commerce Platform · Customer Website UI/UX Specification

---

## 1. Figma File Architecture

One Figma Team, project **`Handicraft Commerce`**, containing both product surfaces.

| File | Purpose | Published as library |
|------|---------|---------------------|
| `00 · Chamunda DS — Primitives` | Shared raw tokens: colour primitives, spacing, radius, motion, icon set, brand assets | ✅ Yes — consumed by both storefront and admin |
| `01 · Chamunda DS — Storefront Foundations` | Storefront semantic tokens, type scale, grids, effects, illustrations, photography direction | ✅ Yes |
| `02 · Chamunda DS — Storefront Components` | All 140 component sets from `03-Component-Library.md` | ✅ Yes |
| `03 · Storefront — Product Design` | Every page, state and breakpoint | ❌ No |
| `04 · Storefront — Prototypes` | Interactive flows for testing and demos | ❌ No |
| `05 · Storefront — Content & Assets` | Real product photography, copy decks, illustration masters | ❌ No |
| (existing) `06–09 · Admin Panel files` | Per the Admin specification | — |

**Dependency rule:** `03` consumes `02` which consumes `01` which consumes `00`. Nothing is drawn from scratch in `03` that could be a component in `02`.

---

## 2. File `01` — Foundations: Page Structure

| Page | Contents |
|------|----------|
| `📖 Cover` | Project, version, owner, last updated, status, links to both spec folders |
| `📐 00 Guidelines` | How to use, contribution rules, naming rules, campaign theming rules |
| `🎨 01 Colour` | Primitive swatches, semantic map (light/dark), commerce-state mapping, contrast proof board, campaign override rules |
| `🔤 02 Typography` | Fraunces + Inter specimens, full scale, pairing rules, Devanagari specimens, do/don't |
| `📏 03 Spacing & Grid` | Spacing scale, layout grids per breakpoint, templates SL-01…SL-12 |
| `🌑 04 Elevation & Radius` | Shadow and radius specimens in both themes |
| `⚡ 05 Motion` | Duration/easing specimens with animated prototypes, signature patterns |
| `🧩 06 Iconography` | Lucide set as components, craft icon set, sizes, usage map |
| `🖼 07 Illustrations` | Empty, error, success, onboarding — light and dark variants |
| `📷 08 Photography` | Direction boards: pack shot, detail, scale, lifestyle, artisan, process; crop templates per derivative |
| `🏷 09 Brand & Marks` | Logo lockups, payment marks, courier marks, social marks, trust badges |
| `♿ 10 Accessibility` | Contrast matrix, focus specimens, touch-target overlays, reduced-motion notes |
| `🧪 11 Token Playground` | Live examples wired to Variables for testing theme and campaign switches |

---

## 3. File `02` — Components: Page Structure

| Page | Component sets |
|------|----------------|
| `📖 Cover` | — |
| `🔘 01 Actions` | Button, Icon Button, Link, Quantity Stepper, Wishlist Toggle, Share Menu, FAB |
| `🧭 02 Navigation` | Announcement Bar, Header, Nav Bar, Mega Menu, Mobile Drawer, Bottom Tabs, Breadcrumb, Footer, Tabs, Pagination, Stepper, Accordion, Category Menu, Chip Nav |
| `🔍 03 Search` | Search Bar, Suggestions Panel, Search Overlay |
| `🏺 04 Product` | Product Card (all 3), Price Block, Badge, Rating, Swatch, Option Selector, Stock, Variation Notice, Delivery Estimate, Spec List, Dimension Diagram, Artisan Chip, Artisan Card, Rail, Grid, Compare Bar |
| `🖼 05 Media` | Image, Gallery, Zoom, Lightbox, 360 Viewer, Video Player, Carousel, Hero, Category Tile, Collection Banner |
| `🛒 06 Commerce` | Cart Line Item, Mini Cart, Order Summary, Coupon components, Gift Options, Shipping Progress, Saved Item, Address Card, Delivery Option, Payment Option, Saved Card, Points Applicator, Confirmation Card |
| `📦 07 Orders` | Order Card, Order Timeline, Status Chip, Tracking Map, Return Item, Refund Status |
| `⭐ 08 Reviews` | Review Card, Rating Input, Breakdown, Photo Strip, AI Summary, Review Form |
| `⌨ 09 Forms` | All input components + Field Wrapper |
| `🎚 10 Filters` | Filter Rail, Group, Chip, Active Bar, Sort, Filter Sheet |
| `💬 11 Feedback` | Toast, Alert, Inline Message, Tooltip, Progress, Spinner, Skeleton, Empty/Error/Success States |
| `🪟 12 Overlays` | Modal, Drawer, Bottom Sheet, Popover, Cookie Consent, Newsletter Popup |
| `🔖 13 Indicators` | Tag, Label, Counter, Avatar, Trust Badge, Payment Marks, Countdown |
| `👤 14 Account & Content` | Account Sidebar, Profile Card, Points Card, Notification Item, Article Card, TOC, FAQ Item, Table, Instagram Tile, Newsletter Form |
| `✨ 15 AI` | AI Launcher, Chat Panel, Message, Suggestion, Disclosure |
| `✅ 16 Usage Examples` | Correct vs incorrect boards, composition examples, anti-pattern boards |

---

## 4. File `03` — Product Design: Page Structure

| Page | Contents |
|------|----------|
| `📖 00 Cover & Index` | Screen map, status legend, change log |
| `🗺 00a Information Architecture` | Sitemap, navigation model, journey maps, funnel diagram |
| `🎨 00b Shell` | Header (all states), mega menu panels, mobile drawer, bottom tabs, footer (all variants), announcement bar, cookie consent |
| `🔐 01 Authentication` | Module 1 |
| `🏠 02 Home` | Module 2 |
| `🛍 03 Shop / PLP` | Module 3 |
| `🏺 04 Product Details` | Module 4 |
| `⚖ 05 Compare` | Module 5 |
| `♡ 06 Wishlist` | Module 6 |
| `🛒 07 Cart` | Module 7 |
| `💳 08 Checkout` | Module 8 |
| `💰 09 Payment` | Module 9 |
| `👤 10 My Account` | Module 10 |
| `📦 11 Orders` | Module 11 |
| `🚚 12 Order Tracking` | Module 12 |
| `🔍 13 Search` | Module 13 |
| `💬 14 Customer Support` | Module 14 |
| `⭐ 15 Reviews` | Module 15 |
| `🎁 16 Rewards` | Module 16 |
| `🔔 17 Notifications` | Module 17 |
| `📰 18 Blog` | Module 18 |
| `📄 19 Static Pages` | Module 19 |
| `✨ 20 AI Shopping` | Module 20 |
| `⚠ 21 System Pages` | 404, 500, 503, offline, browser unsupported, session expired |
| `📱 90 Mobile-Only Screens` | Consolidated mobile-specific surfaces (sheets, scanner, native share) |
| `🌑 91 Dark Theme` | Divergent dark screens + spot checks |
| `📧 92 Transactional Emails` | Order confirmation, shipped, delivered, OTP, password reset, review request, abandoned cart |
| `🖨 93 Print Artefacts` | Invoice PDF, packing slip (customer copy) |
| `🧪 94 Explorations` | Parked ideas — never referenced by engineering |
| `🗄 99 Archive` | Superseded designs, date-stamped |

### 4.1 Section Structure Within a Module Page

Fixed Figma **Section** order on every module page:

```
▸ SECTION: 00 · Overview            (flows, screen map, journey, notes)
▸ SECTION: 01 · Mobile — 390        ← designed FIRST
▸ SECTION: 02 · Tablet — 768
▸ SECTION: 03 · Desktop — 1440
▸ SECTION: 04 · States              (loading, empty, error, success, edge cases)
▸ SECTION: 05 · Overlays            (modals, drawers, sheets)
▸ SECTION: 06 · Dark Theme
▸ SECTION: 07 · Annotations & Redlines
```

**Mobile first is a structural rule, not a preference** — 68% of traffic is mobile, and the mobile section is the one reviewed first in every design critique.

Section colours: Overview grey · Mobile green · Tablet teal · Desktop blue · States amber · Overlays purple · Dark near-black · Annotations red.

---

## 5. Frame Specification

### 5.1 Standard Frame Sizes

| Name | Size | Purpose |
|------|------|---------|
| `Mobile / 390` | 390 × auto | **Primary mobile design size** (iPhone 14/15 class) |
| `Mobile / 360` | 360 × auto | Small-Android verification |
| `Mobile / 430` | 430 × auto | Large-phone verification |
| `Tablet / 768` | 768 × auto | **Primary tablet size** |
| `Tablet / 1024` | 1024 × auto | Landscape tablet |
| `Desktop / 1440` | 1440 × auto | **Primary desktop size** |
| `Desktop / 1280` | 1280 × auto | Minimum desktop verification |
| `Desktop / 1920` | 1920 × auto | Large-screen verification |
| `Modal / {w}` | Per modal width | Isolated overlays |
| `Sheet / 390` | 390 × auto | Bottom sheets |
| `Email / 600` | 600 × auto | Transactional emails |
| `Doc / A4` | 1240 × 1754 @150 dpi | Invoice |

Page frames use auto height. Never fix a page height and clip.

### 5.2 Frame Naming

```
[{SCREEN-ID}] {Module} / {Screen} / {Variant} — {Breakpoint}

[PG-04-01] PDP / Product Detail / Default — Mobile 390
[PG-04-01] PDP / Product Detail / Out of Stock — Mobile 390
[PG-04-01] PDP / Product Detail / Default — Desktop 1440
[DRW-07-01] Cart / Mini Cart / With Items — Desktop 1440
[SHT-03-01] Shop / Filters Sheet / Applied — Mobile 390
[MOD-08-02] Checkout / Address Form / Error — Modal 640
```

### 5.3 Frame Status Badge

Pinned outside the top-left of every screen frame:

| Badge | Meaning |
|-------|---------|
| 🔴 `DRAFT` | In progress |
| 🟡 `REVIEW` | Awaiting design/PO/CX review |
| 🟢 `APPROVED` | Ready for development |
| 🔵 `BUILT` | Implemented and verified against production |
| 🟣 `A/B TEST` | Variant under live test — includes the hypothesis and test ID |
| ⚫ `DEPRECATED` | Superseded — links to the replacement |

---

## 6. Layer Naming

| Layer type | Pattern | Example |
|------------|---------|---------|
| Page section / band | `BAND / {name}` | `BAND / New Arrivals` |
| Region | `REGION / {name}` | `REGION / Gallery` |
| Component instance | Component name; rename only when semantically necessary | `Button — Add to Cart` |
| Text | `txt / {purpose}` | `txt / Product Title` |
| Image | `img / {subject}` | `img / Blue Pottery Vase — detail` |
| Icon | `icon / {name}` | `icon / heart` |
| Auto Layout stack | `stack-v / {purpose}` or `stack-h / {purpose}` | `stack-v / Price Block` |
| Group | `grp / {purpose}` | `grp / Badge Cluster` |
| Placeholder | `ph / {what}` | `ph / Map` |
| Annotation | `note / {topic}` | `note / Validation` |

**Forbidden:** `Frame 12`, `Group 3`, `Rectangle 5`, `Vector`, `Ellipse 7`. A file containing any auto-generated layer name fails design QA.

---

## 7. Figma Variables

### 7.1 Collections

| Collection | Modes | Scoping | Published |
|------------|-------|---------|-----------|
| `1 · Primitives` | `Value` | Colour | Hidden from consumers |
| `2 · Semantic` | `Light`, `Dark` | Colour | ✅ |
| `3 · Campaign` | `Default`, `Diwali`, `Wedding`, `Sale` | Colour (limited set only) | ✅ |
| `4 · Spacing` | `Value` | Gap, padding, width, height | ✅ |
| `5 · Radius` | `Value` | Corner radius | ✅ |
| `6 · Typography` | `Value` | Size, line height, weight, tracking | ✅ |
| `7 · Sizing` | `Mobile`, `Tablet`, `Desktop` | Control heights, container widths, gutters | ✅ |
| `8 · Effects` | `Light`, `Dark` | Shadows | ✅ |
| `9 · Grid` | `Mobile`, `Tablet`, `Desktop` | Columns, gutter, margin | ✅ |
| `10 · Content` | `EN`, `HI` | Strings for localisation testing | ✅ |

### 7.2 Colour Variable Naming

```
color/bg/canvas
color/bg/surface
color/bg/subtle
color/bg/craft
color/bg/premium
color/bg/overlay
color/text/primary
color/text/secondary
color/text/tertiary
color/text/craft
color/price/default
color/price/sale
color/price/strike
color/border/subtle
color/border/default
color/border/strong
color/action/primary/bg
color/action/primary/bg-hover
color/action/secondary/bg
color/action/buy-now/bg
color/status/success/text
color/status/warning/text
color/status/danger/text
color/status/info/text
color/rating/fill
color/focus/ring
```

### 7.3 Typography Variable Naming

```
type/display-2xl/size          type/display-2xl/line-height
type/heading-xl/size           type/heading-xl/weight
type/body-md/size              type/body-md/line-height
type/price-2xl/size            type/price-2xl/weight
type/button-lg/size            type/label-sm/tracking
```

Composite **Text Styles** are built on top of these variables and named `{Category}/{token}` — `Display/display-2xl`, `Heading/heading-xl`, `Body/body-md`, `Price/price-2xl`, `Label/label-md`, `Button/button-lg`, `Mono/mono-md`.

### 7.4 Spacing & Grid Variable Naming

```
space/3xs … space/5xl
size/control/sm | md | lg | xl
size/container/max
size/header/height
size/card/image-ratio
grid/columns
grid/gutter
grid/margin
radius/xs … radius/full
effect/elevation-1 … effect/elevation-5
```

### 7.5 Mode Switching Rules

- Every top-level screen frame explicitly sets the `Semantic` mode (`Light` default) and the `Sizing`/`Grid` mode matching its breakpoint.
- Dark screens are produced by duplicating the frame and switching the mode — **never** by manual recolouring.
- Campaign variants are produced by switching the `Campaign` mode; if a campaign requires anything beyond the permitted token set, it is a design change, not a theme.
- Localisation checks are run by switching the `Content` mode to `HI` to verify text expansion.

---

## 8. Auto Layout Standards

### 8.1 Global Rules

| ID | Rule |
|----|------|
| AL-01 | Any frame with more than one child uses Auto Layout. Absolute positioning only for on-image badges, overlay controls and decorative art. |
| AL-02 | Padding and gap always come from the Spacing collection — never typed numbers. |
| AL-03 | Page frames are vertical stacks, Fill width, Hug height. |
| AL-04 | Text inside Auto Layout is Fill width / Auto height so it wraps, except where clamping is specified. |
| AL-05 | Product card title uses a fixed height so cards align across a grid row. |
| AL-06 | Image containers use ratio-locked frames with Fill width. |
| AL-07 | Min/max width constraints are set on content columns (article 680, form 560, container 1440). |
| AL-08 | Components expose sensible resizing: buttons Hug with a Fill variant; inputs Fill; cards Fill within grid cells. |
| AL-09 | Sticky elements are separate top-level siblings, never nested inside scrolling stacks. |
| AL-10 | Rails use horizontal Auto Layout with Fixed width and clipped content, with scroll behaviour set in prototype settings. |

### 8.2 Canonical Auto Layout Trees

**Home page**
```
Frame: Home — Desktop 1440 (V, Fill × Hug, gap 0)
├── Instance: AnnouncementBar (Fill × 40)
├── Instance: Header (Fill × 80)          [Fixed position]
├── Instance: NavBar (Fill × 52)          [Fixed position]
├── Frame: Content (V, Fill × Hug, gap 80)
│   ├── Instance: Hero (Fill × 640)
│   ├── Frame: BAND / Categories (V, Fill × Hug, gap 32, padding 0 40)
│   │   ├── Frame: Band Header (H, Fill × Hug, space-between)
│   │   └── Frame: Tile Grid (H wrap, Fill × Hug, gap 24)
│   ├── Instance: BAND / Featured Rail
│   ├── Instance: BAND / Craft Story
│   ├── Instance: BAND / New Arrivals Rail
│   └── … (18 bands total)
└── Instance: Footer (Fill × Hug)
```

**Product Detail (desktop)**
```
Frame: PDP — Desktop 1440 (V, Fill × Hug, gap 0)
├── Shell instances…
├── Instance: Breadcrumb (Fill × 44)
├── Frame: Main (H, Fill × Hug, gap 48, padding 24 40, align top)
│   ├── Frame: Gallery Column (58.33% ≈ 7 cols, V, Hug)
│   │   └── Instance: Gallery
│   └── Frame: Info Column (41.67% ≈ 5 cols, V, Hug, gap 24)  [Sticky]
│       ├── Frame: Identity (V, gap 8)      → Brand, Title, Rating, Artisan chip
│       ├── Instance: PriceBlock
│       ├── Instance: VariationNotice
│       ├── Frame: Options (V, gap 20)      → Swatches, Size selector
│       ├── Instance: StockIndicator
│       ├── Instance: DeliveryEstimate
│       ├── Frame: Actions (H, Fill, gap 12) → Qty, Add to Cart, Buy Now, Wishlist
│       ├── Instance: TrustBadge Row
│       └── Instance: Accordion Group        → Details, Care, Shipping, Returns
├── Frame: Tabs Section (V, Fill × Hug, padding 80 40)
├── Instance: BAND / Artisan Story
├── Instance: BAND / Reviews
├── Instance: BAND / Related Rail
├── Instance: BAND / Recently Viewed Rail
└── Instance: Footer
```

**Product Detail (mobile)**
```
Frame: PDP — Mobile 390 (V, Fill × Hug, gap 0)
├── Instance: Header (Fill × 56)  [Fixed]
├── Instance: Gallery Carousel (Fill × 390)
├── Frame: Info (V, Fill × Hug, gap 20, padding 16)
│   └── … same order as desktop info column
├── Instance: Accordion Group
├── Instance: BAND / Reviews
├── Instance: BAND / Related Rail
├── Instance: Footer
└── Instance: Sticky CTA Bar (Fill × 72)  [Fixed bottom]
```

**Checkout (desktop)**
```
Frame: Checkout — Desktop 1440 (V, Fill × Hug)
├── Instance: Header / Minimal (Fill × 72)   [no nav, protects conversion]
├── Frame: Body (H, Fill × Hug, gap 40, padding 32 40, align top)
│   ├── Frame: Form Column (58.33%, V, gap 32)
│   │   ├── Instance: Stepper
│   │   ├── Instance: Card / Contact
│   │   ├── Instance: Card / Delivery Address
│   │   ├── Instance: Card / Delivery Method
│   │   └── Instance: Card / Payment
│   └── Frame: Summary Column (41.67%, V, gap 16)  [Sticky]
│       ├── Instance: OrderSummary
│       ├── Instance: CouponInput
│       ├── Instance: TrustBadge stack
│       └── Instance: Button / Place Order
└── Instance: Footer / Minimal
```

**Product Card**
```
Component: Product Card / MD (V, Fill × Hug, gap 12)
├── Frame: Media (Fill × ratio 1:1, radius-lg, clip)
│   ├── Instance: Image (Fill)
│   ├── Frame: Badges (V, gap 4)          [Absolute, top-left, 8px]
│   ├── Instance: WishlistToggle          [Absolute, top-right, 8px]
│   └── Instance: Button / Quick View     [Absolute, centre — hover only]
└── Frame: Content (V, Fill × Hug, gap 6, padding 0 16 16)
    ├── txt / Category Overline           [optional]
    ├── txt / Title (Fill, fixed height 44, 2-line clamp)
    ├── Instance: ArtisanChip             [optional]
    ├── Instance: Rating / SM
    ├── Instance: PriceBlock / SM
    ├── txt / Stock Line                  [conditional]
    └── Instance: Button / Add to Cart (Fill × 36)  [hover only on desktop]
```

---

## 9. Component Construction Standards

| ID | Rule |
|----|------|
| C-01 | Build the base component with full Auto Layout, then add variants |
| C-02 | Variant property names are Title Case and consistent library-wide: `Variant`, `Size`, `State`, `Type`, `Icon`, `Width`, `Layout`, `Placement`, `Tone`, `Media` |
| C-03 | Boolean properties for optional elements: `Has Badge`, `Has Rating`, `Has Artisan`, `Has Discount` |
| C-04 | Text properties expose every editable string: `Title`, `Price`, `MRP`, `Discount`, `Stock Text` |
| C-05 | Instance swap properties for icons, images, avatars and nested cards |
| C-06 | Default variant is the most common real usage (Product Card → MD / Default / No badge / Rating shown / Portrait) |
| C-07 | Every component description contains purpose, when to use, when NOT to use, a11y notes and a spec reference (`See 03-Component-Library §25`) |
| C-08 | Nested components use Fill sizing so parents control width |
| C-09 | Component sets are laid out in a labelled grid ordered by the primary variant property |
| C-10 | No hidden layers left inside components — use boolean properties |
| C-11 | Interactive states exist as variants AND are wired with While-hovering / While-pressing interactions so prototypes feel real |
| C-12 | Deprecated components are prefixed `⚠ [DEPRECATED]` and kept for one release |
| C-13 | Every component with an image slot must have its ratio locked so CLS cannot be designed in |

---

## 10. Prototype Strategy

### 10.1 Prototype Files

| ID | Flow | Start frame | Audience | Device |
|----|------|-------------|----------|--------|
| `SP-01` | Discover → Buy (mobile, guest) | Home — Mobile | Usability testing | 390 |
| `SP-02` | Discover → Buy (desktop, signed in) | Home — Desktop | Usability testing | 1440 |
| `SP-03` | Search → Filter → PDP → Cart | Search Overlay | Usability testing | 390 |
| `SP-04` | Full checkout with all payment methods | Cart | Payment QA + stakeholder | 390 + 1440 |
| `SP-05` | Guest checkout with new address | Cart | Usability testing | 390 |
| `SP-06` | Account: orders, tracking, return request | Account Dashboard | Usability testing | 390 |
| `SP-07` | Wishlist and Compare | PLP | Usability testing | 1440 |
| `SP-08` | Reviews: read, filter, write | PDP Reviews | Content review | 390 |
| `SP-09` | AI assistant shopping journey | Home | Stakeholder demo | 390 |
| `SP-10` | Error and recovery paths (payment failure, out of stock, offline) | Cart | QA + stakeholder | 390 |
| `SP-11` | Authentication: register, OTP, social, reset | Sign In | Usability testing | 390 |
| `SP-12` | Full navigation walkthrough | Home | Executive demo | 1440 |

### 10.2 Interaction Standards

| Interaction | Trigger | Animation |
|-------------|---------|-----------|
| Navigate | On click | Instant (Smart Animate 200 ms for in-page changes) |
| Open modal | On click | Open overlay · Move In from bottom 8 px + Dissolve · 350 ms · Ease Out |
| Close modal | On click / Key Esc | Close overlay · Dissolve · 250 ms |
| Open drawer | On click | Open overlay · Move In from Right · 350 ms · Ease Out |
| Open bottom sheet | On click | Open overlay · Move In from Bottom · 350 ms · Ease Out |
| Dropdown / popover | On click | Open overlay · Dissolve · 150 ms |
| Tooltip | While hovering | Open overlay · Dissolve · 150 ms · delay 300 ms |
| Toast | After delay 300 ms | Move In from Right, then After Delay 4000 ms → Close |
| Card hover | While hovering | Change To hover variant · 150 ms |
| Image hover zoom | While hovering | Smart Animate · 400 ms · Ease Out |
| Add to cart | On click | Change To loading → After Delay 800 ms → success variant → open Mini Cart |
| Gallery change | On click | Smart Animate · 200 ms |
| Tab / accordion | On click | Smart Animate · 250 ms · Ease Out |
| Filter apply | On click | Change To filtered variant · Dissolve 200 ms |
| Scroll reveal | On scroll | Not prototyped — documented in annotations |
| Sticky elements | — | Fixed position on Header, Sticky CTA, Summary column, Bottom Tabs |

### 10.3 Prototype Hygiene

- Every prototype opens on a "Start Here" frame stating the persona, scenario and task list.
- No dead ends: every screen links back to at least its parent.
- Overlays close on scrim click and `Esc`.
- Real product photography and real copy only — never lorem ipsum in a testing prototype.
- Device frame: iPhone 14 Pro for mobile prototypes, Desktop 1440 with background `paper-100` for desktop.
- Prototypes used for usability testing hide the Figma UI and use "Fit width" scaling.

---

## 11. Content & Data Population Standards

| Data | Rule |
|------|------|
| Product names | Real craft names: "Blue Pottery Vase — Jaipur", "Brass Diya Set of 5", "Kantha Embroidered Cushion Cover", "Channapatna Wooden Elephant", "Kani Weave Pashmina Shawl", "Dhokra Tribal Figurine" |
| Artisan names | Plausible, regionally varied, with real cluster names (Jaipur, Kutch, Channapatna, Bishnupur, Moradabad) |
| Prices | Realistic spread ₹250 – ₹45,000, never all round numbers |
| Ratings | Varied: 4.8, 4.6, 4.2, 3.9 — never all 5.0 |
| Review counts | Varied: 128, 42, 7, 0 |
| Review text | Real-sounding, including one critical review per product |
| Dates | Relative to the design date; include today, yesterday, last week |
| Customer names | Diverse Indian and international names |
| Addresses | Real Indian address formats with valid PIN formats |
| Order numbers | `#HC-2026-000482` sequential |
| Images | Licensed handicraft photography — grey boxes are never acceptable in an APPROVED frame |
| Edge cases | Every grid includes: one long product name (2 lines), one missing image, one out-of-stock item, one item with no rating, one heavily discounted item |
| Empty text | Rendered as `—`, never blank |

---

## 12. Annotation & Redline Standards

Each module page's `SECTION: 07 · Annotations & Redlines` contains:

| Annotation | Component | Content |
|------------|-----------|---------|
| Spec pin | Numbered circle + callout | Element, size, spacing, token names |
| Behaviour note | Yellow sticky | Interaction, timing, edge cases |
| Validation note | Red sticky | Field rules and exact error copy |
| Content note | Blue sticky | Copy source, character limits, localisation notes |
| API note | Purple sticky | Endpoint, key fields, error states |
| Accessibility note | Green sticky | Role, accessible name, keyboard, announcement |
| Analytics note | Orange sticky | Event name and properties fired |
| Performance note | Grey sticky | Image budget, lazy-load boundary, LCP element |
| Open question | Pink sticky + `@mention` | Question, owner, due date |

Redlines use a consistent 12 px mono font and 1 px dashed measurement lines in `#E11D48`.

**Mandatory annotations per screen:** the LCP element must be marked; the lazy-load boundary must be drawn; every conversion action must carry its analytics event.

---

## 13. Developer Handoff

### 13.1 Handoff Checklist (per screen)

- [ ] Frame status is 🟢 APPROVED
- [ ] Mobile 390, Tablet 768 and Desktop 1440 exist (or a documented "no change" note)
- [ ] Dark theme variant exists or is confirmed as an automatic mode switch
- [ ] All states designed: loading, empty, filtered-empty, error, success, offline, out-of-stock, signed-out
- [ ] Every element maps to a library component — zero detached instances
- [ ] Spacing, colour and type inspect as Variable names, not raw values
- [ ] Image ratios locked; LCP element marked; lazy boundary drawn
- [ ] Annotations complete: behaviour, validation, content, API, a11y, analytics, performance
- [ ] Copy is final and matches the module spec tables verbatim
- [ ] Prototype link exists for any multi-step flow
- [ ] Assets marked for export at 1× and 2×
- [ ] Touch targets verified ≥48 px on mobile
- [ ] Contrast verified in both themes

### 13.2 Dev Mode Configuration

- Dev Mode enabled on file `03`; approved sections marked "Ready for development".
- Each module section links to its Jira/Azure DevOps epic.
- Variables published so tokens inspect as named values.
- A maintained mapping table (in file `01` → `00 Guidelines`) lists: Figma variable → CSS custom property name → the Bootstrap 5 variable or utility it overrides. Designers guarantee every visual value has a token name; engineering owns the implementation.

### 13.3 Asset Export

| Asset | Format | Scales | Naming |
|-------|--------|--------|--------|
| Icons | SVG (stroke preserved) | 1× | `icon-{name}.svg` |
| Illustrations | SVG preferred, PNG fallback | 1×, 2× | `illus-{name}-{theme}.svg` |
| Logos | SVG | 1× | `logo-{variant}.svg` |
| Payment/courier marks | SVG | 1× | `mark-{brand}.svg` |
| Photography | AVIF + WEBP + JPG | per derivative table | `{entity}-{slug}-{size}.{ext}` |
| Favicons | PNG/ICO/SVG | 16, 32, 180, 192, 512 | standard |
| OG images | JPG | 1200×630 | `og-{page}.jpg` |

### 13.4 Bootstrap 5 Handoff Notes

The build uses Bootstrap 5 with a custom theme layer. Designers must know:

| Concern | Guidance |
|---------|----------|
| Grid | The 12-column grid and gutters map to Bootstrap's grid; use the documented breakpoints so `col-*` classes align to the design |
| Container | `container-xxl` with a custom max width of 1440 |
| Spacing | The spacing scale maps to a custom `$spacers` map; do not invent intermediate values |
| Buttons | Variants map to custom `.btn-*` classes; sizes map to `.btn-sm/.btn-lg` plus a custom XL |
| Components not in Bootstrap | Gallery, rails, filter sheet, mini cart, 360 viewer, AI panel are custom — flag them clearly in handoff so effort is estimated correctly |
| jQuery plugins | Carousels, sliders and lightbox may use existing plugins; the design must specify behaviour precisely enough that plugin defaults are overridden correctly |
| Progressive enhancement | Every conversion path must work without JavaScript-dependent enhancements where feasible (forms submit, links navigate) |

---

## 14. Design QA Gates

| Gate | Owner | Criteria |
|------|-------|----------|
| G1 · Structure | UX Architect | IA correct; every screen in the module spec exists |
| G2 · System | Design System Owner | 100% component/token usage; zero detached instances; zero local styles |
| G3 · Content | Business Analyst / Content | Copy matches spec verbatim; character limits respected; HI mode checked |
| G4 · Accessibility | A11y Lead | Contrast, focus, keyboard, targets, announcements documented |
| G5 · Responsive | UI Designer | 390 / 768 / 1440 present; reflow rules honoured; 320 and 1920 verified |
| G6 · Performance | Front-End Lead | LCP element marked; image budgets respected; lazy boundary drawn |
| G7 · Conversion | CX Lead / PO | Funnel steps intact; no dark patterns; trust elements present |
| G8 · Prototype | UX Lead | Flow complete, no dead ends |
| G9 · Handoff | Front-End Lead | Buildable without further questions |

A frame reaches 🟢 APPROVED only after all nine gates pass.

---

## 15. Versioning & Branching

- Figma **Branches** for any change touching more than 3 frames.
- Branch naming: `feat/{module}-{description}`, `fix/{module}-{issue}`, `test/{module}-{ab-id}`, `chore/{topic}`.
- Merge only after G1–G9 and resolution of all review comments.
- Named versions at every release: `v1.0.0 — Launch Scope Frozen`.
- Library files publish weekly with release notes; breaking token changes require a MAJOR bump and a migration note posted to both design and engineering channels.

---

## 16. Estimated Figma Build Effort

| Workstream | Frames / variants | Designer-days |
|------------|------------------:|--------------:|
| Foundations (tokens, type, colour, icons, illustrations, photography direction) | ~140 | 9 |
| Component library (140 sets, all variants, both themes) | ~2,100 variants | 32 |
| Module screens — mobile 390 | ~420 | 30 |
| Module screens — desktop 1440 | ~380 | 24 |
| Module screens — tablet 768 | ~180 | 9 |
| States (loading, empty, error, success, edge) | ~320 | 12 |
| Overlays (modals, drawers, sheets) | ~270 | 14 |
| Dark theme divergences | ~120 | 6 |
| Transactional emails | ~14 | 4 |
| Print artefacts | ~4 | 1 |
| Prototypes (12 flows) | — | 10 |
| Annotations & redlines | — | 12 |
| Design QA & revisions | — | 14 |
| **Total** | **~3,950 frames/variants** | **~177 designer-days** |

Recommended team: 1 Design Lead + 2 UI Designers + 1 UX Architect + 0.5 Content Designer over ~14 weeks, with the component library front-loaded into weeks 1–5 and the mobile purchase funnel (PLP → PDP → Cart → Checkout) prioritised in weeks 4–8.
