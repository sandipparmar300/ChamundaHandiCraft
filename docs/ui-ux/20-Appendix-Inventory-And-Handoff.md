# 20 — Appendix: Master Inventory, Prototypes, QA & Handoff

Enterprise Handicraft E-Commerce Platform · UI/UX Design Specification

---

## A1. Master Screen Inventory

Every full-page screen in the product, with its route, module, layout template and primary role.

| ID | Screen | Route | Module | Layout | Primary role |
|----|--------|-------|--------|--------|--------------|
| SCR-SYS-01 | Login | `/admin/login` | System | L-10 | All |
| SCR-SYS-02 | Two-Factor Verification | `/admin/login/2fa` | System | L-10 | All |
| SCR-SYS-03 | Forgot Password | `/admin/forgot-password` | System | L-10 | All |
| SCR-SYS-04 | Reset Password | `/admin/reset-password` | System | L-10 | All |
| SCR-SYS-05 | Account Locked | — | System | L-10 | All |
| SCR-SYS-06 | Password Expired | — | System | L-10 | All |
| SCR-SYS-07 | First-Time Setup | `/admin/welcome` | System | L-06 | All |
| SCR-SYS-08 | Session Timeout Warning | — | System | Modal | All |
| SCR-SYS-09 | Session Expired | — | System | L-10 | All |
| SCR-SYS-10 | 403 Forbidden | — | System | L-10 | All |
| SCR-SYS-11 | 404 Not Found | — | System | L-10 | All |
| SCR-SYS-12 | 500 Server Error | — | System | L-10 | All |
| SCR-SYS-13 | 503 Maintenance | — | System | L-10 | All |
| SCR-SYS-14 | Offline | — | System | Banner | All |
| SCR-01-01 | Dashboard Home | `/admin` | 01 | L-07 | All |
| SCR-01-02 | Dashboard Edit Mode | `/admin?edit=1` | 01 | L-07 | All |
| SCR-01-03 | Widget Library | `/admin/widgets` | 01 | L-05 | All |
| SCR-01-04 | Dashboard Layout Manager | `/admin/dashboards` | 01 | L-01 | All |
| SCR-02-01 | Admin User List | `/admin/users` | 02 | L-01 | Super Admin, Admin |
| SCR-02-02 | Admin User Create | `/admin/users/create` | 02 | L-02 | Super Admin, Admin |
| SCR-02-03 | Admin User Detail | `/admin/users/{id}` | 02 | L-02 | Super Admin, Admin |
| SCR-02-04 | Admin User Edit | `/admin/users/{id}/edit` | 02 | L-02 | Super Admin, Admin |
| SCR-02-05 | Roles & Permissions | `/admin/roles` | 02 | L-01 | Super Admin |
| SCR-02-06 | Role Permission Matrix | `/admin/roles/{id}/edit` | 02 | L-01 | Super Admin |
| SCR-02-07 | Login History | `/admin/users/login-history` | 02 | L-01 | Super Admin, Admin |
| SCR-02-08 | Customer List | `/admin/customers` | 02 | L-01 | Admin, Support, Order, Finance, Marketing |
| SCR-02-09 | Customer 360 | `/admin/customers/{id}` | 02 | L-02 | Admin, Support |
| SCR-02-10 | Customer Create/Edit | `/admin/customers/create` | 02 | L-02 | Admin, Support |
| SCR-02-11 | Customer Segments | `/admin/customers/segments` | 02 | L-01 | Admin, Marketing |
| SCR-02-12 | Segment Builder | `/admin/customers/segments/{id}` | 02 | L-04 | Admin, Marketing |
| SCR-03-01 | Product List | `/admin/products` | 03 | L-01 | Product Manager |
| SCR-03-02 | Product Create Wizard | `/admin/products/create?mode=guided` | 03 | L-06 | Product Manager |
| SCR-03-03 | Product Tabbed Editor | `/admin/products/{id}/edit` | 03 | L-02 | Product Manager |
| SCR-03-04 | Product Detail | `/admin/products/{id}` | 03 | L-02 | All catalog roles |
| SCR-03-05 | Variant Manager | `/admin/products/{id}/variants` | 03 | L-01 | Product Manager |
| SCR-03-06 | Product Media Manager | `/admin/products/{id}/media` | 03 | L-04 | Product Manager |
| SCR-03-07 | Bulk Import Wizard | `/admin/products/import` | 03 | L-06 | Product Manager |
| SCR-03-08 | Import History | `/admin/products/import/history` | 03 | L-01 | Product Manager |
| SCR-03-09 | Brands List | `/admin/brands` | 03 | L-01 | Product Manager |
| SCR-03-10 | Brand Create/Edit | `/admin/brands/{id}/edit` | 03 | L-05 | Product Manager |
| SCR-03-11 | Artisans List | `/admin/artisans` | 03 | L-01 | Product Manager |
| SCR-03-12 | Artisan Profile | `/admin/artisans/{id}` | 03 | L-02 | Product Manager |
| SCR-03-13 | Attributes & Sets | `/admin/attributes` | 03 | L-09 | Product Manager |
| SCR-03-14 | Product Recycle Bin | `/admin/products/recycle-bin` | 03 | L-01 | Admin |
| SCR-04-01 | Category Manager | `/admin/categories` | 04 | L-09 | Product Manager |
| SCR-04-02 | Category Create | `/admin/categories/create` | 04 | L-02 | Product Manager |
| SCR-04-03 | Category Edit | `/admin/categories/{id}/edit` | 04 | L-02 | Product Manager |
| SCR-04-04 | Category Detail (products) | `/admin/categories/{id}` | 04 | L-01 | Product Manager |
| SCR-04-05 | Menu Order Manager | `/admin/categories/menu-order` | 04 | L-04 | Product Manager, Marketing |
| SCR-04-06 | Category Import/Export | `/admin/categories/import` | 04 | L-06 | Product Manager |
| SCR-05-01 | Inventory Dashboard | `/admin/inventory` | 05 | L-07 | Inventory Manager |
| SCR-05-02 | Stock List | `/admin/inventory/stock` | 05 | L-01 | Inventory Manager |
| SCR-05-03 | Stock Detail / Ledger | `/admin/inventory/stock/{id}` | 05 | L-02 | Inventory Manager |
| SCR-05-04 | Purchase Entry List | `/admin/inventory/purchases` | 05 | L-01 | Inventory Manager |
| SCR-05-05 | Purchase Entry Create | `/admin/inventory/purchases/create` | 05 | L-02 | Inventory Manager |
| SCR-05-06 | Purchase Entry Detail | `/admin/inventory/purchases/{id}` | 05 | L-02 | Inventory Manager |
| SCR-05-07 | Stock Adjustment List | `/admin/inventory/adjustments` | 05 | L-01 | Inventory Manager |
| SCR-05-08 | Stock Adjustment Create | `/admin/inventory/adjustments/create` | 05 | L-05 | Inventory Manager |
| SCR-05-09 | Damage & Loss Register | `/admin/inventory/damage` | 05 | L-01 | Inventory Manager |
| SCR-05-10 | Stock Transfers | `/admin/inventory/transfers` | 05 | L-01 | Inventory Manager |
| SCR-05-11 | Stock Take | `/admin/inventory/stock-take` | 05 | L-01 | Inventory Manager |
| SCR-05-12 | Warehouses | `/admin/inventory/warehouses` | 05 | L-01 | Admin, Inventory |
| SCR-05-13 | Low Stock Alerts | `/admin/inventory/alerts` | 05 | L-01 | Inventory Manager |
| SCR-05-14 | Barcode Print | `/admin/inventory/barcodes` | 05 | L-05 | Inventory Manager |
| SCR-06-01 | Order Queue | `/admin/orders` | 06 | L-01 / L-04 | Order Manager |
| SCR-06-02 | Order Detail | `/admin/orders/{id}` | 06 | L-02 | Order Manager |
| SCR-06-03 | Order Create (manual) | `/admin/orders/create` | 06 | L-06 | Order Manager, Support |
| SCR-06-04 | Order Edit | `/admin/orders/{id}/edit` | 06 | L-02 | Order Manager |
| SCR-06-05 | Pick List | `/admin/orders/pick-list` | 06 | L-01 | Order, Inventory |
| SCR-06-06 | Packing Station | `/admin/orders/{id}/pack` | 06 | L-06 | Order, Inventory |
| SCR-06-07 | Dispatch Manifest | `/admin/orders/dispatch` | 06 | L-01 | Order Manager |
| SCR-06-08 | Returns List | `/admin/returns` | 06 | L-01 | Order Manager |
| SCR-06-09 | Return Detail | `/admin/returns/{id}` | 06 | L-02 | Order Manager |
| SCR-06-10 | Return Create | `/admin/returns/create` | 06 | L-06 | Order, Support |
| SCR-06-11 | Invoices List | `/admin/invoices` | 06 | L-01 | Finance, Order |
| SCR-06-12 | Invoice Detail | `/admin/invoices/{id}` | 06 | L-05 | Finance, Order |
| SCR-06-13 | Order Board (Kanban) | `/admin/orders/board` | 06 | L-01 | Order Manager |
| SCR-06-14 | Abandoned Carts | `/admin/orders/abandoned` | 06 | L-01 | Marketing, Order |
| SCR-07-01 | Transactions List | `/admin/payments` | 07 | L-01 | Finance |
| SCR-07-02 | Transaction Detail | `/admin/payments/{id}` | 07 | L-02 | Finance |
| SCR-07-03 | Refunds List | `/admin/refunds` | 07 | L-01 | Finance |
| SCR-07-04 | Refund Detail | `/admin/refunds/{id}` | 07 | L-02 | Finance |
| SCR-07-05 | Settlements | `/admin/payments/settlements` | 07 | L-01 | Finance |
| SCR-07-06 | Settlement Detail | `/admin/payments/settlements/{id}` | 07 | L-01 | Finance |
| SCR-07-07 | Disputes | `/admin/payments/disputes` | 07 | L-01 | Finance |
| SCR-07-08 | Payment Gateways | `/admin/settings/payment-gateways` | 07/20 | L-03 | Super Admin, Admin |
| SCR-08-01 | Shipping Overview | `/admin/shipping` | 08 | L-07 | Order Manager |
| SCR-08-02 | Shipping Zones | `/admin/shipping/zones` | 08 | L-01 | Order Manager |
| SCR-08-03 | Zone Editor | `/admin/shipping/zones/{id}` | 08 | L-02 | Order Manager |
| SCR-08-04 | Couriers List | `/admin/shipping/couriers` | 08 | L-01 | Order Manager |
| SCR-08-05 | Courier Configuration | `/admin/shipping/couriers/{code}` | 08 | L-02 | Admin |
| SCR-08-06 | Shipments List | `/admin/shipping/shipments` | 08 | L-01 | Order Manager |
| SCR-08-07 | Shipment Detail | `/admin/shipping/shipments/{id}` | 08 | L-02 | Order Manager |
| SCR-08-08 | Delivery Exceptions | `/admin/shipping/exceptions` | 08 | L-01 | Order, Support |
| SCR-08-09 | Pickup Manifests | `/admin/shipping/manifests` | 08 | L-01 | Order Manager |
| SCR-08-10 | Packaging Master | `/admin/shipping/packaging` | 08 | L-01 | Inventory, Order |
| SCR-09-01 | Coupons List | `/admin/coupons` | 09 | L-01 | Marketing |
| SCR-09-02 | Coupon Editor | `/admin/coupons/{id}/edit` | 09 | L-02 | Marketing |
| SCR-09-03 | Coupon Detail & Performance | `/admin/coupons/{id}` | 09 | L-02 | Marketing |
| SCR-09-04 | Redemption Log | `/admin/coupons/{id}/redemptions` | 09 | L-01 | Marketing, Finance |
| SCR-09-05 | Bulk Code Generator | `/admin/coupons/bulk-generate` | 09 | L-06 | Marketing |
| SCR-09-06 | Coupon Performance Report | `/admin/coupons/performance` | 09 | L-07 | Marketing, Finance |
| SCR-10-01 | Offers List | `/admin/offers` | 10 | L-01 | Marketing |
| SCR-10-02 | Offer Editor | `/admin/offers/{id}/edit` | 10 | L-02 | Marketing |
| SCR-10-03 | Offer Detail & Performance | `/admin/offers/{id}` | 10 | L-02 | Marketing |
| SCR-10-04 | Combo Builder | `/admin/offers/{id}/combo` | 10 | L-02 | Marketing |
| SCR-10-05 | Flash Sale Manager | `/admin/offers/flash-sales` | 10 | L-01 | Marketing |
| SCR-10-06 | Offer Calendar | `/admin/offers/calendar` | 10 | L-01 | Marketing |
| SCR-10-07 | Conflict Checker | `/admin/offers/conflicts` | 10 | L-01 | Marketing |
| SCR-10-08 | Offer Performance Report | `/admin/offers/performance` | 10 | L-07 | Marketing |
| SCR-11-01 | Banners List | `/admin/banners` | 11 | L-01 | Marketing |
| SCR-11-02 | Banner Editor | `/admin/banners/{id}/edit` | 11 | L-02 | Marketing |
| SCR-11-03 | Slider Manager | `/admin/banners/sliders/{placement}` | 11 | L-04 | Marketing |
| SCR-11-04 | Popup Manager | `/admin/banners/popups` | 11 | L-01 | Marketing |
| SCR-11-05 | Banner Performance | `/admin/banners/performance` | 11 | L-07 | Marketing |
| SCR-11-06 | Placement Map | `/admin/banners/placements` | 11 | L-05 | Marketing |
| SCR-12-01 | CMS Pages List | `/admin/cms/pages` | 12 | L-01 | Content Manager |
| SCR-12-02 | Page Editor | `/admin/cms/pages/{id}/edit` | 12 | L-02 | Content Manager |
| SCR-12-03 | Page Create | `/admin/cms/pages/create` | 12 | L-02 | Content Manager |
| SCR-12-04 | FAQ Manager | `/admin/cms/faq` | 12 | L-09 | Content Manager |
| SCR-12-05 | Contact Submissions | `/admin/cms/submissions` | 12 | L-01 | Content, Support |
| SCR-12-06 | Menu Builder | `/admin/cms/menus` | 12 | L-04 | Content Manager |
| SCR-13-01 | Blog Posts List | `/admin/blog/posts` | 13 | L-01 | Content Manager |
| SCR-13-02 | Post Editor | `/admin/blog/posts/{id}/edit` | 13 | L-02 | Content Manager |
| SCR-13-03 | Post Create | `/admin/blog/posts/create` | 13 | L-02 | Content Manager |
| SCR-13-04 | Blog Categories | `/admin/blog/categories` | 13 | L-01 | Content Manager |
| SCR-13-05 | Blog Tags | `/admin/blog/tags` | 13 | L-01 | Content Manager |
| SCR-13-06 | Authors | `/admin/blog/authors` | 13 | L-01 | Content Manager |
| SCR-13-07 | Comments Moderation | `/admin/blog/comments` | 13 | L-01 | Content, Support |
| SCR-13-08 | Content Calendar | `/admin/blog/calendar` | 13 | L-01 | Content, Marketing |
| SCR-14-01 | Reviews Queue | `/admin/reviews` | 14 | L-01 | Content, Support |
| SCR-14-02 | Review Detail | `/admin/reviews/{id}` | 14 | L-02 | Content, Support |
| SCR-14-03 | Reported Reviews | `/admin/reviews/reported` | 14 | L-01 | Content, Support |
| SCR-14-04 | Review Analytics | `/admin/reviews/analytics` | 14 | L-07 | Product, Marketing |
| SCR-14-05 | Review Request Campaigns | `/admin/reviews/requests` | 14 | L-01 | Marketing |
| SCR-14-06 | Moderation Settings | `/admin/reviews/settings` | 14 | L-03 | Admin |
| SCR-15-01 | Testimonials List | `/admin/testimonials` | 15 | L-01 | Content Manager |
| SCR-15-02 | Testimonial Editor | `/admin/testimonials/{id}/edit` | 15 | L-02 | Content Manager |
| SCR-15-03 | Submissions Queue | `/admin/testimonials/submissions` | 15 | L-01 | Content Manager |
| SCR-15-04 | Placement Manager | `/admin/testimonials/placements` | 15 | L-04 | Content, Marketing |
| SCR-15-05 | Testimonial Detail | `/admin/testimonials/{id}` | 15 | L-02 | Content Manager |
| SCR-16-01 | Subscribers List | `/admin/newsletter/subscribers` | 16 | L-01 | Marketing |
| SCR-16-02 | Subscriber Detail | `/admin/newsletter/subscribers/{id}` | 16 | L-02 | Marketing |
| SCR-16-03 | Lists & Segments | `/admin/newsletter/lists` | 16 | L-01 | Marketing |
| SCR-16-04 | Segment Builder | `/admin/newsletter/segments/{id}` | 16 | L-04 | Marketing |
| SCR-16-05 | Campaigns List | `/admin/newsletter/campaigns` | 16 | L-01 | Marketing |
| SCR-16-06 | Campaign Builder | `/admin/newsletter/campaigns/{id}/edit` | 16 | L-06 | Marketing |
| SCR-16-07 | Campaign Report | `/admin/newsletter/campaigns/{id}/report` | 16 | L-07 | Marketing |
| SCR-16-08 | Automated Flows | `/admin/newsletter/flows` | 16 | L-01 | Marketing |
| SCR-16-09 | Flow Builder | `/admin/newsletter/flows/{id}` | 16 | Canvas | Marketing |
| SCR-16-10 | Email Templates | `/admin/newsletter/templates` | 16 | L-01 | Marketing |
| SCR-16-11 | Suppression List | `/admin/newsletter/suppressions` | 16 | L-01 | Marketing |
| SCR-17-01 | Notification Templates | `/admin/notifications/templates` | 17 | L-01 | Marketing, Admin |
| SCR-17-02 | Template Editor | `/admin/notifications/templates/{id}` | 17 | L-02 | Marketing, Admin |
| SCR-17-03 | Event Trigger Matrix | `/admin/notifications/events` | 17 | L-01 | Admin |
| SCR-17-04 | Channel Settings | `/admin/notifications/channels` | 17 | L-03 | Super Admin, Admin |
| SCR-17-05 | Delivery Log | `/admin/notifications/log` | 17 | L-01 | Admin, Support |
| SCR-17-06 | In-App Inbox | `/admin/notifications/inbox` | 17 | L-05 | All |
| SCR-17-07 | My Notification Preferences | `/admin/profile/notifications` | 17 | L-03 | All |
| SCR-17-08 | Push Composer | `/admin/notifications/push` | 17 | L-02 | Marketing |
| SCR-17-09 | Notification Analytics | `/admin/notifications/analytics` | 17 | L-07 | Admin, Marketing |
| SCR-17-10 | Escalation Rules | `/admin/notifications/escalations` | 17 | L-01 | Admin |
| SCR-18-01 | Reports Home | `/admin/reports` | 18 | L-01 | All (scoped) |
| SCR-18-02 | Sales Report | `/admin/reports/sales` | 18 | L-03 | Finance, Admin |
| SCR-18-03 | Profit & Margin Report | `/admin/reports/profit` | 18 | L-03 | Finance |
| SCR-18-04 | Customer Report | `/admin/reports/customers` | 18 | L-03 | Marketing, Finance |
| SCR-18-05 | Inventory Report | `/admin/reports/inventory` | 18 | L-03 | Inventory |
| SCR-18-06 | Product Performance | `/admin/reports/products` | 18 | L-03 | Product Manager |
| SCR-18-07 | Tax / GST Report | `/admin/reports/tax` | 18 | L-03 | Finance |
| SCR-18-08 | Payment Report | `/admin/reports/payments` | 18 | L-03 | Finance |
| SCR-18-09 | Order Report | `/admin/reports/orders` | 18 | L-03 | Order Manager |
| SCR-18-10 | Return & Refund Report | `/admin/reports/returns` | 18 | L-03 | Order, Finance |
| SCR-18-11 | Artisan Performance | `/admin/reports/artisans` | 18 | L-03 | Product, Admin |
| SCR-18-12 | Custom Report Builder | `/admin/reports/builder` | 18 | L-04 | Admin, Finance |
| SCR-18-13 | Saved Reports | `/admin/reports/saved` | 18 | L-01 | All (scoped) |
| SCR-18-14 | Scheduled Exports | `/admin/reports/schedules` | 18 | L-01 | All (scoped) |
| SCR-19-01 | SEO Dashboard | `/admin/seo` | 19 | L-07 | Marketing |
| SCR-19-02 | Meta Tag Manager | `/admin/seo/meta` | 19 | L-01 | Marketing, Content |
| SCR-19-03 | Sitemap Manager | `/admin/seo/sitemap` | 19 | L-03 | Marketing |
| SCR-19-04 | Robots.txt Editor | `/admin/seo/robots` | 19 | L-05 | Admin |
| SCR-19-05 | Redirect Manager | `/admin/seo/redirects` | 19 | L-01 | Marketing, Content |
| SCR-19-06 | 404 Monitor | `/admin/seo/404s` | 19 | L-01 | Marketing, Content |
| SCR-19-07 | Structured Data | `/admin/seo/schema` | 19 | L-03 | Marketing |
| SCR-19-08 | Global SEO Settings | `/admin/seo/settings` | 19 | L-03 | Admin |
| SCR-19-09 | Search Performance | `/admin/seo/performance` | 19 | L-07 | Marketing |
| SCR-19-10 | Keyword Tracking | `/admin/seo/keywords` | 19 | L-01 | Marketing |
| SCR-20-01 | Settings Home | `/admin/settings` | 20 | L-01 | Admin |
| SCR-20-02 | Company Information | `/admin/settings/company` | 20 | L-03 | Admin |
| SCR-20-03 | Tax & GST | `/admin/settings/tax` | 20 | L-03 | Finance, Admin |
| SCR-20-04 | Currency | `/admin/settings/currency` | 20 | L-03 | Finance, Admin |
| SCR-20-05 | Email Settings | `/admin/settings/email` | 20 | L-03 | Admin |
| SCR-20-06 | SMS & WhatsApp | `/admin/settings/sms` | 20 | L-03 | Admin |
| SCR-20-07 | Payment Gateways | `/admin/settings/payment-gateways` | 20 | L-03 | Super Admin |
| SCR-20-08 | Shipping Defaults | `/admin/settings/shipping` | 20 | L-03 | Admin |
| SCR-20-09 | Social Media | `/admin/settings/social` | 20 | L-03 | Marketing |
| SCR-20-10 | Website Settings | `/admin/settings/website` | 20 | L-03 | Admin |
| SCR-20-11 | Localisation | `/admin/settings/localisation` | 20 | L-03 | Admin |
| SCR-20-12 | Order Settings | `/admin/settings/orders` | 20 | L-03 | Admin |
| SCR-20-13 | Product Settings | `/admin/settings/products` | 20 | L-03 | Admin, Product |
| SCR-20-14 | Customer Settings | `/admin/settings/customers` | 20 | L-03 | Admin |
| SCR-20-15 | Security Policy | `/admin/settings/security` | 20 | L-03 | Super Admin |
| SCR-20-16 | Integrations | `/admin/settings/integrations` | 20 | L-01 | Admin |
| SCR-20-17 | Settings Change History | `/admin/settings/history` | 20 | L-01 | Super Admin, Admin |
| SCR-20-18 | Backup & Data Export | `/admin/settings/backup` | 20 | L-03 | Super Admin |
| SCR-PRF-01 | My Profile | `/admin/profile` | Profile | L-02 | All |
| SCR-PRF-02 | Security & 2FA | `/admin/profile/security` | Profile | L-03 | All |
| SCR-PRF-03 | Preferences | `/admin/profile/preferences` | Profile | L-03 | All |
| SCR-PRF-04 | My Activity | `/admin/profile/activity` | Profile | L-01 | All |
| SCR-APR-01 | Approvals Queue | `/admin/approvals` | Cross-cutting | L-01 | Admin, Finance |
| SCR-AUD-01 | Audit Log | `/admin/audit` | Cross-cutting | L-01 | Super Admin, Admin |
| SCR-MED-01 | Media Library | `/admin/media` | Cross-cutting | L-04 | Content, Product, Marketing |
| SCR-SYS-15 | System Health | `/admin/system/health` | Cross-cutting | L-07 | Super Admin |

**Total full-page screens: 189.**

---

## A2. Master Modal & Drawer Inventory (Summary)

| Module | Modals | Drawers | Notable guarded dialogs |
|--------|-------:|--------:|-------------------------|
| 01 Dashboard | 6 | 2 | Reset dashboard |
| 02 User Management | 18 | 3 | Delete user, Change role, Merge customers, Anonymise (GDPR) |
| 03 Products | 26 | 4 | Bulk delete, Delete product, Unpublish with open orders |
| 04 Categories | 10 | 2 | Delete category, Merge categories |
| 05 Inventory | 18 | 3 | Confirm receipt, Deactivate warehouse, Variance acceptance |
| 06 Orders | 30 | 4 | Cancel order, Bulk cancel, Refund initiation |
| 07 Payments | 12 | 2 | Approve refund, Accept chargeback, Reveal secret |
| 08 Shipping | 15 | 2 | Delete zone, Void AWB |
| 09 Coupons | 12 | 2 | Delete coupon, High-discount approval |
| 10 Offers | 12 | 2 | End offer early, Below-cost combo override |
| 11 Banners | 10 | 2 | Delete active banner |
| 12 CMS | 14 | 2 | Delete page, Legal page approval |
| 13 Blog | 12 | 2 | Delete published post |
| 14 Reviews | 10 | 2 | Delete review, Bulk reject |
| 15 Testimonials | 8 | 1 | Publish without consent (blocked) |
| 16 Newsletter | 17 | 2 | Send campaign (typed confirm), Resubscribe |
| 17 Notifications | 14 | 2 | Disable critical notification, Reveal credentials |
| 18 Reports | 10 | 2 | Large export confirmation |
| 19 SEO | 14 | 2 | robots.txt site-wide disallow, Bulk overwrite meta |
| 20 Settings | 18 | 2 | Maintenance mode, Invoice numbering, IP allow-list, Reset section |
| System / Cross-cutting | 12 | 2 | Session timeout, Impersonation |
| **Total** | **298** | **47** | — |

---

## A3. Master API Dependency Map

| Domain | Base path | Consumed by modules |
|--------|-----------|---------------------|
| Auth & Session | `/api/auth/*` | System, all |
| Admin Users & Roles | `/api/admin-users`, `/api/roles`, `/api/permissions` | 02 |
| Customers | `/api/customers`, `/api/segments` | 02, 06, 16, 18 |
| Products | `/api/products`, `/api/brands`, `/api/artisans`, `/api/attributes` | 03, 04, 05, 06, 09, 10, 13, 18, 19 |
| Categories | `/api/categories`, `/api/menus` | 04, 03, 12, 19 |
| Inventory | `/api/inventory`, `/api/warehouses` | 05, 03, 06, 18 |
| Orders | `/api/orders`, `/api/returns`, `/api/invoices` | 06, 01, 07, 08, 18 |
| Payments | `/api/payments`, `/api/refunds`, `/api/settlements`, `/api/disputes` | 07, 06, 18, 20 |
| Shipping | `/api/shipping`, `/api/couriers` | 08, 06, 20 |
| Promotions | `/api/coupons`, `/api/offers` | 09, 10, 06, 18 |
| Banners | `/api/banners` | 11 |
| CMS | `/api/cms`, `/api/menus` | 12, 19 |
| Blog | `/api/blog` | 13, 19 |
| Reviews | `/api/reviews` | 14, 03, 15, 18 |
| Testimonials | `/api/testimonials` | 15, 12 |
| Newsletter | `/api/newsletter` | 16, 02 |
| Notifications | `/api/notifications` | 17, all (in-app) |
| Reports | `/api/reports` | 18, 01 |
| SEO | `/api/seo` | 19, 03, 04, 12, 13 |
| Settings | `/api/settings`, `/api/integrations` | 20, all |
| Media | `/api/media` | 03, 11, 12, 13, 15 |
| Audit | `/api/audit` | Cross-cutting |
| Approvals | `/api/approvals` | 02, 05, 06, 07, 09, 12 |
| Real-time | `/hub/dashboard`, `/hub/orders`, `/hub/inventory`, `/hub/payments`, `/hub/shipping` | 01, 05, 06, 07, 08 |
| Webhooks (inbound) | `/webhooks/payments/*`, `/webhooks/courier/*`, `/webhooks/email/*` | 07, 08, 16 |

---

## A4. Master Database Entity Map

| Domain | Core entities |
|--------|---------------|
| Identity | AdminUsers, Roles, Permissions, RolePermissions, UserRoles, UserPermissionOverrides, UserSessions, LoginHistory, Invitations, Departments, UserWarehouseScope |
| Customers | Customers, CustomerAddresses, CustomerNotes, CustomerTags, Segments, SegmentRules, SegmentMembers, RewardPoints, RewardPointTransactions, Wishlists, WishlistItems, ConsentLog |
| Catalog | Products, ProductVariants, ProductOptions, ProductOptionValues, ProductMedia, ProductMedia360Frames, ProductVideos, ProductAttributes, AttributeSets, Attributes, AttributeValues, Brands, Artisans, CraftClusters, Tags, ProductTags, ProductRelations, ProductVersions, ProductImports, ProductPricing, ScheduledPriceChanges |
| Taxonomy | Categories, ProductCategories, CategoryMedia, CategoryFilters, Menus, MenuItems |
| Inventory | Inventory, InventoryTransactions, PurchaseEntries, PurchaseEntryLines, StockAdjustments, DamageRecords, StockTransfers, StockTakes, StockTakeLines, Warehouses, WarehouseBins, Suppliers, ReasonCodes |
| Sales | Orders, OrderItems, OrderItemFulfilments, OrderStatusHistory, OrderAddresses, OrderDiscounts, OrderTaxes, OrderTags, OrderNotes, OrderCommunications, OrderAssignments, Returns, ReturnItems, ReturnInspections, Exchanges, AbandonedCarts |
| Fulfilment | Shipments, ShipmentPackages, TrackingEvents, DeliveryExceptions, Manifests, ShippingZones, ZoneRegions, ZonePinRanges, ShippingRates, Couriers, CourierServices, CourierServiceability, BoxTypes |
| Finance | Payments, PaymentEvents, PaymentMethods, PaymentGateways, GatewayCredentials, Refunds, RefundApprovals, Settlements, SettlementLines, Disputes, DisputeEvidence, PaymentLinks, CodCollections, Invoices, InvoiceSequences, TaxClasses, HsnCodes, Currencies, ExchangeRates |
| Promotions | Coupons, CouponCodes, CouponConditions, CouponApplicability, CouponRedemptions, Offers, OfferRules, OfferScope, OfferTiers, Combos, ComboItems, FlashSales, OfferRedemptions, Campaigns |
| Content | CmsPages, CmsPageVersions, CmsBlocks, CmsTemplates, FaqCategories, FaqItems, ContactSubmissions, BlogPosts, BlogPostVersions, BlogCategories, BlogTags, BlogAuthors, BlogComments, Banners, BannerCreatives, BannerPlacements, PopupRules, Testimonials, TestimonialConsent, TestimonialPlacements, Media |
| Reviews | Reviews, ReviewSubRatings, ReviewMedia, ReviewReplies, ReviewReports, ReviewVotes, ReviewModerationLog, ReviewRequests |
| Communications | Subscribers, SubscriberConsent, Lists, ListMembers, Campaigns (email), CampaignRecipients, CampaignEvents, Flows, FlowSteps, FlowEnrolments, Suppressions, NotificationTemplates, NotificationEvents, NotificationChannels, NotificationLog, InAppNotifications, PushSubscriptions, EscalationRules |
| Analytics & Reporting | DailySalesSummary, DailyProductSummary, DailyInventorySummary, DailyCustomerSummary, MonthlyTaxSummary, OrderProfitability, ProductCostHistory, SavedReports, ReportSchedules, ReportAnnotations, AnalyticsSessions |
| SEO | SeoMeta, SeoMetaTemplates, UrlRedirects, NotFoundLog, SitemapConfig, RobotsTxt, SchemaConfig, TrackedKeywords, KeywordPositions, HreflangMappings |
| Platform | Settings, SettingsHistory, Integrations, IntegrationCredentials, SecurityPolicy, IpAllowList, AuditLog, Approvals, BackupJobs, DataExportRequests, ExportJobs, DashboardLayouts, UserPreferences, Targets, Festivals |

---

## A5. Prototype Flow Map

| ID | Flow | Screens involved | Purpose | Duration |
|----|------|------------------|---------|----------|
| PT-01 | Product creation end-to-end | SCR-03-01 → 03-02 (5 steps) → MOD-03-13 → 03-04 → 03-03 (Variants) → MOD-03-10 | Usability testing with Product Manager persona | ~8 min |
| PT-02 | Order fulfilment | SCR-06-01 (split view) → 06-05 → 06-06 → MOD-06-04 → 06-07 | Usability testing with Order Manager persona | ~10 min |
| PT-03 | Return & refund | SCR-06-02 → MOD-06-19 → 06-09 → MOD-06-20 → MOD-06-22 → SCR-APR-01 → SCR-07-04 | Stakeholder demo of approval controls | ~7 min |
| PT-04 | Inventory receiving with scanner | SCR-05-01 → 05-13 → 05-05 → MOD-05-02 → MOD-05-17 → MOD-05-12 (desktop + 375px) | Warehouse usability testing | ~9 min |
| PT-05 | Campaign launch | SCR-09-02 → SCR-10-02 → SCR-11-02 → SCR-16-06 → SCR-16-07 | Stakeholder demo of the marketing stack | ~12 min |
| PT-06 | Admin onboarding & permissions | SCR-02-01 → MOD-02-01 → SCR-02-03 → TAB-02-02 → MOD-02-09 → SCR-02-06 | Stakeholder demo of RBAC | ~6 min |
| PT-07 | Reporting & export | SCR-18-01 → 18-02 → drill-through → SCR-06-01 → back → MOD-18-05 → SCR-18-14 | Finance review | ~7 min |
| PT-08 | Mobile order management | SCR-06-01 (375) → 06-02 (375) → MOD-06-04 (sheet) → toast | Mobile usability testing | ~5 min |
| PT-09 | Content publishing | SCR-13-08 → 13-03 → MOD-13-02 → TAB (SEO) → MOD-13-04 → SCR-12-02 → SCR-19-02 | Content team review | ~9 min |
| PT-10 | Full navigation walkthrough | Shell → every module landing screen | Executive demo | ~6 min |

**Prototype rules:** every flow begins with a "Start Here" frame stating the persona, scenario and task list; no dead ends; overlays close on scrim click; realistic content only.

---

## A6. Cross-Module Interaction Map

| Source | Action | Target module effect |
|--------|--------|----------------------|
| Order confirmed (06) | Reserve stock | Inventory (05) writes a reservation transaction |
| Order cancelled (06) | Release stock + initiate refund | Inventory (05), Payments (07) |
| Order delivered (06) | Trigger review request | Reviews (14), Newsletter (16) |
| Return received (06) | Restock or write off | Inventory (05), Damage register |
| Refund approved (07) | Update order + notify | Orders (06), Notifications (17) |
| Purchase receipt confirmed (05) | Update stock + average cost | Products (03) margin display, Reports (18) |
| Product published (03) | Sitemap regeneration, SEO index | SEO (19) |
| Product unpublished (03) | Remove from offers/coupon scope warnings | Offers (10), Coupons (09) |
| Category slug changed (04) | Create redirect | SEO (19) |
| Coupon redeemed (09) | Increment usage, attribute revenue | Reports (18), Orders (06) |
| Offer activated (10) | Price display changes | Products (03) storefront, Banners (11) linkage |
| Review approved (14) | Update product rating aggregate | Products (03), Reports (18) |
| Review promoted (14) | Create testimonial with consent check | Testimonials (15) |
| Blog post published (13) | Sitemap + newsletter candidate | SEO (19), Newsletter (16) |
| Customer blocked (02) | Prevent new orders | Orders (06) |
| Low stock threshold crossed (05) | Alert + dashboard widget | Dashboard (01), Notifications (17) |
| Settings tax change (20) | Applies to new orders only | Orders (06), Invoices, Reports (18) |
| Gateway disabled (20/07) | Checkout method removal | Payments (07), storefront |
| Maintenance mode (20) | Storefront offline | All storefront surfaces |

---

## A7. Design QA Checklist (per screen)

**Structure**
- [ ] Screen exists at all required breakpoints (or a documented "no change" note)
- [ ] Layout template matches the module spec
- [ ] Shell regions correct (top bar, sidebar, breadcrumb, footer)
- [ ] Breadcrumb trail matches the spec exactly

**States**
- [ ] Default, loading (initial), loading (refresh), empty (no data), empty (filtered), error, no-permission
- [ ] All interactive elements: default, hover, active, focus, disabled, loading
- [ ] Dark theme verified

**System usage**
- [ ] Zero detached component instances
- [ ] Zero local colour, text or effect styles
- [ ] All spacing from the spacing scale
- [ ] All colours from semantic variables

**Content**
- [ ] All labels, buttons and messages match the module spec verbatim
- [ ] Realistic handicraft content, no lorem ipsum
- [ ] Edge cases present: long name, missing image, zero stock, error row
- [ ] Numbers and currency formatted per §6.5 of Product Foundations

**Interaction**
- [ ] Every action documented with its confirmation model
- [ ] Every destructive action guarded appropriately
- [ ] Keyboard path documented for all drag-and-drop
- [ ] Unsaved-changes guard specified where applicable

**Accessibility**
- [ ] Contrast verified for all text and non-text UI
- [ ] Focus order documented and logical
- [ ] Accessible names specified for icon-only controls
- [ ] Announcements specified for async and state changes
- [ ] Touch targets ≥44px (tablet) / ≥48px (mobile)

**Handoff**
- [ ] Annotations complete: behaviour, validation, permission, API, a11y
- [ ] Assets marked for export
- [ ] Prototype links present for multi-step flows
- [ ] Frame status set to 🟢 APPROVED

---

## A8. Suggested Delivery Phasing

| Phase | Scope | Modules | Rationale |
|-------|-------|---------|-----------|
| **P0 — Foundations** | Design system, shell, auth, system pages | DS, System | Nothing can be built without tokens, components and the shell |
| **P1 — Sell** | Catalog + orders + payments + shipping basics | 03, 04, 05, 06, 07, 08 | The minimum needed to take and fulfil an order |
| **P2 — Operate** | Dashboard, users & roles, customers, reports (core) | 01, 02, 18 (Sales/Order/Inventory) | Visibility and delegation once transactions flow |
| **P3 — Grow** | Coupons, offers, banners, newsletter, SEO | 09, 10, 11, 16, 19 | Demand generation once operations are stable |
| **P4 — Tell** | CMS, blog, reviews, testimonials | 12, 13, 14, 15 | Brand and trust content |
| **P5 — Refine** | Notifications matrix, advanced reports, settings depth, integrations | 17, 18 (full), 20 | Configuration depth and automation |

Design must run one phase ahead of engineering. Each phase ends with a usability test on its primary prototype.

---

## A9. Open Decisions Register

| # | Decision | Options | Owner | Impact if deferred |
|---|----------|---------|-------|--------------------|
| D-01 | Multi-warehouse at launch? | Single vs multi | Product Owner | Affects Inventory, Orders, Shipping UI density |
| D-02 | Marketplace channels in v1? | Yes / reserved only | Product Owner | Product editor gains a Channels tab |
| D-03 | B2B/wholesale pricing timing | v1 / v2 | Business | Pricing tab scope |
| D-04 | Made-to-order capacity planning | Manual vs scheduled | Operations | Artisan production board |
| D-05 | Loyalty tiers vs flat points | Flat now, tiers later | Marketing | Customer settings and rewards UI |
| D-06 | Storefront theme editing in admin | Full builder vs preset options | Product Owner | Website settings scope |
| D-07 | Review incentives policy | Enabled with disclosure vs disabled | Legal/Marketing | Review request campaign UI |
| D-08 | Hindi launch scope | Admin UI vs storefront only | Product Owner | Localisation coverage and testing |
| D-09 | Native mobile admin app | PWA vs native | Engineering | Mobile design depth |
| D-10 | Accounting integration | Tally vs Zoho vs export only | Finance | Integrations scope |

Each open decision has a placeholder in the design (reserved slot or documented assumption) so resolving it does not require restructuring.

---

## A10. Document Completeness Statement

This specification covers:

- **189** full-page screens with routes, layouts and role ownership
- **298** modals and **47** drawers, each with type, title, content and buttons
- **20** modules documented against an identical 35-section template
- **95** UI components with variants, states, sizes and behaviour
- **9** user roles with a module-level and action-level permission matrix
- **15** canonical layout templates and **6** breakpoints
- Complete design tokens: colour (light, dark, high-contrast), typography, spacing, elevation, radius, motion, iconography
- Validation rules with exact user-facing messages for every form in the product
- Loading, empty, filtered-empty, error, partial and no-permission states for every data surface
- Accessibility requirements at the global, component and module level, targeting WCAG 2.1 AA
- Mermaid diagrams for navigation, state machines and user journeys, plus ASCII wireframes for every significant screen
- Figma organisation: file structure, page structure, naming conventions, variables, auto-layout trees, variant matrices and prototype definitions
- Developer handoff notes, API endpoints and database entities per module

A UI designer can open Figma and build this product from these documents without further clarification, except where §A9 records an explicitly open business decision.
