# Enterprise Handicraft E-Commerce Platform
## UI/UX Design Specification — Master Index

**Document ID:** HCX-UXSPEC-001
**Version:** 1.0
**Status:** Approved for Figma Production
**Owner:** Principal Product Designer / Enterprise Product Owner
**Audience:** UI Designers (Figma), UX Architects, Front-End Engineers, Business Analysts, QA, Product Owners
**Target Platform:** ASP.NET Core MVC (.NET 8) · Modular Monolith · Clean Architecture · MSSQL · Bootstrap 5 · jQuery

---

## 0.1 Purpose of This Document

This document set is the **single source of truth** for the complete UI/UX design of the Enterprise Handicraft E-Commerce Platform Admin Panel and its associated storefront-facing configuration surfaces.

It is written so that a UI Designer can open Figma and build **every screen, every modal, every dialog, every state, and every component** without asking a single additional question.

It contains **no code**. All technical references are declarative specifications (tokens, measurements, behaviours, rules), not implementations.

---

## 0.2 Document Set Structure

| # | File | Contents |
|---|------|----------|
| 00 | `00-Master-Index.md` | This file. Index, conventions, glossary, global screen inventory summary |
| 01 | `01-Product-Foundations.md` | Business goals, personas, roles, information architecture, app shell, navigation model, responsive strategy, content & microcopy standards |
| 02 | `02-Design-System-Foundations.md` | Typography, colour, spacing, grid, breakpoints, elevation, radius, motion, iconography, light/dark theming, accessibility foundations |
| 03 | `03-Component-Library.md` | Every UI component: anatomy, sizes, variants, states, validation, keyboard behaviour, responsive behaviour, Figma variant matrix |
| 04 | `04-Figma-Organization.md` | Figma file structure, pages, sections, frames, naming conventions, variables, styles, auto-layout rules, prototype flows, developer handoff |
| 05 | `05-Roles-And-Permission-Matrix.md` | 9 roles, permission matrix per module, UI-permission binding rules, role-based navigation rendering |
| 06 | `06-Global-UX-Patterns.md` | List page pattern, detail page pattern, form pattern, wizard pattern, bulk actions, filters, dialogs, toasts, empty/loading/error states, system pages (404/500/Maintenance) |
| 10 | `10-Modules-01-02-Dashboard-Users.md` | Module 1 Dashboard · Module 2 User Management |
| 11 | `11-Module-03-Product-Management.md` | Module 3 Product Management (incl. Brands, Artisans, Attributes) |
| 12 | `12-Modules-04-05-Category-Inventory.md` | Module 4 Category Management · Module 5 Inventory |
| 13 | `13-Module-06-Order-Management.md` | Module 6 Order Management (incl. Returns, Invoices, Fulfilment) |
| 14 | `14-Modules-07-08-Payments-Shipping.md` | Module 7 Payment Management · Module 8 Shipping |
| 15 | `15-Modules-09-11-Coupons-Offers-Banners.md` | Module 9 Coupons · Module 10 Offers · Module 11 Banners |
| 16 | `16-Modules-12-15-Content.md` | Module 12 CMS · Module 13 Blog · Module 14 Reviews · Module 15 Testimonials |
| 17 | `17-Modules-16-18-Newsletter-Notifications-Reports.md` | Module 16 Newsletter · Module 17 Notifications · Module 18 Reports |
| 18 | `18-Modules-19-20-SEO-Settings.md` | Module 19 SEO · Module 20 Settings |
| 20 | `20-Appendix-Inventory-And-Handoff.md` | Master screen inventory, master modal inventory, master API/DB dependency map, prototype flow map, cross-module interaction map, QA checklist, delivery phasing, open decisions |

---

## 0.3 How To Read a Module Chapter

Every one of the 20 module chapters follows an **identical 35-section template**. This consistency is deliberate — a designer can navigate any module blind.

| § | Section | What it gives the designer |
|---|---------|---------------------------|
| 1 | Business Goal | Why the module exists commercially |
| 2 | Purpose | What job the user hires the module to do |
| 3 | Features | Enumerated capability list |
| 4 | Complete Screen List | Every route + every modal, uniquely IDed |
| 5 | Navigation Flow | Mermaid flow diagram |
| 6 | Screen Hierarchy | Parent/child tree |
| 7 | Desktop Layout | ≥1280px layout spec |
| 8 | Tablet Layout | 768–1279px layout spec |
| 9 | Mobile Layout | <768px layout spec |
| 10 | Wireframe Description | ASCII wireframes + region-by-region narrative |
| 11 | Header | Page header composition |
| 12 | Sidebar | Sidebar/nav state for the module |
| 13 | Breadcrumb | Breadcrumb trail rules |
| 14 | Toolbar | Toolbar composition |
| 15 | Action Buttons | Every button, hierarchy, placement, permission |
| 16 | Search | Search scope + behaviour |
| 17 | Filters | Every filter, type, default, dependency |
| 18 | Sorting | Sortable columns + default sort |
| 19 | Bulk Actions | Every bulk operation + confirmation model |
| 20 | Cards / Tables / Widgets | Data display specs incl. column definitions |
| 21 | Forms & Fields | Every field: type, label, placeholder, help, constraints |
| 22 | Validation Rules | Field-level and form-level rules with exact messages |
| 23 | Dropdowns & Data Sources | Every select, its source, its dependencies |
| 24 | Icons | Icon usage per action |
| 25 | Pagination | Pagination model |
| 26 | Notifications & Toasts | Every toast + trigger |
| 27 | Dialogs (Confirm / Success / Error) | Every dialog with exact copy |
| 28 | Permission Matrix | Role × action grid |
| 29 | User Journey | Narrative journey + Mermaid journey diagram |
| 30 | UX Guidelines | Module-specific do/don't rules |
| 31 | Accessibility | Module-specific a11y requirements |
| 32 | Micro-interactions | Motion + feedback details |
| 33 | Loading / Empty / Error States | All three state families |
| 34 | API & Database Dependencies | Endpoint list + entity list |
| 35 | Figma Assets: Components, Auto Layout, Variants, Prototype, Dev Notes, Future Scalability | Direct build instructions |

---

## 0.4 Global Naming & ID Conventions

### 0.4.1 Screen IDs

```
SCR-<MODULE#>-<SEQ>       Full page screen        e.g. SCR-03-02  (Product Create)
MOD-<MODULE#>-<SEQ>       Modal / dialog          e.g. MOD-03-05  (Bulk Price Update)
DRW-<MODULE#>-<SEQ>       Drawer / side panel     e.g. DRW-06-01  (Order Quick View)
TAB-<MODULE#>-<SEQ>       Tab panel within screen e.g. TAB-03-04  (Product SEO Tab)
WID-<MODULE#>-<SEQ>       Dashboard widget        e.g. WID-01-07  (Low Stock Widget)
STA-<MODULE#>-<SEQ>       Named state variant     e.g. STA-06-03  (Orders Empty State)
```

### 0.4.2 Component IDs

```
CMP-<Category>-<Name>     e.g. CMP-INPUT-TextField, CMP-TABLE-DataGrid
```

### 0.4.3 Route Convention (for prototype linking + dev handoff)

```
/admin/<module-slug>                       List
/admin/<module-slug>/create                Create
/admin/<module-slug>/{id}                  Detail / View
/admin/<module-slug>/{id}/edit             Edit
/admin/<module-slug>/{id}/<sub-resource>   Nested
```

---

## 0.5 Global Glossary

| Term | Definition |
|------|------------|
| **Artisan** | The handicraft maker credited on a product ("Handmade By"). A first-class catalog entity in this platform. |
| **Craft Cluster** | A geographic/community grouping of artisans, used for storytelling, filtering and reporting. |
| **SKU** | Stock Keeping Unit — unique per variant, not per product. |
| **Product Code** | Human-friendly internal reference, unique per product (parent). |
| **Variant** | A sellable combination of Size × Colour × Material × Finish. |
| **Lot** | Inventory batch received via Purchase Entry; carries cost price and artisan attribution. |
| **Shell** | The persistent app frame: top bar + sidebar + content area + footer. |
| **Workspace** | The content area inside the shell. |
| **Destructive Action** | Any action causing irreversible data loss or customer-visible financial change. |
| **Soft Delete** | Record flagged inactive, recoverable from Recycle Bin for 30 days. |
| **Guarded Action** | Action requiring confirmation + typed verification + optional reason. |
| **Truth Row** | The single row in a table that is currently focused/selected via keyboard. |
| **Token** | A named design value (colour, spacing, radius, etc.) defined once in Figma Variables. |

---

## 0.6 Global Screen Count Summary

| Module | Full Screens | Modals/Dialogs | Drawers | Widgets | Total Frames (Desktop) |
|--------|-------------|----------------|---------|---------|------------------------|
| 01 Dashboard | 4 | 6 | 2 | 16 | 28 |
| 02 User Management | 12 | 18 | 3 | – | 33 |
| 03 Product Management | 14 | 26 | 4 | – | 44 |
| 04 Category Management | 6 | 10 | 2 | – | 18 |
| 05 Inventory | 12 | 18 | 3 | 4 | 37 |
| 06 Order Management | 14 | 24 | 4 | 3 | 45 |
| 07 Payment Management | 8 | 12 | 2 | 3 | 25 |
| 08 Shipping | 10 | 14 | 2 | – | 26 |
| 09 Coupons | 6 | 9 | 2 | – | 17 |
| 10 Offers | 8 | 12 | 2 | – | 22 |
| 11 Banners | 6 | 10 | 2 | – | 18 |
| 12 CMS | 6 | 8 | 1 | – | 15 |
| 13 Blog | 8 | 12 | 2 | – | 22 |
| 14 Reviews | 5 | 10 | 2 | – | 17 |
| 15 Testimonials | 5 | 8 | 1 | – | 14 |
| 16 Newsletter | 8 | 12 | 2 | – | 22 |
| 17 Notifications | 10 | 14 | 2 | – | 26 |
| 18 Reports | 12 | 8 | 2 | 12 | 34 |
| 19 SEO | 7 | 9 | 1 | – | 17 |
| 20 Settings | 14 | 18 | 2 | – | 34 |
| System (Auth, Errors, Profile) | 14 | 10 | 1 | – | 25 |
| **TOTAL** | **189** | **270** | **42** | **38** | **539** |

> Multiply by 3 breakpoints for responsive coverage where the layout materially differs (approx. **1,180 total Figma frames**). Tablet frames are only required where the desktop layout does not reflow predictably — flagged per module in §8.

---

## 0.7 Design Principles (Non-Negotiable)

1. **Operator Speed Over Beauty.** This is a tool used 8 hours a day. Density, keyboard access, and predictable placement beat visual novelty.
2. **One Primary Action Per Screen.** Exactly one filled primary button per view region. Everything else is secondary, tertiary, or in an overflow menu.
3. **Never Lose Work.** Any navigation away from a dirty form triggers an unsaved-changes guard. Long forms autosave drafts every 30s.
4. **Destructive Actions Are Guarded.** Red button + confirmation + consequence statement + typed verification for high-impact deletes.
5. **State Is Always Visible.** Every list shows loading, empty, error, filtered-empty, and no-permission states. No blank screens ever.
6. **Explain, Don't Just Block.** Validation messages state what is wrong AND how to fix it.
7. **Craft Is the Product.** Imagery, artisan attribution and material storytelling are surfaced prominently in catalog UI — this differentiates a handicraft platform from generic retail.
8. **Permission-Aware, Not Permission-Surprising.** Users never see a control they cannot use, except where hiding it would confuse — then it is disabled with a tooltip explaining why.
9. **Every Number Is Traceable.** Every dashboard/report metric has a definition tooltip and drill-through to its source records.
10. **Accessible by Default.** WCAG 2.1 AA is the floor, not the goal.

---

## 0.8 Change Control

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0 | 2026-08-03 | Principal Product Designer | Initial complete specification |

Any change to this document must be reflected in Figma within one working day, and vice versa. The Figma file version label must match the version number in §0 of this document.
