# Styling reports

Report Relay injects `/report.css` into every stored report document and renders it in a sandboxed iframe. Author content for that stylesheet instead of building a standalone web page.

## Recommended structure

```html
<h1>Quarterly delivery review</h1>
<p>A concise summary of scope, progress, and next decisions.</p>

<div class="callout">
  <strong>Recommendation:</strong> Ship the core workflow and defer bulk export.
</div>

<h2>At a glance</h2>
<div class="metric"><strong>82%</strong>Milestones complete</div>

<h2>Findings</h2>
<table>
  <thead><tr><th>Area</th><th>Status</th><th>Evidence</th></tr></thead>
  <tbody><tr><td>Core flow</td><td>Ready</td><td>All acceptance tests pass</td></tr></tbody>
</table>

<h2>Next steps</h2>
<ol><li>Resolve the remaining accessibility issue.</li><li>Schedule release review.</li></ol>
```

## Visual language

- Start with one `h1`, followed by a one- or two-sentence executive summary.
- Divide the report with descriptive `h2` headings. Use `h3` only for real subsections; do not skip heading levels.
- Use paragraphs for interpretation, lists for actions or comparable points, and tables for repeated fields across several items.
- Use `.metric` for a single prominent number plus a short label. Do not pack multiple unrelated metrics into one box.
- Use `.callout` for the most important recommendation, decision, warning, or takeaway. Limit callouts so emphasis remains meaningful.
- Use `blockquote` for quoted or specially framed source material, not as a generic colored panel.
- Use `pre > code` for multiline code and `code` for short identifiers or commands.
- Include meaningful `alt` text on images. Avoid images when a compact table or prose communicates the result more clearly.

## Built-in behavior

The default report canvas is white, centered, and at most 900px wide. It uses dark ink, a forest-green accent, pale mint callouts, responsive typography, rounded tables and code blocks, fluid images, and horizontally scrolling tables on narrow screens.

The stylesheet already styles:

- `h1` through `h4`, paragraphs, links, emphasis, lists, and rules
- blockquotes, inline code, and code blocks
- tables, including header and row separators
- responsive images
- `.metric` and `.callout`

## Restraint and compatibility

- Prefer a fragment such as `<h1>…</h1><p>…</p>`. Full documents are accepted, but add no value unless metadata or narrowly scoped CSS is necessary.
- Do not add body widths, global resets, font imports, page backgrounds, or competing color systems; they fight the injected stylesheet.
- Avoid fixed widths, complex grids, tiny type, excessive badges, and wide tables. If a table becomes dense, reduce columns or split it by topic.
- Do not use JavaScript. The report is a reading artifact, and the iframe is sandboxed.
- If custom CSS is essential, scope it to distinctive report classes and preserve responsive behavior. Use the existing CSS variables when possible: `--ink`, `--muted`, `--forest`, `--mint`, `--paper`, and `--line`.

## Content quality check

Before publishing, verify that the report:

- states the conclusion or purpose near the top;
- can be skimmed from headings, callouts, and table headers;
- distinguishes evidence from recommendations;
- has no empty sections, placeholder prose, or repeated title metadata;
- uses valid, escaped HTML and contains no secrets;
- remains understandable on a narrow screen.
