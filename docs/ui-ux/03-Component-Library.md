# 03 — Component Library

Enterprise Handicraft E-Commerce Platform · UI/UX Design Specification
Every component below must exist as a **Figma Component Set** with the listed variant properties, built with Auto Layout, bound to semantic Variables.

---

## Index

| # | Component | ID |
|---|-----------|-----|
| 1 | Button | `CMP-ACT-Button` |
| 2 | Icon Button | `CMP-ACT-IconButton` |
| 3 | Button Group / Split Button | `CMP-ACT-ButtonGroup` |
| 4 | Link | `CMP-ACT-Link` |
| 5 | Text Field | `CMP-INP-TextField` |
| 6 | Textarea | `CMP-INP-Textarea` |
| 7 | Number / Stepper | `CMP-INP-Number` |
| 8 | Currency Field | `CMP-INP-Currency` |
| 9 | Password Field | `CMP-INP-Password` |
| 10 | Select / Dropdown | `CMP-INP-Select` |
| 11 | Multi-Select | `CMP-INP-MultiSelect` |
| 12 | Combobox / Autocomplete | `CMP-INP-Combobox` |
| 13 | Checkbox | `CMP-INP-Checkbox` |
| 14 | Radio | `CMP-INP-Radio` |
| 15 | Switch / Toggle | `CMP-INP-Switch` |
| 16 | Segmented Control | `CMP-INP-Segmented` |
| 17 | Slider / Range | `CMP-INP-Slider` |
| 18 | Date Picker | `CMP-INP-DatePicker` |
| 19 | Date Range Picker | `CMP-INP-DateRange` |
| 20 | Time Picker | `CMP-INP-TimePicker` |
| 21 | Date-Time Picker | `CMP-INP-DateTime` |
| 22 | Colour Picker | `CMP-INP-ColorPicker` |
| 23 | Rich Text Editor | `CMP-INP-RichText` |
| 24 | Tag Input | `CMP-INP-TagInput` |
| 25 | File Upload | `CMP-INP-FileUpload` |
| 26 | Image Upload | `CMP-INP-ImageUpload` |
| 27 | Form Field Wrapper | `CMP-FRM-Field` |
| 28 | Form Section | `CMP-FRM-Section` |
| 29 | Card | `CMP-SRF-Card` |
| 30 | Stat / KPI Card | `CMP-SRF-StatCard` |
| 31 | Panel | `CMP-SRF-Panel` |
| 32 | Data Table | `CMP-DAT-Table` |
| 33 | Table Row Actions | `CMP-DAT-RowActions` |
| 34 | Pagination | `CMP-DAT-Pagination` |
| 35 | Bulk Action Bar | `CMP-DAT-BulkBar` |
| 36 | Filter Bar | `CMP-DAT-FilterBar` |
| 37 | Filter Chip | `CMP-DAT-FilterChip` |
| 38 | Search Field | `CMP-DAT-Search` |
| 39 | Saved View Selector | `CMP-DAT-SavedView` |
| 40 | Column Manager | `CMP-DAT-ColumnManager` |
| 41 | Tabs | `CMP-NAV-Tabs` |
| 42 | Breadcrumb | `CMP-NAV-Breadcrumb` |
| 43 | Sidebar | `CMP-NAV-Sidebar` |
| 44 | Sidebar Item | `CMP-NAV-SidebarItem` |
| 45 | Top Bar | `CMP-NAV-TopBar` |
| 46 | Footer | `CMP-NAV-Footer` |
| 47 | Page Header | `CMP-NAV-PageHeader` |
| 48 | Stepper / Wizard | `CMP-NAV-Stepper` |
| 49 | Accordion | `CMP-NAV-Accordion` |
| 50 | Menu / Dropdown Menu | `CMP-NAV-Menu` |
| 51 | Modal | `CMP-OVL-Modal` |
| 52 | Drawer | `CMP-OVL-Drawer` |
| 53 | Popover | `CMP-OVL-Popover` |
| 54 | Tooltip | `CMP-OVL-Tooltip` |
| 55 | Toast | `CMP-FBK-Toast` |
| 56 | Alert / Banner | `CMP-FBK-Alert` |
| 57 | Inline Message | `CMP-FBK-InlineMessage` |
| 58 | Progress Bar | `CMP-FBK-Progress` |
| 59 | Spinner | `CMP-FBK-Spinner` |
| 60 | Skeleton | `CMP-FBK-Skeleton` |
| 61 | Empty State | `CMP-FBK-EmptyState` |
| 62 | Error State | `CMP-FBK-ErrorState` |
| 63 | Success State | `CMP-FBK-SuccessState` |
| 64 | Badge | `CMP-IND-Badge` |
| 65 | Status Chip | `CMP-IND-StatusChip` |
| 66 | Tag | `CMP-IND-Tag` |
| 67 | Label | `CMP-IND-Label` |
| 68 | Counter / Notification Dot | `CMP-IND-Counter` |
| 69 | Rating Stars | `CMP-IND-Rating` |
| 70 | Avatar | `CMP-IND-Avatar` |
| 71 | Avatar Group | `CMP-IND-AvatarGroup` |
| 72 | Profile Card | `CMP-IND-ProfileCard` |
| 73 | Timeline | `CMP-DSP-Timeline` |
| 74 | Activity Feed | `CMP-DSP-ActivityFeed` |
| 75 | Description List | `CMP-DSP-DescriptionList` |
| 76 | Gallery | `CMP-MED-Gallery` |
| 77 | Carousel | `CMP-MED-Carousel` |
| 78 | Media Tile | `CMP-MED-Tile` |
| 79 | Lightbox | `CMP-MED-Lightbox` |
| 80 | Chart — Line | `CMP-CHT-Line` |
| 81 | Chart — Bar | `CMP-CHT-Bar` |
| 82 | Chart — Donut | `CMP-CHT-Donut` |
| 83 | Chart — Area | `CMP-CHT-Area` |
| 84 | Chart — Sparkline | `CMP-CHT-Sparkline` |
| 85 | Chart — Funnel | `CMP-CHT-Funnel` |
| 86 | Chart — Heatmap | `CMP-CHT-Heatmap` |
| 87 | Chart — Gauge | `CMP-CHT-Gauge` |
| 88 | Widget Frame | `CMP-WID-Frame` |
| 89 | Tree View | `CMP-DSP-Tree` |
| 90 | Kanban Column | `CMP-DSP-Kanban` |
| 91 | Command Palette | `CMP-OVL-CommandPalette` |
| 92 | Keyboard Key | `CMP-IND-Kbd` |
| 93 | Divider | `CMP-LAY-Divider` |
| 94 | Scrollbar | `CMP-LAY-Scrollbar` |
| 95 | Print Header | `CMP-PRN-Header` |

---

## 1. Button — `CMP-ACT-Button`

### 1.1 Variant Properties

| Property | Values |
|----------|--------|
| `Variant` | Primary, Secondary, Outline, Ghost, Danger, Danger Outline, Success, Link |
| `Size` | XS, SM, MD, LG |
| `State` | Default, Hover, Active, Focus, Disabled, Loading |
| `Icon` | None, Leading, Trailing, Both, Only |
| `Width` | Hug, Fill |

Total variants: 8 × 4 × 6 × 5 × 2 = manageable via Figma boolean/instance-swap for icons (build 8 × 4 × 6 = 192, with icon slots as swappable instances toggled by booleans `Has Leading Icon` / `Has Trailing Icon` / `Icon Only`).

### 1.2 Size Specification

| Size | Height | Padding X | Font | Icon | Radius | Min width | Gap |
|------|--------|-----------|------|------|--------|-----------|-----|
| XS | 28 | 10 | 12/16 500 | 12 | 6 | 60 | 6 |
| SM | 32 | 12 | 13/18 500 | 16 | 6 | 72 | 6 |
| MD | 40 | 16 | 14/20 500 | 16 | 8 | 88 | 8 |
| LG | 48 | 20 | 16/24 600 | 20 | 8 | 104 | 8 |

Icon-only widths equal heights (square), radius unchanged.

### 1.3 Variant Styling (Light Theme)

| Variant | BG | Text | Border | Hover BG | Active BG | Disabled |
|---------|-----|------|--------|----------|-----------|----------|
| Primary | `indigo-600` | white | none | `indigo-700` | `indigo-800` | `indigo-200` bg / white text |
| Secondary | `terracotta-500` | white | none | `terracotta-600` | `terracotta-700` | `terracotta-200` |
| Outline | transparent | `text-primary` | 1px `border-strong` | `bg-hover` | `neutral-200` | text-disabled, border-subtle |
| Ghost | transparent | `text-secondary` | none | `bg-hover` | `neutral-200` | text-disabled |
| Danger | `danger-600` | white | none | `danger-700` | `danger-800` | `danger-200` |
| Danger Outline | transparent | `danger-600` | 1px `danger-300` | `danger-50` | `danger-100` | opacity .5 |
| Success | `success-600` | white | none | `success-700` | `success-800` | `success-200` |
| Link | transparent | `text-link` | none | underline | `indigo-800` | text-disabled |

### 1.4 States

| State | Spec |
|-------|------|
| Hover | Background per table, 80ms transition |
| Active | Background per table + `scale(0.98)` 80ms |
| Focus | 2px `--color-focus-ring` at 2px offset |
| Disabled | Per table, `cursor: not-allowed`, no hover, tooltip if reason is non-obvious |
| Loading | Spinner 16px replaces leading icon; label remains but dimmed to 70%; width locked to prevent jump; pointer-events off; announces "Loading" |

### 1.5 Rules

- Exactly one Primary button per view region.
- Destructive actions use Danger and are never the default focused button in a dialog.
- Button order (LTR): tertiary/cancel ← secondary ← **primary** (rightmost).
- On mobile sticky bars: primary is full-width top row; secondary below or beside at 50/50.
- Labels: verb + noun. Never "OK", "Submit", "Yes".
- Loading state must be used for any action >400ms.
- Minimum 12px gap between a Danger button and its neighbour.

---

## 2. Icon Button — `CMP-ACT-IconButton`

| Property | Values |
|----------|--------|
| `Variant` | Ghost, Outline, Filled, Danger |
| `Size` | XS 24, SM 32, MD 40, LG 48 |
| `Shape` | Square (radius-md), Circle (radius-full) |
| `State` | Default, Hover, Active, Focus, Disabled, Loading |

Always requires a tooltip and accessible label. Used for: table row actions, top bar utilities, modal close, toolbar toggles, media tile overlays.

---

## 3. Button Group / Split Button — `CMP-ACT-ButtonGroup`

| Property | Values |
|----------|--------|
| `Type` | Segmented (joined), Spaced, Split |
| `Size` | SM, MD, LG |
| `Items` | 2, 3, 4, 5 |

- **Segmented:** shared border, inner dividers 1px, first/last radius only.
- **Split:** main action + 32px chevron trigger separated by 1px divider; chevron opens a Menu aligned right.
- Used for: Save / Save & New / Save & Close; Export CSV / XLSX / PDF; view density toggles.

---

## 4. Link — `CMP-ACT-Link`

| Property | Values |
|----------|--------|
| `Variant` | Default, Muted, Danger, Inverse |
| `Size` | SM 13, MD 14, LG 16 |
| `Icon` | None, External, Leading |
| `State` | Default, Hover, Focus, Visited, Disabled |

Underline on hover always. External links show `external-link` 12px trailing icon and open in a new tab (announced to screen readers).

---

## 5. Text Field — `CMP-INP-TextField`

### 5.1 Anatomy

```
Label *                                     [optional badge]
┌──────────────────────────────────────────────────────┐
│ [icon]  Placeholder or value          [action][icon] │  h=40
└──────────────────────────────────────────────────────┘
Helper text                                    12 / 200
```

### 5.2 Sizes

| Size | Height | Padding X | Font | Icon |
|------|--------|-----------|------|------|
| SM | 32 | 10 | 13 | 16 |
| MD | 40 | 12 | 14 | 16 |
| LG | 48 | 14 | 16 | 20 |

### 5.3 Variant Properties

| Property | Values |
|----------|--------|
| `Size` | SM, MD, LG |
| `State` | Default, Hover, Focus, Filled, Disabled, Readonly, Error, Warning, Success, Loading |
| `Leading` | None, Icon, Prefix Text, Select |
| `Trailing` | None, Icon, Clear, Unit, Action Button, Counter |
| `Helper` | None, Text, Error, Success |
| `Required` | True, False |

### 5.4 State Styling

| State | Border | BG | Text | Extra |
|-------|--------|-----|------|-------|
| Default | 1px `border-default` | `bg-surface` | `text-primary` | — |
| Hover | 1px `border-strong` | `bg-surface` | — | — |
| Focus | 1px `border-brand` | `bg-surface` | — | 3px ring `indigo-600` @20% |
| Filled | 1px `border-default` | `bg-surface` | — | Clear button appears if clearable |
| Disabled | 1px `border-subtle` | `bg-subtle` | `text-disabled` | not-allowed cursor |
| Readonly | 1px `border-subtle` | `bg-subtle` | `text-primary` | Copy button in trailing slot |
| Error | 1px `danger-500` | `bg-surface` | `text-primary` | `circle-alert` 16 trailing in danger; error text below |
| Warning | 1px `warning-500` | `bg-surface` | — | `triangle-alert` trailing |
| Success | 1px `success-500` | `bg-surface` | — | `check` trailing in success |
| Loading | 1px `border-default` | `bg-surface` | — | Spinner 16 trailing |

### 5.5 Label & Helper Rules

- Label: `label-lg` (14/20, 500), `text-primary`, 6px above field.
- Required marker: red asterisk after label text with 2px gap; accessible label includes "required".
- Optional marker: "(optional)" in `caption` `text-tertiary` — used only when most fields in the form are required.
- Helper text: `caption` (12/16), `text-secondary`, 6px below.
- Error text replaces helper text, `text-danger`, prefixed with a 12px `circle-alert` icon.
- Character counter: right-aligned on the helper row, `caption` `text-tertiary`; turns `warning-600` at 90%, `danger-600` at 100%.

### 5.6 Behaviour

| Behaviour | Rule |
|-----------|------|
| Validation timing | On blur for format/length; on submit for required; live for counters and uniqueness (debounced 500ms) |
| Error clearing | Clears the moment input becomes valid |
| Autofocus | First empty required field on Create; never on Edit |
| Trim | Leading/trailing whitespace trimmed on blur |
| Paste | Sanitised; multi-line paste into single-line collapses to spaces |
| Clear button | Appears when filled + focused/hovered; `ESC` also clears when focused |
| Max length | Hard-stop at max with a shake micro-animation (disabled under reduced motion) |

---

## 6. Textarea — `CMP-INP-Textarea`

| Property | Values |
|----------|--------|
| `Size` | SM, MD, LG |
| `Rows` | 3, 5, 8, Auto-grow |
| `State` | as Text Field |
| `Counter` | On, Off |
| `Resize` | None, Vertical |

Min height 88px (3 rows). Auto-grow caps at 400px then scrolls. Counter mandatory when maxlength exists.

---

## 7. Number / Stepper — `CMP-INP-Number`

```
┌───┬─────────────┬───┐
│ − │    1,240    │ + │   h=40, steppers 40×40
└───┴─────────────┴───┘
```
| Property | Values |
|----------|--------|
| `Size` | SM, MD, LG, XL (warehouse, h=56) |
| `Controls` | Steppers, Spinner, None |
| `State` | Default, Focus, Disabled, Error, Min Reached, Max Reached |

- Value right-aligned, tabular figures.
- `↑`/`↓` arrows increment/decrement; `Shift+↑` = ×10; `Page Up` = ×100.
- Stepper disabled at min/max with tooltip "Minimum is {n}".
- Negative values shown in `danger-600` where semantically negative (stock adjustment).

---

## 8. Currency Field — `CMP-INP-Currency`

- Prefix slot shows currency symbol on `bg-subtle` with a right divider.
- Value right-aligned, 2 decimals enforced on blur, thousands separators inserted live.
- Optional trailing helper showing converted value (multi-currency stores).
- Negative disallowed unless `Allow Negative` is true (refund/adjustment contexts).

---

## 9. Password Field — `CMP-INP-Password`

- Trailing `eye`/`eye-off` toggle; toggling is announced.
- Optional strength meter: 4-segment bar below (Weak `danger-500` / Fair `warning-500` / Good `info-500` / Strong `success-500`) + label + requirement checklist with live check marks.
- Caps-lock warning inline: "Caps Lock is on".
- Never autofill-disabled on login; always disabled on "set new password for another user".

---

## 10. Select / Dropdown — `CMP-INP-Select`

### 10.1 Anatomy

```
┌──────────────────────────────────────────┐
│ [icon] Selected value              [▾]   │  h=40
└──────────────────────────────────────────┘
   ┌──────────────────────────────────────┐
   │ ⌕ Search…                            │  (if searchable)
   ├──────────────────────────────────────┤
   │ GROUP LABEL                          │
   │ ✓ Option one              meta       │  h=40
   │   Option two              meta       │
   │   Option three (disabled)            │
   ├──────────────────────────────────────┤
   │ + Create new…                        │
   └──────────────────────────────────────┘
```

| Property | Values |
|----------|--------|
| `Size` | SM, MD, LG |
| `State` | Default, Hover, Focus, Open, Filled, Disabled, Error, Loading |
| `Searchable` | True, False |
| `Grouped` | True, False |
| `Clearable` | True, False |
| `Create` | True, False |

### 10.2 Menu Spec

- Width = trigger width (min 200, max 480). Max height 320px then scrolls.
- Item height 40 (SM 32). Selected item shows a 16px check on the left and `bg-selected`.
- Group headers: `overline`, sticky within scroll.
- Search appears when options > 8; debounce 200ms; highlights matched substring in `--color-text-brand` 600 weight.
- Keyboard: `↑↓` move, `↵` select, `ESC` close, type-ahead jump, `Home`/`End`.
- Loading: 3 skeleton rows. Empty: "No options found" + optional "Create '{query}'".
- Placement flips above trigger when insufficient viewport space below.

---

## 11. Multi-Select — `CMP-INP-MultiSelect`

- Selected values render as removable Tags inside the field; field grows to a max of 3 rows then scrolls.
- "Clear all" appears when ≥2 selected.
- Menu items use Checkboxes; "Select all (filtered)" row at top when searchable.
- Trailing counter "+3 more" when collapsed (compact mode used inside table cells).
- Max-selection limit shows a helper "Select up to {n}" and disables unselected items at the limit.

---

## 12. Combobox / Autocomplete — `CMP-INP-Combobox`

- Free typing queries a remote source (products, customers, SKUs, artisans, HSN codes).
- 240ms debounce; min 2 characters; inline spinner in trailing slot.
- Result rows are rich: 32px thumbnail + primary + secondary + right meta (e.g. stock, price).
- Recent selections shown before typing (max 5) under a "Recent" group.
- Announces result count on each update.

---

## 13. Checkbox — `CMP-INP-Checkbox`

| Property | Values |
|----------|--------|
| `Size` | SM 16, MD 18, LG 20 |
| `State` | Unchecked, Checked, Indeterminate, Disabled-Unchecked, Disabled-Checked, Error, Focus |
| `Label` | None, Text, Text + Helper |

- Box radius `radius-xs`, 1.5px border `border-strong`; checked = `indigo-600` fill + white check (path-draw 150ms).
- Indeterminate = `indigo-600` fill + white 2px horizontal bar (used for parent "select all" with partial selection).
- Label click toggles; hit area covers label + 8px padding.
- Checkbox group with error shows a group-level error message below the last item.

---

## 14. Radio — `CMP-INP-Radio`

| Property | Values |
|----------|--------|
| `Size` | SM 16, MD 18, LG 20 |
| `State` | Unselected, Selected, Disabled, Focus, Error |
| `Layout` | Inline, Stacked, Card |

- **Card radio**: bordered 1px card with radio top-left, title, description, optional icon/illustration; selected = 2px `border-brand` + `bg-selected`. Used for: payment method, offer type, shipping rate type, report format.
- Arrow keys move selection within a group (standard radio semantics).

---

## 15. Switch / Toggle — `CMP-INP-Switch`

| Property | Values |
|----------|--------|
| `Size` | SM (32×18), MD (44×24), LG (52×28) |
| `State` | Off, On, Disabled-Off, Disabled-On, Focus, Loading |
| `Label` | None, Right, Left, With Description |

- Track off = `neutral-300`; on = `indigo-600`; knob white with `elevation-1`.
- Loading: knob becomes a 12px spinner; track at 60% opacity.
- Used for instant-apply settings only (publish, active, featured). Never inside a form that requires Save — use Checkbox there.
- Every switch toggle emits a toast confirming the new state, with Undo where reversible.

---

## 16. Segmented Control — `CMP-INP-Segmented`

| Property | Values |
|----------|--------|
| `Size` | SM 32, MD 40 |
| `Items` | 2, 3, 4, 5 |
| `Type` | Text, Icon, Text + Icon |

Track `bg-subtle` radius-md, 2px inner padding; selected pill = `bg-surface` + `elevation-1`; indicator slides 240ms. Used for: chart period (D/W/M/Y), density, list/grid view, theme.

---

## 17. Slider / Range — `CMP-INP-Slider`

| Property | Values |
|----------|--------|
| `Type` | Single, Range |
| `State` | Default, Hover, Focus, Disabled |
| `Marks` | None, Ticks, Labelled |

Track 4px `neutral-200`, filled `indigo-600`, thumb 20px white with 2px `indigo-600` border and `elevation-1`. Value tooltip appears on drag. Always paired with numeric inputs for exact entry (price filter, discount range).

---

## 18. Date Picker — `CMP-INP-DatePicker`

### 18.1 Anatomy

```
┌──────────────────────────────────────┐
│ 📅 03 Aug 2026                   [×] │
└──────────────────────────────────────┘
 ┌────────────────────────────────────┐
 │  ‹   August 2026 ▾   2026 ▾    ›   │
 │  Mo Tu We Th Fr Sa Su              │
 │  ...  01 02 03 04 05 06            │
 │  07 08 09 10 11 12 13              │
 ├────────────────────────────────────┤
 │ Today            [Clear]  [Apply]  │
 └────────────────────────────────────┘
```

| Property | Values |
|----------|--------|
| `State` | Default, Focus, Open, Filled, Disabled, Error |
| `Mode` | Date, Month, Quarter, Year |
| `Constraints` | None, Min, Max, Min+Max, Disabled Dates |

- Cell 36×36, radius-md. Today = 1px `border-brand`. Selected = `indigo-600` fill white text. In-range = `indigo-50`. Disabled = `text-disabled`, not selectable, tooltip on hover explaining why.
- Weekend column headers in `text-tertiary`; Indian public holidays optionally dotted (`terracotta-500` dot) with a tooltip.
- Manual typing accepted in `DD/MM/YYYY`, `DD-MM-YYYY`, `DD MMM YYYY`; invalid input shows error "Enter a valid date (DD/MM/YYYY)".
- Keyboard: arrows move by day, `PgUp/PgDn` by month, `Shift+PgUp/PgDn` by year, `Home/End` week bounds, `↵` select, `ESC` close.

---

## 19. Date Range Picker — `CMP-INP-DateRange`

- Dual month view on desktop (≥768), single month with month toggle on mobile.
- Left rail of presets: Today, Yesterday, Last 7 Days, Last 30 Days, This Month, Last Month, This Quarter, This Financial Year (Apr–Mar), Last Financial Year, Custom.
- Selected range fill `indigo-50` with rounded ends; hover previews the prospective range.
- Footer shows "{start} – {end} · {n} days" plus Cancel / Apply.
- Comparison toggle: "Compare to previous period / same period last year" (used by Reports & Dashboard).
- Validation: end ≥ start; max range configurable per module (e.g. 366 days for reports) with message "Select a range of 366 days or less."

---

## 20. Time Picker — `CMP-INP-TimePicker`

- Trigger shows `hh:mm A`. Dropdown = three scroll columns (Hour, Minute, AM/PM) or a 15-minute interval list depending on `Granularity` (1, 5, 15, 30 min).
- "Now" quick action.
- 12h display, 24h optional per user preference.
- Used for: flash sale windows, scheduled publishing, campaign send time, delivery slots, business hours.

---

## 21. Date-Time Picker — `CMP-INP-DateTime`

Calendar + time column side by side; footer shows resolved value plus timezone abbreviation and a timezone selector when the store operates across zones. Validation: "Scheduled time must be in the future."

---

## 22. Colour Picker — `CMP-INP-ColorPicker`

- Trigger: 24px swatch + hex value + chevron.
- Panel: saturation/value area, hue slider, alpha slider (optional), hex/RGB inputs, 12 preset craft swatches (indigo, terracotta, brass, natural jute, ivory, charcoal, madder red, turmeric, forest, sky, rose, mint), eyedropper.
- Used for: product colour attribute swatches, banner overlay colour, category tile colour, theme accents.
- Validation: hex format; contrast warning if chosen text/background pair falls below 4.5:1 ("This combination may be hard to read").

---

## 23. Rich Text Editor — `CMP-INP-RichText`

### 23.1 Toolbar Groups

| Group | Controls |
|-------|----------|
| History | Undo, Redo |
| Block | Paragraph/H2/H3/H4 select, Quote, Code block |
| Inline | Bold, Italic, Underline, Strikethrough, Inline code, Clear formatting |
| Lists | Bullet, Numbered, Checklist, Indent, Outdent |
| Insert | Link, Image, Video embed, Table, Divider, Product card, Emoji |
| Alignment | Left, Centre, Right, Justify |
| View | Source/HTML toggle, Full screen, Preview |

### 23.2 Spec

- Toolbar sticky at editor top, 44px, wraps into a "More" overflow below 768px.
- Editor min height 320px, max 720px then scrolls; content column max 720px for readability.
- Bubble toolbar appears on text selection (Bold, Italic, Link, H2, Quote).
- Slash command `/` opens an insert menu.
- Word/character count in the bottom bar plus estimated reading time.
- Image insert opens the Media Library picker (never a raw file input alone).
- Paste from Word/Google Docs is sanitised; a toast offers "Keep formatting / Paste as plain text".
- Autosave indicator in the bottom bar.
- Accessibility: full keyboard shortcuts, toolbar as a proper toolbar widget with roving tabindex.

---

## 24. Tag Input — `CMP-INP-TagInput`

- Type + `Enter`/`,` creates a tag; `Backspace` on empty removes the last.
- Autocomplete suggests existing tags with usage counts.
- Duplicate attempt shakes the existing tag and shows "Already added".
- Max tags enforced with counter "12 / 20".
- Used for: product tags, blog tags, SEO keywords, customer segments.

---

## 25. File Upload — `CMP-INP-FileUpload`

### 25.1 Dropzone

```
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
│              [ ⬆ 32 ]                    │
│      Drag files here or Browse           │
│   CSV, XLSX up to 10 MB · Max 5 files    │
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```
- 2px dashed `border-default`, radius-lg, min height 160, `bg-subtle` at 50%.
- Drag-over: `border-brand` 2px solid + `bg-selected` + icon scales 1.1.
- File row: type icon 32 + name + size + progress bar + status icon + remove.
- Progress: determinate bar with % and "1.2 MB of 4.8 MB".
- Errors per file: "File too large (max 10 MB)", "Unsupported format", "Upload failed — Retry".
- Keyboard: dropzone is a button; `Enter/Space` opens the file dialog.

---

## 26. Image Upload — `CMP-INP-ImageUpload`

| Property | Values |
|----------|--------|
| `Type` | Single, Multiple, Gallery |
| `Aspect` | 1:1, 4:3, 16:9, 3:1, Free |
| `State` | Empty, Uploading, Uploaded, Error, Processing |

- Grid of tiles (multiple mode), 120×120 desktop / 96×96 mobile, `+ Add` tile last.
- Tile overlay on hover: Preview (eye), Set as thumbnail (star), Edit/Crop (crop), Alt text (type), Delete (trash).
- Drag to reorder with a `grip` handle; first tile carries a "Thumbnail" badge.
- Built-in cropper modal: aspect lock presets, zoom slider, rotate 90°, flip, reset, live preview at 3 output sizes.
- Alt text prompt is mandatory before save for storefront-visible images — an amber "Missing alt text" chip appears otherwise.
- Validation: min 800×800 for product images (warning, not blocker), max 5 MB, JPG/PNG/WEBP/AVIF.

---

## 27. Form Field Wrapper — `CMP-FRM-Field`

Provides consistent Label / Required / Tooltip / Control / Helper / Error / Counter arrangement. Variant properties: `Layout` (Stacked, Inline, Horizontal-Label), `State` (Default, Error, Warning, Success, Disabled), `Helper` (None, Text, Error).

Horizontal-label layout: label column 200px right-aligned, control column fills — used in Settings only.

---

## 28. Form Section — `CMP-FRM-Section`

```
┌──────────────────────────────────────────────────────┐
│ Section Title                            [Optional ▾]│  heading-sm
│ Short description of this section.                   │  caption
├──────────────────────────────────────────────────────┤
│  fields…                                             │
└──────────────────────────────────────────────────────┘
```
Variants: `Collapsible` (True/False), `State` (Expanded, Collapsed), `Status` (Default, Has Errors, Complete). Sections with errors show a danger count chip in the header and cannot be collapsed while invalid.

---

## 29. Card — `CMP-SRF-Card`

| Property | Values |
|----------|--------|
| `Padding` | None, Compact 16, Standard 24 |
| `Header` | None, Title, Title + Action, Title + Tabs |
| `Footer` | None, Actions, Meta |
| `State` | Default, Hover, Selected, Disabled, Loading |
| `Elevation` | Flat (border only), Raised (elevation-1) |

Default: `bg-surface`, 1px `border-default`, `radius-lg`, `elevation-1` on hover if clickable. Card header 56px with 20px title, divider optional.

---

## 30. Stat / KPI Card — `CMP-SRF-StatCard`

### 30.1 Anatomy

```
┌────────────────────────────────────────┐
│ ┌────┐  TOTAL SALES              [ⓘ]  │   overline + info tooltip
│ │ 💰 │                                 │
│ └────┘  ₹12,45,800                     │   numeric-xl
│         ▲ 12.4%  vs last month         │   delta
│         ▁▂▄▆█▇▅  (sparkline)           │
├────────────────────────────────────────┤
│ View report →                          │   optional footer link
└────────────────────────────────────────┘
```

| Property | Values |
|----------|--------|
| `Size` | SM (h 108), MD (h 140), LG (h 176) |
| `Trend` | None, Up, Down, Flat |
| `Sparkline` | On, Off |
| `Icon` | On, Off |
| `State` | Default, Loading, Error, Empty, No Permission |
| `Emphasis` | Default, Highlighted (2px brand border) |

- Delta colour: semantic to the metric, not to direction. Rising "Cancelled Orders" is `danger`; rising "Revenue" is `success`. Each widget declares `positiveDirection`.
- Info tooltip gives the exact metric definition and calculation window.
- Whole card is clickable → drill-through; hover raises elevation and shows a `chevron-right` at the right edge.
- Loading: skeleton for label (60×10), value (140×28), delta (90×12).
- Error: `circle-alert` + "Couldn't load" + inline "Retry".

---

## 31. Panel — `CMP-SRF-Panel`

Lightweight grouping surface without a border, used inside cards: `bg-subtle`, radius-md, padding 16. Variants: `Tone` (Neutral, Info, Success, Warning, Danger, Craft/Terracotta).

---

## 32. Data Table — `CMP-DAT-Table`

### 32.1 Anatomy

```
┌───────────────────────────────────────────────────────────────────────────┐
│ [☐] │ Image │ Name ⇅        │ SKU     │ Category │ Price ⇅ │ Stock │ ● │ ⋮ │  header 44
├───────────────────────────────────────────────────────────────────────────┤
│ [☐] │ [img] │ Blue Pottery… │ HC-1001 │ Décor    │ ₹1,250  │  24   │ ● │ ⋮ │  row 52
│ [☐] │ [img] │ Brass Diya…   │ HC-1002 │ Festive  │ ₹  450  │   3   │ ● │ ⋮ │
└───────────────────────────────────────────────────────────────────────────┘
```

### 32.2 Variant Properties

| Property | Values |
|----------|--------|
| `Density` | Comfortable, Standard, Compact |
| `Selection` | None, Single, Multi |
| `Stickiness` | None, Header, Header + First Column, Header + First + Last |
| `Row State` | Default, Hover, Selected, Focused, Disabled, Error, New, Editing |
| `State` | Loaded, Loading, Empty, Filtered-Empty, Error |
| `Zebra` | On, Off |

### 32.3 Specification

| Element | Spec |
|---------|------|
| Header | 44px, `bg-subtle`, `label-md` 13/18 600, `text-secondary`, bottom 1px `border-default`, sticky |
| Sortable header | Cursor pointer, `arrow-up-down` 14px at 40% opacity; active shows filled arrow + `text-primary`; announces sort state |
| Row height | Comfortable 64 / Standard 52 / Compact 40 |
| Row divider | 1px `border-subtle` |
| Row hover | `bg-hover`; row actions fade in |
| Row selected | `bg-selected` + 3px left `indigo-600` bar |
| Row focused | 2px inset focus ring |
| Checkbox column | 48px fixed, centred |
| Image column | 64px fixed (48px thumb) |
| Actions column | 96px fixed, right sticky, right-aligned |
| Numeric columns | Right-aligned, tabular |
| Status column | Centred or left per module spec |
| Empty cell | `—` in `text-tertiary` |
| Horizontal scroll | Shadow gradient appears on the sticky column edge when scrolled |
| Max columns visible | 12; beyond that use the Column Manager |
| Virtualisation | Enabled beyond 100 rows |
| Row expansion | Optional chevron column 40px; expanded panel spans full width with `bg-subtle` |
| Inline edit | Double-click or `Enter` on a focused editable cell; cell becomes an input with Save/Cancel icons; `Esc` cancels, `Tab` commits and moves right |
| Drag reorder | `grip-vertical` handle in a 40px first column; keyboard alternative "Move to position…" in the row menu |
| Grouping | Optional sticky group header rows with count and collapse toggle |
| Totals | Optional sticky footer row, `bg-subtle`, 600 weight |

### 32.4 Column Definition Schema (used by every module's §20)

| Attribute | Meaning |
|-----------|---------|
| Key | Data field |
| Label | Header text |
| Width | Fixed px / min-max / flex |
| Align | left / right / centre |
| Sortable | yes / no |
| Default sort | asc / desc / — |
| Priority | 1 (always visible) → 4 (hidden by default) |
| Cell type | text, link, numeric, currency, date, chip, avatar+text, image, tags, progress, actions, boolean-icon |
| Truncate | chars before ellipsis |
| Permission | role gate if any |

---

## 33. Table Row Actions — `CMP-DAT-RowActions`

- Up to 3 icon buttons inline (32px) + overflow `more-vertical`.
- Always visible on touch devices; fade in on hover for pointer devices (but remain in the tab order).
- Overflow menu groups: Primary actions · Secondary actions · Destructive (separated by a divider, danger-coloured).
- Menu opens aligned to the right edge, flips upward near the viewport bottom.

---

## 34. Pagination — `CMP-DAT-Pagination`

```
Showing 1–25 of 1,482            [25 ▾] per page   ‹‹  ‹  1 2 3 … 60  ›  ››   Go to [ 12 ]
```

| Property | Values |
|----------|--------|
| `Type` | Numbered, Simple (prev/next), Load More, Infinite |
| `Size` | SM, MD |
| `State` | Default, First Page, Last Page, Single Page, Loading |

- Page size options: 10, 25, 50, 100, 200 (200 warns "Large page sizes may load slowly").
- Buttons 32×32, radius-md; current page = `indigo-600` fill, white text.
- Ellipsis when >7 pages; always shows first, last, current ±1.
- Mobile: Simple type only, "Page 3 of 60" centred between prev/next.
- Selection persists across pages; the Bulk Bar shows "25 on this page selected · Select all 1,482".
- Position: bottom of the table, and additionally at the top for tables over 50 rows.

---

## 35. Bulk Action Bar — `CMP-DAT-BulkBar`

```
┌──────────────────────────────────────────────────────────────────────┐
│ ✓ 12 selected   Select all 1,482    │  [Edit] [Publish] [Export] [⋮] │  [Clear]
└──────────────────────────────────────────────────────────────────────┘
```
- Appears as a sticky bar directly beneath the toolbar (desktop) or floating above the bottom bar (mobile), sliding in 240ms.
- `bg-inverse` with inverse text (high visibility), radius-lg, elevation-3.
- Max 4 inline actions, rest in overflow. Destructive actions always last, danger-tinted.
- Every bulk action opens a confirmation modal stating the exact count and consequence.
- Progress modal for operations >20 records with per-item results and a downloadable failure report.

---

## 36. Filter Bar — `CMP-DAT-FilterBar`

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [⌕ Search products…      ] [Category ▾][Status ▾][Stock ▾][+ More Filters] │
│ Active: (Category: Décor ×) (Status: Published ×) (Stock: Low ×)  Clear all │
└────────────────────────────────────────────────────────────────────────────┘
```
- Up to 4 primary filters inline; the rest live behind "More Filters" which opens a Drawer (desktop) or full-screen sheet (mobile).
- Active filters render as removable chips on a second row with an "N filters" count and "Clear all".
- Filters apply immediately (no Apply button) except inside the drawer, which uses Apply/Reset.
- Filter state is encoded in the URL for shareability and is restored on back-navigation.
- "Save as view" action turns the current filter+sort+columns combination into a Saved View.

---

## 37. Filter Chip — `CMP-DAT-FilterChip`

| Property | Values |
|----------|--------|
| `Type` | Static, Removable, Dropdown, Count |
| `State` | Default, Hover, Active, Disabled |

Height 28 (SM) / 32 (MD), radius-full, `bg-subtle` default, `bg-selected` + `border-brand` when active. Dropdown type shows a trailing chevron and a value count badge.

---

## 38. Search Field — `CMP-DAT-Search`

- Leading `search` 16px; trailing clear `x` when filled; optional trailing `⌘K` or `/` keyboard hint.
- Debounce 300ms; minimum 2 characters; inline spinner while querying.
- Result count announced: "42 results".
- Recent searches dropdown (max 5) on focus when empty.
- Scope selector (optional leading Select): "All fields ▾ / Name / SKU / Barcode".

---

## 39. Saved View Selector — `CMP-DAT-SavedView`

- Trigger shows the active view name + chevron; unsaved modifications add a "• Modified" dot.
- Menu lists: My Views · Shared Views · System Views (All, Drafts, Low Stock, etc.).
- Row actions per view: Rename, Duplicate, Set as default, Share with role, Delete.
- "Save changes" / "Save as new view" appear when modified.

---

## 40. Column Manager — `CMP-DAT-ColumnManager`

- Popover/drawer listing all columns with checkboxes, drag handles for order, pin left/right toggles and width reset.
- "Reset to default" action.
- Locked columns (e.g. Name, Actions) show a lock icon and are non-removable.
- Preferences persist per user per module.

---

## 41. Tabs — `CMP-NAV-Tabs`

| Property | Values |
|----------|--------|
| `Type` | Underline, Pill, Enclosed, Vertical |
| `Size` | SM 36, MD 44 |
| `State` | Default, Hover, Active, Focus, Disabled |
| `Badge` | None, Count, Dot, Warning |
| `Icon` | None, Leading |

- Underline (default): 2px `indigo-600` indicator, sliding 240ms; active label `text-primary` 600; inactive `text-secondary`.
- Count badge shows record counts; warning dot (danger) flags tabs containing validation errors — mandatory on multi-tab forms.
- Overflow: horizontal scroll with edge fade + chevron scroll buttons; on mobile, a Select replaces tabs when >4.
- Keyboard: `←/→` move, `Home/End`, `Tab` enters the panel. Tab panels are lazily loaded but state-preserved.
- Deep-linkable via URL hash for prototype and dev parity.

---

## 42. Breadcrumb — `CMP-NAV-Breadcrumb`

```
Dashboard / Catalog / Products / Blue Pottery Vase / Edit
```
- Separator `/` in `text-tertiary` with 8px gaps; items `body-sm` 13; last item `text-primary` 500, non-clickable.
- Truncation: >4 levels collapses the middle into `…` with a popover listing hidden levels.
- Includes a "Back" chevron button on detail pages that returns to the filtered list (preserving state).
- Mobile: shows only "‹ {parent}".
- Record names in breadcrumbs truncate at 32 chars with a tooltip.

---

## 43–44. Sidebar & Sidebar Item — `CMP-NAV-Sidebar`, `CMP-NAV-SidebarItem`

### Sidebar Variants
`State`: Expanded (264), Collapsed (72), Mobile Drawer (280 overlay).

### Sidebar Item Variants
`Level`: 1, 2 · `State`: Default, Hover, Active, Active-Parent, Focus, Disabled · `Badge`: None, Count, Dot · `Icon`: On (L1), Off (L2) · `Collapsed`: True/False

| Element | Spec |
|---------|------|
| Item height | 40 (L1), 36 (L2) |
| Padding | 10 × 12; L2 indents to 44 left |
| Icon | 20px, 12px gap to label |
| Label | `body-md` 14/20, 500 when active |
| Active | `bg-selected`, `text-brand`, 3px left accent bar, icon brand-coloured |
| Active parent | Label `text-primary` 600, chevron rotated |
| Badge | Right-aligned pill, `danger-500` for attention counts (pending orders), `neutral-200` otherwise |
| Collapsed | Icon only, centred; label appears as a tooltip 12px right after 300ms; badge becomes a 8px dot at the icon's top-right |
| Group header | 32px, `overline`, `text-tertiary`, 16px top margin |
| Footer | "Collapse" toggle with `chevrons-left`, plus version label |
| Scroll | Independent scroll with a thin scrollbar; header/footer pinned |

---

## 45. Top Bar — `CMP-NAV-TopBar`

Variants: `Breakpoint` (Desktop, Tablet, Mobile) · `Environment` (Production, Staging) · `Impersonating` (True/False — adds a 32px orange strip above).

---

## 46. Footer — `CMP-NAV-Footer`

48px, `body-sm` `text-tertiary`. Left: `© 2026 {Company}`. Centre: Help · Documentation · Keyboard Shortcuts · Changelog. Right: `v1.0.0` + system status dot (green Online / amber Degraded / red Incident) linking to System Health.

---

## 47. Page Header — `CMP-NAV-PageHeader`

| Property | Values |
|----------|--------|
| `Type` | Simple, With Subtitle, With Meta, With Tabs, With Back |
| `Actions` | 0, 1, 2, 3, Overflow |
| `State` | Default, Sticky-Compact |
| `Status` | None, Chip |

```
◀  Blue Pottery Vase  [● Published]                [Preview] [Duplicate] [⋮] [Save Product]
   SKU HC-1001 · Updated 2 hours ago by Anand      
```
Sticky-compact (after 120px scroll): height 56, title drops to `heading-sm`, subtitle hidden, actions persist, 1px bottom border + elevation-1 appears.

---

## 48. Stepper / Wizard — `CMP-NAV-Stepper`

| Property | Values |
|----------|--------|
| `Orientation` | Horizontal, Vertical |
| `Steps` | 2–8 |
| `Step State` | Upcoming, Current, Complete, Error, Skipped, Disabled |
| `Size` | SM, MD |

- Node 32px circle: Upcoming = `neutral-200` border + number; Current = `indigo-600` fill + white number + 4px halo; Complete = `success-600` fill + white check; Error = `danger-600` fill + `!`.
- Connector 2px line, `success-600` when the preceding step is complete.
- Labels below (horizontal) or right (vertical): title `label-md` + optional caption.
- Completed steps are clickable to return; upcoming steps are locked until valid.
- Mobile: "Step 3 of 5 — Pricing" + 4px progress bar.

---

## 49. Accordion — `CMP-NAV-Accordion`

| Property | Values |
|----------|--------|
| `Type` | Single-open, Multi-open |
| `Style` | Bordered, Separated, Flush |
| `State` | Collapsed, Expanded, Disabled, Error |

Header 56px: optional icon, title `heading-xs`, optional meta right, chevron rotating 180° in 240ms. Body padding 20 with a top divider. Error state shows a danger count chip and auto-expands on submit.

---

## 50. Menu / Dropdown Menu — `CMP-NAV-Menu`

- Min width 200, max 320; item height 40; radius-md; elevation-3; 4px inner padding.
- Item anatomy: leading icon 16 · label · trailing shortcut/meta/chevron (submenu).
- Sections separated by 1px dividers with optional `overline` section labels.
- Destructive items in `text-danger` with a divider above.
- Checkable items show a leading check (single-select) or checkbox (multi-select).
- Submenus open on hover (150ms delay) or `→`; flip when near the viewport edge.
- Keyboard: `↑↓`, `↵`, `ESC`, type-ahead, `←` closes submenu.

---

## 51. Modal — `CMP-OVL-Modal`

### 51.1 Sizes

| Size | Width | Use |
|------|-------|-----|
| XS | 400 | Confirmations |
| SM | 520 | Simple forms, alerts |
| MD | 640 | **Default** — standard forms |
| LG | 800 | Complex forms, previews |
| XL | 1000 | Tables inside modals, comparisons |
| Full | 100vw − 64 | Media editors, bulk import mapping |

### 51.2 Anatomy

```
┌──────────────────────────────────────────────────┐
│ [icon] Modal Title                          [×]  │  header 64
├──────────────────────────────────────────────────┤
│                                                  │
│  Body content (max-height 60vh, scrolls)         │  padding 24
│                                                  │
├──────────────────────────────────────────────────┤
│ [Helper text]              [Cancel]  [Primary]   │  footer 72
└──────────────────────────────────────────────────┘
```

### 51.3 Variant Properties

| Property | Values |
|----------|--------|
| `Size` | XS, SM, MD, LG, XL, Full |
| `Type` | Default, Confirmation, Destructive, Success, Error, Form, Loading |
| `Header` | Title, Title + Icon, Title + Subtitle, None |
| `Footer` | 1 Action, 2 Actions, 3 Actions, Split, None |
| `Scroll` | Body, Full |
| `State` | Default, Loading, Submitting, Error |

### 51.4 Rules

- Scrim `--color-bg-overlay`, blur 2px. Click on scrim closes only non-destructive, non-dirty modals; otherwise triggers the unsaved-changes guard.
- `ESC` closes with the same rule.
- Focus moves to the first interactive element (or the modal title if none) on open; returns to the trigger on close.
- Never nest modals more than 2 deep; prefer a drawer or a stepped modal instead.
- Body max-height 60vh with sticky header/footer; a 1px divider + subtle shadow appears on the scrolled edge.
- Mobile: becomes a full-screen sheet with the header as a bar and the footer sticky at the bottom (safe-area padded).
- Destructive type: danger icon in a `danger-50` circle, danger primary button, and the primary button is **not** auto-focused.

---

## 52. Drawer — `CMP-OVL-Drawer`

| Property | Values |
|----------|--------|
| `Position` | Right, Left, Bottom |
| `Width` | SM 400, MD 480, LG 560, XL 720, Full |
| `Type` | Detail, Form, Filter, Notifications, Help |
| `Footer` | None, Actions, Sticky Actions |
| `State` | Default, Loading, Empty, Error |

- Header 64: title + optional subtitle + close; optional record navigation (`‹ ›` "3 of 42").
- Detail drawers support "Open full page →" in the footer.
- Bottom drawers (mobile) have a 40×4 grab handle and are swipe-dismissible; snap points 50% / 90%.
- Only one drawer at a time; opening another replaces it with a cross-fade.

---

## 53. Popover — `CMP-OVL-Popover`

Radius-lg, elevation-3, padding 16, max width 360, 12px arrow optional. Trigger: click (default) or hover (info only). Used for: column manager, quick filters, help content, colour picker, mini-forms (add note, change quantity).

---

## 54. Tooltip — `CMP-OVL-Tooltip`

| Property | Values |
|----------|--------|
| `Placement` | Top, Bottom, Left, Right (+ start/end alignment) |
| `Size` | SM (single line), MD (multi-line, max 280) |
| `Type` | Plain, With Title, With Shortcut |

`bg-inverse`, `text-inverse`, `caption` 12/16, padding 8×12, radius-md, 6px arrow. Delay in 300ms, out 100ms. Never contains interactive content (use a Popover). Truncated text tooltips show the full value.

---

## 55. Toast — `CMP-FBK-Toast`

```
┌────────────────────────────────────────────────┐
│ ✓  Product published                      [×]  │
│    "Blue Pottery Vase" is now live.            │
│    [View Product]  [Undo]                      │
└────────────────────────────────────────────────┘
```

| Property | Values |
|----------|--------|
| `Type` | Success, Error, Warning, Info, Loading, Progress |
| `Content` | Title only, Title + Body, Title + Body + Actions |
| `Dismiss` | Auto, Manual |

- Width 360 (desktop) / calc(100% − 32) (mobile), radius-lg, elevation-5, left 4px accent bar in the type colour.
- Durations: Success 4s, Info 5s, Warning 6s, Error manual, Loading until resolved.
- Auto-dismiss pauses on hover/focus; a 2px bottom progress line shows the remaining time.
- Max 3 stacked, newest on top, 12px gap; overflow collapses to "+N more".
- Undo window 8s where offered; the toast persists for the full window.
- Position: top-right desktop, bottom-centre mobile (above bottom bar/safe area).

---

## 56. Alert / Banner — `CMP-FBK-Alert`

| Property | Values |
|----------|--------|
| `Type` | Info, Success, Warning, Danger, Neutral, Craft |
| `Style` | Inline (in-page), Page-level, Global (full-bleed top) |
| `Dismissible` | True, False |
| `Actions` | None, Link, Buttons |
| `Icon` | On, Off |

Left 3px accent bar, tinted background (50-step), 1px border (200-step), icon 20, title `label-lg` 600, body `body-sm`. Global banners sit above the top bar and push content down (never overlay).

---

## 57. Inline Message — `CMP-FBK-InlineMessage`

12–13px message with a 14px leading icon, used under fields, inside table cells and beside toggles. Types: Error, Warning, Success, Info, Hint.

---

## 58. Progress Bar — `CMP-FBK-Progress`

| Property | Values |
|----------|--------|
| `Type` | Determinate, Indeterminate, Segmented, Circular |
| `Size` | XS 2, SM 4, MD 8, LG 12 |
| `Label` | None, Percent, Fraction, Text |
| `Tone` | Brand, Success, Warning, Danger |

Track `neutral-200` radius-full; fill radius-full; transitions 240ms. Circular variant sizes 24/40/64 with a centred percentage. Segmented used for password strength and profile-completion meters. Colour shifts to warning >80% / danger =100% only for capacity meters (storage, usage limits).

---

## 59. Spinner — `CMP-FBK-Spinner`

Sizes 12/16/20/24/32/48. 2px stroke (3px at ≥32), `indigo-600` arc on `neutral-200` track, 800ms linear rotation. Always paired with a text label when it is the sole page content ("Loading orders…").

---

## 60. Skeleton — `CMP-FBK-Skeleton`

| Property | Values |
|----------|--------|
| `Shape` | Text, Heading, Circle, Rect, Thumbnail, Chip, Button |
| `Width` | 25%, 50%, 75%, 100%, Fixed |
| `Animation` | Shimmer, Pulse, None |

`neutral-100` base with a 1400ms gradient sweep; dark theme uses `rgba(148,163,184,0.10)`. Composed presets: Table Skeleton (header + 8 rows), Card Skeleton, KPI Skeleton, Form Skeleton, Detail Skeleton, Chart Skeleton. Skeletons must mirror the real layout's geometry — never generic blocks.

---

## 61. Empty State — `CMP-FBK-EmptyState`

```
              ┌─────────────┐
              │ illustration│   160×160
              └─────────────┘
              No products yet
     Add your first product to start selling.
        [ + Add Product ]   [ Import CSV ]
              Learn about products →
```

| Property | Values |
|----------|--------|
| `Size` | SM (in card, icon 48), MD (in table, illus 120), LG (full page, illus 160) |
| `Type` | No Data, No Results, No Permission, Not Configured, Coming Soon, Success/All Clear |
| `Actions` | None, Primary, Primary + Secondary |

Heading `heading-sm`; body `body-md` `text-secondary`, max 400px, centred. Illustrations are line-art in brand + terracotta with dedicated dark variants.

---

## 62. Error State — `CMP-FBK-ErrorState`

| Property | Values |
|----------|--------|
| `Scope` | Inline, Card, Section, Page |
| `Type` | Load Failed, Save Failed, Network, Timeout, Server, Forbidden, Not Found, Conflict |

Contains: icon 48/64 `danger-500`, heading, plain-language cause, recovery actions (Try Again / Go Back / Contact Support), and a copyable monospace error reference `ERR-{module}-{code}-{traceId}`.

---

## 63. Success State — `CMP-FBK-SuccessState`

Full-screen or card confirmation used after wizards, imports and campaign sends. Contains: animated check (circle draw 300ms + check 200ms), heading, summary metrics (e.g. "48 products imported · 2 skipped"), and next-step actions (View, Create Another, Download Report, Back to List).

---

## 64. Badge — `CMP-IND-Badge`

| Property | Values |
|----------|--------|
| `Type` | Count, Dot, Text |
| `Tone` | Neutral, Brand, Success, Warning, Danger, Info, Brass |
| `Size` | SM 16, MD 20 |
| `Position` | Standalone, Overlay (top-right of a host) |

Count caps at 99+. Dot 8px. Overlay badges have a 2px surface-coloured ring for separation.

---

## 65. Status Chip — `CMP-IND-StatusChip`

| Property | Values |
|----------|--------|
| `Status` | (enumerated per §2.9 of the Design System) |
| `Style` | Soft (tinted bg + coloured text), Solid (filled), Outline |
| `Size` | SM 20, MD 24, LG 28 |
| `Dot` | On, Off |
| `Icon` | On, Off |

Radius-full, padding 2×8 (SM) / 4×10 (MD). Soft is the default in tables; Solid is used on detail-page headers. Chips are non-interactive unless they open a status-change menu — then they show a trailing chevron and a hover background.

---

## 66. Tag — `CMP-IND-Tag`

Removable label for keywords/attributes: radius-xs (rectangular, distinguishing it from status chips), `bg-subtle`, `text-secondary`, optional leading colour dot, trailing `x` (12px). Overflow: "+N" chip with a popover listing the rest.

---

## 67. Label — `CMP-IND-Label`

Static text descriptor used in description lists and detail panels: `label-md` `text-secondary`, optional info icon with tooltip, optional required asterisk.

---

## 68. Counter / Notification Dot — `CMP-IND-Counter`

Used on the bell, sidebar items and tabs. Pulse animation (scale 1→1.15→1, 600ms) once on increment; disabled under reduced motion.

---

## 69. Rating Stars — `CMP-IND-Rating`

| Property | Values |
|----------|--------|
| `Mode` | Display, Interactive |
| `Size` | SM 14, MD 18, LG 24 |
| `Precision` | Whole, Half |
| `Meta` | None, Count, Average + Count |

Filled `brass-300`, empty `neutral-200` outline. Interactive mode: hover preview, keyboard arrows, clear via "0". Display mode shows "4.5 (128)".

---

## 70. Avatar — `CMP-IND-Avatar`

| Property | Values |
|----------|--------|
| `Size` | XS 20, SM 24, MD 32, LG 40, XL 56, 2XL 80 |
| `Type` | Image, Initials, Icon |
| `Shape` | Circle, Square (radius-md) |
| `Status` | None, Online, Away, Busy, Offline |
| `Ring` | None, Brand, Success, Danger |

Initials background derived deterministically from a name hash across 8 accessible tints; text always meets 4.5:1. Status dot bottom-right with a 2px surface ring.

---

## 71. Avatar Group — `CMP-IND-AvatarGroup`

Max 5 shown with −8px overlap and 2px surface rings; overflow "+N" avatar opens a popover listing all people.

---

## 72. Profile Card — `CMP-IND-ProfileCard`

```
┌──────────────────────────────────────────────┐
│  ┌────┐  Priya Sharma            [● Active]  │
│  │ 80 │  Operations Head                     │
│  └────┘  priya@company.com                   │
│          +91 98765 43210                     │
├──────────────────────────────────────────────┤
│  Role: Admin      Last login: 2 hours ago    │
│  Orders: 1,204    Since: Jan 2024            │
├──────────────────────────────────────────────┤
│  [Message]  [Edit]              [⋮]          │
└──────────────────────────────────────────────┘
```
Variants: `Type` (Admin User, Customer, Artisan), `Size` (Compact, Standard, Expanded), `State` (Default, Loading, Blocked). Customer variant adds lifetime value, order count, reward points and a segment chip. Artisan variant adds craft cluster, region, product count and a story excerpt.

---

## 73. Timeline — `CMP-DSP-Timeline`

```
 ●───  Order Placed                       03 Aug 2026, 10:24 AM
 │     by Customer · Payment: Razorpay
 │
 ●───  Payment Confirmed                  03 Aug 2026, 10:25 AM
 │     ₹4,250.00 · TXN-7712341
 │
 ◉───  Processing                         03 Aug 2026, 11:02 AM   ← current
 │     by Karan (Order Manager)
 │
 ○───  Packed                             Pending
 ○───  Shipped                            Pending
```

| Property | Values |
|----------|--------|
| `Orientation` | Vertical, Horizontal |
| `Node State` | Complete, Current, Pending, Error, Skipped, Cancelled |
| `Density` | Compact, Standard |
| `Content` | Title, Title + Meta, Title + Meta + Body, Rich (with attachments/actions) |

Node 12px (pending = outline, complete = filled success, current = brand filled with 4px halo, error = danger with `!`). Rail 2px, coloured to the preceding node's state. Horizontal variant is used for order status progress on desktop detail headers.

---

## 74. Activity Feed — `CMP-DSP-ActivityFeed`

Row: avatar 32 + actor name (600) + action phrase + target link + relative timestamp + optional before→after diff panel (`bg-subtle`, two columns, changed values highlighted). Groups by day with sticky headers. Filters: All / Comments / Changes / System. Infinite scroll with a "Load more" fallback.

---

## 75. Description List — `CMP-DSP-DescriptionList`

Key/value display used on all detail pages. Variants: `Layout` (Two-column, Stacked, Inline), `Density` (Compact, Standard), `Divider` (On/Off). Label `label-md` `text-secondary` fixed 160px column; value `body-md` `text-primary`; empty values render `—`. Copyable values show a copy icon on hover with a "Copied" toast.

---

## 76. Gallery — `CMP-MED-Gallery`

- Responsive grid: 6 cols ≥1400, 5 ≥1200, 4 ≥992, 3 ≥768, 2 <768. Gap 16.
- Tile: square, radius-md, hover overlay with actions, selection checkbox top-left, badge slot top-right ("Thumbnail", "360°", "Video").
- Drag to reorder with a live drop indicator; keyboard alternative in the tile menu.
- Bulk select for delete/download/move-to-folder.
- Filter bar: type (Image/Video/360), folder, date, used/unused.
- Detail pane on selection (right drawer): preview, filename, dimensions, size, alt text, caption, tags, usage list ("Used in 4 places"), replace, download, delete.

---

## 77. Carousel — `CMP-MED-Carousel`

| Property | Values |
|----------|--------|
| `Type` | Single slide, Multi-item, Thumbnail-synced |
| `Controls` | Arrows, Dots, Both, None |
| `Autoplay` | On, Off |

Arrows 40px circular, `bg-surface` + elevation-2, vertically centred, 16px inset. Dots 8px, active 24×8 pill. Autoplay pauses on hover/focus and always exposes a pause control (a11y requirement). Swipe on touch; `←/→` on keyboard; slide count announced ("Slide 2 of 6").

---

## 78. Media Tile — `CMP-MED-Tile`

Variants: `State` (Default, Hover, Selected, Uploading, Error, Processing), `Badge` (None, Thumbnail, Video, 360, Alt Missing), `Size` (SM 96, MD 120, LG 160).

---

## 79. Lightbox — `CMP-MED-Lightbox`

Full-viewport scrim 90%, image centred at max 90vw/85vh, thumbnail strip at the bottom (56px), counter "3 / 12" top-left, actions top-right (zoom in/out, rotate, download, fullscreen, close). Keyboard: `←/→`, `+/−`, `0` reset, `ESC`. Pinch-zoom and drag-pan on touch.

---

## 80–87. Charts — `CMP-CHT-*`

### 80.1 Shared Chart Anatomy

```
┌─────────────────────────────────────────────────────┐
│ Sales Trend                    [D][W][M][Y]   [⋮]   │  header 56
│ ₹12,45,800 · ▲ 12.4% vs last period                 │  summary
├─────────────────────────────────────────────────────┤
│  ₹                                                  │
│  15L ┤                          ╭──                 │
│  10L ┤            ╭─────╮  ╭────╯                   │
│   5L ┤  ╭────╮────╯     ╰──╯                        │
│    0 ┼──┴────┴────┴────┴────┴────┴────┴────         │
│      Jan  Feb  Mar  Apr  May  Jun  Jul              │
├─────────────────────────────────────────────────────┤
│ ● This year   ● Last year          [View as table]  │  legend
└─────────────────────────────────────────────────────┘
```

### 80.2 Shared Rules

| Aspect | Rule |
|--------|------|
| Axis lines | 1px `border-default`; only the baseline is emphasised |
| Grid lines | Horizontal only, 1px `border-subtle`; no vertical grid except on categorical bars |
| Axis labels | `caption` 12 `text-tertiary`; Y-axis abbreviated (₹1.2L), full value in tooltip |
| Tick count | Max 6 on Y, max 12 on X (rotate 45° or thin out beyond) |
| Series colours | Data-viz palette in order; max 8 |
| Line | 2px stroke, round caps; markers 4px shown on hover or when <20 points |
| Area | Series colour at 12% opacity gradient to 0% |
| Bar | Radius 4 top corners; min height 2px for non-zero values; group gap 8, category gap 24 |
| Donut | Inner radius 62%, centre shows total + label; slices with a 2px surface-coloured gap |
| Tooltip | Follows cursor, elevation-3, shows all series at that X with colour dots, values right-aligned, plus delta vs comparison |
| Crosshair | 1px dashed `border-strong` vertical line on hover |
| Legend | Bottom, interactive (click toggles a series, double-click isolates), keyboard operable |
| Zero/negative | Zero baseline emphasised 1px `border-strong`; negatives below in `danger-500` |
| No data | Chart area shows a dashed frame + "No data for this period" + "Change date range" |
| Loading | Skeleton with animated bars/line placeholder |
| Accessibility | "View as table" toggle mandatory; each series described in an accessible summary; colour never the only differentiator (dash patterns / labels) |
| Export | `⋮` menu: Download PNG, Download CSV, Full screen, View as table |
| Responsive | Below 768: legend moves to a 2-column list; X labels thin to 4; height min 240 |
| Performance | Max 500 points/series; bucket beyond that with a note "Aggregated to weekly" |

### 80.3 Chart Type Selection Guide

| Question | Chart |
|----------|-------|
| Trend over time | Line (Area if a single cumulative series) |
| Comparison across categories | Horizontal Bar (>6 categories) / Vertical Bar (≤6) |
| Composition of a whole | Donut (≤5 slices) / Stacked Bar (>5) |
| Distribution | Histogram / Box |
| Conversion sequence | Funnel |
| Density across two dimensions | Heatmap (e.g. orders by day × hour) |
| Progress toward a target | Gauge / Progress |
| Micro-trend inside a KPI | Sparkline |
| Correlation | Scatter |

### 80.4 Specific Charts

| Component | Notes |
|-----------|-------|
| `CMP-CHT-Line` | Multi-series, comparison overlay (dashed for previous period), annotations for events (sale launch, festival) |
| `CMP-CHT-Bar` | Vertical/Horizontal/Grouped/Stacked/100% Stacked variants; value labels optional |
| `CMP-CHT-Donut` | Centre metric + legend with value & percentage; "Others" bucket beyond 5 slices |
| `CMP-CHT-Area` | Stacked and non-stacked; used for revenue composition |
| `CMP-CHT-Sparkline` | 24×64 to 40×160, no axes, last point marked, optional min/max markers |
| `CMP-CHT-Funnel` | Stages with count, %, and drop-off between stages; used for Visitors → Product Views → Cart → Checkout → Order |
| `CMP-CHT-Heatmap` | 7×24 grid for order density; sequential indigo ramp; legend scale below |
| `CMP-CHT-Gauge` | Semi-circular, target marker, zones (danger/warning/success); used for goal attainment and SLA |

---

## 88. Widget Frame — `CMP-WID-Frame`

The container used for all dashboard widgets. Variants: `Span` (3, 4, 6, 8, 12 cols), `Height` (SM 160, MD 280, LG 400, Auto), `Header` (Title, Title + Filter, Title + Actions, None), `State` (Loaded, Loading, Empty, Error, No Permission).

Header 56: title `heading-xs`, optional info tooltip, optional period selector, `⋮` menu (Refresh, Configure, Export, Hide widget, Move). Footer optional: "View all →". Drag handle appears in dashboard Edit Mode only.

---

## 89. Tree View — `CMP-DSP-Tree`

Used by Category Management, Menu builder and Permission groups.
- Row 40px, indent 24px per level, expand chevron 16px, optional icon/thumbnail 24, label, count meta, row actions on hover.
- Drag to re-parent/reorder with drop indicators: line = sibling position, highlighted row = child of.
- Guides: 1px vertical connector lines in `border-subtle`.
- Keyboard: `↑↓` move, `→` expand/enter, `←` collapse/exit, `Space` select, `⌘↑/↓` reorder within siblings, `Shift+←/→` outdent/indent.
- Max depth enforced (3 for categories) with the message "Maximum depth reached".

---

## 90. Kanban Column — `CMP-DSP-Kanban`

Optional order-processing view. Column: header (title, count, WIP limit, `⋮`), scrollable card list, "+ Add" footer. Card: order number, customer, item count, value, age chip (colours after SLA thresholds), avatar of assignee. Drag between columns triggers a status change with a confirmation for irreversible transitions.

---

## 91. Command Palette — `CMP-OVL-CommandPalette`

Specified in `01-Product-Foundations §4.4`. Variants: `State` (Empty, Typing, Results, No Results, Loading, Scoped).

---

## 92. Keyboard Key — `CMP-IND-Kbd`

Monospace 11px, padding 2×6, radius-xs, `bg-subtle`, 1px `border-strong`, bottom border 2px for a keycap effect. Used in tooltips, menus and the shortcuts sheet.

---

## 93. Divider — `CMP-LAY-Divider`

Variants: `Orientation` (Horizontal, Vertical), `Style` (Solid, Dashed), `Label` (None, Centre, Start), `Tone` (Subtle, Default). 1px, with 16/24px surrounding space depending on context.

---

## 94. Scrollbar — `CMP-LAY-Scrollbar`

Width 10px, thumb `neutral-300` radius-full with 2px track padding, hover `neutral-400`, track transparent. Dark theme uses `rgba(148,163,184,0.24)`. Overlay scrollbars on touch devices.

---

## 95. Print Header — `CMP-PRN-Header`

Used on all printable artefacts: company logo (left), document title + number (centre), generated-at + page x/y (right), 1px bottom rule, plus a filter summary line for reports.

---

## Component Coverage Checklist (for Figma QA)

For every component above, the Figma library must contain:

- [ ] All variant combinations listed
- [ ] Light and Dark modes (via Variable modes)
- [ ] Default / Hover / Active / Focus / Disabled / Loading states where applicable
- [ ] Auto Layout with correct resizing (Hug/Fill) behaviour
- [ ] Named layers matching the anatomy in this document
- [ ] Component description containing usage rules and a link to this spec section
- [ ] Accessible name/role notes in the description
- [ ] Responsive variants or documented reflow behaviour
- [ ] Example instances on the "Usage" page showing correct and incorrect use
