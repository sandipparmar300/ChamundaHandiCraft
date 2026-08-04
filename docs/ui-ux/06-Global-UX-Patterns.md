# 06 — Global UX Patterns

Enterprise Handicraft E-Commerce Platform · UI/UX Design Specification

These patterns are inherited by every module. A module chapter only documents its **deviations** from these patterns plus its own data.

---

## 1. Pattern P-01 — List / Index Page

### 1.1 Desktop Wireframe (1440)

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ TOP BAR                                                                            │
├──────────────┬─────────────────────────────────────────────────────────────────────┤
│              │ Dashboard / Catalog / Products                                      │
│  SIDEBAR     ├─────────────────────────────────────────────────────────────────────┤
│              │ Products                              [Import] [Export] [+ Add Product]│
│              │ 1,482 products · 24 low stock · 6 drafts                             │
│              ├─────────────────────────────────────────────────────────────────────┤
│              │ ┌─ Tabs ───────────────────────────────────────────────────────────┐ │
│              │ │ All (1482) │ Published (1401) │ Draft (6) │ Low Stock (24) │ ... │ │
│              │ └─────────────────────────────────────────────────────────────────┘ │
│              │ ┌─ Toolbar ────────────────────────────────────────────────────────┐ │
│              │ │ [⌕ Search name, SKU, barcode]  [Category▾][Status▾][Stock▾]      │ │
│              │ │ [+ More Filters]        [My View ▾] [⚙ Columns] [▤ Density] [↻]  │ │
│              │ ├──────────────────────────────────────────────────────────────────┤ │
│              │ │ Active: (Category: Décor ×) (Stock: Low ×)          Clear all    │ │
│              │ └─────────────────────────────────────────────────────────────────┘ │
│              │ ┌─ Bulk bar (when selection > 0) ─────────────────────────────────┐ │
│              │ │ ✓ 12 selected  Select all 1,482 │ [Edit][Publish][Export][⋮] [×] │ │
│              │ └─────────────────────────────────────────────────────────────────┘ │
│              │ ┌─ Table ──────────────────────────────────────────────────────────┐ │
│              │ │ [☐] IMG  Name ⇅        SKU      Category  Price ⇅ Stock  ●  ⋮   │ │
│              │ │ ─────────────────────────────────────────────────────────────── │ │
│              │ │ [☐] [ ]  Blue Pottery… HC-1001  Décor     ₹1,250    24  ●  ⋮   │ │
│              │ │ …                                                                │ │
│              │ └─────────────────────────────────────────────────────────────────┘ │
│              │ Showing 1–25 of 1,482    [25 ▾]      ‹‹ ‹ 1 2 3 … 60 › ››           │
│              ├─────────────────────────────────────────────────────────────────────┤
│              │ FOOTER                                                              │
└──────────────┴─────────────────────────────────────────────────────────────────────┘
```

### 1.2 Region Specification

| Region | Height | Contents | Sticky |
|--------|--------|----------|--------|
| Breadcrumb bar | 44 | Trail + optional back button | Yes |
| Page header | 72–88 | Title, record count summary, secondary actions, primary action | Compacts on scroll |
| Status tabs | 44 | Segmented counts by primary status (optional per module) | No |
| Toolbar | 56 | Search, up to 4 filters, More Filters, Saved View, Columns, Density, Refresh | Yes (below breadcrumb) |
| Active filter row | 40 | Removable chips + Clear all | Appears only when filters exist |
| Bulk bar | 56 | Selection count, select-all-matching, actions | Appears on selection |
| Table | auto | See `03-Component-Library §32` | Header sticky |
| Pagination | 56 | Count, page size, pager, go-to | No |

### 1.3 Toolbar Right-Side Controls

| Control | Icon | Behaviour |
|---------|------|-----------|
| Saved View | `bookmark` | Menu of views; "• Modified" dot when dirty |
| Column Manager | `settings-2` | Popover with checkbox list, drag order, pin |
| Density | `rows-3` | Segmented: Comfortable / Standard / Compact |
| Refresh | `refresh-cw` | Re-fetches; spins during load; shows "Updated just now" tooltip |
| Full screen | `maximize` | Hides sidebar for maximum table width |

### 1.4 List Page Behaviour Rules

| Rule | Detail |
|------|--------|
| L-01 | Filters, sort, page, page size, density and column config are all encoded in the URL query string |
| L-02 | Back-navigation from a detail page restores the exact list state and scroll position, and highlights the visited row for 2s |
| L-03 | Default sort is most-recently-updated descending unless the module states otherwise |
| L-04 | Row click opens the detail/edit view; clicks on links, chips, checkboxes and actions do not trigger row navigation |
| L-05 | Selection persists across pagination within the same filter set; changing filters clears selection with a toast "Selection cleared" |
| L-06 | "Select all matching" selects the entire result set (not just the page) and is required before any bulk action can exceed the page |
| L-07 | Any list over 100 rows virtualises; scroll position is preserved on refresh |
| L-08 | Every list supports keyboard row navigation (`↑↓`), `Enter` to open, `X` to select |
| L-09 | Export always respects current filters and selection; the export dialog states exactly what will be exported |
| L-10 | Real-time counts in tabs refresh with the list, not independently |

### 1.5 Tablet (768)

- Sidebar collapses to off-canvas.
- Toolbar: search full width on row 1; filters collapse into a single "Filters (3)" button opening a drawer.
- Table shows priority-1 and 2 columns; horizontal scroll for the rest with a sticky first column.
- Page header actions: primary inline, others in overflow.

### 1.6 Mobile (375)

```
┌──────────────────────────────┐
│ ☰   Products          ⌕  ⋮   │
├──────────────────────────────┤
│ [Filters (2)]  [Sort ▾]      │
│ (Décor ×) (Low ×)            │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │[img] Blue Pottery Vase ⋮ │ │
│ │      HC-POT-10241        │ │
│ │      ● Published  ₹1,250 │ │
│ │      Stock: 24           │ │
│ └──────────────────────────┘ │
│ ┌──────────────────────────┐ │
│ │ …                        │ │
│ └──────────────────────────┘ │
│      [ Load more ]           │
├──────────────────────────────┤
│           [ + ]  FAB          │
├──────────────────────────────┤
│ 🏠   🛒   📦   🏭   ⋯        │
└──────────────────────────────┘
```
- Card list replaces the table.
- Infinite scroll with a "Load more" fallback button.
- Primary action becomes a FAB (56px, bottom-right, 16px inset above the bottom bar).
- Filters open a full-screen sheet with Apply/Reset.
- Long-press enters multi-select; the bulk bar docks above the bottom nav.

### 1.7 List Page States

| State | Design |
|-------|--------|
| Loading | Toolbar rendered (disabled), table skeleton: header + 8 rows matching column widths |
| Empty (first use) | Illustration 160, "No {entities} yet", supporting copy, primary CTA + secondary (Import / Learn) |
| Empty (filtered) | Icon 64, "No {entities} match your filters", chip list of active filters, "Clear all filters" |
| Empty (search) | Icon 64, "No results for '{query}'", "Check spelling or try fewer words", "Clear search" |
| Error | Icon 64 danger, "Couldn't load {entities}", reason, "Try Again", error reference |
| Partial error | Table renders with an amber banner: "Some data couldn't be loaded. [Retry]" |
| No permission | Lock 64, "You don't have access to {module}", "Request Access" |
| Offline | Sticky banner: "You're offline. Showing last loaded data from {time}." |

---

## 2. Pattern P-02 — Detail / View Page

### 2.1 Layout (L-02: 8/4)

```
┌────────────────────────────────────────────────────────────────────────────┐
│ ◀ Blue Pottery Vase   [● Published]        [Preview][Duplicate][⋮][Edit]   │
│   SKU HC-POT-10241 · Updated 2 hours ago by Anand      ‹ 3 of 42 ›         │
├────────────────────────────────────────────────────────────────────────────┤
│ Overview │ Media │ Variants │ Inventory │ Pricing │ SEO │ Activity         │
├──────────────────────────────────────────┬─────────────────────────────────┤
│ ┌──────────────────────────────────────┐ │ ┌─────────────────────────────┐ │
│ │ Key details (Description List)       │ │ │ Status                      │ │
│ └──────────────────────────────────────┘ │ └─────────────────────────────┘ │
│ ┌──────────────────────────────────────┐ │ ┌─────────────────────────────┐ │
│ │ Related data (table/cards)           │ │ │ Quick stats                 │ │
│ └──────────────────────────────────────┘ │ └─────────────────────────────┘ │
│                                          │ ┌─────────────────────────────┐ │
│                                          │ │ Activity (last 5)           │ │
│                                          │ └─────────────────────────────┘ │
└──────────────────────────────────────────┴─────────────────────────────────┘
```

### 2.2 Rules

| Rule | Detail |
|------|--------|
| D-01 | Record navigation `‹ N of M ›` moves through the list result set the user arrived from |
| D-02 | The status chip in the header is the authoritative state; where a status change is permitted it becomes a dropdown chip |
| D-03 | The right rail holds metadata, status, quick stats and recent activity — never primary content |
| D-04 | Every detail page has an Activity tab with the full audit trail |
| D-05 | Copyable identifiers (SKU, order number, tracking number) show a copy icon on hover |
| D-06 | Inline edit is permitted only for single low-risk fields; everything else routes to the Edit page/drawer |
| D-07 | Deleted/archived records open read-only with a banner: "This {entity} was archived on {date} by {user}. [Restore]" |
| D-08 | Mobile collapses tabs to a horizontally scrolling strip; the right rail moves below the main content |

---

## 3. Pattern P-03 — Create / Edit Form Page

### 3.1 Layout

```
┌────────────────────────────────────────────────────────────────────────────┐
│ ◀ Add Product                                    [Cancel] [Save as Draft] [Save & Publish] │
│   Fill in the details below. Fields marked * are required.                 │
├────────────────────────────────────────────────────────────────────────────┤
│ ⚠ 3 fields need your attention  [Review]        (only after failed submit) │
├──────────────────────────────────────────┬─────────────────────────────────┤
│ ┌─ Card: Basic Information ────────────┐ │ ┌─ Card: Status ──────────────┐ │
│ │ Product Name *                       │ │ │ ○ Draft  ● Published        │ │
│ │ [                                  ] │ │ │ Publish at [date] [time]    │ │
│ │ Short Description                    │ │ └─────────────────────────────┘ │
│ │ [                                  ] │ │ ┌─ Card: Organisation ────────┐ │
│ │ ...                                  │ │ │ Category *  [Select    ▾]   │ │
│ └──────────────────────────────────────┘ │ │ Brand       [Select    ▾]   │ │
│ ┌─ Card: Pricing ──────────────────────┐ │ │ Artisan     [Search    ▾]   │ │
│ │ ...                                  │ │ │ Tags        [tag input  ]   │ │
│ └──────────────────────────────────────┘ │ └─────────────────────────────┘ │
├──────────────────────────────────────────┴─────────────────────────────────┤
│ Sticky action bar:  Saved 2 min ago     [Cancel] [Save as Draft] [Save & Publish] │
└────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Form Rules

| Rule | Detail |
|------|--------|
| F-01 | Single column per card; two-column only for short paired fields (e.g. Price / Compare-at Price, City / PIN) |
| F-02 | Field order follows the user's mental model, not the database schema |
| F-03 | Required fields marked with `*`; if >80% are required, mark the optional ones instead |
| F-04 | Labels always visible above the field; placeholders show format examples, never repeat the label |
| F-05 | Help text explains *why* or *how*, not *what* ("Used in the product URL. Keep it short and descriptive.") |
| F-06 | Validate on blur; re-validate live once a field has errored; validate everything on submit |
| F-07 | On failed submit: focus the first invalid field, scroll it into view with 120px offset, show a form-level summary alert listing errors as links |
| F-08 | Tabs/sections containing errors show a danger dot/count |
| F-09 | Sticky action bar appears once the form exceeds one viewport; it shows the autosave status |
| F-10 | "Save & Add Another" is provided wherever repeated entry is expected (products, categories, coupons, blog) |
| F-11 | Cancel triggers the unsaved-changes guard when dirty |
| F-12 | Disabled Save is prohibited — always allow submit and explain failures; the exception is while a submit is in flight |
| F-13 | Long forms (>12 fields) use collapsible sections with a completion indicator per section |
| F-14 | Dependent fields appear with a 240ms reveal, never as a layout jump; irrelevant fields are hidden, not disabled |
| F-15 | Currency, weight and dimension fields always show their unit in the field, not only in the label |
| F-16 | Duplicate-check fields (SKU, slug, coupon code) validate remotely with a debounce and show an inline success tick |

### 3.3 Validation Message Catalogue (Global)

| Condition | Message |
|-----------|---------|
| Required | `{Label} is required.` |
| Min length | `{Label} must be at least {n} characters.` |
| Max length | `{Label} must be {n} characters or fewer.` |
| Numeric range | `{Label} must be between {min} and {max}.` |
| Greater than | `{Label} must be greater than {other}.` |
| Invalid email | `Enter a valid email address.` |
| Invalid phone | `Enter a valid 10-digit mobile number.` |
| Invalid URL | `Enter a valid URL starting with https://` |
| Invalid date | `Enter a valid date (DD/MM/YYYY).` |
| Past date not allowed | `Choose a date in the future.` |
| End before start | `End date must be after the start date.` |
| Duplicate | `This {label} is already in use.` |
| Invalid format | `{Label} can only contain letters, numbers and hyphens.` |
| File too large | `File is too large. Maximum size is {n} MB.` |
| Wrong file type | `Unsupported file type. Use {list}.` |
| Image too small | `Image should be at least {w} × {h} px for best quality.` |
| Max items | `You can add up to {n} {items}.` |
| Nothing selected | `Select at least one {item}.` |
| Server error | `Something went wrong. Your changes were not saved. [Try Again]` |
| Conflict | `This {entity} was changed by {user} while you were editing. [Review Changes] [Overwrite]` |
| Network | `You appear to be offline. Your changes are saved locally and will sync when you reconnect.` |

---

## 4. Pattern P-04 — Multi-Step Wizard

Used by: Product Create (guided mode), Bulk Import, Offer Builder, Campaign Builder, Report Builder, Store Setup, Return/RMA.

### 4.1 Layout (L-06)

```
┌────────────────────────────────────────────────────────────────────────────┐
│ Import Products                                                       [×]  │
├────────────────────────────────────────────────────────────────────────────┤
│  ①───────②───────③───────④                                                 │
│  Upload  Map     Validate Import                                           │
│  ✓       ✓       ●        ○                                                │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│   Step content (max width 880, centred)                                    │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│ [Back]                              Step 3 of 4        [Save & Exit] [Next] │
└────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Rules

| Rule | Detail |
|------|--------|
| W-01 | 3–6 steps maximum; more means the task should be split |
| W-02 | Each step is independently valid; Next is blocked with a summary alert if invalid |
| W-03 | Completed steps are clickable; future steps are locked |
| W-04 | Progress persists — "Save & Exit" creates a resumable draft, listed with a "Resume" action |
| W-05 | A review step precedes any irreversible action, summarising every choice with Edit links |
| W-06 | The final step shows a Success State with outcome metrics and next actions |
| W-07 | Mobile: stepper collapses to "Step 3 of 4 — Validate" plus a progress bar; Back/Next dock to the bottom |
| W-08 | Closing the wizard mid-flow triggers "Save draft and exit / Discard / Keep editing" |

---

## 5. Pattern P-05 — Confirmation & Dialog System

### 5.1 Dialog Types

| Type | When | Icon | Primary button | Auto-focus |
|------|------|------|----------------|-----------|
| **Simple confirm** | Reversible action | Info (blue) | Filled brand | Primary |
| **Destructive confirm** | Irreversible / data loss | Alert (red) in a red circle | Filled danger | Cancel |
| **Guarded destructive** | High-impact (bulk delete, cancel dispatched order, delete a user) | Alert (red) | Filled danger, disabled until verification typed | Verification input |
| **Warning confirm** | Risky but recoverable | Triangle (amber) | Filled brand or amber | Cancel |
| **Input confirm** | Needs a reason/value | Contextual | Filled brand | First input |
| **Success dialog** | After significant completion | Check (green) | Primary next action | Primary |
| **Error dialog** | Blocking failure needing a decision | Alert (red) | Retry | Retry |
| **Information dialog** | Explanatory only | Info | "Got It" | Primary |

### 5.2 Destructive Confirmation Template

```
┌───────────────────────────────────────────────────────┐
│  ⛔  Delete product?                             [×]  │
├───────────────────────────────────────────────────────┤
│  You're about to delete Blue Pottery Vase.            │
│                                                       │
│  This will:                                           │
│   • Remove it from the storefront immediately         │
│   • Keep it on 14 past orders for record-keeping      │
│   • Move 24 units of stock to Unallocated             │
│                                                       │
│  Deleted products can be restored from the Recycle    │
│  Bin for 30 days.                                     │
│                                                       │
│  Reason (optional)                                    │
│  [                                                  ] │
├───────────────────────────────────────────────────────┤
│                              [Cancel]  [Delete Product] │
└───────────────────────────────────────────────────────┘
```

### 5.3 Guarded Destructive Template

Adds a typed verification:
```
  To confirm, type the product name below.
  [ Blue Pottery Vase                                  ]
  ✗ Doesn't match
```
Applied to: deleting an admin user, deleting a category with children, bulk deleting >50 records, cancelling a dispatched order, deleting a warehouse with stock, resetting settings, purging the Recycle Bin.

### 5.4 Dialog Copy Rules

- Title is a question for confirmations: "Delete product?", "Cancel this order?"
- Body states the consequence in concrete numbers, never vague warnings.
- Always state reversibility explicitly.
- Buttons echo the verb: "Delete Product", "Cancel Order", "Publish 12 Products".
- Never use "Are you sure?" alone.

### 5.5 Success Dialog Template

```
┌───────────────────────────────────────────────────────┐
│                        ✓                              │
│                  Order shipped                        │
│                                                       │
│  Order #HC-2026-000412 has been marked as shipped     │
│  and the customer has been notified by email and SMS. │
│                                                       │
│  Tracking: BD1234567890 (Bluedart)                    │
│                                                       │
│  [Print Label]  [View Order]   [Process Next Order]   │
└───────────────────────────────────────────────────────┘
```

### 5.6 Error Dialog Template

```
┌───────────────────────────────────────────────────────┐
│  ⛔  Couldn't process the refund                 [×]  │
├───────────────────────────────────────────────────────┤
│  The payment gateway rejected this refund.            │
│                                                       │
│  Reason: Insufficient balance in the settlement       │
│  account (Razorpay error: BAD_REQUEST_ERROR).         │
│                                                       │
│  What you can do:                                     │
│   • Retry after the next settlement (est. 6 Aug)      │
│   • Process a manual bank refund and record it        │
│                                                       │
│  Reference: ERR-PAY-4021-8f3c92                [copy] │
├───────────────────────────────────────────────────────┤
│  [Record Manual Refund]      [Cancel]      [Try Again] │
└───────────────────────────────────────────────────────┘
```

### 5.7 Bulk Progress Dialog

```
┌───────────────────────────────────────────────────────┐
│  Publishing 128 products                              │
├───────────────────────────────────────────────────────┤
│  ████████████████████░░░░░░░░░  74%                   │
│  95 of 128 processed · 3 failed                       │
│  Estimated time remaining: 12 seconds                 │
│                                                       │
│  ⚠ 3 products couldn't be published                   │
│    HC-POT-10241 — Missing price                       │
│    HC-TEX-20117 — No images                           │
│    HC-MET-30442 — Category inactive                   │
├───────────────────────────────────────────────────────┤
│  [Run in Background]                    [Stop]        │
└───────────────────────────────────────────────────────┘
```
On completion the dialog becomes a Success State with "Download Report (CSV)" and "Fix Failed Items" (which opens the list pre-filtered to the failures).

---

## 6. Pattern P-06 — Filters & Saved Views

### 6.1 Filter Types

| Type | Control | Behaviour |
|------|---------|-----------|
| Single-select | Dropdown chip | Applies immediately |
| Multi-select | Dropdown chip with checkboxes | Applies on menu close or "Apply" inside the menu |
| Search-select (large sets) | Combobox with remote search | Debounced |
| Date range | Date range picker with presets | Applies on Apply |
| Numeric range | Two number inputs + slider | Applies on blur/Apply |
| Boolean | Toggle chip | Immediate |
| Hierarchical (category) | Tree select | Parent selection includes children (with a "include sub-categories" toggle) |
| Tag/keyword | Tag input | Immediate per tag |
| Status | Segmented tabs (primary status) + dropdown (secondary) | Immediate |

### 6.2 Advanced Filter Drawer

```
┌─ Filters ──────────────────────────── [×] ┐
│ Category            [Multi-select      ▾] │
│ Brand               [Multi-select      ▾] │
│ Artisan             [Search…          ▾] │
│ Status              [☐ Published ☐ Draft] │
│ Stock               [☐ In ☐ Low ☐ Out   ] │
│ Price range         [₹ min ] – [₹ max  ] │
│ Created             [Date range        ▾] │
│ Updated by          [User select       ▾] │
│ Has images          [ ⚪ Any ⚪ Yes ⚪ No ] │
│ Missing SEO         [ Toggle            ] │
├───────────────────────────────────────────┤
│ [Reset all]           [Apply Filters (5)] │
└───────────────────────────────────────────┘
```

### 6.3 Saved Views

| Aspect | Spec |
|--------|------|
| Contents | Filters + sort + visible columns + column order + density + page size |
| Scope | Private (default), Shared with a role, Shared with everyone |
| System views | Provided per module, non-deletable, e.g. "Low Stock", "Awaiting Dispatch", "Pending Review" |
| Default view | One per user per module; loads on entry |
| Modified indicator | "• Modified" next to the name; actions "Save changes" / "Save as new" / "Reset" |
| Limit | 20 personal views per module, with a message at the limit |

---

## 7. Pattern P-07 — Bulk Actions

| Aspect | Spec |
|--------|------|
| Entry | Row checkboxes, header select-all (page), "Select all N matching" in the bulk bar |
| Feedback | Bulk bar shows the exact count and scope ("12 selected" vs "All 1,482 matching filters") |
| Confirmation | Always a dialog stating the count and consequence; guarded template beyond 50 records |
| Execution | ≤20 records = inline with a progress toast; >20 = progress dialog with background option |
| Results | Success toast with counts; partial failure opens a results modal with a downloadable CSV of failures |
| Undo | Offered for reversible bulk ops (publish/unpublish, tag add/remove, archive) for 8 seconds |
| Limits | Hard cap of 5,000 records per bulk operation, with a message suggesting narrower filters |
| Permissions | Actions the role cannot perform never appear in the bulk bar |

### 7.1 Standard Bulk Actions by Entity Type

| Entity | Bulk actions |
|--------|--------------|
| Products | Publish, Unpublish, Change category, Add/remove tags, Update price (%, flat, set), Update stock, Assign brand/artisan, Feature/unfeature, Export, Archive, Delete |
| Categories | Activate, Deactivate, Change parent, Reorder, Delete |
| Inventory | Adjust stock, Transfer warehouse, Set reorder level, Print barcodes, Export |
| Orders | Change status, Print invoices, Print labels, Assign courier, Export, Add tag, Cancel |
| Customers | Add to segment, Add/remove tag, Send email, Adjust reward points, Block, Unblock, Export |
| Reviews | Approve, Reject, Delete, Mark as spam |
| Coupons | Activate, Deactivate, Extend expiry, Delete |
| Blog/CMS | Publish, Unpublish, Change category, Delete |
| Subscribers | Add to list, Remove from list, Unsubscribe, Export, Delete |

---

## 8. Pattern P-08 — Search

### 8.1 Three Search Levels

| Level | Scope | Entry | Behaviour |
|-------|-------|-------|-----------|
| **Global** | Everything | Top bar / `⌘K` | Grouped results across orders, products, customers, pages, settings, actions |
| **Module** | Current list | Toolbar search | Filters the current result set on defined fields |
| **In-context** | Within a control | Select/Combobox/Table filter | Local filtering |

### 8.2 Global Search Result Groups & Fields

| Group | Matches on | Result row |
|-------|-----------|------------|
| Orders | Order no., customer name, phone, email, AWB, transaction ID | `#HC-2026-000412` · Customer · ₹ amount · status chip · date |
| Products | Name, SKU, barcode, product code, tags | Thumbnail · name · SKU · stock · status |
| Customers | Name, email, phone, customer ID | Avatar · name · email · orders count · LTV |
| Categories | Name, slug | Icon · name · product count |
| Coupons | Code, name | Code · discount · validity |
| Content | Page/blog title, slug | Icon · title · type · status |
| Settings | Setting name, keyword | Icon · setting · path |
| Actions | Command names | Icon · "Create Product", "Export Orders" |
| Help | Doc titles | Icon · article title |

Ranking: exact ID match → starts-with → contains → fuzzy. Max 5 per group, "See all N results in {module} →" per group.

---

## 9. Pattern P-09 — Notifications & Toasts

Defined in `01-Product-Foundations §11` and `03-Component-Library §55`. Module chapters list only their specific triggers.

### 9.1 Global Toast Trigger Catalogue

| Event | Type | Message | Actions |
|-------|------|---------|---------|
| Record created | Success | "{Entity} created" | View, Create Another |
| Record updated | Success | "Changes saved" | — |
| Record deleted | Success | "{Entity} deleted" | Undo (8s) |
| Record restored | Success | "{Entity} restored" | View |
| Bulk complete | Success | "{n} {entities} {action}" | Undo / View Report |
| Bulk partial | Warning | "{n} succeeded, {m} failed" | View Report |
| Export queued | Info | "Export started. We'll notify you when it's ready." | View Exports |
| Export ready | Success | "Your export is ready" | Download |
| Import complete | Success | "{n} records imported" | View Report |
| Copy to clipboard | Info | "Copied to clipboard" | — |
| Save failed | Error | "Couldn't save. {reason}" | Try Again |
| Permission denied | Error | "You don't have permission to do that" | Request Access |
| Session expiring | Warning | "Your session expires in 2 minutes" | Stay Signed In |
| Connection lost | Error | "You're offline. Changes will sync when reconnected." | — |
| Connection restored | Success | "Back online. Changes synced." | — |
| Setting toggled | Success | "{Setting} turned {on/off}" | Undo |
| New order (realtime) | Info | "New order #HC-2026-000413 · ₹4,250" | View |
| Low stock (realtime) | Warning | "{Product} is low on stock (3 left)" | View |
| Payment failed (realtime) | Error | "Payment failed for order #…" | View |

---

## 10. Pattern P-10 — Empty, Loading & Error States

### 10.1 Skeleton Presets

| Preset | Composition |
|--------|-------------|
| Table | Header bar + 8 rows; each row mirrors real column widths (48 checkbox, 48 thumb, 40% text, 120, 160, 100, 80, 100, 96) |
| KPI row | 4 cards: label 60×10, value 140×28, delta 90×12, sparkline 100% × 32 |
| Chart | Title 160×16, legend 2×80×12, plot area with 7 ascending bar placeholders |
| Form | Section title 200×20 + 6 field groups (label 120×12, control 100%×40) |
| Detail | Header 300×28, chip 80×24, 2-col description list 8 rows, right rail 3 cards |
| Card grid | 8 tiles: image 100%×square, title 70%×16, meta 40%×12 |
| Timeline | 5 nodes: dot 12, title 200×14, meta 140×12 |
| Media gallery | 12 square tiles |

Skeletons appear after 200ms of loading (avoid flash for fast responses) and remain a minimum of 400ms once shown.

### 10.2 Empty State Copy Catalogue

| Module | Heading | Body | Primary CTA |
|--------|---------|------|-------------|
| Products | No products yet | Add your first product to start selling your crafts. | + Add Product |
| Categories | No categories yet | Organise your catalog so customers can browse easily. | + Add Category |
| Inventory | No stock records | Stock appears here once you add products or record a purchase. | + Purchase Entry |
| Orders | No orders yet | Orders will appear here as soon as customers start buying. | View Storefront |
| Payments | No payments yet | Payment records appear after your first order. | — |
| Shipping zones | No shipping zones | Define where you deliver and what you charge. | + Add Zone |
| Coupons | No coupons yet | Create a coupon to run your first promotion. | + Create Coupon |
| Offers | No offers running | Set up festival, combo or flash offers to boost sales. | + Create Offer |
| Banners | No banners yet | Add a homepage banner to showcase your collections. | + Add Banner |
| CMS pages | No pages yet | Create essential pages like About Us and Contact. | + Add Page |
| Blog | No posts yet | Share craft stories to attract and engage customers. | + Write Post |
| Reviews | No reviews yet | Customer reviews will appear here for moderation. | — |
| Testimonials | No testimonials yet | Showcase happy customers on your storefront. | + Add Testimonial |
| Subscribers | No subscribers yet | Subscribers appear here when visitors sign up. | + Add Subscriber |
| Notifications | You're all caught up | New notifications will appear here. | — |
| Reports | No data for this period | Try a different date range or check back later. | Change Date Range |
| Admin users | Only you so far | Invite teammates and give them the right access. | + Invite User |
| Customers | No customers yet | Customer profiles are created automatically on first order. | + Add Customer |
| Audit log | No activity recorded | Actions taken in the admin panel will be logged here. | — |
| Recycle bin | Nothing deleted | Deleted items appear here for 30 days. | — |
| Search | No results for "{query}" | Check your spelling or try fewer words. | Clear Search |

---

## 11. Pattern P-11 — System Pages

### 11.1 404 — Not Found

```
┌──────────────────────────────────────────────────┐
│                  [TOP BAR]                        │
│                                                   │
│              ┌───────────────┐                    │
│              │  illustration  │  240×200          │
│              │  broken pottery│                   │
│              └───────────────┘                    │
│                                                   │
│                     404                           │  display-lg
│              This page doesn't exist              │  heading-lg
│   The page you're looking for may have been       │
│   moved, deleted, or the link may be broken.      │
│                                                   │
│         [⌕ Search the admin panel      ]          │
│                                                   │
│      [ Go to Dashboard ]   [ Go Back ]            │
│                                                   │
│   Popular: Products · Orders · Reports · Settings │
└──────────────────────────────────────────────────┘
```
Illustration concept: a broken-but-being-repaired clay pot (kintsugi-like), tying error states to the craft theme. Dark variant provided.

### 11.2 500 — Server Error

- Illustration: an unfinished loom.
- Heading "Something went wrong on our end"
- Body: "We've been notified and are working on it. Try again in a moment."
- Error reference `ERR-500-{traceId}` in a monospace copyable chip.
- Actions: `Try Again` (primary), `Go to Dashboard`, `Report This Issue` (opens a support modal pre-filled with the reference).
- Auto-retry countdown option: "Retrying in 10s… [Cancel]".

### 11.3 403 — Forbidden

- Illustration: a locked wooden chest.
- Heading "You don't have access to this page"
- Body: "Your role ({role}) doesn't include access to {module}. Ask an administrator if you need it."
- Actions: `Request Access` (primary, sends a notification), `Go to Dashboard`.

### 11.4 503 — Maintenance

```
              ┌───────────────┐
              │  illustration  │  artisan tools laid out
              └───────────────┘
              We'll be right back
   We're performing scheduled maintenance to
   improve your experience.

              ⏱  Estimated completion
                 03 Aug 2026, 03:00 AM IST
                 ── 00 : 42 : 18 ──

        [ Check Status Page ]   [ Refresh ]

   Questions? support@company.com
```
- Live countdown; auto-refresh check every 60s.
- Full-bleed page, no shell chrome.
- A Super Admin bypass link is present when maintenance mode is enabled from Settings.

### 11.5 Offline

- Sticky global banner (danger tone): "You're offline. Some features are unavailable and changes are saved locally."
- Queued actions counter: "3 changes will sync when you reconnect. [View]"
- On reconnect: success toast "Back online. 3 changes synced."

### 11.6 Browser Unsupported

Shown for unsupported legacy browsers: list of supported browsers with download links and a "Continue anyway" link.

---

## 12. Pattern P-12 — Import / Export

### 12.1 Export Dialog

```
┌─ Export Products ─────────────────────────── [×] ┐
│ What to export                                    │
│  ⦿ Current filtered results (1,482)               │
│  ○ Selected items only (12)                       │
│  ○ All products (1,482)                           │
│                                                   │
│ Columns                                           │
│  ⦿ Visible columns (8)                            │
│  ○ All columns (34)                               │
│  ○ Custom…                          [Choose ▾]    │
│                                                   │
│ Format        [⦿ CSV] [○ XLSX] [○ PDF]            │
│ Options       ☑ Include header row                │
│               ☐ Include images as URLs            │
│               ☐ Split variants into rows          │
│                                                   │
│ ℹ Exports over 10,000 rows are emailed to you.    │
├───────────────────────────────────────────────────┤
│                        [Cancel]   [Export 1,482]  │
└───────────────────────────────────────────────────┘
```

### 12.2 Import Wizard (4 steps)

| Step | Content |
|------|---------|
| 1 · Upload | Dropzone, "Download template" link, format rules, sample preview |
| 2 · Map columns | Two-column mapper: file column ↔ system field, auto-matched with confidence, unmapped highlighted, required fields flagged |
| 3 · Validate | Preview table of the first 50 rows with per-cell error markers; summary "1,420 ready · 62 warnings · 18 errors"; toggle "Skip rows with errors" |
| 4 · Import | Progress with live counts; then Success State with counts and a downloadable results file |

Rules: dry-run always precedes commit; duplicates handled by an explicit choice (Skip / Update / Create new); import is resumable and cancellable; a full history of imports is kept with the ability to roll back the last import within 24h.

---

## 13. Pattern P-13 — Activity & Audit Trail

Every entity detail page includes an Activity tab using `CMP-DSP-ActivityFeed`:

| Element | Spec |
|---------|------|
| Entry | Actor avatar + name + role chip · action verb · field summary · relative time |
| Diff | Expandable panel with Before / After columns; changed values highlighted (removed in `danger-50`, added in `success-50`) |
| System entries | Robot icon, "System" actor, e.g. "Stock reduced by order #HC-2026-000412" |
| Filters | All / User changes / System / Comments |
| Comments | Internal notes with @mentions that notify the mentioned user |
| Export | "Download activity (CSV)" for the record |

---

## 14. Pattern P-14 — Micro-interaction Catalogue

| Interaction | Feedback |
|-------------|----------|
| Button click | 80ms scale-down + immediate loading state if async |
| Toggle switch | Knob slide 150ms + toast confirmation |
| Checkbox | Check path draw 150ms |
| Row hover | Background tint + row actions fade in |
| Row select | Background tint + left accent bar + count increment animation in the bulk bar |
| Drag start | Item lifts (scale 1.02 + elevation-3), other items shift to make space |
| Drop | Snap 240ms with slight overshoot, brief success tint on the moved row |
| Copy to clipboard | Icon morphs check for 1.5s + toast |
| Save success | Button shows a check for 800ms before returning to label; "Saved" appears in the sticky bar |
| Field validation pass | Green tick fades in at the field's trailing edge |
| Field validation fail | Border turns danger with a 3px shake (reduced-motion: no shake) |
| Tab switch | Indicator slides, panel cross-fades |
| Accordion expand | Height animates, chevron rotates |
| Number update (realtime KPI) | Value cross-fades and a subtle up/down arrow flashes |
| New realtime row | Row slides in from the top with a 2s `info-50` highlight that fades |
| Notification arrival | Bell shakes once + badge pulses |
| Search typing | Inline spinner in the field, results cross-fade |
| Image upload | Tile appears immediately with a progress ring overlay, then fades to the final image |
| Delete row | Row collapses in height 240ms then removes |
| Undo | Row re-expands from height 0 with a success tint |
| Stepper advance | Node fills with a check draw, connector fills left-to-right |
| Barcode scan success | Green flash on the field + beep + row highlight |
| Reaching a threshold (low stock) | Stock chip pulses once when it crosses into warning |

All of the above are suppressed or reduced to opacity-only under `prefers-reduced-motion`.

---

## 15. Pattern P-15 — Responsive Deviations Summary

| Component | Desktop | Tablet | Mobile |
|-----------|---------|--------|--------|
| Data table | Full | Priority cols + scroll | Card list |
| Filters | Inline | Drawer | Full-screen sheet |
| Modal | Centred | Centred 90vw | Full-screen sheet |
| Drawer | Right 480 | Right 80vw | Bottom sheet |
| Tabs | Horizontal | Scrollable | Scrollable / Select |
| Page actions | Inline | Primary + overflow | Sticky bottom bar / FAB |
| Wizard stepper | Horizontal | Horizontal compact | Text + progress bar |
| Detail 8/4 | Side by side | Stacked | Tabs |
| KPI grid | 4-up | 2-up | 1-up carousel |
| Charts | Full | Full, legend below | Simplified, fewer ticks |
| Gallery | 6 cols | 4 cols | 2 cols |
| Sidebar | Fixed | Off-canvas | Off-canvas + bottom tabs |
| Bulk bar | Under toolbar | Under toolbar | Above bottom nav |
| Pagination | Numbered | Numbered | Simple / infinite |
