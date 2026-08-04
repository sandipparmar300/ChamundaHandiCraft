# 20 — Appendix: Master Inventory, Journeys, QA & Handoff

Enterprise Handicraft E-Commerce Platform · Customer Website UI/UX Specification

---

## A1. Master Page Inventory

Every full-page route in the storefront, with its module, layout template, primary persona and indexability.

| ID | Page | Route | Module | Layout | Primary persona | Indexed |
|----|------|-------|--------|--------|-----------------|:-------:|
| PG-02-01 | Home | `/` | 02 | SL-01 | All | ✔ |
| PG-01-01 | Sign In | `/signin` | 01 | SL-11 | All | ✖ |
| PG-01-02 | Create Account | `/register` | 01 | SL-11 | All | ✖ |
| PG-01-03 | OTP Verification | `/signin/otp` | 01 | SL-06 | All | ✖ |
| PG-01-04 | Forgot Password | `/forgot-password` | 01 | SL-06 | All | ✖ |
| PG-01-05 | Reset Password | `/reset-password` | 01 | SL-06 | All | ✖ |
| PG-01-06 | Email Verification Pending | `/verify-email` | 01 | SL-06 | All | ✖ |
| PG-01-07 | Email Verified | `/verify-email/success` | 01 | SL-06 | All | ✖ |
| PG-01-08 | Mobile Verification | `/verify-mobile` | 01 | SL-06 | All | ✖ |
| PG-01-09 | Complete Your Profile | `/complete-profile` | 01 | SL-06 | All | ✖ |
| PG-01-10 | Account Locked | `/account-locked` | 01 | SL-10 | All | ✖ |
| PG-01-11 | Welcome | `/welcome` | 01 | SL-06 | All | ✖ |
| PG-03-01 | Category Listing | `/c/{category}` | 03 | SL-02 | Rohit, Meera | ✔ |
| PG-03-02 | Sub-category Listing | `/c/{cat}/{sub}` | 03 | SL-02 | Rohit | ✔ |
| PG-03-03 | All Products | `/shop` | 03 | SL-02 | All | ✔ |
| PG-03-04 | Collection Listing | `/collections/{slug}` | 03 | SL-02 | Meera | ✔ |
| PG-03-05 | Material Listing | `/shop/material/{slug}` | 03 | SL-02 | Sara | ✔ |
| PG-03-06 | Artisan Listing | `/artisans/{slug}` | 03/19 | SL-02 | Sara | ✔ |
| PG-04-01 | Product Detail | `/p/{slug}` | 04 | SL-03 | All | ✔ |
| PG-04-03 | All Reviews | `/p/{slug}/reviews` | 04/15 | SL-08 | Rohit | ✔ |
| PG-04-04 | Customer Photos | `/p/{slug}/photos` | 04/15 | SL-01 | Rohit | ✖ |
| PG-05-01 | Compare | `/compare` | 05 | SL-09 | Rohit | ✖ |
| PG-06-01 | Wishlist | `/wishlist` | 06 | SL-01 | Sara, Rohit | ✖ |
| PG-06-02 | Shared Wishlist | `/wishlist/shared/{token}` | 06 | SL-01 | Gift recipients | ✖ |
| PG-07-01 | Cart | `/cart` | 07 | SL-04 | All | ✖ |
| PG-08-01 | Checkout | `/checkout` | 08 | SL-04 | All | ✖ |
| PG-08-02 | Guest or Sign In | `/checkout/start` | 08 | SL-06 | All | ✖ |
| PG-08-03 | Order Confirmation | `/checkout/success/{n}` | 08 | SL-07 | All | ✖ |
| PG-08-04 | Payment Pending | `/checkout/pending/{n}` | 09 | SL-06 | All | ✖ |
| PG-08-05 | Payment Failed | `/checkout/failed` | 09 | SL-06 | All | ✖ |
| PG-08-06 | Session Resume | `/checkout/resume` | 08 | SL-06 | All | ✖ |
| PG-10-01 | Account Dashboard | `/account` | 10 | SL-05 | Priya | ✖ |
| PG-10-02 | Profile | `/account/profile` | 10 | SL-05 | Priya | ✖ |
| PG-10-03 | Addresses | `/account/addresses` | 10 | SL-05 | Priya | ✖ |
| PG-10-06 | My Reviews | `/account/reviews` | 10/15 | SL-05 | Priya | ✖ |
| PG-10-07 | Notifications | `/account/notifications` | 10/17 | SL-05 | Priya | ✖ |
| PG-10-08 | Rewards & Points | `/account/rewards` | 10/16 | SL-05 | Priya | ✖ |
| PG-10-09 | My Coupons | `/account/coupons` | 10 | SL-05 | Meera | ✖ |
| PG-10-10 | Saved Cards | `/account/payment-methods` | 10 | SL-05 | Priya | ✖ |
| PG-10-11 | Security | `/account/security` | 10 | SL-05 | Priya | ✖ |
| PG-10-12 | Communication Preferences | `/account/preferences` | 10/17 | SL-05 | All | ✖ |
| PG-10-13 | Privacy & Data | `/account/privacy` | 10 | SL-05 | All | ✖ |
| PG-10-14 | Referrals | `/account/referrals` | 10/16 | SL-05 | Priya | ✖ |
| PG-11-01 | Order List | `/account/orders` | 11 | SL-05 | All | ✖ |
| PG-11-02 | Order Detail | `/account/orders/{n}` | 11 | SL-04 | All | ✖ |
| PG-11-03 | Invoice | `/account/orders/{n}/invoice` | 11 | SL-06 | Deepak-type | ✖ |
| PG-11-04 | Return Request | `/account/orders/{n}/return` | 11 | SL-06 | Meera | ✖ |
| PG-11-05 | Return Status | `/account/returns/{rma}` | 11 | SL-06 | Meera | ✖ |
| PG-12-01 | Order Tracking | `/track/{n}` | 12 | SL-06 | All | ✖ |
| PG-12-02 | Guest Tracking Form | `/track` | 12 | SL-06 | Guests | ✖ |
| PG-12-03 | Shared Tracking | `/track/shared/{token}` | 12 | SL-06 | Gift recipients | ✖ |
| PG-13-01 | Search Results | `/search?q=` | 13 | SL-02 | All | ✖ |
| PG-13-03 | Search Landing (mobile) | `/search` | 13 | SL-01 | All | ✖ |
| PG-13-04 | Visual Search Results | `/search/visual` | 13/20 | SL-02 | Rohit | ✖ |
| PG-14-01 | Help Centre | `/help` | 14 | SL-01 | All | ✔ |
| PG-14-02 | Help Category | `/help/{category}` | 14 | SL-01 | All | ✔ |
| PG-14-03 | Help Article | `/help/{cat}/{slug}` | 14 | SL-08 | All | ✔ |
| PG-14-04 | Help Search | `/help/search?q=` | 14 | SL-01 | All | ✖ |
| PG-14-05 | Contact Us | `/contact` | 14/19 | SL-11 | All | ✔ |
| PG-14-06 | Submit a Ticket | `/help/ticket/new` | 14 | SL-06 | All | ✖ |
| PG-14-07 | My Tickets | `/account/support` | 14 | SL-05 | All | ✖ |
| PG-14-08 | Ticket Detail | `/account/support/{id}` | 14 | SL-06 | All | ✖ |
| PG-15-01 | Write a Review | `/review/{orderItemId}` | 15 | SL-06 | All | ✖ |
| PG-16-03 | Rewards — How it works | `/rewards` | 16 | SL-01 | All | ✔ |
| PG-16-05 | Referral Landing | `/refer/{code}` | 16 | SL-06 | New shoppers | ✖ |
| PG-17-03 | Unsubscribe | `/unsubscribe` | 17 | SL-06 | All | ✖ |
| PG-18-01 | Blog Index | `/blog` | 18 | SL-01 | Sara | ✔ |
| PG-18-02 | Article | `/blog/{slug}` | 18 | SL-08 | Sara | ✔ |
| PG-18-03 | Blog Category | `/blog/category/{slug}` | 18 | SL-01 | Sara | ✔ |
| PG-18-04 | Blog Tag | `/blog/tag/{slug}` | 18 | SL-01 | Sara | ✔ |
| PG-18-05 | Blog Author | `/blog/author/{slug}` | 18 | SL-08 | Sara | ✔ |
| PG-19-01 | About Us | `/pages/about-us` | 19 | SL-01 | Sara | ✔ |
| PG-19-03 | FAQ | `/pages/faq` | 19 | SL-08 | All | ✔ |
| PG-19-04 | Privacy Policy | `/pages/privacy-policy` | 19 | SL-08 | All | ✔ |
| PG-19-05 | Terms & Conditions | `/pages/terms` | 19 | SL-08 | All | ✔ |
| PG-19-06 | Shipping Policy | `/pages/shipping-policy` | 19 | SL-08 | Ananya | ✔ |
| PG-19-07 | Return Policy | `/pages/return-policy` | 19 | SL-08 | Ananya | ✔ |
| PG-19-08 | Refund Policy | `/pages/refund-policy` | 19 | SL-08 | Meera | ✔ |
| PG-19-09 | Cookie Policy | `/pages/cookie-policy` | 19 | SL-08 | All | ✔ |
| PG-19-10 | Sitemap | `/sitemap` | 19 | SL-01 | All | ✔ |
| PG-19-11 | Meet the Makers | `/artisans` | 19 | SL-01 | Sara | ✔ |
| PG-19-12 | Artisan Profile | `/artisans/{slug}` | 19 | SL-08 | Sara | ✔ |
| PG-20-03 | AI Assistant (full page) | `/assistant` | 20 | SL-06 | All | ✖ |
| PG-20-04 | Gift Finder | `/gift-finder` | 20 | SL-06 | Ananya | ✔ |
| PG-SYS-01 | 404 Not Found | — | System | SL-10 | All | ✖ |
| PG-SYS-02 | 500 Server Error | — | System | SL-10 | All | ✖ |
| PG-SYS-03 | 503 Maintenance | — | System | SL-10 | All | ✖ |
| PG-SYS-04 | Offline | — | System | Banner | All | ✖ |
| PG-SYS-05 | Browser Unsupported | — | System | SL-10 | All | ✖ |
| PG-SYS-06 | 403 Forbidden | — | System | SL-10 | All | ✖ |

**Total distinct pages: 125** (including variants and system pages not separately listed above).

---

## A2. Master Overlay Inventory

| Module | Modals | Drawers | Bottom Sheets | Notable guarded dialogs |
|--------|-------:|--------:|--------------:|-------------------------|
| 01 Authentication | 10 | 1 | 4 | Sign out, Merge guest cart |
| 02 Home | 6 | 2 | 3 | Cookie consent |
| 03 Shop / PLP | 8 | 3 | 5 | Clear all filters (mobile) |
| 04 Product Details | 14 | 4 | 6 | Price change acknowledgement |
| 05 Compare | 4 | 1 | 2 | Clear comparison |
| 06 Wishlist | 6 | 1 | 2 | Clear wishlist, Delete list |
| 07 Cart | 8 | 2 | 4 | Remove item, Coupon conflict |
| 08 Checkout | 12 | 2 | 5 | Leave checkout, Cart changed, Session expiring |
| 09 Payment | 10 | 1 | 3 | COD confirmation, Cancel payment, Leave during processing |
| 10 My Account | 16 | 2 | 6 | Delete account, Delete card, Sign out all sessions |
| 11 Orders | 12 | 2 | 4 | Cancel order, Confirm return |
| 12 Order Tracking | 5 | 1 | 2 | Change address, Reschedule |
| 13 Search | 4 | 2 | 3 | Clear recent searches |
| 14 Customer Support | 10 | 2 | 4 | Close ticket, End chat |
| 15 Reviews | 10 | 2 | 3 | Delete review, Discard draft |
| 16 Rewards | 8 | 1 | 2 | — |
| 17 Notifications | 6 | 2 | 2 | Turn off all marketing, Clear all |
| 18 Blog | 5 | 1 | 2 | Report comment |
| 19 Static Pages | 4 | – | 2 | Leave contact form |
| 20 AI Shopping | 8 | 3 | 4 | Clear AI history, Turn off personalisation |
| System | 3 | – | 1 | Session expired |
| **Total** | **169** | **35** | **69** | — |

---

## A3. Journey Map Library

| ID | Journey | Persona | Modules traversed | Documented in |
|----|---------|---------|-------------------|---------------|
| J-01 | First purchase, mobile, guest, gift | Ananya | 02 → 03 → 04 → 07 → 08 → 09 → 12 → 15 | `01-CX-Foundations §3.1` |
| J-02 | Considered purchase across 3 sessions and 2 devices | Rohit | 13 → 03 → 04 → 05 → 06 → 07 → 08 | `01-CX-Foundations §3.2` |
| J-03 | Abandoned cart recovery | All | 07 → email/WhatsApp → 07 → 08 | `01-CX-Foundations §3.3` |
| J-04 | Damaged delivery service recovery | Meera | 11 → 11 (return) → 09 (refund) | `01-CX-Foundations §3.4` |
| J-05 | Account creation after purchase | Ananya | 08 → 01 | `10-Modules-01-02 §1.3` |
| J-06 | Festival shopping burst | Meera | 02 → 03 → 07 → 08 → 09 (COD) | `10-Modules-01-02 §2.3` |
| J-07 | Filter-driven narrowing | Rohit | 03 | `11-Modules-03-13 §3.3` |
| J-08 | Search with typo and correction | Priya | 13 → 04 | `11-Modules-03-13 §13.3` |
| J-09 | PDP evaluation with anxiety points | Rohit | 04 | `12-Modules-04-05-06 §4.3` |
| J-10 | Comparison to decision | Rohit | 03 → 05 → 07 | `12-Modules-04-05-06 §5.3` |
| J-11 | Wishlist save → price drop → purchase | Sara | 06 → 17 → 06 → 07 | `12-Modules-04-05-06 §6.3` |
| J-12 | Cart optimisation to free shipping | Meera | 07 | `13-Modules-07-08-09 §7.3` |
| J-13 | Guest checkout end to end | Ananya | 08 → 09 | `13-Modules-07-08-09 §8.3` |
| J-14 | Payment failure and recovery to COD | Meera | 09 | `13-Modules-07-08-09 §9.3` |
| J-15 | Second purchase in under 60 seconds | Priya | 10 → 07 → 08 | `14-Modules-10-11-12 §10.3` |
| J-16 | Self-service return with photos | Meera | 11 | `14-Modules-10-11-12 §11.3` |
| J-17 | Tracking a gift and sharing it | Meera | 12 | `14-Modules-10-11-12 §12.3` |
| J-18 | Help search → escalation to WhatsApp | Sara | 14 | `15-Modules-14-17 §14.3` |
| J-19 | Review request → submission → points | Meera | 17 → 15 → 16 | `15-Modules-14-17 §15.3` |
| J-20 | Earning and redeeming points | Priya | 16 → 08 | `15-Modules-14-17 §16.3` |
| J-21 | Notification preference correction | Meera | 17 | `15-Modules-14-17 §17.3` |
| J-22 | Organic article → product purchase | Sara | 18 → 04 → 07 | `16-Modules-18-19 §18.3` |
| J-23 | Policy check during purchase decision | Ananya | 04 → 19 → 04 → 07 | `16-Modules-18-19 §19.3` |
| J-24 | AI-assisted gift discovery | Ananya | 20 → 04 → 07 | `17-Module-20 §20.3` |

---

## A4. Prototype Flow Map

| ID | Prototype | Start | Screens | Device | Purpose |
|----|-----------|-------|---------|--------|---------|
| SP-01 | Discover → Buy (mobile, guest) | Home 390 | ~22 | 390 | Usability testing |
| SP-02 | Discover → Buy (desktop, signed in) | Home 1440 | ~20 | 1440 | Usability testing |
| SP-03 | Search → Filter → PDP → Cart | Search overlay | ~16 | 390 | Usability testing |
| SP-04 | Full checkout, all payment methods | Cart | ~28 | 390 + 1440 | Payment QA + stakeholder |
| SP-05 | Guest checkout, new address | Cart | ~18 | 390 | Usability testing |
| SP-06 | Account, orders, tracking, return | Account | ~24 | 390 | Usability testing |
| SP-07 | Wishlist and Compare | PLP | ~16 | 1440 | Usability testing |
| SP-08 | Reviews: read, filter, write | PDP reviews | ~14 | 390 | Content review |
| SP-09 | AI assistant journey + blog to product | Home | ~20 | 390 | Stakeholder demo |
| SP-10 | Error and recovery paths | Cart | ~18 | 390 | QA + stakeholder |
| SP-11 | Authentication (all methods) | Sign In | ~16 | 390 | Usability testing |
| SP-12 | Full navigation walkthrough | Home | ~30 | 1440 | Executive demo |

---

## A5. Cross-Module Interaction Map

| Source event | Target effect |
|--------------|---------------|
| Add to cart (any surface) | Cart badge, mini cart, free-shipping progress, recommendation refresh |
| Add to wishlist (guest) | Session wishlist + one-time sign-in nudge |
| Sign in | Guest cart merge, guest wishlist merge, saved addresses available, points visible |
| PIN entered (PDP) | Reused on cards, cart, checkout for 30 days |
| Variant selected (PDP) | Price, gallery, stock, SKU, delivery estimate, URL |
| Coupon applied (cart) | Carries into checkout, shown in summary, reversible |
| Order placed | Confirmation, notifications across channels, points pending, tracking created, account prompt for guests |
| Order delivered | Review request scheduled (5 days), points awarded, return window opens |
| Return requested | Refund tracker created, order status updated, pickup scheduled |
| Refund issued | Points from that order reversed proportionally, notification sent |
| Review published | Product rating aggregate updated, points awarded, AI summary regeneration queued |
| Review deleted | Points reversed (stated in the confirmation), aggregate updated |
| Price drop on a saved item | Wishlist badge, notification per preferences |
| Back in stock | Notify-me list triggered, wishlist badge |
| Notification preference change | Honoured immediately by all sending services |
| Personalisation turned off | Home reverts to editorial bands, AI recommendations disabled |
| AI search interpretation | Populates real filter chips on the PLP |
| Cookie consent rejected | Non-essential scripts never load; personalisation disabled |
| Account deleted | 30-day grace; order and tax records retained and disclosed |

---

## A6. Conversion Instrumentation Summary

The complete event catalogue lives in `01-CX-Foundations §15` and per-module in each chapter's §40. This is the minimum set that must be live at launch for the funnel to be measurable:

| Funnel step | Required events |
|-------------|-----------------|
| Discovery | `view_item_list`, `select_item`, `search`, `filter_apply`, `sort_apply` |
| Evaluation | `view_item`, `gallery_interact`, `variant_select`, `delivery_check`, `review_section_view` |
| Intent | `add_to_cart`, `add_to_wishlist`, `compare_add` |
| Cart | `view_cart`, `update_quantity`, `remove_from_cart`, `apply_coupon` |
| Checkout | `begin_checkout`, `checkout_step_complete`, `add_shipping_info`, `add_payment_info` |
| Purchase | `purchase`, `purchase_failed` |
| Retention | `view_order_detail`, `track_order_click`, `review_submit`, `buy_again` |
| Assistance | `ai_session_start`, `support_escalate`, `help_article_view` |

Every event must carry: `session_id`, `user_id` (when signed in), `device`, `breakpoint`, `page_type`, and — for commerce events — the full item payload.

---

## A7. Performance Budget Summary

| Page | LCP element | LCP budget | Total weight | CLS | Notes |
|------|-------------|-----------:|-------------:|----:|-------|
| Home | Hero slide 1 image | 2.5 s | 1.2 MB | 0.05 | Carousel initialises after LCP |
| PLP | First product card image row | 2.5 s | 900 KB initial | 0.05 | 24 products per page |
| PDP | First gallery image | 2.5 s | 1.4 MB | 0.05 | Zoom source loads on demand |
| Cart | Line item image 1 | 2.0 s | 600 KB | 0.02 | No marketing media |
| Checkout | First section render | 1.8 s | 400 KB | 0.00 | No imagery beyond summary thumbnails |
| Search results | First card row | 2.5 s | 900 KB | 0.05 | Suggestions debounce 200 ms |
| Article | Cover image | 2.5 s | 1.0 MB | 0.05 | In-body media lazy |
| Policy pages | Text | 1.2 s | 150 KB | 0.00 | No imagery, no third-party scripts |
| Account | Text + stat cards | 2.0 s | 500 KB | 0.02 | — |

**Global rules:** every image container reserves its aspect ratio; web fonts capped at 180 KB across two families and four weights; no more than three third-party scripts above the fold; chat and pixel scripts load on idle or interaction.

---

## A8. Accessibility Conformance Checklist (per screen)

- [ ] Single H1; heading hierarchy unbroken
- [ ] All text ≥4.5:1; large text and non-text UI ≥3:1, verified in both themes
- [ ] Visible focus on every interactive element; logical focus order
- [ ] Fully operable by keyboard alone, including all overlays
- [ ] Colour never the sole carrier of meaning
- [ ] Every input has a persistent visible label and correct autocomplete
- [ ] Errors linked to fields and announced
- [ ] All images have appropriate alt text; decorative images marked
- [ ] Carousels expose slide count, current slide and a pause control
- [ ] Modals, drawers and sheets trap focus and restore it on close
- [ ] Live regions used correctly (polite for status, assertive for errors)
- [ ] Motion respects `prefers-reduced-motion`
- [ ] Touch targets ≥44 px (tablet) / ≥48 px (mobile) with ≥8 px separation
- [ ] Usable at 200% zoom; readable at 400% in single-column reflow
- [ ] Star ratings, prices and counts have numeric accessible names
- [ ] Cart and wishlist count changes announced
- [ ] No time limit without warning and extension
- [ ] Video has captions; craft-process video has a transcript
- [ ] Skip link is the first tab stop

---

## A9. Design QA Checklist (per screen)

**Structure**
- [ ] Mobile 390, Tablet 768 and Desktop 1440 exist (or a documented "no change")
- [ ] Layout matches the module spec's template
- [ ] Shell regions correct for context (full vs minimal header/footer)
- [ ] Breadcrumb matches the spec exactly

**States**
- [ ] Loading (initial and in-place), loaded, sparse, empty (none), empty (filtered), error, offline, signed-out, out-of-stock
- [ ] All interactive states: default, hover, active, focus, disabled, loading
- [ ] Dark theme verified, with product images on a light inner backdrop

**System usage**
- [ ] Zero detached instances; zero local styles
- [ ] Spacing, colour and type inspect as Variable names
- [ ] Image containers have locked aspect ratios

**Content**
- [ ] Copy matches the module spec verbatim
- [ ] Real handicraft product data and photography
- [ ] Edge cases present: long name, missing image, out of stock, no rating, heavy discount
- [ ] Currency, dates and dimensions formatted per `01-CX-Foundations §7.5`

**Conversion & trust**
- [ ] Funnel step intact; no added friction
- [ ] No dark patterns (checked against `01-CX-Foundations §8.1`)
- [ ] Trust elements present where specified
- [ ] Variation notice present on handmade surfaces

**Performance**
- [ ] LCP element marked
- [ ] Lazy-load boundary drawn
- [ ] Image budgets respected

**Handoff**
- [ ] Annotations complete: behaviour, validation, content, API, a11y, analytics, performance
- [ ] Prototype linked for multi-step flows
- [ ] Assets marked for export
- [ ] Frame status 🟢 APPROVED after all nine gates

---

## A10. Suggested Delivery Phasing

| Phase | Scope | Modules | Rationale |
|-------|-------|---------|-----------|
| **P0 — Foundations** | Tokens, components, shell, system pages | DS, System | Nothing builds without these |
| **P1 — Buy** | Home, PLP, PDP, Cart, Checkout, Payment, Order Confirmation | 02, 03, 04, 07, 08, 09 | The minimum path to revenue |
| **P2 — Trust & Return** | Auth, Account, Orders, Tracking, Search | 01, 10, 11, 12, 13 | Retention and support deflection |
| **P3 — Persuade** | Wishlist, Compare, Reviews, Support | 05, 06, 15, 14 | Conversion and confidence |
| **P4 — Retain** | Rewards, Notifications, Blog, Static | 16, 17, 18, 19 | Repeat purchase and organic growth |
| **P5 — Assist** | AI features | 20 | Differentiation, once the fundamentals are solid |

Design runs one phase ahead of engineering. Each phase ends with a usability test on its primary prototype and a performance audit against §A7.

---

## A11. Open Decisions Register

| # | Decision | Options | Owner | Consequence of deferring |
|---|----------|---------|-------|--------------------------|
| D-01 | Guest wishlist cap | 25 items vs unlimited | Product | Affects the sign-in nudge design |
| D-02 | COD threshold | ₹15,000 vs lower | Finance | Payment method eligibility copy |
| D-03 | Return window | 7 vs 14 days | Operations | Policy copy and return-window indicators |
| D-04 | Points earn rate | 10 per ₹100 vs tiered | Marketing | Rewards copy and redemption caps |
| D-05 | Review incentive | Points vs none | Marketing/Legal | Disclosure requirements on the review form |
| D-06 | AI assistant scope at launch | Discovery only vs discovery + orders | Product | Assistant capability list and handoff rules |
| D-07 | Hindi launch scope | Full storefront vs key pages | Product | Localisation coverage and text-expansion testing |
| D-08 | Multi-currency at launch | INR only vs INR + USD/GBP | Finance | Currency selector, landed-cost display |
| D-09 | Live chat hours | Business hours vs extended | Support | Channel availability states |
| D-10 | Personalised home | On by default vs opt-in | Product/Legal | Home band composition and consent flow |
| D-11 | Sponsored placements | Allowed vs not | Commercial | Product card badge and labelling rules |
| D-12 | PWA / install prompt | In scope vs later | Engineering | Offline shell and install banner |

Each open decision has a reserved affordance or a stated assumption in the design, so resolving it will not force restructuring.

---

## A12. Document Completeness Statement

This customer-website specification covers:

- **125** full pages with routes, layouts, personas and indexability
- **169** modals, **35** drawers and **69** bottom sheets, each with type, trigger, content and actions
- **20** modules documented against an identical 40-section template, plus 24-field detail blocks on key screens
- **140** UI components with variants, states, sizes, behaviour and responsive rules
- **6** shopper personas with a module priority matrix
- **24** documented customer journeys with Mermaid diagrams
- **12** layout templates and **6** breakpoints, designed mobile-first at 390 px
- Complete design tokens: warm-neutral colour system (light, dark, campaign modes), Fraunces + Inter type system, spacing, elevation, radius, motion, iconography, photography direction
- Validation rules with exact shopper-facing messages for every form
- Loading, sparse, empty, filtered-empty, error, offline, signed-out and out-of-stock states for every data surface
- WCAG 2.1 AA requirements at global, component and module level, with announcement maps
- An explicit anti-dark-pattern charter and a trust framework with defined component placements
- Performance budgets per page with the LCP element identified
- Analytics events per module and a minimum launch instrumentation set
- Figma organisation: file architecture, page and section structure, naming, Variables (colour, typography, spacing, grid), auto-layout trees, variant matrices, 12 prototypes, nine QA gates and developer handoff notes
- Mermaid diagrams for navigation, journeys and funnels; ASCII wireframes at desktop and mobile for every significant screen

A Product Designer can open Figma and build this storefront from these documents without further clarification, except where §A11 records an explicitly open business decision.

---

## A13. Relationship to the Admin Specification

| Concern | Where it is specified |
|---------|----------------------|
| Product catalogue management | Admin `11-Module-03-Product-Management.md` |
| Category structure and menu ordering | Admin `12-Modules-04-05` |
| Stock, delivery promise source data | Admin `12-Modules-04-05` (Inventory) |
| Order state machine and fulfilment | Admin `13-Module-06-Order-Management.md` |
| Payment gateway configuration and refunds | Admin `14-Modules-07-08` |
| Shipping zones, rates and courier integration | Admin `14-Modules-07-08` |
| Coupons, offers and banners the storefront renders | Admin `15-Modules-09-11` |
| CMS pages, blog and testimonials | Admin `16-Modules-12-15` |
| Review moderation | Admin `16-Modules-12-15` (Module 14) |
| Newsletter and notification templates | Admin `17-Modules-16-18` |
| Reporting on every storefront event | Admin `17-Modules-16-18` (Module 18) |
| SEO configuration, redirects, structured data | Admin `18-Modules-19-20` |
| Store settings driving storefront behaviour | Admin `18-Modules-19-20` (Module 20) |

**Shared contracts that must not diverge:** delivery promise service, price and stock source, coupon validation service, order status vocabulary, review verification rules, tax display rules, and the primitive design tokens.
