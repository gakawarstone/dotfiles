---
name: typst
description: "Work with Typst."
---

# Typst

Modern alternative to LaTeX. Official docs: https://typst.app/docs, packages: https://typst.app/universe.

Model baseline covers syntax, math, tables, and standard library. This skill covers only agent-specific gaps: path resolution, closure/state pitfalls, and PDF verification without preview.

## Verify (agents cannot preview PDFs)

```bash
typst --version
typst compile document.typ && echo OK || echo FAIL
typst compile document.typ output.pdf
typst compile src/main.typ --root .  # only if using "/..." imports
```

Text-level check: `typst compile doc.typ && pdftotext doc.pdf - | head -50` — see [debug.md](debug.md).

## Minimal Document

```typst
#set page(paper: "a4", margin: 2cm)
#set text(size: 11pt)

= Title

Content goes here.
```

## Common Errors

| Error | Fix |
| ----- | --- |
| "unknown variable" | Check `#let` spelling/scope |
| "file not found" | Path is relative to **current file**, not root — see [basics.md](basics.md) |
| "access denied" | File outside `--root`; move inside or adjust `--root` |
| "unknown font" | Use system fonts |
| "call depth exceeded" | Replace recursion with loop/fold |

## References (load on demand only)

| Task | File |
| ---- | ---- |
| Imports, paths, `--root`, `include` vs `import`, closure/`none` pitfalls | [basics.md](basics.md) |
| `state`/`context`/`query` for counters, headers, cross-refs | [advanced.md](advanced.md) |
| `pdftotext`, `repr`, `measure`, assert-based debugging | [debug.md](debug.md) |

For everything else use official docs, not this skill:

- Templates, set/show rules, page layout → https://typst.app/docs/tutorial/
- Package `typst.toml`, publishing → https://typst.app/docs/packages/
- Markdown/LaTeX conversion → `pandoc -f markdown -t typst in.md -o out.typ` (check output manually)
- Performance → `typst compile --timings timings.json`, view in Perfetto

## Examples

| Example | Description |
| ------- | ----------- |
| [basic-document.typ](examples/basic-document.typ) | Document setup, math, figures, tables |
| [template-report.typ](examples/template-report.typ) | Template fn, show rules, counters, appendix |
| [package-example/](examples/package-example/) | Minimal `typst.toml` + `lib.typ` re-export pattern |
