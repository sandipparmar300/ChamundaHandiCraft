# ChamundaHandicraft.APIGateway

Ocelot reverse proxy. The only host the Admin panel and Storefront are allowed to talk
to. It gives us one public surface, one place for rate limiting and CORS, and the
freedom to split `ChamundaHandicraft.API` later without touching either web tier.

---

## Route map (`ocelot.json`)

| Upstream (what the web tiers call) | Downstream (API) | Caller |
|------------------------------------|------------------|--------|
| `/Admin/{everything}` | `/api/admin/{everything}` | ChamundaHandicraft.Admin |
| `/Shop/{everything}` | `/api/storefront/{everything}` | ChamundaHandicraft.Storefront |
| `/Public/{everything}` | `/api/public/{everything}` | Anonymous (sitemap, robots, tracking) |
| `/Webhooks/{everything}` | `/api/webhooks/{everything}` | Payment gateways, couriers, email provider |

The `Admin` / `Shop` / `Public` prefixes are the same string constants used at the top
of `ChamundaHandicraft.Helper/Constants/ApiEndPoint.cs`, so a route change is a
one-line edit in two files.

---

## Program.cs responsibilities

- `AddOcelot()` + `UseOcelot()`
- CORS policy — Admin origin and Storefront origin only
- Rate limiting — tighter on `/Public/*` and `/Webhooks/*` than on `/Admin/*`
- Request/correlation ID propagation to the API for traceable logs

The gateway performs **no** authentication of its own. JWT validation happens in the
API so a single implementation governs both tiers.

---

## Ports (development)

| Host | Port |
|------|------|
| Gateway | 7138 |
| API | 7139 |
| Admin | 7140 |
| Storefront | 7141 |

Update the downstream ports in `ocelot.json` and `APIGatewayBaseUrl` in both web tiers'
`appsettings.json` together.
