# 05 — Global UX Patterns (Storefront)

Enterprise Handicraft E-Commerce Platform · Customer Website UI/UX Specification

These patterns are inherited by every module. A module chapter documents only its **deviations** plus its own data.

---

## Pattern P-01 — Product Listing Page (PLP)

### Desktop Wireframe (1440)

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ ANNOUNCEMENT · HEADER · NAV BAR                                                       │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ Home / Home Décor / Vases                                                             │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ Handcrafted Vases                                                    (H1, display-lg) │
│ 84 products · Hand-thrown, blue pottery, brass and terracotta vases from across India │
├────────────────────┬─────────────────────────────────────────────────────────────────┤
│ FILTERS   Clear all│ [Grid ▦][List ☰]        84 products      Sort: [Popularity ▾]   │
│                    │ (Category: Vases ×) (Material: Ceramic ×) (₹500–₹2000 ×)  Clear │
│ ▾ Category         ├─────────────────────────────────────────────────────────────────┤
│   ☑ Vases (84)     │ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐                     │
│   ☐ Wall Art (102) │ │ [SALE] │ │        │ │  [NEW] │ │        │                     │
│   ☐ Lamps (68)     │ │  img   │ │  img   │ │  img   │ │  img   │                     │
│ ▾ Price            │ │        │ │        │ │        │ │        │                     │
│   ▁▃▅▇▅▃▁ histogram│ │ Title  │ │ Title  │ │ Title  │ │ Title  │                     │
│   [₹500]──●──●─[₹2k]│ │ ★4.6   │ │ ★4.2   │ │ ★4.8   │ │ ★4.4   │                     │
│ ▾ Material         │ │ ₹1,250 │ │ ₹890   │ │ ₹2,100 │ │ ₹640   │                     │
│   ☑ Ceramic (42)   │ └────────┘ └────────┘ └────────┘ └────────┘                     │
│   ☐ Brass (18)     │ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐                     │
│   ☐ Terracotta (14)│ │  …     │ │  …     │ │  …     │ │  …     │                     │
│   Show all (8)     │ └────────┘ └────────┘ └────────┘ └────────┘                     │
│ ▾ Colour           │                                                                  │
│   ●●●●●●●●         │ ┌────────────────────────────────────────────────────────────┐  │
│ ▾ Rating           │ │  COLLECTION BANNER — Diwali Décor · Up to 25% off  [Shop →] │  │
│   ☐ ★4 & above     │ └────────────────────────────────────────────────────────────┘  │
│ ▾ Artisan          │ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐                     │
│ ▾ Availability     │ │  …     │ │  …     │ │  …     │ │  …     │                     │
│ ▾ Discount         │ └────────┘ └────────┘ └────────┘ └────────┘                     │
│                    │                  [ Load More (24 of 84) ]                        │
│                    │                  ○ ○ ● ○ ○  1 2 3 4 →                            │
├────────────────────┴─────────────────────────────────────────────────────────────────┤
│ SEO INTRO COPY (120 words about the craft, materials and makers)                      │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ RELATED CATEGORIES · RECENTLY VIEWED RAIL · FOOTER                                    │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### Mobile Wireframe (390)

```
┌──────────────────────────────────┐
│ ☰   KARIGAR         ♡2    🛍3    │
├──────────────────────────────────┤
│ ‹ Home Décor                     │
│ Handcrafted Vases                │
│ 84 products                      │
├──────────────────────────────────┤
│ [⚙ Filters (3)]      [Sort ▾]    │  sticky
│ (Ceramic ×) (₹500–2k ×)          │
├──────────────────────────────────┤
│ ┌───────────┐ ┌───────────┐      │
│ │  [SALE] ♡ │ │        ♡  │      │
│ │    img    │ │    img    │      │
│ │           │ │           │      │
│ │ Blue      │ │ Terracotta│      │
│ │ Pottery…  │ │ Planter   │      │
│ │ ★4.6 (128)│ │ ★4.2 (44) │      │
│ │ ₹1,250    │ │ ₹680      │      │
│ │ ₹1,600 22%│ │           │      │
│ └───────────┘ └───────────┘      │
│ ┌───────────┐ ┌───────────┐      │
│ │    …      │ │    …      │      │
│ └───────────┘ └───────────┘      │
│       [ Load More ]              │
├──────────────────────────────────┤
│ 🏠   🛍   🔍   ♡   👤            │
└──────────────────────────────────┘
```

### Region Specification

| Region | Desktop | Mobile | Sticky |
|--------|---------|--------|--------|
| Breadcrumb | 44 px | Back link only | No |
| Page heading block | Title + count + intro | Title + count | No |
| Filter rail | 264 px left, sticky, independently scrollable | Sheet trigger | Yes (desktop) |
| Toolbar | View toggle, count, sort | Filter + Sort buttons | Yes |
| Active filter bar | Chip row | Chip row (scrollable) | Yes |
| Grid | 4 across | 2 across | — |
| Injected banners | After every 8th product | After every 6th | — |
| Pagination | Load More + numbered fallback | Load More | — |
| SEO copy | Below the grid | Below, collapsed to 3 lines with "Read more" | — |

### Behaviour Rules

| ID | Rule |
|----|------|
| PLP-01 | Filters, sort and page are encoded in the URL query string and are shareable |
| PLP-02 | Desktop applies filters immediately; mobile batches them in the sheet until "Show N products" |
| PLP-03 | Facet counts update live and options producing zero results are disabled, not hidden, so shoppers understand the catalogue |
| PLP-04 | Back-navigation from PDP restores the exact scroll position, loaded pages and filters |
| PLP-05 | "Load More" preserves history — the URL updates so refresh and back work |
| PLP-06 | Default sort is Popularity; the current sort is always visible in the trigger |
| PLP-07 | Out-of-stock products are shown by default at the end of the result set, with a filter to hide them |
| PLP-08 | The grid never reflows after images load — ratio boxes are mandatory |
| PLP-09 | Above the fold on mobile there must be at least one full product card visible |
| PLP-10 | The result count is announced on every filter or sort change |
| PLP-11 | Indexable facet combinations get a real H1 and intro copy; non-indexable ones canonicalise to the base category |
| PLP-12 | Sponsored placements are labelled and never exceed 1 in 8 cards |

---

## Pattern P-02 — Product Detail Page (PDP)

### Above-the-Fold Contract

On both desktop 1440×900 and mobile 390×844, the following must be visible without scrolling:

1. Product image (primary)
2. Product name
3. Rating with review count
4. Price with any discount
5. Stock status
6. At least the beginning of the primary action area (mobile: sticky bar always visible)

### Desktop Wireframe

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ Home / Home Décor / Vases / Blue Pottery Vase                                         │
├────────────────────────────────────────┬─────────────────────────────────────────────┤
│ ┌────┐┌──────────────────────────────┐ │ JAIPUR BLUE POTTERY                          │
│ │thmb││                              │ │ Blue Pottery Vase — Hand-painted             │
│ ├────┤│                              │ │ ★★★★★ 4.6 (128 reviews) · 240 sold           │
│ │thmb││       main image 1:1         │ │ 🤲 Made by Ram Prasad Sharma · Jaipur        │
│ ├────┤│       with zoom lens         │ │                                              │
│ │thmb││                              │ │ ₹1,250  ₹̶1̶,̶6̶0̶0̶  [22% OFF]                   │
│ ├────┤│                              │ │ Inclusive of all taxes · You save ₹350       │
│ │360 ││                              │ │                                              │
│ ├────┤│                              │ │ ┌──────────────────────────────────────────┐ │
│ │vid ││                    [⤢][♡][⇪]│ │ │🤲 Every piece is unique                  │ │
│ └────┘└──────────────────────────────┘ │ │  Handmade items vary slightly in colour, │ │
│                                        │ │  finish and size.  [What to expect →]    │ │
│                                        │ └──────────────────────────────────────────┘ │
│                                        │ Colour: Indigo Blue                          │
│                                        │ ● ○ ○ ○   (4 colours)                        │
│                                        │ Size: Medium              [Size guide →]     │
│                                        │ [Small][Medium][Large]                       │
│                                        │ ✓ In stock · Only 3 left                     │
│                                        │ ┌──────────────────────────────────────────┐ │
│                                        │ │📍 Deliver to [560038] [Check]            │ │
│                                        │ │🚚 Get it by Wed, 12 Aug · Free shipping  │ │
│                                        │ │💵 Cash on delivery available             │ │
│                                        │ └──────────────────────────────────────────┘ │
│                                        │ [− 1 +]  [  Add to Cart  ] [  Buy Now  ] [♡] │
│                                        │ 🤲 Handmade  ✅ 7-day returns  🔒 Secure pay │
│                                        │ ▸ Product details                            │
│                                        │ ▸ Materials & care                           │
│                                        │ ▸ Dimensions & weight                        │
│                                        │ ▸ Shipping & returns                         │
│                                        │ [⚖ Compare]  [⇪ Share]                       │
├────────────────────────────────────────┴─────────────────────────────────────────────┤
│ BAND · The story behind this piece (craft technique, process images)                  │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ BAND · Meet the maker — Ram Prasad Sharma (photo, story, shop his work)                │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ BAND · Specifications (two-column spec list + dimension diagram)                       │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ BAND · Reviews — ★4.6, breakdown, AI summary, customer photo strip, review list       │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ BAND · Frequently asked questions (accordion, FAQ schema)                              │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ RAIL · Complete the look    RAIL · Similar products    RAIL · Recently viewed          │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ FOOTER                                                                                 │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### Mobile Wireframe

```
┌──────────────────────────────────┐
│ ‹        KARIGAR      ⇪    🛍3   │
├──────────────────────────────────┤
│                             ♡    │
│        gallery carousel          │
│           390×390                │
│      ● ● ● ○ ○ ○   3/8           │
├──────────────────────────────────┤
│ JAIPUR BLUE POTTERY              │
│ Blue Pottery Vase —              │
│ Hand-painted                     │
│ ★4.6 (128) · 240 sold            │
│ 🤲 Ram Prasad Sharma, Jaipur     │
│                                  │
│ ₹1,250  ₹̶1̶,̶6̶0̶0̶  22% OFF        │
│ Inclusive of all taxes           │
│                                  │
│ ┌──────────────────────────────┐ │
│ │🤲 Every piece is unique  →   │ │
│ └──────────────────────────────┘ │
│ Colour: Indigo Blue              │
│ ● ○ ○ ○                          │
│ Size: Medium      [Size guide]   │
│ [Small][Medium][Large]           │
│ ✓ Only 3 left                    │
│ ┌──────────────────────────────┐ │
│ │📍 560038 · Get it Wed, 12 Aug│ │
│ │🚚 Free · 💵 COD available    │ │
│ └──────────────────────────────┘ │
│ 🤲 Handmade ✅ Returns 🔒 Secure │
│ ▸ Product details                │
│ ▸ Materials & care               │
│ ▸ Dimensions & weight            │
│ ▸ Shipping & returns             │
│ [ story / maker / reviews … ]    │
├──────────────────────────────────┤
│ ₹1,250  [♡] [ Add to Cart ]      │  sticky, 72px
└──────────────────────────────────┘
```

### Behaviour Rules

| ID | Rule |
|----|------|
| PDP-01 | Selecting a variant updates price, images, stock and SKU **without a page reload**, and updates the URL |
| PDP-02 | An unselected required option blocks Add to Cart with an inline message and scroll-to-field, never a silent disabled button |
| PDP-03 | The delivery PIN persists for 30 days and is reused across the site |
| PDP-04 | The variation notice is mandatory for handmade products and cannot be dismissed |
| PDP-05 | The sticky mobile bar appears once the inline CTA scrolls out of view, and shows price + wishlist + Add to Cart |
| PDP-06 | Add to Cart opens the mini cart on desktop; on mobile it shows a product toast with "View Cart" |
| PDP-07 | Out of stock replaces both CTAs with "Notify Me" and surfaces alternatives immediately below |
| PDP-08 | Reviews load with the page (first 5) — never behind a click, because they drive conversion |
| PDP-09 | The first gallery image is the LCP element and is eagerly loaded with high priority |
| PDP-10 | Product, Review, Breadcrumb and FAQ structured data are emitted |
| PDP-11 | Every accordion's content is present in the DOM when collapsed for SEO |
| PDP-12 | Price and stock are re-validated when the tab regains focus after 10 minutes |

---

## Pattern P-03 — Form Pattern

### Layout Rules

| ID | Rule |
|----|------|
| F-01 | Single column. Two columns only for genuinely paired short fields (city/PIN, expiry/CVV) |
| F-02 | Labels always visible above the field; placeholders show format examples only |
| F-03 | Required fields marked with `*`; if most fields are required, mark the optional ones instead |
| F-04 | Field order follows the shopper's mental model and matches physical documents (address as written on an envelope) |
| F-05 | Correct autocomplete attributes so browser and password-manager autofill work — this is a conversion feature |
| F-06 | Correct input modes so mobile keyboards match (numeric for PIN and OTP, email for email, tel for phone) |
| F-07 | Validate on blur for format, on submit for required, live for uniqueness and strength |
| F-08 | On failed submit: focus the first invalid field, scroll it into view with 120 px offset, and show a summary listing errors as links |
| F-09 | Never disable the submit button to enforce validation — allow the attempt and explain the failure |
| F-10 | Show progress on multi-step forms and allow returning to completed steps |
| F-11 | Preserve input across accidental navigation, refresh and session expiry |
| F-12 | Success is always explicit — a state change, confirmation or navigation, never silence |

### Validation Message Catalogue (Global)

| Condition | Message |
|-----------|---------|
| Required | `{Label} is required` |
| Min length | `{Label} must be at least {n} characters` |
| Max length | `{Label} must be {n} characters or fewer` |
| Invalid email | `Enter a valid email address` |
| Invalid phone | `Enter a valid 10-digit mobile number` |
| Invalid PIN | `Enter a valid 6-digit PIN code` |
| Non-serviceable PIN | `We don't deliver to {pin} yet. [Notify me when we do]` |
| Invalid OTP | `That code isn't right. {n} attempts left` |
| Expired OTP | `This code has expired. [Send a new one]` |
| Password strength | `Use at least 8 characters with a number and a letter` |
| Password mismatch | `Passwords don't match` |
| Email already registered | `This email is already registered. [Sign in instead]` |
| Phone already registered | `This number is already registered. [Sign in instead]` |
| Invalid card | `Check your card number` |
| Expired card | `This card has expired` |
| Invalid CVV | `Enter the 3-digit code on the back of your card` |
| Invalid UPI ID | `Enter a valid UPI ID (like name@bank)` |
| Coupon invalid | `This coupon isn't valid` |
| Coupon expired | `This coupon expired on {date}` |
| Coupon minimum | `Add ₹{n} more to use this coupon` |
| Coupon not applicable | `This coupon doesn't apply to items in your cart` |
| File too large | `File is too large. Maximum {n} MB` |
| Wrong file type | `Use JPG, PNG or WEBP` |
| Too many files | `You can upload up to {n} photos` |
| Network | `Check your connection and try again` |
| Server | `Something went wrong on our end. Your details are safe — [Try again]` |
| Session expired | `Your session timed out for security. [Sign in to continue] — your cart is saved` |
| Rate limited | `Too many attempts. Try again in {n} minutes` |

---

## Pattern P-04 — Overlay Pattern (Modal / Drawer / Sheet)

### Choosing the Right Overlay

| Situation | Desktop | Mobile |
|-----------|---------|--------|
| Quick product view | Modal MD | Bottom sheet 92% |
| Cart preview | Drawer right 420 | Toast + navigate, or sheet |
| Filters | Inline rail (no overlay) | Full-screen sheet |
| Sort | Popover | Bottom sheet |
| Variant selection from a card | Modal MD | Bottom sheet |
| Size guide | Modal LG | Bottom sheet 92% |
| Address select/add | Modal MD | Bottom sheet |
| Payment method detail | Inline expand | Inline expand |
| Sign-in prompt | Modal SM | Bottom sheet |
| Image lightbox | Full lightbox | Full lightbox |
| AI assistant | Drawer right 420 | Bottom sheet 92% |
| Share | Popover | Native share, or bottom sheet |
| Confirmation | Modal XS | Modal XS (centred, not a sheet — decisions deserve focus) |

### Rules

| ID | Rule |
|----|------|
| OVL-01 | One overlay at a time; opening another replaces it |
| OVL-02 | Focus is trapped inside; the first interactive element (or the title) receives focus |
| OVL-03 | `Esc` and scrim click close, unless a dirty form triggers a guard |
| OVL-04 | Focus returns to the invoking element on close |
| OVL-05 | Background scroll is locked while an overlay is open, without layout shift |
| OVL-06 | Overlays never nest more than two deep |
| OVL-07 | Every overlay has an accessible name matching its visible title |
| OVL-08 | Bottom sheets support drag-to-dismiss with a visible grab handle |
| OVL-09 | Overlay content that exceeds the height scrolls internally with sticky header and footer |
| OVL-10 | On mobile the primary action is pinned to the bottom of the overlay, in the thumb zone |

---

## Pattern P-05 — Confirmation Dialogs

| Type | When | Icon | Primary | Auto-focus |
|------|------|------|---------|-----------|
| Simple confirm | Reversible action | Info | Filled brand | Primary |
| Destructive confirm | Data loss (remove address, delete account) | Alert in a red circle | Filled danger | Cancel |
| Warning confirm | Risky but recoverable (cancel order) | Triangle amber | Filled brand | Cancel |
| Input confirm | Needs a reason (return, cancel) | Contextual | Filled brand | First input |
| Leave confirm | Dirty form navigation | Info | "Stay" | Stay |

### Template — Remove from Cart

```
┌────────────────────────────────────────────────┐
│  Remove this item?                        [×]  │
├────────────────────────────────────────────────┤
│  ┌────┐  Blue Pottery Vase — Jaipur            │
│  │img │  Size: Medium · Qty 1                  │
│  └────┘  ₹1,250                                │
│                                                │
│  You can move it to your wishlist instead.     │
├────────────────────────────────────────────────┤
│  [Save for Later]   [Cancel]   [Remove Item]   │
└────────────────────────────────────────────────┘
```

### Template — Cancel Order

```
┌────────────────────────────────────────────────┐
│  ⚠  Cancel order #HC-2026-000482?         [×]  │
├────────────────────────────────────────────────┤
│  This will cancel all 3 items.                 │
│                                                │
│  • Your refund of ₹4,250 will be issued to     │
│    your UPI within 5–7 business days           │
│  • This cannot be undone                       │
│                                                │
│  Why are you cancelling? (optional)            │
│  [ Select a reason                          ▾] │
├────────────────────────────────────────────────┤
│  [Keep My Order]              [Cancel Order]   │
└────────────────────────────────────────────────┘
```

### Copy Rules

- Title is a question: "Remove this item?", "Cancel order?"
- Body states the concrete consequence with real numbers.
- Reversibility is stated explicitly.
- Buttons echo the verb; never "Yes"/"No"/"OK".
- Never use confirm-shaming ("No thanks, I like paying more").
- Offer a softer alternative where one exists (Save for Later instead of Remove).

---

## Pattern P-06 — Empty States

| Context | Illustration | Heading | Body | Primary | Secondary |
|---------|-------------|---------|------|---------|-----------|
| Cart | Empty woven basket | Your cart is empty | Discover handmade pieces from artisans across India. | Start Shopping | View Wishlist |
| Wishlist | Heart with a thread | Your wishlist is empty | Tap the heart on any product to save it here. | Explore Products | Shop New Arrivals |
| Orders | Wrapped parcel | No orders yet | When you place an order, you'll be able to track it here. | Start Shopping | — |
| Search | Magnifier over pottery | No results for "{query}" | Check the spelling or try a different word. | Clear Search | Browse Categories |
| PLP filtered | Filter funnel | No products match your filters | Try removing a filter to see more. | Clear All Filters | — |
| Reviews (product) | Speech mark | No reviews yet | Be the first to share your experience. | Write a Review | — |
| Reviews (account) | Speech mark | You haven't reviewed anything yet | Reviews from your delivered orders will appear here. | View Orders | — |
| Addresses | Map pin | No saved addresses | Add an address to check out faster next time. | Add Address | — |
| Coupons | Ticket | No coupons available | We'll show your offers here when you have some. | Shop Now | — |
| Points | Gem | Start earning points | Earn points on every order and redeem them for discounts. | How It Works | Shop Now |
| Notifications | Bell | You're all caught up | Order updates and offers will appear here. | — | — |
| Compare | Balance scale | Nothing to compare yet | Add up to 4 products to compare them side by side. | Browse Products | — |
| Recently viewed | Eye | Nothing viewed yet | Products you look at will show up here. | Start Shopping | — |
| Support tickets | Envelope | No support requests | If you need help, we're here. | Contact Us | Visit Help Centre |
| Blog search | Newspaper | No articles found | Try another search or browse all stories. | View All Stories | — |
| Guest account prompt | Person | Sign in to see this | Sign in or create an account to view your orders. | Sign In | Continue as Guest |

All illustrations are line-art in indigo + terracotta on a transparent background, with dedicated dark variants.

---

## Pattern P-07 — Loading States & Skeletons

### Preset Compositions

| Preset | Composition |
|--------|-------------|
| Product Card | Image ratio box + 2 title lines (100%, 60%) + rating bar (90×14) + price bar (80×18) |
| Product Grid | 8 card skeletons in the live column count |
| Product Rail | 5 card skeletons, horizontally scrolled |
| PLP | Toolbar bar + filter rail (6 groups) + grid skeleton |
| PDP | Gallery square + thumb column + title lines + rating + price + 2 option rows + CTA bars + 4 accordion rows |
| Cart | 3 line-item skeletons + summary block |
| Checkout | Stepper + 3 section cards + summary |
| Order Card | Status chip + 3 thumbnails + 2 text lines + 2 buttons |
| Review | Avatar + name line + star row + 3 body lines + photo strip |
| Article | Cover ratio box + title + meta + 6 body lines |
| Search Suggestions | 3 text rows + 3 product rows |
| Account Dashboard | Greeting + 3 stat cards + order card |

### Rules

- Skeletons appear only after 200 ms of loading (avoids flashing on fast responses) and stay a minimum of 400 ms once shown.
- Skeleton geometry must match the real content exactly — this is how CLS stays at zero.
- Shimmer sweeps left→right over 1400 ms; under reduced motion it becomes a static 8% grey.
- Never mix skeletons and spinners on the same surface.
- Spinners are for in-place actions (button, filter apply), skeletons for content areas.
- Above 3 seconds, add reassuring text: "Still loading — thanks for your patience."

---

## Pattern P-08 — Error States & Recovery

| Error | Where | Message | Recovery |
|-------|-------|---------|----------|
| Network failure | Any | "Check your connection and try again" | Retry button; cached content shown where possible |
| Server error (5xx) | Any | "Something went wrong on our end" | Retry, Go Home, Contact Support, copyable reference |
| Product not found | PDP | "This product is no longer available" | Similar products rail shown immediately |
| Out of stock at add | PDP/PLP | "Sorry, this just sold out" | Notify Me + alternatives |
| Out of stock in cart | Cart | Line tinted, "No longer available" | Save for Later / Remove; checkout blocked until resolved |
| Price changed | Cart | "Price updated from ₹1,400 to ₹1,250" | Accept and continue; never silently change |
| Coupon failure | Cart/Checkout | Specific reason per §P-03 catalogue | Suggest an eligible coupon |
| Address non-serviceable | Checkout | "We don't deliver to {pin} yet" | Use another address / Notify me |
| Payment declined | Payment | "Your bank declined the payment" | Try another method, retry, **cart and address preserved** |
| Payment timeout | Payment | "We didn't hear back from your bank" | Check status, retry, do not double-charge |
| Session expired | Checkout | "Your session timed out for security" | Sign in and resume, cart preserved |
| Stock reservation expired | Checkout | "We couldn't hold your items" | Re-validate cart, show what changed |
| Upload failure | Reviews/Returns | "That photo couldn't be uploaded" | Retry that file only |
| Rate limited | Auth | "Too many attempts. Try again in {n} minutes" | Password reset path offered |
| Feature unavailable | AI, live tracking | "This isn't available right now" | Graceful fallback to the non-AI/manual path |

**Recovery principles:** never lose the shopper's data; always state what happened in plain language; always offer at least one forward path; never blame the shopper; log a reference the support team can use.

---

## Pattern P-09 — Success States

| Event | Treatment |
|-------|-----------|
| Add to cart | Button success flash + product toast + cart badge animation + mini cart (desktop) |
| Add to wishlist | Heart fill animation + toast "Saved to wishlist · View" |
| Coupon applied | Coupon row turns green, saving announced, total animates down |
| Address saved | Card appears in the list, selected, with a brief highlight |
| Order placed | Full-page success state with an animated check, order number, delivery date, next actions, and a single confetti burst |
| Review submitted | Success state with "Thanks for helping other shoppers" + points earned if applicable |
| Return requested | Success state with the RMA number, pickup date and refund expectation |
| Newsletter subscribed | Form replaced by a confirmation and the welcome code if offered |
| Password changed | Confirmation + "You'll stay signed in on this device" |
| Notify-me registered | Button becomes "We'll notify you" with an undo option |

**Rule:** every success state answers "what happens next?" — a confirmation without a next step is incomplete.

---

## Pattern P-10 — Toast Catalogue (Global)

| Event | Type | Message | Actions | Duration |
|-------|------|---------|---------|----------|
| Added to cart | Product | "Added to cart" | View Cart | 4 s |
| Added to wishlist | Product | "Saved to wishlist" | View | 4 s |
| Removed from cart | Success | "Item removed" | Undo | 8 s |
| Removed from wishlist | Success | "Removed from wishlist" | Undo | 8 s |
| Moved to cart | Success | "Moved to cart" | View Cart | 4 s |
| Coupon applied | Success | "Coupon applied · You save ₹350" | — | 4 s |
| Coupon removed | Info | "Coupon removed" | Undo | 6 s |
| Copied | Info | "Copied to clipboard" | — | 2 s |
| Quantity updated | Silent | (in-place update, no toast) | — | — |
| Compare added | Info | "Added to compare (2 of 4)" | Compare Now | 4 s |
| Compare full | Warning | "You can compare up to 4 products" | — | 5 s |
| Address saved | Success | "Address saved" | — | 4 s |
| Notify-me set | Success | "We'll email you when it's back" | Undo | 6 s |
| Sign-in needed | Info | "Sign in to save this across devices" | Sign In | 6 s |
| Offline | Warning | "You're offline — showing saved content" | — | Manual |
| Back online | Success | "Back online" | — | 3 s |
| Generic error | Error | "Something went wrong. Please try again." | Retry | Manual |

Position: top-right (desktop), bottom-centre above the tab bar (mobile). Max 3 stacked. Auto-dismiss pauses on hover/focus.

---

## Pattern P-11 — System Pages

### 404 — Not Found

```
┌──────────────────────────────────────────────────┐
│ HEADER                                            │
│                                                   │
│            ┌──────────────────┐                   │
│            │  illustration:   │                   │
│            │  broken pot being│  240×220          │
│            │  repaired (kintsugi)                 │
│            └──────────────────┘                   │
│                                                   │
│                    404                            │
│          We couldn't find that page               │
│   The link may be broken, or the page may have    │
│   moved. Let's get you back to something lovely.  │
│                                                   │
│      [ ⌕ Search for products…              ]      │
│                                                   │
│       [ Go to Homepage ]   [ Shop All ]           │
│                                                   │
│   Popular: Home Décor · Festive · Gifting · Sale  │
├──────────────────────────────────────────────────┤
│ RAIL · Bestsellers you might like                 │
├──────────────────────────────────────────────────┤
│ FOOTER                                            │
└──────────────────────────────────────────────────┘
```

The bestsellers rail is deliberate: a 404 is a recovery opportunity, not a dead end.

### 500 — Server Error

Illustration: an unfinished loom. Heading "Something went wrong on our end". Body: "We've been notified and are fixing it. Your cart is safe." Actions: Try Again (primary), Go to Homepage, Contact Support. A copyable reference `ERR-{code}-{traceId}`. Optional auto-retry countdown with a cancel option.

### 503 — Maintenance

Illustration: artisan tools laid out. Heading "We'll be back shortly". Body with the expected return time and a live countdown. Actions: Check Status, Refresh, and the WhatsApp/support contact. No header navigation — full-bleed page. Social links retained so shoppers can follow updates.

### Offline

Persistent banner at the top: "You're offline. Showing saved content." Cached PDPs and cart remain viewable; actions requiring the network are disabled with the reason. On reconnect, a success toast and a silent refresh.

### Browser Unsupported

Simple centred page listing supported browsers with download links and a "Continue anyway" link.

### Session Expired (Checkout)

Modal, not a page: "Your session timed out for security. Your cart and details are saved." Actions: Sign In and Continue (primary), Continue as Guest.

---

## Pattern P-12 — Sign-In Prompts (Contextual)

Never hard-redirect a shopper to a sign-in page mid-task. Instead:

| Trigger | Treatment |
|---------|-----------|
| Wishlist (guest) | Works immediately in session; a one-time toast offers "Sign in to keep it across devices" |
| Checkout | Choice screen: Continue as Guest (equal prominence) / Sign In / Create Account |
| Order tracking (guest) | Track by order number + email or phone, no account required |
| Review writing | Modal prompt explaining that reviews require a verified purchase, with sign-in inline |
| Reward points | Inline card in cart: "Sign in to use your 2,480 points (₹248 off)" |
| Saved addresses | Inline at checkout: "Sign in to use your saved addresses" |

The prompt always explains **the benefit**, never merely demands authentication.

---

## Pattern P-13 — Micro-interaction Catalogue

| Interaction | Feedback |
|-------------|----------|
| Button press | Scale 0.98, 80 ms; loading state if async |
| Card hover | Image scale 1.04, card lift 2 px, elevation 1→2, secondary image cross-fade |
| Wishlist toggle | Heart draw + scale pop (`ease-craft`) + radial pulse |
| Add to cart | Spinner → check → flying thumbnail arc to the cart icon → badge pop |
| Cart badge change | Scale 1→1.25→1 with a colour flash |
| Quantity change | Number rolls; line total fades and updates |
| Swatch select | Ring animates in; gallery cross-fades; price transitions |
| Filter chip add | Chip scales in from 0.9; result count rolls |
| Filter apply | Grid cross-fades 200 ms |
| Sort change | Grid cross-fades; scroll returns to the grid top |
| Load more | Button → spinner; new cards fade + rise in a 60 ms stagger |
| Gallery thumb select | Active ring slides to the new thumb |
| Zoom | Lens follows cursor; pane fades in |
| Accordion | Height animates; chevron rotates |
| Sticky bar reveal | Slides up 250 ms when the inline CTA leaves the viewport |
| Free-shipping threshold met | Bar fills, turns green, single pulse |
| Coupon applied | Row slides in green; total counts down to the new value |
| Order placed | Check circle draws, then the check strokes, then one confetti burst |
| Timeline progress | Completed node fills with a check-draw; connector fills left-to-right |
| Toast | Slides in; progress line depletes |
| Skeleton → content | Cross-fade 200 ms, never a hard swap |
| Scroll reveal | Fade + 16 px rise, once, staggered across up to 6 children |
| Pull to refresh (mobile) | Rubber-band with a craft-motif spinner |
| Form error | Field border turns danger with a 3 px shake (disabled under reduced motion) |
| OTP complete | Boxes flash success, then auto-submit |
| Search typing | Suggestions cross-fade; matched substring bolds |

All motion is suppressed or reduced to ≤100 ms opacity changes under `prefers-reduced-motion`.

---

## Pattern P-14 — Responsive Deviation Summary

| Component / pattern | Desktop | Tablet | Mobile |
|--------------------|---------|--------|--------|
| Navigation | Mega menu | Left drawer | Full-screen drawer + bottom tabs |
| Search | Inline field | Icon → overlay | Persistent field row |
| PLP filters | Left rail, instant apply | Drawer, instant apply | Full sheet, batched apply |
| Product grid | 4 across | 3 across | 2 across |
| Product rail | 5 visible + arrows | 3.5 + swipe | 2.2 + swipe |
| PDP | 7/5 split, sticky info | 6/6 split | Stacked + sticky CTA |
| PDP gallery | Thumbs left + zoom lens | Thumbs below | Swipe carousel + pinch zoom |
| Cart | 8/4 with sticky summary | 7/5 | Stacked + sticky total bar |
| Checkout | 7/5 with sticky summary | 7/5 | Stacked, collapsible summary, sticky pay bar |
| Account | Sidebar + content | Tabs + content | Menu list → drill-down |
| Compare | 4 columns | 3 columns | 2 columns + horizontal scroll |
| Modals | Centred | Centred 90vw | Full-screen sheet |
| Drawers | Right 420 | Right 80vw | Bottom sheet |
| Footer | 5 columns | 3 columns | Accordions |
| Order timeline | Horizontal | Horizontal | Vertical |
| Reviews | 2 columns | 1 column | 1 column |
| Tables | Full | Horizontal scroll | Stacked key/value cards |
