# 03 — Component Library (Storefront)

Enterprise Handicraft E-Commerce Platform · Customer Website UI/UX Specification
Every component below must exist as a **Figma Component Set** with the listed variant properties, built with Auto Layout and bound to semantic Variables.

---

## Index

| # | Component | ID |
|---|-----------|-----|
| **Actions** |
| 1 | Button | `CMP-ACT-Button` |
| 2 | Icon Button | `CMP-ACT-IconButton` |
| 3 | Link | `CMP-ACT-Link` |
| 4 | Quantity Stepper | `CMP-ACT-QtyStepper` |
| 5 | Wishlist Toggle | `CMP-ACT-WishlistToggle` |
| 6 | Share Menu | `CMP-ACT-ShareMenu` |
| 7 | Floating Action Button | `CMP-ACT-FAB` |
| **Navigation** |
| 8 | Announcement Bar | `CMP-NAV-AnnouncementBar` |
| 9 | Header | `CMP-NAV-Header` |
| 10 | Nav Bar | `CMP-NAV-NavBar` |
| 11 | Mega Menu | `CMP-NAV-MegaMenu` |
| 12 | Mobile Nav Drawer | `CMP-NAV-MobileDrawer` |
| 13 | Bottom Tab Bar | `CMP-NAV-BottomTabs` |
| 14 | Breadcrumb | `CMP-NAV-Breadcrumb` |
| 15 | Footer | `CMP-NAV-Footer` |
| 16 | Tabs | `CMP-NAV-Tabs` |
| 17 | Pagination | `CMP-NAV-Pagination` |
| 18 | Stepper | `CMP-NAV-Stepper` |
| 19 | Accordion | `CMP-NAV-Accordion` |
| 20 | Category Menu | `CMP-NAV-CategoryMenu` |
| 21 | Chip Nav / Scroll Chips | `CMP-NAV-ChipNav` |
| **Search** |
| 22 | Search Bar | `CMP-SRC-SearchBar` |
| 23 | Search Suggestions Panel | `CMP-SRC-Suggestions` |
| 24 | Search Overlay (mobile) | `CMP-SRC-Overlay` |
| **Product** |
| 25 | Product Card | `CMP-PRD-Card` |
| 26 | Product Card (list view) | `CMP-PRD-CardList` |
| 27 | Product Card (compact) | `CMP-PRD-CardCompact` |
| 28 | Price Block | `CMP-PRD-Price` |
| 29 | Badge | `CMP-PRD-Badge` |
| 30 | Rating Display | `CMP-PRD-Rating` |
| 31 | Colour Swatch | `CMP-PRD-Swatch` |
| 32 | Size / Option Selector | `CMP-PRD-OptionSelector` |
| 33 | Stock Indicator | `CMP-PRD-Stock` |
| 34 | Variation Notice | `CMP-PRD-VariationNotice` |
| 35 | Delivery Estimate | `CMP-PRD-DeliveryEstimate` |
| 36 | Specification List | `CMP-PRD-SpecList` |
| 37 | Dimension Diagram | `CMP-PRD-Dimensions` |
| 38 | Artisan Chip | `CMP-PRD-ArtisanChip` |
| 39 | Artisan Story Card | `CMP-PRD-ArtisanCard` |
| 40 | Product Rail | `CMP-PRD-Rail` |
| 41 | Product Grid | `CMP-PRD-Grid` |
| 42 | Compare Bar | `CMP-PRD-CompareBar` |
| **Media** |
| 43 | Image | `CMP-MED-Image` |
| 44 | Product Gallery | `CMP-MED-Gallery` |
| 45 | Zoom Lens | `CMP-MED-Zoom` |
| 46 | Lightbox | `CMP-MED-Lightbox` |
| 47 | 360° Viewer | `CMP-MED-Spin360` |
| 48 | Video Player | `CMP-MED-VideoPlayer` |
| 49 | Carousel | `CMP-MED-Carousel` |
| 50 | Hero Banner | `CMP-MED-Hero` |
| 51 | Category Tile | `CMP-MED-CategoryTile` |
| 52 | Collection Banner | `CMP-MED-CollectionBanner` |
| **Commerce** |
| 53 | Cart Line Item | `CMP-CRT-LineItem` |
| 54 | Mini Cart Drawer | `CMP-CRT-MiniCart` |
| 55 | Order Summary | `CMP-CRT-Summary` |
| 56 | Coupon Input | `CMP-CRT-CouponInput` |
| 57 | Applied Coupon | `CMP-CRT-AppliedCoupon` |
| 58 | Coupon Card | `CMP-CRT-CouponCard` |
| 59 | Gift Options | `CMP-CRT-GiftOptions` |
| 60 | Free Shipping Progress | `CMP-CRT-ShippingProgress` |
| 61 | Saved for Later Item | `CMP-CRT-SavedItem` |
| 62 | Address Card | `CMP-CHK-AddressCard` |
| 63 | Delivery Method Card | `CMP-CHK-DeliveryOption` |
| 64 | Payment Method Card | `CMP-CHK-PaymentOption` |
| 65 | Saved Card Item | `CMP-CHK-SavedCard` |
| 66 | Reward Points Applicator | `CMP-CHK-PointsApplicator` |
| 67 | Order Confirmation Card | `CMP-CHK-Confirmation` |
| **Orders** |
| 68 | Order Card | `CMP-ORD-Card` |
| 69 | Order Timeline | `CMP-ORD-Timeline` |
| 70 | Order Status Chip | `CMP-ORD-StatusChip` |
| 71 | Tracking Map | `CMP-ORD-TrackingMap` |
| 72 | Return Request Item | `CMP-ORD-ReturnItem` |
| 73 | Refund Status | `CMP-ORD-RefundStatus` |
| **Reviews** |
| 74 | Review Card | `CMP-REV-Card` |
| 75 | Rating Input | `CMP-REV-RatingInput` |
| 76 | Rating Breakdown | `CMP-REV-Breakdown` |
| 77 | Review Photo Strip | `CMP-REV-PhotoStrip` |
| 78 | Review Summary (AI) | `CMP-REV-AiSummary` |
| 79 | Write Review Form | `CMP-REV-Form` |
| **Forms** |
| 80 | Text Field | `CMP-INP-TextField` |
| 81 | Textarea | `CMP-INP-Textarea` |
| 82 | Select | `CMP-INP-Select` |
| 83 | Combobox | `CMP-INP-Combobox` |
| 84 | Checkbox | `CMP-INP-Checkbox` |
| 85 | Radio | `CMP-INP-Radio` |
| 86 | Switch | `CMP-INP-Switch` |
| 87 | Segmented Control | `CMP-INP-Segmented` |
| 88 | Range Slider | `CMP-INP-RangeSlider` |
| 89 | Date Picker | `CMP-INP-DatePicker` |
| 90 | Time Picker | `CMP-INP-TimePicker` |
| 91 | OTP Input | `CMP-INP-OtpInput` |
| 92 | Phone Input | `CMP-INP-PhoneInput` |
| 93 | PIN Code Check | `CMP-INP-PincodeCheck` |
| 94 | File Upload | `CMP-INP-FileUpload` |
| 95 | Photo Upload | `CMP-INP-PhotoUpload` |
| 96 | Form Field Wrapper | `CMP-INP-Field` |
| **Filters** |
| 97 | Filter Rail | `CMP-FLT-Rail` |
| 98 | Filter Group | `CMP-FLT-Group` |
| 99 | Filter Chip | `CMP-FLT-Chip` |
| 100 | Active Filter Bar | `CMP-FLT-ActiveBar` |
| 101 | Sort Dropdown | `CMP-FLT-Sort` |
| 102 | Filter Sheet (mobile) | `CMP-FLT-Sheet` |
| **Feedback** |
| 103 | Toast | `CMP-FBK-Toast` |
| 104 | Alert / Banner | `CMP-FBK-Alert` |
| 105 | Inline Message | `CMP-FBK-InlineMessage` |
| 106 | Tooltip | `CMP-FBK-Tooltip` |
| 107 | Progress Bar | `CMP-FBK-Progress` |
| 108 | Spinner | `CMP-FBK-Spinner` |
| 109 | Skeleton | `CMP-FBK-Skeleton` |
| 110 | Empty State | `CMP-FBK-EmptyState` |
| 111 | Error State | `CMP-FBK-ErrorState` |
| 112 | Success State | `CMP-FBK-SuccessState` |
| **Overlays** |
| 113 | Modal | `CMP-OVL-Modal` |
| 114 | Drawer | `CMP-OVL-Drawer` |
| 115 | Bottom Sheet | `CMP-OVL-BottomSheet` |
| 116 | Popover | `CMP-OVL-Popover` |
| 117 | Cookie Consent | `CMP-OVL-CookieConsent` |
| 118 | Newsletter Popup | `CMP-OVL-NewsletterPopup` |
| **Indicators** |
| 119 | Tag | `CMP-IND-Tag` |
| 120 | Label | `CMP-IND-Label` |
| 121 | Counter Badge | `CMP-IND-Counter` |
| 122 | Avatar | `CMP-IND-Avatar` |
| 123 | Trust Badge | `CMP-IND-TrustBadge` |
| 124 | Payment Marks | `CMP-IND-PaymentMarks` |
| 125 | Countdown Timer | `CMP-IND-Countdown` |
| **Account & Content** |
| 126 | Account Sidebar | `CMP-ACC-Sidebar` |
| 127 | Profile Card | `CMP-ACC-ProfileCard` |
| 128 | Points Card | `CMP-ACC-PointsCard` |
| 129 | Notification Item | `CMP-ACC-NotificationItem` |
| 130 | Article Card | `CMP-CNT-ArticleCard` |
| 131 | Table of Contents | `CMP-CNT-Toc` |
| 132 | FAQ Item | `CMP-CNT-FaqItem` |
| 133 | Table | `CMP-CNT-Table` |
| 134 | Instagram Tile | `CMP-CNT-InstagramTile` |
| 135 | Newsletter Form | `CMP-CNT-NewsletterForm` |
| **AI** |
| 136 | AI Assistant Launcher | `CMP-AI-Launcher` |
| 137 | AI Chat Panel | `CMP-AI-ChatPanel` |
| 138 | AI Message Bubble | `CMP-AI-Message` |
| 139 | AI Product Suggestion | `CMP-AI-Suggestion` |
| 140 | AI Disclosure Chip | `CMP-AI-Disclosure` |

---

## 1. Button — `CMP-ACT-Button`

### Variant Properties

| Property | Values |
|----------|--------|
| `Variant` | Primary, Secondary, Outline, Ghost, Buy Now, Danger, Link |
| `Size` | SM, MD, LG, XL |
| `State` | Default, Hover, Active, Focus, Disabled, Loading, Success |
| `Icon` | None, Leading, Trailing, Only |
| `Width` | Hug, Fill |

### Sizes

| Size | Height | Padding X | Font | Icon | Radius | Min width |
|------|--------|-----------|------|------|--------|-----------|
| SM | 36 | 14 | `button-sm` | 16 | 8 | 80 |
| MD | 44 | 20 | `button-md` | 20 | 8 | 104 |
| LG | 52 | 24 | `button-lg` | 20 | 8 | 140 |
| XL | 56 | 28 | `button-lg` | 24 | 8 | 180 |

**XL is reserved for Add to Cart, Buy Now and Place Order.** On mobile these are always full-width at 56 px.

### Variant Styling (Light)

| Variant | BG | Text | Border | Hover | Active | Disabled |
|---------|-----|------|--------|-------|--------|----------|
| Primary | `indigo-600` | white | none | `indigo-700` | `indigo-800` | `indigo-200`, white text |
| Secondary | `terracotta-500` | white | none | `terracotta-600` | `terracotta-700` | `terracotta-200` |
| Buy Now | `terracotta-600` | white | none | `terracotta-700` | `terracotta-800` | `terracotta-200` |
| Outline | transparent | `text-primary` | 1.5px `border-strong` | `bg-subtle`, border brand | `paper-200` | text-disabled |
| Ghost | transparent | `text-secondary` | none | `bg-subtle` | `paper-200` | text-disabled |
| Danger | `danger-600` | white | none | `danger-700` | `danger-800` | `danger-100` |
| Link | transparent | `text-link` | none | underline | `indigo-800` | text-disabled |

### States

| State | Spec |
|-------|------|
| Hover | Background per table, 150 ms |
| Active | Background per table + `scale(0.98)`, 80 ms |
| Focus | 2 px focus ring at 2 px offset |
| Disabled | Per table, `not-allowed`, **reason shown adjacent or in a tooltip** |
| Loading | 20 px spinner replaces the leading icon; label dims to 70%; width locked; pointer-events off; announces "Loading" |
| Success | Check icon replaces the leading icon for 1.2 s with `ease-craft` scale pop, then reverts |

### Rules

- One primary action per view region. On PDP, Add to Cart is Primary and Buy Now is the Buy Now variant — they are visually distinct but equally weighted.
- Button order (LTR): tertiary ← secondary ← **primary** (rightmost). On mobile, the primary is the top full-width button in a stacked pair.
- Loading state is mandatory for any action exceeding 400 ms.
- Never disable Add to Cart silently — show the blocking reason.

---

## 2. Icon Button — `CMP-ACT-IconButton`

| Property | Values |
|----------|--------|
| `Variant` | Ghost, Outline, Filled, On-Image |
| `Size` | SM 32, MD 40, LG 44, XL 48 |
| `Shape` | Circle, Square |
| `State` | Default, Hover, Active, Focus, Disabled, Loading, Active-Selected |

**On-Image variant:** white icon on `rgba(26,24,22,0.45)` circular backdrop with backdrop blur 8 px — used for gallery controls, carousel arrows and card overlays. Always ≥40 px, with a 3:1 contrast check against the busiest region of the underlying image.

---

## 3. Link — `CMP-ACT-Link`

| Property | Values |
|----------|--------|
| `Variant` | Body (underlined), Nav (underline on hover), Muted, Inverse, Standalone (with trailing chevron) |
| `Size` | SM, MD, LG |
| `State` | Default, Hover, Focus, Visited, Disabled |

Standalone links ("View all", "Shop the collection") carry a trailing `chevron-right` that translates 3 px on hover.

---

## 4. Quantity Stepper — `CMP-ACT-QtyStepper`

```
┌──────┬────────┬──────┐
│  −   │   2    │  +   │
└──────┴────────┴──────┘
```

| Property | Values |
|----------|--------|
| `Size` | SM (32), MD (40), LG (48) |
| `State` | Default, Focus, Disabled, Min Reached, Max Reached, Loading |
| `Style` | Bordered, Filled, Inline-text |

- Radius-full; the value area is a real numeric input (type-able), centred, tabular figures.
- `−` disabled at min with tooltip "Minimum 1"; at quantity 1 it becomes a trash icon in cart contexts (with confirmation).
- `+` disabled at max with tooltip "Only {n} available" or "Maximum {n} per order".
- Changes debounce 500 ms before committing; the line total shows a subtle in-place loading tint during commit.
- Keyboard: `↑`/`↓` adjust, direct typing allowed, invalid input reverts on blur.

---

## 5. Wishlist Toggle — `CMP-ACT-WishlistToggle`

| Property | Values |
|----------|--------|
| `State` | Off, On, Hover-Off, Hover-On, Focus, Loading, Disabled |
| `Style` | On-Card (on-image circular), Inline (icon + label), Icon-only |
| `Size` | SM, MD, LG |

Off = outline heart in `text-secondary`; On = filled `danger-500` heart. Toggle animates per §8.3 of the design system. Accessible name toggles between "Save {product} to wishlist" and "Remove {product} from wishlist". For signed-out shoppers it still works (session wishlist) and shows a one-time toast: "Saved. Sign in to keep your wishlist across devices."

---

## 6. Share Menu — `CMP-ACT-ShareMenu`

Trigger icon button → popover (desktop) / bottom sheet (mobile) with: Copy Link (with success confirmation), WhatsApp, Facebook, X, Pinterest, Email, and native share on supported devices. Includes an optional preview card showing what will be shared.

---

## 7. Floating Action Button — `CMP-ACT-FAB`

Mobile only. 56 px circular, `elevation-4`, bottom-right at 16 px inset above the bottom tab bar. Uses: back-to-top (appears after 2 viewports, `chevron-up`), AI assistant launcher, filter shortcut on long PLPs.

---

## 8. Announcement Bar — `CMP-NAV-AnnouncementBar`

| Property | Values |
|----------|--------|
| `Type` | Single message, Rotating (max 3), With CTA, Countdown |
| `Tone` | Craft (terracotta-50), Brand (indigo-600 inverse), Success, Campaign |
| `Dismissible` | True, False |

Height 40 (desktop) / 36 (mobile). Centred text, `body-sm`. Rotating messages cross-fade every 5 s with a pause on hover/focus and a visible pause control if more than one message. Dismissal persists 7 days.

---

## 9–10. Header & Nav Bar — `CMP-NAV-Header`, `CMP-NAV-NavBar`

| Property | Values |
|----------|--------|
| `Breakpoint` | Desktop, Tablet, Mobile |
| `State` | Default, Scrolled-Compact, Search-Expanded, Menu-Open |
| `Auth` | Signed Out, Signed In |
| `Announcement` | Visible, Hidden |
| `Theme` | Light, Dark |

Full specification in `01-CX-Foundations §5`. Cart and wishlist badges are `CMP-IND-Counter` instances that animate on change.

---

## 11. Mega Menu — `CMP-NAV-MegaMenu`

| Property | Values |
|----------|--------|
| `Panel` | Shop, Festive, Gifting, Artisans, Help |
| `Columns` | 3, 4, 5 |
| `Feature Tile` | On, Off |
| `State` | Closed, Opening, Open |

Panel width = container width, max height 560, `elevation-3`, radius-lg on the bottom corners only. Column heading uses `overline`; items use `body-md` with 8 px vertical padding and a hover background. The feature tile is a 280×320 image card with a heading, sub-line and CTA. Full keyboard traversal: `↓` enters, arrows move within and between columns, `Esc` closes and returns focus to the trigger.

---

## 12. Mobile Nav Drawer — `CMP-NAV-MobileDrawer`

Left drawer, 88vw max 360, full height. Contents in order: close + logo, sign-in CTA or account row with avatar and points, search field, category accordion (3 levels), quick links (New, Sale, Gifting, Artisans, Stories), account links, help links, currency/language, theme toggle, social row. Accordions animate at 250 ms. Focus trapped; swipe-left to dismiss.

---

## 13. Bottom Tab Bar — `CMP-NAV-BottomTabs`

Mobile only, height 60 + safe-area, `elevation-sticky-up`, `bg-surface`, top border. Five items: Home, Shop, Search, Wishlist, Account. Each: 24 px icon + 11 px label; active state uses brand colour with a filled icon variant and a 3 px top indicator. Wishlist and Account carry counter badges. Hides during checkout to reduce distraction.

---

## 14. Breadcrumb — `CMP-NAV-Breadcrumb`

```
Home / Home Décor / Vases / Blue Pottery Vase
```

| Property | Values |
|----------|--------|
| `Length` | 2, 3, 4, 5+ (collapsed) |
| `Breakpoint` | Desktop, Mobile |

`body-sm`, separator `chevron-right` 14 px in `text-tertiary`, 8 px gaps. Last item is `text-primary`, non-clickable. Over 4 levels the middle collapses to `…` with a popover. Mobile shows only "‹ {parent}". Emits BreadcrumbList structured data.

---

## 15. Footer — `CMP-NAV-Footer`

| Property | Values |
|----------|--------|
| `Breakpoint` | Desktop, Tablet, Mobile |
| `Newsletter` | Visible, Hidden |
| `Variant` | Full, Minimal (checkout) |

Minimal variant (used on checkout and payment) shows only: logo, secure-payment marks, help contact, and policy links — no navigation, to protect conversion.

---

## 16. Tabs — `CMP-NAV-Tabs`

| Property | Values |
|----------|--------|
| `Type` | Underline, Pill, Segmented |
| `Size` | SM 40, MD 48 |
| `State` | Default, Hover, Active, Focus, Disabled |
| `Count` | None, Number |
| `Overflow` | Fit, Scroll |

Used for PDP information tabs (Description / Specifications / Reviews / Shipping & Returns), account sections and order filters. Underline indicator slides 250 ms. Deep-linkable via URL hash. Below 640 px, tabs scroll horizontally with edge fades.

---

## 17. Pagination — `CMP-NAV-Pagination`

| Property | Values |
|----------|--------|
| `Type` | Numbered, Load More, Infinite + fallback |
| `State` | Default, First, Last, Single, Loading |
| `Size` | SM, MD |

Storefront default is **Load More** with a real paginated URL fallback for SEO and for the back button. The button shows "Load More (24 of 482)" and a progress line. After 3 loads, a numbered pager also appears so shoppers can jump. Numbered buttons are 40×40, radius-md, current page filled brand.

---

## 18. Stepper — `CMP-NAV-Stepper`

| Property | Values |
|----------|--------|
| `Orientation` | Horizontal, Compact |
| `Steps` | 2, 3, 4 |
| `State` | Upcoming, Current, Complete, Error |

Used in checkout (Address → Delivery → Payment) and returns. Node 28 px; complete = `success-600` fill + white check; current = brand fill + 4 px halo; upcoming = `paper-200` border. Completed steps are clickable. Mobile shows "Step 2 of 3 — Delivery" with a 4 px progress bar.

---

## 19. Accordion — `CMP-NAV-Accordion`

| Property | Values |
|----------|--------|
| `Type` | Single-open, Multi-open |
| `Style` | Bordered, Flush, Card |
| `State` | Collapsed, Expanded, Disabled |
| `Size` | SM 48, MD 56, LG 64 |

Used for PDP detail sections, FAQ, footer on mobile, filter groups, and order line expansion. Header shows title (`heading-xs`), optional meta, and a chevron rotating 180° over 250 ms. Body padding 20 with a top divider. Content is present in the DOM for SEO even when collapsed.

---

## 20. Category Menu — `CMP-NAV-CategoryMenu`

Left-rail category tree used on PLP (desktop) and inside the mobile drawer. Row 40 px, indent 16 px per level, active item bold with a 3 px left brand bar, product counts in `text-tertiary`. Expand/collapse per branch; the active branch auto-expands.

---

## 21. Chip Nav — `CMP-NAV-ChipNav`

Horizontally scrolling chip row (mobile category quick links, PLP sub-category shortcuts, blog tags). Chip height 36, radius-full, `bg-subtle` default, brand-filled when active. Edge fade masks indicate scrollability; scroll-snap per chip.

---

## 22. Search Bar — `CMP-SRC-SearchBar`

| Property | Values |
|----------|--------|
| `Size` | MD 44, LG 52 |
| `State` | Default, Hover, Focus, Filled, Loading, Disabled |
| `Placement` | Header, Overlay, Inline (PLP/help) |
| `Scope` | None, Category-scoped |

Leading `search` icon; trailing clear `x` when filled; optional voice-input mic and image-search camera icons (AI module). Placeholder rotates through real examples every 4 s while empty and unfocused ("Search blue pottery", "Search brass diyas", "Search kantha cushions") — pauses on focus.

---

## 23. Search Suggestions Panel — `CMP-SRC-Suggestions`

```
┌──────────────────────────────────────────────────────┐
│ RECENT                                    Clear all   │
│ ⟲ blue pottery vase                              ×    │
│ ⟲ brass diya set                                 ×    │
├──────────────────────────────────────────────────────┤
│ TRENDING                                              │
│ 🔥 diwali gifts   🔥 kantha cushion   🔥 marble inlay │
├──────────────────────────────────────────────────────┤
│ SUGGESTIONS                                           │
│ ⌕ blue pottery **vase**                               │
│ ⌕ blue pottery **bowl**                    in Décor   │
├──────────────────────────────────────────────────────┤
│ PRODUCTS                                              │
│ [img] Blue Pottery Vase — Jaipur          ₹1,250      │
│ [img] Blue Pottery Bowl Set               ₹2,100      │
├──────────────────────────────────────────────────────┤
│ CATEGORIES        ARTISANS                            │
│ Vases (84)        Ram Prasad Sharma                   │
├──────────────────────────────────────────────────────┤
│ See all 42 results for "blue pottery"            ↵    │
└──────────────────────────────────────────────────────┘
```

Width matches the search field, max height 560, `elevation-3`. Query match is bolded in suggestions. Product rows 64 px with a 48 px thumbnail. Keyboard: `↓↑` traverse all rows, `Enter` opens, `Esc` closes. Empty query shows Recent + Trending only. Debounce 200 ms; skeleton rows while loading.

---

## 24. Search Overlay — `CMP-SRC-Overlay`

Mobile full-screen: back chevron + field + cancel, then the suggestions content. Opens with a 250 ms fade + 8 px upward translate; the keyboard is raised automatically.

---

## 25. Product Card — `CMP-PRD-Card`

### Anatomy

```
┌──────────────────────────┐
│ [SALE]              [♡]  │  badges TL, wishlist TR
│                          │
│      product image       │  1:1, radius-lg
│                          │
│  ⟨ ● ● ● ⟩  (dots on hover│  secondary image on hover
│  [  Quick View  ]        │  overlay on hover (desktop)
├──────────────────────────┤
│ HOME DÉCOR               │  overline, optional
│ Blue Pottery Vase —      │  2-line clamp
│ Jaipur                   │
│ 🤲 Ram Prasad Sharma     │  artisan chip, optional
│ ★ 4.6 (128)              │  rating
│ ₹1,250  ₹1,600  22% OFF  │  price block
│ Only 3 left              │  stock, conditional
│ [    Add to Cart    ]    │  appears on hover (desktop)
└──────────────────────────┘
```

### Variant Properties

| Property | Values |
|----------|--------|
| `Size` | XS (rail compact 160), SM (200), MD (280), LG (320) |
| `State` | Default, Hover, Focus, Loading, Out of Stock, Unavailable |
| `Badge` | None, Sale, New, Bestseller, Handmade, Limited, Sponsored |
| `Rating` | Show, Hide |
| `Artisan` | Show, Hide |
| `Stock` | None, Low, Out |
| `Action` | None, Add to Cart, Quick View, Both |
| `Wishlist` | Off, On |
| `Image` | Single, Dual (hover swap) |
| `Layout` | Portrait (1:1), Tall (4:5) |

### Specification

| Element | Spec |
|---------|------|
| Image container | 1:1, radius-lg, `bg-image-placeholder`, overflow hidden |
| Image hover | Scale 1.04 over 400 ms; if a secondary image exists it cross-fades at 250 ms |
| Badges | Top-left stack, max 2, 8 px inset, `label-sm` |
| Wishlist | Top-right, 8 px inset, on-image icon button 36 px |
| Quick View | Centred overlay button, appears on hover, hidden on touch devices |
| Category overline | Optional, `overline`, `text-tertiary` |
| Title | `body-md` 500, `text-primary`, 2-line clamp, 44 px reserved height so cards align |
| Artisan chip | 20 px avatar + name, `body-xs`, `text-craft` |
| Rating | `CMP-PRD-Rating` SM |
| Price | `CMP-PRD-Price` card size |
| Stock line | `body-xs`, warning tone when low |
| Add to Cart | Full-width SM button, appears on hover (desktop) / always visible (mobile, if configured) |
| Card padding | 0 on the image, 16 on the text block (12 on mobile) |
| Card background | `bg-surface`; border 1 px `border-subtle` only in dark theme |
| Whole card | Clickable; nested controls stop propagation |
| Out of stock | Image at 60% saturation, "Out of Stock" pill centred on the image, Add to Cart replaced by "Notify Me" |

### Rules

- Title height is reserved so a 1-line and a 2-line title produce equal card heights.
- Maximum 2 badges; priority Sale > Bestseller > New > Handmade > Limited.
- Add to Cart on a card adds the default variant; if the product has required options it opens Quick View instead, with a brief inline hint "Choose a size".
- Never show a countdown on a card unless a genuine flash sale is running.

---

## 26. Product Card — List View — `CMP-PRD-CardList`

Horizontal layout: 200×200 image, then a content column with title, artisan, rating, short description (2-line clamp), key specs (material, dimensions), price block, stock, and an action row (Add to Cart + Wishlist + Compare). Height 220 desktop / auto mobile. Used in PLP list view and in comparison contexts.

---

## 27. Product Card — Compact — `CMP-PRD-CardCompact`

64 px thumbnail + title (1 line) + price, 72 px row height. Used in search suggestions, mini cart recommendations, recently viewed strips and AI suggestions.

---

## 28. Price Block — `CMP-PRD-Price`

```
₹1,250   ₹̶1̶,̶6̶0̶0̶   22% OFF
```

| Property | Values |
|----------|--------|
| `Size` | SM (card), MD (list), LG (PDP), XL (checkout total) |
| `Discount` | None, Percent chip, Amount saved, Both |
| `Layout` | Inline, Stacked |
| `State` | Default, Member price, Price drop, Range (from ₹x) |
| `Tax` | Hidden, Inclusive note |

- Selling price: `price-*` weight 600/700, `--color-price`; when discounted it uses `--color-price-sale`.
- MRP: struck, one step smaller, `--color-price-strike`, always after the selling price.
- Discount chip: `label-sm` on `danger-50` with `danger-600` text (light) — never the sole indicator, the struck price is always present.
- "You save ₹350" line optional, `body-xs`, `success-700`.
- Price range for variable products: "From ₹1,050" until a variant is chosen.
- Member price variant shows a brass-toned chip "Member price" with the standard price struck.
- Tax note on PDP: "Inclusive of all taxes" in `body-xs` `text-tertiary`.
- Accessible name reads the full amount in words plus the saving.

---

## 29. Badge — `CMP-PRD-Badge`

| Property | Values |
|----------|--------|
| `Type` | Sale, New, Bestseller, Handmade, Limited, Eco, GI Tagged, Sponsored, Back in Stock, Pre-order |
| `Size` | SM (20), MD (24) |
| `Style` | Solid, Soft, Outline |
| `Placement` | On-image, Inline |

`label-sm` uppercase, radius-sm, 4×8 padding, optional 12 px leading icon. Sale shows the percentage ("22% OFF"). Sponsored is mandatory on any paid placement and uses neutral styling so it cannot be mistaken for a merchandising badge.

---

## 30. Rating Display — `CMP-PRD-Rating`

| Property | Values |
|----------|--------|
| `Size` | XS 12, SM 14, MD 18, LG 24 |
| `Precision` | Whole, Half, Decimal |
| `Meta` | None, Count, Value + Count, Value + Count + Link |
| `Style` | Stars, Compact (value + single star) |

Filled `--color-rating-fill`, empty `--color-rating-empty`. Compact style ("★ 4.6 (128)") is used on cards to save space. Accessible name: "Rated 4.6 out of 5 from 128 reviews". Clicking scrolls to the reviews section on PDP.

---

## 31. Colour Swatch — `CMP-PRD-Swatch`

| Property | Values |
|----------|--------|
| `Type` | Colour, Image, Text |
| `Size` | SM 28, MD 36, LG 44 |
| `State` | Default, Hover, Selected, Disabled, Out of Stock, Focus |

Circular, 2 px transparent ring that becomes brand-coloured with a 2 px offset when selected. Out of stock shows a diagonal strike and remains selectable to view details. **The colour name is always rendered as text beside or below the group** ("Colour: Indigo Blue") — swatches never carry meaning by colour alone.

---

## 32. Option Selector — `CMP-PRD-OptionSelector`

| Property | Values |
|----------|--------|
| `Type` | Swatch, Pill, Dropdown, Card |
| `State` | Default, Selected, Disabled, Out of Stock, Error |
| `Label` | With label, Without |

Pill: 44 px height, radius-md, border 1.5 px; selected = brand border + `bg-selected`. Card type (used for sets, gift wrap tiers, delivery speed) includes a title, description and price delta. Group label shows the selected value inline ("Size: Medium"). Unselected required options block Add to Cart with the message "Choose a size" and a shake + scroll-to on attempt.

---

## 33. Stock Indicator — `CMP-PRD-Stock`

| Property | Values |
|----------|--------|
| `State` | In Stock, Low Stock, Out of Stock, Backorder, Made to Order, Pre-order |
| `Style` | Text, Pill, With icon |

In Stock: `success-600` + check. Low: `warning-600` + "Only {n} left" (only when the true figure is ≤5). Out: `text-secondary` + "Out of stock" + Notify Me. Made to Order: `info-600` + "Made to order · ships in {n} days".

---

## 34. Variation Notice — `CMP-PRD-VariationNotice`

```
┌────────────────────────────────────────────────────┐
│ 🤲  Every piece is unique                          │
│     Handmade items vary slightly in colour, finish │
│     and size. Your piece will be one of a kind.    │
│     [What to expect →]                             │
└────────────────────────────────────────────────────┘
```

| Property | Values |
|----------|--------|
| `Size` | Compact (one line, cart), Standard (PDP), Expanded (with example imagery) |
| `Tone` | Craft (default) |

Mandatory on PDP for handmade products, on cart line items in compact form, and on the order confirmation. `bg-craft` background, `text-craft` heading, `body-sm` body. The "What to expect" link opens a modal with side-by-side example photographs of acceptable variation.

---

## 35. Delivery Estimate — `CMP-PRD-DeliveryEstimate`

| Property | Values |
|----------|--------|
| `State` | Prompt (no PIN), Checking, Serviceable, Not Serviceable, Error |
| `Placement` | PDP, Cart, Checkout, Card |
| `Options` | Single, Multiple (standard/express) |

Prompt state shows a PIN input inline. Serviceable state shows: "Get it by **Wed, 12 Aug**" with a truck icon, the courier name, COD availability, and a "Change" link. The entered PIN is remembered for 30 days and reused everywhere, including on cards in search results. Not serviceable shows the reason and a "Notify me when we deliver here" action.

---

## 36. Specification List — `CMP-PRD-SpecList`

Two-column key/value list. Label column `label-md` `text-secondary` fixed 160 px, value `body-md` `text-primary`. Rows 44 px with `border-subtle` dividers. Groups: Materials & Craft, Dimensions & Weight, Care, Origin, Product Codes. Values that need explanation carry an info icon opening a popover. Mobile stacks label above value.

---

## 37. Dimension Diagram — `CMP-PRD-Dimensions`

Illustrated product silhouette annotated with L, W, H and dimension lines, plus:
- Unit toggle (cm ↔ inch) remembered per shopper.
- A scale reference chip: "About the height of a 1-litre bottle".
- Optional "Compare to a common object" expander.

This component measurably reduces size-related returns and is mandatory for décor, vessels and furniture.

---

## 38–39. Artisan Chip & Artisan Story Card — `CMP-PRD-ArtisanChip`, `CMP-PRD-ArtisanCard`

**Chip:** 20–24 px circular photo + name + optional cluster, `body-xs`, `text-craft`; links to the artisan profile.

**Story card:**
```
┌───────────────────────────────────────────────────┐
│ ┌────────┐  MEET THE MAKER                        │
│ │ artisan│  Ram Prasad Sharma                     │
│ │  photo │  Blue Pottery · Jaipur, Rajasthan      │
│ │ 96×96  │  Third-generation potter working with  │
│ └────────┘  quartz clay and natural cobalt oxide. │
│             ★ 4.8 · 212 products · 18 years       │
│             [Read his story →] [Shop his work →]  │
└───────────────────────────────────────────────────┘
```
Variants: `Size` (Compact, Standard, Feature), `Media` (Photo, Photo + Video). `bg-craft` background, radius-lg.

---

## 40. Product Rail — `CMP-PRD-Rail`

| Property | Values |
|----------|--------|
| `Cards` | XS, SM, MD |
| `Controls` | Arrows, Dots, Both, None |
| `Heading` | With heading + View all, Heading only, None |
| `State` | Default, Loading, Empty |

Horizontal scroll with CSS scroll-snap, 20 px gap. Desktop shows 5 cards with 40 px circular arrow buttons vertically centred, appearing on hover and always visible on touch. Mobile shows 2.2 cards to signal scrollability. A 4 px scroll-progress indicator sits below on mobile. Arrows disable at the ends. Keyboard: `Tab` moves card to card and auto-scrolls the container.

---

## 41. Product Grid — `CMP-PRD-Grid`

| Property | Values |
|----------|--------|
| `Columns` | 2, 3, 4, 5 |
| `Density` | Comfortable, Compact |
| `State` | Default, Loading, Empty, Filtered-Empty |
| `Injections` | None, Banner, Editorial, AI recommendation |

Gutter 24 (desktop) / 12 (mobile), row gap 40 / 24. Supports injected full-width promotional tiles after every 8th or 12th product without breaking grid alignment. Virtualises beyond 60 cards.

---

## 42. Compare Bar — `CMP-PRD-CompareBar`

Sticky bottom bar appearing when ≥1 product is selected for comparison. Shows up to 4 thumbnails with remove buttons, empty slots as dashed placeholders, a count, "Compare Now" primary and "Clear All" ghost. Slides up 250 ms. On mobile it becomes a compact 64 px bar with stacked thumbnails.

---

## 43. Image — `CMP-MED-Image`

| Property | Values |
|----------|--------|
| `Ratio` | 1:1, 4:5, 4:3, 3:2, 16:9, 3:1, Free |
| `State` | Loading, Loaded, Error, Placeholder |
| `Fit` | Cover, Contain |
| `Radius` | None, SM, MD, LG, XL |
| `Overlay` | None, Scrim, Scrim + Content |

Every image instance must have its ratio set — this is how CLS stays at zero.

---

## 44. Product Gallery — `CMP-MED-Gallery`

### Desktop layout

```
┌────────┬────────────────────────────────────┐
│ [thumb]│                                    │
│ [thumb]│                                    │
│ [thumb]│        main image 1:1              │
│ [thumb]│        with zoom lens              │
│ [ 360 ]│                                    │
│ [video]│                                    │
│  +3    │                       [⤢] [♡] [⇪] │
└────────┴────────────────────────────────────┘
```

| Property | Values |
|----------|--------|
| `Layout` | Thumbs-left, Thumbs-below, Stacked-scroll, Carousel (mobile) |
| `Media` | Images only, With 360, With video, Full |
| `Zoom` | Lens, Click-to-lightbox, None |
| `State` | Default, Loading, Error, Single-image |

- Thumbnails 72×72, radius-md, 8 px gap, active has a 2 px brand ring; overflow shows "+N" opening the lightbox.
- Main image 1:1; hover shows the zoom lens with a 2× pane to the right (desktop ≥1280) or in-place 2.5× zoom (1024–1279).
- Overlay controls bottom-right: expand (lightbox), wishlist, share.
- 360° and video entries appear as thumbnails with an overlay icon.
- **Mobile:** full-width swipeable carousel with dots and a "1/8" counter chip; pinch-to-zoom; tap opens the lightbox.
- Keyboard: `←/→` change image, `Enter` opens the lightbox, `Esc` closes.
- All images preloaded at thumbnail resolution; full resolution loads on demand.

---

## 45. Zoom Lens — `CMP-MED-Zoom`

Lens 160×160 with a 1 px brand border and a 40% white overlay; the zoom pane is 480×480 positioned to the right with `elevation-3`. Follows the cursor with no easing delay. Disabled when the source image is under 1500 px, in which case the expand control opens the lightbox instead.

---

## 46. Lightbox — `CMP-MED-Lightbox`

Full-viewport, scrim `rgba(15,14,13,0.94)`. Image centred at max 90vw/88vh. Thumbnail strip at the bottom (64 px). Counter top-left ("3 / 8"). Controls top-right: zoom in/out, rotate, download (if permitted), close. Keyboard `←/→`, `+/−`, `0` reset, `Esc`. Touch: pinch-zoom, drag-pan, swipe to change, swipe-down to dismiss. Focus trapped; returns focus to the invoking thumbnail.

---

## 47. 360° Viewer — `CMP-MED-Spin360`

Drag-to-rotate across 24 or 36 frames with momentum and snap. Auto-rotates once on first open (unless reduced motion), then stops. Controls: play/pause, reset, fullscreen, and a scrub track with a frame indicator. Loading shows a progress ring with "Loading 360° view… 12/24". Keyboard: `←/→` step frames, `Shift+←/→` jump 5.

---

## 48. Video Player — `CMP-MED-VideoPlayer`

| Property | Values |
|----------|--------|
| `State` | Poster, Playing, Paused, Buffering, Ended, Error |
| `Controls` | Full, Minimal, None (looping ambient) |
| `Ratio` | 1:1, 16:9, 9:16 |

Custom control bar: play/pause, scrub with buffered range, time, volume, captions toggle, quality, fullscreen. Captions required. Poster frame always set. No autoplay with sound, ever. Ambient loops are muted, have a visible pause control, and are disabled under reduced motion.

---

## 49. Carousel — `CMP-MED-Carousel`

| Property | Values |
|----------|--------|
| `Type` | Hero, Banner, Content, Testimonial |
| `Slides` | 2–6 |
| `Controls` | Arrows, Dots, Both, Thumbnails |
| `Autoplay` | On, Off |

Autoplay interval ≥6 s, pauses on hover, focus and tab-blur, and **always** exposes a visible pause control. Slide count and current index announced. Swipe on touch, `←/→` on keyboard. Max 6 slides — beyond that, use a grid. Under reduced motion, autoplay is disabled and transitions become instant.

---

## 50. Hero Banner — `CMP-MED-Hero`

| Property | Values |
|----------|--------|
| `Layout` | Full-bleed, Contained, Split (image/content) |
| `Height` | Tall (640), Standard (520), Short (400), Auto (mobile 4:5) |
| `Content position` | Left, Centre, Right, Bottom-left |
| `Media` | Image, Video, Image + Video |
| `Overlay` | None, Scrim, Colour wash, Gradient |

Content block: overline (optional), `display-2xl` headline, `body-xl` sub-line, one primary and one secondary CTA. Text max width 560. Contrast against the underlying image region must reach 4.5:1 — the scrim is adjusted per creative, and each banner's contrast is verified at design time. Mobile uses a dedicated 4:5 crop with the content below or over the lower third.

---

## 51. Category Tile — `CMP-MED-CategoryTile`

| Property | Values |
|----------|--------|
| `Size` | SM, MD, LG, Feature |
| `Layout` | Image + label below, Image with overlay label, Circular |
| `State` | Default, Hover, Focus |

Overlay variant: 4:3 image, bottom scrim, category name in `heading-md` inverse, optional product count, hover scales the image 1.05 and lifts the label 2 px. Circular variant (mobile category strip): 72 px circle + 12 px label below.

---

## 52. Collection Banner — `CMP-MED-CollectionBanner`

Full-width promotional band, 8:3 desktop / 1:1 mobile, with an overlay content block (eyebrow, heading, sub-line, CTA) and an optional countdown. Used inside PLP grids and between home bands. Always includes real HTML text so it is translatable and readable by assistive technology.

---

## 53. Cart Line Item — `CMP-CRT-LineItem`

```
┌──────────────────────────────────────────────────────────┐
│ ┌──────┐ Blue Pottery Vase — Jaipur              ₹1,250  │
│ │ img  │ Size: Medium · Colour: Indigo          ₹̶1̶,̶6̶0̶0̶  │
│ │ 96   │ 🤲 Ram Prasad Sharma                            │
│ └──────┘ 🤲 Handmade — each piece varies slightly        │
│          ⚠ Only 2 left                                   │
│          [− 1 +]   Save for later · Remove      ₹1,250   │
└──────────────────────────────────────────────────────────┘
```

| Property | Values |
|----------|--------|
| `Size` | Standard (cart), Compact (mini cart, checkout summary) |
| `State` | Default, Updating, Removing, Out of Stock, Price Changed, Unavailable |
| `Editable` | True (cart), False (checkout, order) |
| `Gift` | None, Wrapped |

- Thumbnail 96 (standard) / 64 (compact), radius-md, links to PDP.
- Variant attributes on one line, separated by `·`.
- Variation notice in compact form for handmade items.
- Stock warning when low; when a line goes out of stock the row tints `danger-50`, shows "No longer available", and offers "Save for later" or "Remove", with checkout blocked until resolved.
- Price-changed state shows "Price updated from ₹1,400" with an info tone.
- Remove triggers an 8-second Undo toast; the row collapses over 250 ms.

---

## 54. Mini Cart Drawer — `CMP-CRT-MiniCart`

Right drawer 420 (desktop) / bottom sheet 90vh (mobile).

```
┌─ Your Cart (3) ──────────────────── [×] ┐
│ ⚡ Add ₹249 more for free shipping       │
│ ████████████░░░░  ₹750 of ₹999          │
├──────────────────────────────────────────┤
│ [compact line items, scrollable]         │
├──────────────────────────────────────────┤
│ You may also like  [mini rail]           │
├──────────────────────────────────────────┤
│ Subtotal                        ₹3,930   │
│ Delivery                    Calculated   │
│ ─────────────────────────────────────    │
│ [        Checkout · ₹3,930         ]     │
│ [        View Cart                 ]     │
│ 🔒 Secure checkout · 7-day returns       │
└──────────────────────────────────────────┘
```

Opens automatically after Add to Cart (desktop) and auto-closes after 6 s unless interacted with; on mobile a toast with a "View Cart" action is used instead to avoid interrupting browsing. The newly added item highlights `success-50` for 1.5 s.

---

## 55. Order Summary — `CMP-CRT-Summary`

| Property | Values |
|----------|--------|
| `Context` | Cart, Checkout, Confirmation, Order Detail |
| `State` | Default, Loading, With Coupon, With Points, With Gift, Error |
| `Collapsible` | True (mobile), False |

Rows: Subtotal ({n} items) · Discount (with coupon code and a remove action) · Reward points applied · Gift wrap · Delivery · Taxes (with an info popover explaining GST) · **Total** (`price-xl`) · "You saved ₹{n}" in `success-700`.

**Rule:** no cost may appear for the first time after the shopper has entered payment details. Delivery shows "Calculated at checkout" in the cart only until a PIN is known, at which point it resolves to a real figure.

Mobile: collapsed to a single "Total ₹3,930 · {n} items ⌄" row that expands; the total remains visible in the sticky bar at all times.

---

## 56–58. Coupon Components

**`CMP-CRT-CouponInput`** — field + Apply button; states Default / Checking / Applied / Invalid / Expired / Not Eligible; error text explains precisely why ("This coupon needs a minimum order of ₹1,500 — add ₹250 more"). Includes a "View available coupons" link.

**`CMP-CRT-AppliedCoupon`** — green-tinted row: ticket icon, code, description, saving amount, remove `×`. Announces the saving on apply.

**`CMP-CRT-CouponCard`** — used in the coupon list modal and the account coupons page: dashed-edge ticket shape, code (copyable), headline discount, conditions, validity with days remaining, and an Apply button. States: Available, Applied, Not Eligible (with the reason), Expired, Used.

---

## 59. Gift Options — `CMP-CRT-GiftOptions`

Expandable panel: "This is a gift" switch → reveals gift-wrap style cards (with images and prices), a gift-message textarea (250 char counter, with a live preview of the printed card), a "Hide prices on the packing slip" checkbox (checked by default when gifting), and an optional recipient name field. Per-item gifting is supported where the store enables it.

---

## 60. Free Shipping Progress — `CMP-CRT-ShippingProgress`

Progress bar with the remaining amount: "Add ₹249 more for free shipping". On reaching the threshold it animates to full, turns `success`, and reads "You've unlocked free shipping 🎉" with a single celebratory pulse. Appears in the mini cart, cart and (as a compact bar) at the top of checkout.

---

## 61. Saved for Later Item — `CMP-CRT-SavedItem`

Compact row: thumbnail, name, price with any price-drop indicator, stock status, and actions "Move to Cart" and "Remove". Grouped under a "Saved for later ({n})" heading below the cart.

---

## 62. Address Card — `CMP-CHK-AddressCard`

| Property | Values |
|----------|--------|
| `State` | Default, Selected, Hover, Focus, Editing, Invalid |
| `Type` | Home, Work, Other |
| `Badge` | None, Default, Non-serviceable |
| `Actions` | Edit, Delete, Set Default |

Radio-card pattern: radio + label chip + full name + full address + phone. Selected shows a 2 px brand border and `bg-selected`. A non-serviceable address is disabled with the explanation "We don't deliver to this PIN code yet" and a "Use another address" prompt.

---

## 63. Delivery Method Card — `CMP-CHK-DeliveryOption`

Radio card: method name, delivery-date range, price (or "FREE" in `success`), courier name, and an optional note ("Fragile items are packed with extra care"). Selected state as above. Options that are unavailable for the basket are disabled with a reason.

---

## 64. Payment Method Card — `CMP-CHK-PaymentOption`

| Property | Values |
|----------|--------|
| `Method` | UPI, Card, Net Banking, Wallet, COD, EMI, Gift Card, Reward Points |
| `State` | Default, Selected, Expanded, Disabled, Processing, Failed |
| `Badge` | None, Recommended, Offer, Fee |

Selected cards expand in place to reveal their input (UPI ID field or QR, card fields, bank list, wallet list). Offers appear as a chip: "10% off with HDFC cards". COD shows any fee explicitly and its eligibility rule. Disabled methods state why ("COD isn't available for orders above ₹15,000").

---

## 65. Saved Card Item — `CMP-CHK-SavedCard`

Network logo + `•••• 4821` + expiry + nickname + radio; CVV field appears inline when selected; "Delete card" action with confirmation. Shows a "Card expiring soon" warning within 60 days of expiry.

---

## 66. Reward Points Applicator — `CMP-CHK-PointsApplicator`

Shows the balance, the maximum redeemable for this order (with the rule stated: "Up to 20% of the order value"), a slider plus numeric input, the resulting discount, and the remaining balance after use. Toggling off restores the total instantly.

---

## 67. Order Confirmation Card — `CMP-CHK-Confirmation`

Large success check, "Thank you, {first name}!", order number (copyable), estimated delivery date in `heading-md`, the delivery address, payment summary, item list, and next actions (Track Order, View Order, Continue Shopping, Create Account for guests). Includes the variation notice for handmade items and the returns window.

---

## 68. Order Card — `CMP-ORD-Card`

```
┌──────────────────────────────────────────────────────────┐
│ #HC-2026-000482 · Placed 03 Aug 2026    [● Out for delivery]│
│ ┌────┐┌────┐┌────┐  3 items                       ₹4,250 │
│ │img ││img ││img │  Blue Pottery Vase + 2 more            │
│ └────┘└────┘└────┘                                        │
│ Arriving Wed, 12 Aug                                      │
│ [Track Order]  [View Details]  [Buy Again]           [⋮]  │
└──────────────────────────────────────────────────────────┘
```

Variants: `Status` (12 states), `Items` (1, 2, 3+), `Actions` (contextual by status), `State` (Default, Hover, Loading). Actions change with status — Track while in transit, Return/Review after delivery, Retry Payment on failure.

---

## 69. Order Timeline — `CMP-ORD-Timeline`

Vertical (mobile) or horizontal (desktop) progress through: Order Placed → Confirmed → Packed → Shipped → Out for Delivery → Delivered. Each node carries a timestamp when complete and a projected date when pending. Current node has a pulsing halo. Exception states (On Hold, Cancelled, Returned, Failed Delivery) replace the rail with a status banner explaining what happened and what happens next. Courier details and the AWB (copyable) sit beneath, with a "Track on courier site" external link.

---

## 70. Order Status Chip — `CMP-ORD-StatusChip`

12 states with icon + text: Placed, Confirmed, Packed, Shipped, Out for Delivery, Delivered, Cancelled, Return Requested, Return Picked Up, Returned, Refunded, Failed. Soft style by default, solid on the order detail header.

---

## 71. Tracking Map — `CMP-ORD-TrackingMap`

Optional live map with the courier position, route and destination, an ETA chip, and a text alternative listing the same tracking events. Falls back gracefully to the timeline alone when live data is unavailable.

---

## 72. Return Request Item — `CMP-ORD-ReturnItem`

Item row with a quantity selector (bounded by delivered quantity), a reason dropdown, a comment field, a photo uploader (required for damage), and a resolution selector (Refund / Exchange / Store Credit). Shows the refund estimate per item and any restocking rule in plain language.

---

## 73. Refund Status — `CMP-ORD-RefundStatus`

Stepped indicator: Requested → Approved → Item Picked Up → Received & Inspected → Refund Issued → Credited. Each step shows a date; the final step shows the method and expected credit timing ("5–7 business days to your UPI"). Amount breakdown expandable.

---

## 74. Review Card — `CMP-REV-Card`

```
┌──────────────────────────────────────────────────────────┐
│ ★★★★★  Beautiful craftsmanship        ✓ Verified purchase │
│ Meera N. · Bengaluru · 12 Jun 2026                        │
│ Size: Medium · Colour: Indigo                             │
│ "The colours are richer than the photos. You can see the  │
│  brush strokes where the artisan painted it…" Read more   │
│ [photo][photo]                                            │
│ Quality ★★★★★  Value ★★★★☆  As pictured ★★★★★             │
│ 👍 Helpful (24)   ⚑ Report                                │
│ ┌────────────────────────────────────────────────────┐    │
│ │ Reply from Karigar · 14 Jun                        │    │
│ │ Thank you, Meera! We'll pass this to Ram Prasad.   │    │
│ └────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────┘
```

Variants: `Media` (None, Photos, Video), `Reply` (With, Without), `Verified` (Yes, No), `Length` (Clamped, Expanded), `Sub-ratings` (Show, Hide). Photos open the review lightbox. Helpful voting is optimistic with a signed-out prompt on first use.

---

## 75. Rating Input — `CMP-REV-RatingInput`

Interactive stars, 32 px (44 px touch target each). Hover/keyboard preview fills up to the hovered star and shows the label ("Very good"). Arrow keys adjust; `0` clears. Labels: 1 Poor · 2 Fair · 3 Good · 4 Very good · 5 Excellent.

---

## 76. Rating Breakdown — `CMP-REV-Breakdown`

Average value in `display-lg`, stars, total count, then five horizontal bars (5★ → 1★) with counts and percentages. Bars are clickable filters. Sub-rating averages (Quality, Value, As pictured, Craftsmanship) listed beneath. Includes the authenticity note: "We only publish reviews from verified purchases."

---

## 77. Review Photo Strip — `CMP-REV-PhotoStrip`

Horizontally scrolling strip of customer photos with a "+N" tile opening the full customer-photo gallery. Sits directly above the review list on PDP — customer photos are among the highest-converting elements on a craft PDP and must be prominent.

---

## 78. AI Review Summary — `CMP-REV-AiSummary`

```
┌────────────────────────────────────────────────────────┐
│ ✨ What customers say            AI-generated summary   │
│ Customers love the colour depth and the visible hand-  │
│ painted detail. Several mention it is smaller than     │
│ expected — check the dimensions before ordering.       │
│ 👍 Loved: colour (42) · craftsmanship (38) · packaging │
│ 👎 Mentioned: size (12) · delivery time (6)            │
│ Based on 128 reviews · Updated 2 days ago              │
└────────────────────────────────────────────────────────┘
```

Always labelled as AI-generated. Themes link to filtered reviews. Never hides negative themes — balanced summarisation is a trust requirement, and the component must render at least one "mentioned" theme when any exists.

---

## 79. Write Review Form — `CMP-REV-Form`

Fields: overall rating (required), sub-ratings (optional), title (optional, ≤80), review body (required, 20–2000 with a counter), photo upload (up to 6, 5 MB each), video (optional, ≤60 s), "I recommend this product" toggle, display-name choice, and a guidelines link. Shows the incentive disclosure when points are offered.

---

## 80. Text Field — `CMP-INP-TextField`

```
Label *
┌──────────────────────────────────────────┐
│ [icon]  Placeholder / value      [action] │  h=48
└──────────────────────────────────────────┘
Helper text                            12/60
```

| Property | Values |
|----------|--------|
| `Size` | SM 40, MD 48, LG 56 |
| `State` | Default, Hover, Focus, Filled, Disabled, Readonly, Error, Success, Loading |
| `Leading` | None, Icon, Prefix |
| `Trailing` | None, Icon, Clear, Action, Counter, Validation |
| `Helper` | None, Text, Error, Success |

Storefront inputs are larger than admin inputs (48 default vs 40) because they are used less often, on touch, and under commercial pressure. Labels are always visible above the field. Validation is on blur for format, on submit for required, and live for uniqueness and strength. Error text replaces helper text and is programmatically linked.

---

## 81–96. Remaining Form Components

| Component | Key specification |
|-----------|-------------------|
| **Textarea** | Min 96 px (3 rows), auto-grow to 320 then scroll, counter mandatory with maxlength |
| **Select** | 48 px trigger, native on mobile, custom listbox on desktop; searchable above 8 options |
| **Combobox** | Remote search with 200 ms debounce, rich rows (thumbnail + primary + meta), recent selections |
| **Checkbox** | 20 px box, radius-xs, 44 px touch target, label clickable; marketing consent is never pre-ticked |
| **Radio** | 20 px, plus a Card variant used for addresses, delivery and payment |
| **Switch** | 44×24, used for instant-apply preferences only |
| **Segmented** | 44 px, 2–4 options, sliding indicator; used for view toggles, unit toggles, address type |
| **Range Slider** | Dual-handle price filter with numeric inputs, histogram of product distribution behind the track, ₹ formatting on handles |
| **Date Picker** | 40 px cells; used for delivery-date preference and return pickup slots; disabled dates explain why on hover |
| **Time Picker** | Slot-based (delivery windows), not free time entry |
| **OTP Input** | 6 boxes of 48×56, auto-advance, paste-fills all, auto-submit on completion, 30 s resend timer, error shakes and clears |
| **Phone Input** | Country selector (flag + code) + number; validates by country; `+91` default |
| **PIN Code Check** | 6-digit input + Check button; on success shows the delivery estimate and remembers the value; on failure offers "Notify me" |
| **File Upload** | Dashed dropzone, drag states, per-file progress and error |
| **Photo Upload** | Tile grid with previews, reorder, remove, camera capture on mobile, client-side compression notice |
| **Field Wrapper** | Standardises label / required marker / tooltip / control / helper / error / counter arrangement |

---

## 97–102. Filter Components

**`CMP-FLT-Rail`** — sticky left column 264 px with a scrollable body; header shows "Filters" and "Clear all"; groups are `CMP-FLT-Group` instances.

**`CMP-FLT-Group`** — collapsible group with a title, selected-count badge, and a body containing checkboxes with counts, swatches, a price range slider, or a rating selector. Long value lists show the top 8 with "Show all (24)" and an inline search above 12 values.

**`CMP-FLT-Chip`** — active filter chip with a remove `×`; variants Value, Range, Rating, Clear-all.

**`CMP-FLT-ActiveBar`** — horizontal row of applied filter chips + result count + "Clear all"; sticky beneath the toolbar; announces the new count on change.

**`CMP-FLT-Sort`** — dropdown (desktop) / bottom sheet (mobile) with 6 options; selected shows a check; the trigger displays the current option.

**`CMP-FLT-Sheet`** — mobile full-screen sheet: header with close and "Clear all", scrollable accordion of filter groups with live counts, sticky footer showing "Show 128 products" as the primary action. Filters do not apply until the shopper taps Show (avoiding repeated reloads on mobile), while desktop applies immediately.

---

## 103. Toast — `CMP-FBK-Toast`

| Property | Values |
|----------|--------|
| `Type` | Success, Error, Warning, Info, Loading, Product (with thumbnail) |
| `Content` | Title, Title + Body, Title + Body + Actions |
| `Dismiss` | Auto, Manual |

Width 380 desktop / calc(100% − 32) mobile, radius-lg, `elevation-5`, 4 px leading accent. **Product variant** includes a 48 px thumbnail and is used for cart and wishlist confirmations: "Added to cart · [View Cart]". Position: top-right desktop, bottom-centre mobile above the tab bar. Durations: success 4 s, info 5 s, warning 6 s, error manual. Max 3 stacked. Undo actions hold the toast for the full 8 s window.

---

## 104. Alert / Banner — `CMP-FBK-Alert`

| Property | Values |
|----------|--------|
| `Type` | Info, Success, Warning, Danger, Craft, Promo |
| `Scope` | Inline, Section, Page, Global |
| `Dismissible` | True, False |
| `Actions` | None, Link, Buttons |

Used for: out-of-stock notices in cart, price-change notices, delivery-area warnings, promotional eligibility ("Add ₹250 more to get free shipping"), and global service messages.

---

## 105. Inline Message — `CMP-FBK-InlineMessage`

Small contextual message with a 14 px leading icon: field errors, stock notes, coupon feedback, delivery notes. Types: Error, Warning, Success, Info, Hint.

---

## 106. Tooltip — `CMP-FBK-Tooltip`

`bg-inverse`, `text-inverse`, `body-xs`, padding 8×12, radius-md, 6 px arrow, max width 280. Delay in 300 ms, out 100 ms. Touch devices get tap-to-toggle. Never contains interactive content — that is a Popover.

---

## 107–109. Progress, Spinner, Skeleton

**Progress:** determinate, indeterminate and circular; sizes 2/4/8/12; used for free-shipping thresholds, upload, checkout steps and password strength.

**Spinner:** 16/20/24/32/48; 2 px stroke; brand arc on a `paper-200` track; always paired with text when it is the sole page content.

**Skeleton:** shapes Text, Heading, Circle, Rect, Image, Chip, Button, Price. Composed presets: Product Card, Product Grid (8), Product Rail (5), PDP, Cart, Order Card, Review, Article, Filter Rail, Search Suggestions. **Skeletons must mirror the real geometry exactly** — a product-card skeleton reserves the same image ratio and the same 2-line title height, so nothing shifts on load.

---

## 110–112. State Components

**`CMP-FBK-EmptyState`** — illustration (120/160/200) + heading + supporting line (max 400 px) + primary CTA + optional secondary path. Types: No Data, No Results, Not Signed In, Coming Soon, All Clear.

**`CMP-FBK-ErrorState`** — icon 48/64 + heading + plain-language cause + recovery actions + optional copyable reference code. Types: Load Failed, Network, Timeout, Server, Not Found, Forbidden, Payment Failed.

**`CMP-FBK-SuccessState`** — animated check + heading + summary + next actions. Used for order placed, review submitted, return requested, subscription confirmed.

---

## 113. Modal — `CMP-OVL-Modal`

| Size | Width | Use |
|------|-------|-----|
| XS | 400 | Confirmations |
| SM | 520 | Simple forms, sign-in prompt |
| MD | 640 | **Default** — quick view, coupon list |
| LG | 800 | Size guide, review form |
| XL | 1000 | Compare, gallery-heavy content |
| Full | 100vw − 64 | Lightbox-adjacent experiences |

Header 64 (title + close), body max-height 70vh scrolling with sticky header/footer and a scroll shadow, footer 80. Scrim + 2 px blur. `Esc` and scrim click close unless the form is dirty, in which case a guard appears. **Mobile: every modal becomes a full-screen sheet** with the primary action pinned to the bottom.

---

## 114. Drawer — `CMP-OVL-Drawer`

| Property | Values |
|----------|--------|
| `Position` | Right, Left |
| `Width` | SM 360, MD 420, LG 480, XL 560 |
| `Type` | Cart, Filters, Menu, Detail, AI Assistant |
| `Footer` | None, Actions, Sticky Actions |

Slides 350 ms `ease-decelerate`. Only one drawer at a time. Focus trapped; returns focus on close. Swipe-to-dismiss on touch.

---

## 115. Bottom Sheet — `CMP-OVL-BottomSheet`

Mobile primary overlay. Radius-xl on the top corners, 40×4 grab handle, snap points at 50% and 92%, drag-to-dismiss with rubber-band resistance, scrim fade. Sticky footer action when present. Used for: filters, sort, variant selection, size guide, share, address selection, payment method, PIN check, gift options.

---

## 116. Popover — `CMP-OVL-Popover`

Radius-lg, `elevation-3`, padding 16, max width 320, optional arrow. Click-triggered (hover only for pure information). Used for: tax explanation, points rules, coupon terms, colour name, dimension conversion, delivery details.

---

## 117. Cookie Consent — `CMP-OVL-CookieConsent`

Bottom banner (desktop) / bottom sheet (mobile). Plain-language explanation, "Accept All", "Reject All" **equally prominent**, and "Customise" opening category toggles (Essential locked on, Analytics, Marketing, Personalisation) with descriptions. No pre-ticked non-essential categories. Persists 12 months; re-openable from the footer.

---

## 118. Newsletter Popup — `CMP-OVL-NewsletterPopup`

Appears at most once per 14 days, never within 20 s of arrival, never on checkout or during an active cart session, never on exit-intent on mobile. Content: craft imagery, headline, one email field, incentive if any, an unticked consent checkbox, "Subscribe" and a clearly visible "Not now". Dismissal is remembered.

---

## 119–125. Indicators

| Component | Specification |
|-----------|---------------|
| **Tag** | Radius-sm, `bg-subtle`, `body-xs`; used for blog tags, product tags, filter values; removable variant has a trailing `×` |
| **Label** | Static descriptor in description lists and specs |
| **Counter Badge** | 18 px circle (dot variant 8 px) on cart/wishlist/notification icons; caps at 99+; scale-pop animation on increment; announced on change |
| **Avatar** | 24/32/40/56/80; image, initials (deterministic tint) or icon; used for reviewers, artisans, account |
| **Trust Badge** | Icon 32 + label + optional sub-line; horizontal band variant (4-up) and inline variant |
| **Payment Marks** | Row of official network/gateway logos at a consistent 24 px height on white chips; greyscale variant for the footer |
| **Countdown Timer** | DD:HH:MM:SS or HH:MM:SS blocks; sizes SM/MD/LG; server-time anchored; **only rendered when a real scheduled sale window exists**; announces politely at most once a minute; ends into an "Offer ended" state rather than disappearing |

---

## 126–129. Account Components

**`CMP-ACC-Sidebar`** — vertical nav for account sections with icons, labels, counts (Orders 12, Wishlist 8, Coupons 3), active state with a left brand bar; becomes a list page on mobile with drill-down.

**`CMP-ACC-ProfileCard`** — avatar, name, email, phone, member since, tier chip, and quick edit.

**`CMP-ACC-PointsCard`** — brass-toned card: balance in `display-lg`, value equivalent ("worth ₹248"), expiring-soon warning with a date, progress toward the next tier, and "How to earn" / "Redeem" actions.

**`CMP-ACC-NotificationItem`** — unread dot, category icon in a tinted circle, title, body (2-line clamp), relative time, thumbnail where relevant, and actions (mark read, dismiss). Grouped by day with sticky headers.

---

## 130–135. Content Components

| Component | Specification |
|-----------|---------------|
| **Article Card** | 16:9 cover, category chip, title (2-line), excerpt (2-line), author avatar + name, date, reading time; sizes SM/MD/LG/Feature |
| **Table of Contents** | Sticky rail listing article headings with a scroll-spy active state; becomes a collapsible panel on mobile |
| **FAQ Item** | Accordion row with the question in `heading-xs`, rich-text answer, helpful vote, and deep-linkable anchor; emits FAQ structured data |
| **Table** | Responsive content table for size guides, care instructions and comparison; sticky header; horizontal scroll with a shadow hint on mobile; zebra optional |
| **Instagram Tile** | Square image with a hover overlay showing likes/comments and an external-link icon; grid of 6–12 with a "Follow us" CTA |
| **Newsletter Form** | Inline (footer band) and stacked (modal) variants; email field + button + unticked consent checkbox + privacy link; success state replaces the form with a confirmation and a discount code if offered |

---

## 136–140. AI Components

**`CMP-AI-Launcher`** — floating pill or FAB with a `sparkles` icon and the label "Ask Karigar"; pulses once on first visit only; hidden during checkout.

**`CMP-AI-ChatPanel`** — right drawer 420 (desktop) / bottom sheet 92vh (mobile): header with title, AI disclosure and close; scrollable message list; suggested-prompt chips; composer with text input, mic and image-upload; footer note "AI can make mistakes — check product details before ordering".

**`CMP-AI-Message`** — variants User / Assistant / System; assistant messages may embed product suggestion cards, comparison tables or links; streaming state shows a typing indicator; each assistant message carries thumbs-up/down feedback and a "Show sources" affordance where it cites catalogue data.

**`CMP-AI-Suggestion`** — compact product card carrying a short reason line ("Similar shape, lighter, ₹400 less") and Add to Cart / View actions.

**`CMP-AI-Disclosure`** — small chip "✨ AI-generated" placed on every AI-produced surface: review summaries, recommendations, search interpretation, assistant replies. This is mandatory and non-dismissible.

---

## Component QA Checklist (Figma)

For every component:

- [ ] All listed variant combinations exist
- [ ] Light and Dark modes via Variable modes
- [ ] Default / Hover / Active / Focus / Disabled / Loading where applicable
- [ ] Auto Layout with correct Hug/Fill resizing
- [ ] Layers named per the anatomy in this document
- [ ] Description contains purpose, when to use, when not to use, a11y notes and a link to this section
- [ ] Accessible name and role documented
- [ ] Responsive behaviour documented or variants provided
- [ ] Touch target ≥44/48 px verified
- [ ] Contrast verified in both themes
- [ ] Correct and incorrect usage examples placed on the Usage page
