---
name: report-relay
description: Create, style, publish, inspect, update, and delete HTML reports in Report Relay. Use when an agent needs to deliver a polished result through the Report Relay API, compose report HTML that fits its built-in viewer stylesheet, or troubleshoot a Report Relay request.
---

# Report Relay

Turn the result into a readable report and publish it through the service API.

## Workflow

1. Determine the service base URL and whether writes require an API key. Default to `http://localhost:3001` only when local project context supports that assumption.
2. Read [references/styling.md](references/styling.md) before authoring or revising report HTML.
3. Read [references/api.md](references/api.md) before calling the API or when exact limits, authentication, filtering, or response shapes matter.
4. Compose a JSON payload with `title`, `project`, and `html`; add a concise `description` and useful, low-cardinality `tags` when known.
5. Send JSON with an HTTP client. Build JSON with a serializer rather than shell interpolation so HTML quotes and newlines remain valid.
6. Check the HTTP status and parse the response. On creation, report the saved ID and reader URL `/?report=<id>` resolved against the base URL.
7. If visual quality matters and the running service is accessible, open or fetch the saved report and correct obvious hierarchy, overflow, or density problems.

## Authoring rules

- Provide an HTML fragment rooted in report content. Do not recreate the Report Relay navigation or application shell.
- Use semantic elements and the built-in stylesheet first. Add inline or embedded CSS only when the requested presentation cannot be expressed with supported patterns.
- Treat report HTML as untrusted viewer content: do not depend on scripts, parent-page access, external state, or interactive application behavior.
- Keep the payload self-contained and durable. Prefer text, tables, lists, and stable image URLs or data supplied by the user.
- Preserve facts and uncertainty from the source work. Styling must improve scanning without inventing conclusions.

## Mutations

- Use `POST` to create, `PATCH` to change only supplied fields, and `PUT` only to replace the complete editable report.
- Fetch the current report before a risky update. Do not delete a report unless the user explicitly requests deletion or the report is clearly a disposable artifact created during the current task.
- Never expose an API key in report HTML, logs, examples, or the final response.

## Handoff

Return the report title, project, saved ID, and reader URL. Mention failures with the server's error text and the corrective action needed; do not claim publication succeeded from a request body alone.
