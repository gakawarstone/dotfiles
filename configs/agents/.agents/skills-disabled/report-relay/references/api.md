# API reference

Use the service base URL supplied by the user or environment. Local development defaults to `http://localhost:3001`.

## Report fields

| Field | Create/replace | Constraints |
| --- | --- | --- |
| `title` | Required | Non-empty string, at most 160 characters |
| `project` | Required | Non-empty string, at most 100 characters |
| `html` | Required | Non-empty string |
| `description` | Optional | String, at most 500 characters |
| `tags` | Optional | Array of strings |

Saved reports also contain `id`, `createdAt`, and `updatedAt`. List responses omit `html` and include `htmlBytes`.

## Endpoints

| Method | Path | Result |
| --- | --- | --- |
| `GET` | `/api/health` | `{ "status": "ok" }` |
| `GET` | `/api/reports` | `{ "reports": [...] }` summaries |
| `POST` | `/api/reports` | `201` with `{ "report": {...} }` and a `Location` header |
| `GET` | `/api/reports/:id` | `{ "report": {...} }` |
| `PATCH` | `/api/reports/:id` | Update only supplied editable fields |
| `PUT` | `/api/reports/:id` | Replace all editable fields |
| `DELETE` | `/api/reports/:id` | `204` on success |

Filter the list endpoint with `q`, `tag`, or `project` query parameters. URL-encode parameter values.

## Authentication

When `API_KEY` is configured, all non-GET requests require either:

```text
Authorization: Bearer <key>
```

or:

```text
X-API-Key: <key>
```

GET requests remain public. Never embed the key in a URL or report.

## Create example

Use a JSON-aware client or serialize a payload file. A concise request shape is:

```json
{
  "title": "Release readiness",
  "project": "Checkout",
  "description": "Decision brief for the release review.",
  "tags": ["release", "status"],
  "html": "<h1>Release readiness</h1><p>Core flows are ready.</p>"
}
```

Set `Content-Type: application/json`. If authentication is configured, add one of the supported key headers.

## Errors and limits

- `400`: invalid body or fields; use the returned `error` string to correct the request.
- `401`: missing or invalid write credential.
- `404`: unknown route or report ID.
- Oversized bodies are rejected according to the deployment's `MAX_REPORT_BYTES`; keep HTML focused and avoid embedding large binary data.

Treat only a successful status with a valid response body as confirmation. The reader URL is the service root plus `/?report=<id>`; the API resource URL is `/api/reports/<id>`.
