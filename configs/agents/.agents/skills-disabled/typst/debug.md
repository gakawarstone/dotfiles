# Typst Debugging (for agents without PDF preview)

## Text Verification with pdftotext

```bash
typst compile document.typ && pdftotext document.pdf - | head -50
typst compile document.typ && pdftotext document.pdf - | grep -i "expected text"
```

## Inspect Values

```typst
#repr(my-var)   // structure
#type(my-var)   // integer, string, array, dictionary, content
```

Gated debug helper (set `DEBUG = false` before publishing):

```typst
#let DEBUG = true
#let debug(label, value) = if DEBUG {
  block(fill: yellow.lighten(80%), inset: 4pt, radius: 2pt,
    text(size: 8pt, fill: red)[#label: #repr(value)])
}
```

Fail fast: `#assert(type(cfg) == dictionary, message: "cfg must be dict")`.

## Layout (needs `context`)

```typst
#context {
  let s = measure([Hello World])
  [Width: #s.width, Height: #s.height]
}
```

Visual boundary during development:

```typst
#let debug-box(c) = context { box(stroke: 0.5pt + red)[#c] }
#debug-box[Check boundaries]
```

State/query debugging:

```typst
#context [state=#repr(my-state.get()), headings=#query(heading).len()]
```

CLI flag alternative: `typst compile doc.typ --input debug=true` with `#let DEBUG = sys.inputs.at("debug", default: "false") == "true"`.
