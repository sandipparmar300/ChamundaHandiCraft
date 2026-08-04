# 04 — Figma Organization & Developer Handoff

Enterprise Handicraft E-Commerce Platform · UI/UX Design Specification

---

## 1. Figma File Architecture

The design lives in **one Figma Team** with **four files** in a project named `Handicraft Commerce — Admin`.

| File | Purpose | Published as library |
|------|---------|---------------------|
| `01 · Karigar DS — Foundations` | Variables, styles, tokens, icons, illustrations, grids | ✅ Yes |
| `02 · Karigar DS — Components` | All component sets from `03-Component-Library.md` | ✅ Yes |
| `03 · Admin Panel — Product Design` | Every screen, every state, every breakpoint | ❌ No |
| `04 · Admin Panel — Prototypes` | Interactive flows for testing & stakeholder demos | ❌ No |

**Rule:** `03` consumes `01` and `02`. Nothing is drawn from scratch in `03` that could be a component in `02`.

---

## 2. File 01 — Foundations: Page Structure

| Page | Contents |
|------|----------|
| `📖 Cover` | Project name, version, owner, last updated, status |
| `📐 00 Guidelines` | How to use this library, contribution rules, naming rules |
| `🎨 01 Colour` | Primitive swatches, semantic mapping table, contrast proofs, light/dark comparison |
| `🔤 02 Typography` | Type scale specimens, usage examples, do/don't |
| `📏 03 Spacing & Grid` | Spacing scale, layout grids, column templates L-01…L-10 |
| `🌑 04 Elevation & Radius` | Shadow specimens, radius specimens |
| `⚡ 05 Motion` | Duration/easing specimens with animated prototypes |
| `🧩 06 Iconography` | Full icon set as components, sized variants, craft icon set |
| `🖼 07 Illustrations` | Empty state, error state, success, onboarding — light & dark variants |
| `🏷 08 Logos & Brand` | Logo lockups, payment gateway logos, courier logos |
| `📊 09 Data Viz` | Chart colour ramps, series specimens, greyscale proofs |
| `♿ 10 Accessibility` | Contrast matrix, focus specimens, touch target overlays |

---

## 3. File 02 — Components: Page Structure

| Page | Component sets |
|------|----------------|
| `📖 Cover` | — |
| `🔘 01 Actions` | Button, Icon Button, Button Group, Split Button, Link, FAB |
| `⌨ 02 Inputs` | Text Field, Textarea, Number, Currency, Password, Select, Multi-Select, Combobox, Checkbox, Radio, Switch, Segmented, Slider, Tag Input |
| `📅 03 Date & Time` | Date Picker, Date Range, Time Picker, Date-Time, Calendar cell |
| `📝 04 Forms` | Field Wrapper, Form Section, Fieldset, Rich Text Editor, File Upload, Image Upload, Cropper |
| `🗂 05 Surfaces` | Card, Stat Card, Panel, Widget Frame, Divider |
| `📋 06 Data Display` | Data Table (+ cells, header, row states), Pagination, Bulk Bar, Filter Bar, Filter Chip, Search, Saved View, Column Manager, Tree, Description List, Timeline, Activity Feed, Kanban |
| `🧭 07 Navigation` | Sidebar, Sidebar Item, Top Bar, Breadcrumb, Tabs, Stepper, Accordion, Menu, Footer, Page Header, Command Palette |
| `🪟 08 Overlays` | Modal (all sizes/types), Drawer, Popover, Tooltip, Lightbox |
| `💬 09 Feedback` | Toast, Alert, Inline Message, Progress, Spinner, Skeleton, Empty State, Error State, Success State |
| `🔖 10 Indicators` | Badge, Status Chip, Tag, Label, Counter, Rating, Avatar, Avatar Group, Profile Card, Kbd |
| `🖼 11 Media` | Gallery, Carousel, Media Tile, Image Placeholder |
| `📈 12 Charts` | Line, Bar, Donut, Area, Sparkline, Funnel, Heatmap, Gauge, Legend, Tooltip, Axis |
| `🖨 13 Print` | Invoice template, Shipping label, Packing slip, Barcode sheet, Report cover |
| `✅ 14 Usage Examples` | Correct vs incorrect usage boards |

---

## 4. File 03 — Product Design: Page Structure

One Figma page per module, plus system pages. Pages are numbered so they sort correctly.

| Page | Contents |
|------|----------|
| `📖 00 Cover & Index` | Screen map, status legend, change log |
| `🗺 00a Information Architecture` | Sitemap, navigation model, user flows |
| `🔐 00b Auth & System` | Login, Forgot/Reset Password, 2FA, Lockout, Session Timeout, 404, 500, 403, Maintenance, Offline |
| `🏠 01 Dashboard` | Module 1 |
| `👥 02 User Management` | Module 2 |
| `📦 03 Product Management` | Module 3 |
| `🗂 04 Category Management` | Module 4 |
| `🏭 05 Inventory` | Module 5 |
| `🛒 06 Order Management` | Module 6 |
| `💳 07 Payment Management` | Module 7 |
| `🚚 08 Shipping` | Module 8 |
| `🎟 09 Coupons` | Module 9 |
| `🏷 10 Offers` | Module 10 |
| `🖼 11 Banners` | Module 11 |
| `📄 12 CMS` | Module 12 |
| `📰 13 Blog` | Module 13 |
| `⭐ 14 Reviews` | Module 14 |
| `💬 15 Testimonials` | Module 15 |
| `✉ 16 Newsletter` | Module 16 |
| `🔔 17 Notifications` | Module 17 |
| `📊 18 Reports` | Module 18 |
| `🔍 19 SEO` | Module 19 |
| `⚙ 20 Settings` | Module 20 |
| `👤 21 Profile & Preferences` | My Profile, Security, Preferences, My Activity |
| `📱 90 Mobile Screens` | Consolidated mobile-only frames (bottom nav, sheets, scanner) |
| `🖨 91 Print Artefacts` | Filled examples of every printable |
| `🧪 92 Explorations` | Discarded/parked ideas — never referenced by dev |
| `🗄 99 Archive` | Superseded designs with date stamps |

### 4.1 Section Structure Within a Module Page

Every module page uses Figma **Sections** in this fixed order:

```
▸ SECTION: 00 · Module Overview        (documentation frames — flows, screen map, permissions)
▸ SECTION: 01 · Desktop — 1440         (all desktop screens)
▸ SECTION: 02 · Desktop — States       (loading/empty/error/no-permission variants)
▸ SECTION: 03 · Modals & Dialogs
▸ SECTION: 04 · Drawers & Panels
▸ SECTION: 05 · Tablet — 768
▸ SECTION: 06 · Mobile — 375
▸ SECTION: 07 · Dark Theme (spot checks + any divergent screens)
▸ SECTION: 08 · Annotations & Redlines
```

Section colours: Overview = grey, Desktop = blue, States = amber, Modals = purple, Tablet = teal, Mobile = green, Dark = near-black, Annotations = red.

---

## 5. Frame Specification

### 5.1 Standard Frame Sizes

| Name | Size | Use |
|------|------|-----|
| `Desktop / 1440` | 1440 × auto (min 900) | **Primary design size** |
| `Desktop / 1920` | 1920 × auto | Large-screen verification only |
| `Desktop / 1280` | 1280 × auto | Minimum desktop verification |
| `Tablet / 1024` | 1024 × auto | Landscape tablet |
| `Tablet / 768` | 768 × auto | **Primary tablet size** |
| `Mobile / 375` | 375 × auto | **Primary mobile size** |
| `Mobile / 414` | 414 × auto | Large phone verification |
| `Modal / {size}` | Per modal width | Isolated modal frames |
| `Doc / A4` | 1240 × 1754 @150dpi | Print artefacts |
| `Label / 4x6` | 600 × 900 @150dpi | Shipping labels |

Frames use "auto height" — content grows downward. Never fix a page frame height and clip content.

### 5.2 Frame Naming Convention

```
[{SCREEN-ID}] {Module} / {Screen Name} / {Variant} — {Breakpoint}

Examples:
[SCR-03-01] Products / Product List / Default — Desktop 1440
[SCR-03-01] Products / Product List / Empty — Desktop 1440
[SCR-03-01] Products / Product List / Loading — Desktop 1440
[SCR-03-01] Products / Product List / Default — Mobile 375
[MOD-03-05] Products / Bulk Price Update / Step 1 — Modal 640
[DRW-06-01] Orders / Order Quick View / Default — Drawer 480
```

### 5.3 Frame Status Badge

Every screen frame carries a status badge component pinned to its top-left, outside the frame bounds:

| Badge | Meaning |
|-------|---------|
| 🔴 `DRAFT` | In progress, do not build |
| 🟡 `REVIEW` | Awaiting design/PO review |
| 🟢 `APPROVED` | Ready for development |
| 🔵 `BUILT` | Implemented, matches production |
| ⚫ `DEPRECATED` | Superseded — see linked replacement |

---

## 6. Layer Naming Convention

| Layer type | Pattern | Example |
|------------|---------|---------|
| Section container | `SECTION / {name}` | `SECTION / Product Details` |
| Region | `REGION / {name}` | `REGION / Toolbar` |
| Component instance | Keep component name; rename only when semantically needed: `{Component} — {purpose}` | `Button — Save Product` |
| Text layer | `txt / {purpose}` | `txt / Page Title` |
| Image | `img / {subject}` | `img / Product Thumbnail` |
| Icon | `icon / {name}` | `icon / trash-2` |
| Group | `grp / {purpose}` | `grp / Price Fields` |
| Auto Layout stack | `stack-v / {purpose}` or `stack-h / {purpose}` | `stack-v / Form Fields` |
| Spacer | `spacer / {size}` | `spacer / 24` |
| Annotation | `note / {topic}` | `note / Validation Rules` |
| Placeholder | `ph / {what}` | `ph / Chart Area` |

**Forbidden layer names:** `Frame 123`, `Group 4`, `Rectangle 7`, `Vector`, `Ellipse 2`. A file with any auto-generated layer name fails design QA.

---

## 7. Figma Variables

### 7.1 Collections

| Collection | Modes | Scoping |
|------------|-------|---------|
| `1 · Primitives` | Single (`Value`) | Colour only; hidden from publishing |
| `2 · Semantic` | `Light`, `Dark`, `High Contrast` | Colour |
| `3 · Spacing` | Single | Width/height/gap/padding |
| `4 · Radius` | Single | Corner radius |
| `5 · Typography` | Single | Font size, line height, weight, letter spacing |
| `6 · Sizing` | `Desktop`, `Tablet`, `Mobile` | Component heights, sidebar width, container max |
| `7 · Effects` | `Light`, `Dark` | Shadows |
| `8 · Content` | `EN`, `HI` | Strings for localisation testing |

### 7.2 Variable Naming

```
color/bg/canvas
color/bg/surface
color/text/primary
color/border/default
color/action/primary/bg
color/action/primary/bg-hover
color/status/success/text
color/chart/series-01

space/md
radius/lg
size/control/md
size/sidebar/expanded
type/body-md/size
type/body-md/line-height
effect/elevation-2
```

### 7.3 Mode Switching Rules

- Every top-level screen frame has the `Semantic` collection mode applied explicitly (`Light` by default).
- Dark-theme boards are created by duplicating the frame and switching the mode — **never** by manually recolouring.
- The `Sizing` collection mode is set per breakpoint frame so component heights adapt automatically.

---

## 8. Styles vs Variables Policy

| Use Variables for | Use Styles for |
|-------------------|----------------|
| All colours | Text styles (composite of size/weight/line-height/tracking) |
| All spacing | Effect styles (composite shadows) |
| All radii | Grid styles (layout grids) |
| Component sizing | — |

Text style naming: `{Category}/{Token}` → `Heading/heading-lg`, `Body/body-md`, `Numeric/numeric-xl`, `Mono/mono-md`, `Overline/overline`.

Effect style naming: `Elevation/01` … `Elevation/05`, `Focus/Ring`, `Inset/Pressed`.

Grid style naming: `Grid/Desktop-12`, `Grid/Tablet-8`, `Grid/Mobile-4`, `Baseline/4px`.

---

## 9. Auto Layout Standards

### 9.1 Global Rules

| Rule | Detail |
|------|--------|
| AL-01 | Every frame that contains more than one child uses Auto Layout. Absolute positioning is permitted only for overlay badges, drag handles and decorative art. |
| AL-02 | Padding and gap values come from the Spacing collection — never typed numbers. |
| AL-03 | Page-level stacks are vertical, `Fill` width, `Hug` height. |
| AL-04 | Text layers inside Auto Layout are set to `Fill` width and `Auto height` so they wrap, not truncate — except where truncation is specified. |
| AL-05 | Use "Absolute position" only inside a parent that has Auto Layout, never as a substitute for it. |
| AL-06 | Min/max width constraints are set on containers that must respect content width limits (e.g. form column max 720). |
| AL-07 | Every component exposes sensible resizing: buttons Hug by default with a `Width: Fill` variant; inputs Fill by default. |

### 9.2 Canonical Auto Layout Trees

**List Page**
```
Frame: Screen (V, Fill × Hug, gap 0)
├── Instance: TopBar (Fill × 64, fixed)
└── Frame: Body (H, Fill × Fill, gap 0)
    ├── Instance: Sidebar (264 × Fill, fixed)
    └── Frame: Workspace (V, Fill × Fill, padding 0, gap 0)
        ├── Instance: Breadcrumb Bar (Fill × 44)
        ├── Frame: Content (V, Fill × Hug, padding 24, gap 24)
        │   ├── Instance: Page Header (Fill × Hug)
        │   ├── Instance: Filter Bar (Fill × Hug)
        │   ├── Instance: Bulk Bar (Fill × Hug)  [visible when selection > 0]
        │   ├── Instance: Data Table (Fill × Hug)
        │   └── Instance: Pagination (Fill × 56)
        └── Instance: Footer (Fill × 48)
```

**Form Page (L-02: Main + Sidebar)**
```
Frame: Content (V, Fill × Hug, padding 24, gap 24)
├── Instance: Page Header
├── Frame: Columns (H, Fill × Hug, gap 24)
│   ├── Frame: Main (V, Fill × Hug, gap 24)      ← 8 cols
│   │   ├── Instance: Card / Basic Information
│   │   ├── Instance: Card / Pricing
│   │   └── Instance: Card / Media
│   └── Frame: Rail (V, 360 fixed × Hug, gap 24)  ← 4 cols
│       ├── Instance: Card / Status
│       ├── Instance: Card / Organisation
│       └── Instance: Card / SEO Preview
└── Instance: Sticky Action Bar (Fill × 72)
```

**Table Row**
```
Component: Table Row (H, Fill × 52, padding 0 16, gap 16, align centre)
├── Instance: Checkbox (48 fixed, centre)
├── Instance: Thumbnail (48 fixed)
├── Frame: Primary Cell (V, Fill × Hug, gap 2)
│   ├── txt / Name        (Fill, truncate 1 line)
│   └── txt / Secondary   (Fill, truncate 1 line)
├── txt / SKU (140 fixed, mono)
├── txt / Category (160 fixed)
├── txt / Price (120 fixed, right)
├── Instance: Stock Indicator (100 fixed, right)
├── Instance: Status Chip (120 fixed, centre)
└── Instance: Row Actions (96 fixed, right)
```

**Modal**
```
Component: Modal (V, 640 × Hug, radius 12, elevation-4)
├── Frame: Header (H, Fill × 64, padding 20 24, gap 12, align centre)
│   ├── Instance: Icon (optional)
│   ├── Frame: Titles (V, Fill × Hug, gap 2)
│   └── Instance: Icon Button / Close
├── Frame: Body (V, Fill × Hug, padding 24, gap 20, max-height 60vh, scroll)
└── Frame: Footer (H, Fill × 72, padding 16 24, gap 12, justify space-between)
    ├── Frame: Left slot (helper text / secondary)
    └── Frame: Right slot (H, Hug, gap 12) → Cancel, Primary
```

---

## 10. Component Construction Standards

| Rule | Detail |
|------|--------|
| C-01 | Build the **base** component first with all Auto Layout, then add variants. |
| C-02 | Variant property names are Title Case and consistent across the library: `Size`, `Variant`, `State`, `Type`, `Icon`, `Width`, `Density`, `Placement`, `Tone`. |
| C-03 | Boolean properties for optional elements: `Has Leading Icon`, `Has Helper`, `Has Badge`, `Is Required`. |
| C-04 | Text properties expose all editable strings: `Label`, `Placeholder`, `Helper Text`, `Value`, `Count`. |
| C-05 | Instance swap properties for icons and nested components: `Leading Icon`, `Trailing Icon`, `Avatar`. |
| C-06 | Default variant = the most common real-world usage (e.g. Button → Primary / MD / Default / No Icon / Hug). |
| C-07 | Every component has a description containing: purpose, when to use, when NOT to use, a11y notes, and the spec section reference (`See 03-Component-Library §12`). |
| C-08 | Nested components use `Fill` sizing so parents control width. |
| C-09 | Component sets are laid out in a grid ordered by the primary variant property, with a labelled header row. |
| C-10 | No hidden layers left in components; use boolean properties instead. |
| C-11 | Interactive states are built as variants AND wired with "Change to" interactions (While hovering / While pressing) so prototypes feel real. |
| C-12 | Deprecated components are renamed with a `⚠ [DEPRECATED] ` prefix and kept for one release. |

---

## 11. Prototype Strategy

### 11.1 Prototype Files

| Prototype | Flow | Starting frame | Audience |
|-----------|------|----------------|----------|
| `PT-01` | Product creation end-to-end | Product List | Usability testing |
| `PT-02` | Order fulfilment (New → Delivered) | Order Queue | Usability testing |
| `PT-03` | Return & refund | Order Detail | Stakeholder demo |
| `PT-04` | Inventory receiving with scanner | Inventory Dashboard | Warehouse testing |
| `PT-05` | Campaign launch (coupon + banner + newsletter) | Marketing Dashboard | Stakeholder demo |
| `PT-06` | New admin onboarding & permissions | Admin Users | Stakeholder demo |
| `PT-07` | Reporting & export | Reports Home | Finance review |
| `PT-08` | Mobile order management | Mobile Dashboard | Mobile testing |
| `PT-09` | Content publishing (blog + CMS + SEO) | Blog List | Content team review |
| `PT-10` | Full navigation walkthrough | Dashboard | Executive demo |

### 11.2 Interaction Standards

| Interaction | Trigger | Animation |
|-------------|---------|-----------|
| Navigate to page | On click | Instant (or Smart Animate 200ms for in-page changes) |
| Open modal | On click | Open overlay, Move in from bottom 8px + Dissolve, 320ms, Ease Out |
| Close modal | On click / key ESC | Close overlay, Dissolve 240ms |
| Open drawer | On click | Open overlay, Move In from Right, 320ms, Ease Out |
| Open dropdown/menu | On click | Open overlay, Dissolve 150ms |
| Tooltip | While hovering | Open overlay, Dissolve 150ms, delay 300ms |
| Toast | After delay 300ms | Move In from Right, then After Delay 4000ms → Close |
| Tab switch | On click | Smart Animate 240ms Ease Out |
| Accordion | On click | Smart Animate 240ms Ease Out |
| Hover states | While hovering | Change To variant, 80ms |
| Press states | While pressing | Change To variant, 80ms |
| Loading → Loaded | After delay 800ms | Dissolve 240ms |
| Scroll behaviour | — | Fixed position on TopBar, Sidebar, Breadcrumb, Sticky Action Bar |

### 11.3 Prototype Hygiene

- Every prototype has a "Start Here" frame with the scenario, persona and task list.
- Dead ends are prohibited: every screen links back to at least its parent.
- Overlays close on scrim click.
- Realistic content only — no lorem ipsum in prototypes used for testing.
- Prototype settings: Device = Desktop (1440), Background = `neutral-200`.

---

## 12. Content & Data Population Standards

| Data type | Rule |
|-----------|------|
| Product names | Real handicraft names: "Blue Pottery Vase — Jaipur", "Brass Diya Set of 5", "Kantha Embroidered Cushion Cover", "Channapatna Wooden Elephant", "Pashmina Shawl — Kani Weave" |
| Artisan names | Plausible, varied regional Indian names with craft cluster labels |
| SKUs | `HC-{CATEGORY}-{5 digits}` e.g. `HC-POT-10241` |
| Order numbers | `#HC-2026-000123` sequential |
| Prices | Realistic ranges: ₹250 – ₹45,000 |
| Dates | Within a plausible window around the design date; include today, yesterday, last week |
| Customer names | Diverse Indian and international names |
| Images | Real handicraft photography (licensed) — never grey boxes in APPROVED frames |
| Numbers | Never all-round numbers; use 1,482 not 1,000 |
| Edge cases | Every list must include at least one long name, one missing image, one zero-stock item, one error row |
| Empty strings | Show as `—`, never blank |

---

## 13. Annotation & Redline Standards

Each module page's `SECTION: 08 · Annotations & Redlines` contains:

| Annotation type | Component | Content |
|-----------------|-----------|---------|
| Spec pin | Numbered circle + callout card | Element name, size, spacing, token names |
| Behaviour note | Yellow sticky | Interaction description, timing, edge cases |
| Validation note | Red sticky | Field rules and exact error copy |
| Permission note | Purple sticky | Which roles see/can use the element |
| API note | Blue sticky | Endpoint, method, key fields, error codes |
| Accessibility note | Green sticky | Role, label, keyboard, announcement |
| Open question | Orange sticky + `@mention` | Question, owner, due date |

Redlines use the `Annotation` component set with a consistent 12px mono font and 1px dashed measurement lines in `#E11D48`.

---

## 14. Developer Handoff Rules

### 14.1 Handoff Checklist (per screen)

- [ ] Frame status is 🟢 APPROVED
- [ ] All three breakpoints exist (or a "no change" note is present)
- [ ] Dark theme variant exists or is confirmed as an automatic mode switch
- [ ] All states designed: default, loading, empty, filtered-empty, error, no-permission
- [ ] Every interactive element maps to a library component (no detached instances)
- [ ] Spacing uses tokens only — Dev Mode inspection shows variable names, not raw px
- [ ] Annotations complete: behaviour, validation, permission, API, a11y
- [ ] Copy is final and matches the module spec's validation/message tables
- [ ] Prototype link exists for any multi-step flow
- [ ] Assets exported/marked for export (SVG icons, PNG/WEBP illustrations at 1×/2×)

### 14.2 Dev Mode Configuration

- Enable Dev Mode on File 03; mark approved sections as "Ready for development".
- Link each module section to its Jira/Azure DevOps epic.
- Code Connect (if used) maps Figma components to the Bootstrap 5 partial/view component names.
- Variables published so tokens are inspectable as named values.

### 14.3 Token → Implementation Mapping Guidance

Provide developers a single mapping table (maintained in File 01 → `00 Guidelines`) of Figma variable → CSS custom property name → Bootstrap 5 utility/variable it overrides. Designers do not write the CSS; they only guarantee that every visual value has a token name.

### 14.4 Asset Export Settings

| Asset | Format | Scales | Naming |
|-------|--------|--------|--------|
| Icons | SVG (stroke preserved, no fills baked) | 1× | `icon-{name}.svg` |
| Illustrations | SVG preferred, PNG fallback | 1×, 2× | `illus-{name}-{theme}.svg` |
| Logos | SVG | 1× | `logo-{variant}.svg` |
| Photography | WEBP + JPG fallback | 1×, 2× | `{entity}-{slug}-{size}.webp` |
| Favicons | PNG/ICO/SVG | 16, 32, 180, 192, 512 | standard names |

---

## 15. Design QA Gates

| Gate | Owner | Criteria |
|------|-------|----------|
| G1 · Structure | UX Architect | IA correct, all screens listed in the module spec exist |
| G2 · System | Design System Owner | 100% component/token usage, zero detached instances, zero local styles |
| G3 · Content | Business Analyst | Labels, copy, validation messages match the spec exactly |
| G4 · Accessibility | A11y Lead | Contrast, focus, keyboard, target sizes, announcements documented |
| G5 · Responsive | UI Designer | All breakpoints present and reflow rules honoured |
| G6 · Prototype | UX Lead | Flow is complete and has no dead ends |
| G7 · Handoff | Front-End Lead | Annotations sufficient to build without asking questions |

A frame may only be marked 🟢 APPROVED after all seven gates pass.

---

## 16. Versioning & Branching

- Use Figma **Branches** for any change touching more than 3 frames.
- Branch naming: `feat/{module}-{short-description}`, `fix/{module}-{issue}`, `chore/{topic}`.
- Merge only after G1–G7 and a design review comment thread is resolved.
- Named versions created at every release: `v1.0.0 — Release 1 Scope Frozen`.
- The library files use scheduled publishing (weekly) with detailed release notes; breaking token changes require a MAJOR bump and a migration note.

---

## 17. Estimated Figma Build Effort

| Workstream | Frames | Est. designer-days |
|------------|--------|--------------------|
| Foundations (tokens, type, colour, icons, illustrations) | ~120 | 8 |
| Component library (95 sets, all variants, both themes) | ~1,400 variants | 25 |
| Module screens — desktop | ~540 | 34 |
| Module screens — states (loading/empty/error) | ~380 | 12 |
| Module screens — tablet | ~180 | 9 |
| Module screens — mobile | ~300 | 15 |
| Dark theme verification & divergent screens | ~120 | 6 |
| Print artefacts | ~14 | 3 |
| Prototypes (10 flows) | — | 8 |
| Annotations & redlines | — | 10 |
| Design QA & revisions | — | 12 |
| **Total** | **~3,050 frames/variants** | **~142 designer-days** |

Recommended team: 1 Design Lead + 2 UI Designers + 1 UX Architect over ~12 weeks, with the component library front-loaded in weeks 1–4.
