# Typst State, Context, Query

Needed for counters, headers, cross-refs. Full reference: https://typst.app/docs/reference/ — search `state`, `context`, `query`, `counter`.

Rule: `state.get()` and `query()` only work inside `context`. `counter(page)` / `counter(heading)` are built-in; use `state()` for custom data.

## Basic State

```typst
#let n = state("n", 0)
#n.update(i => i + 1)
#context n.get()           // read
#context [Total: #n.final()] // value at document end
```

## Headers: track current chapter

```typst
#let chapter = state("chapter", none)
#show heading.where(level: 1): it => { chapter.update(it.body); it }
#set page(header: context { chapter.get() })
```

## Query: find elements (needs `context`)

```typst
#context {
  let hs = query(heading.where(level: 1))
  for h in hs { [- #h.body] }
}

// Marker pattern for custom collection:
#metadata((key: "k")) <my-mark>
#context {
  for m in query(<my-mark>) { [#m.value.key] }
}
```

## Labels

```typst
= Intro <intro>
#figure(image("f.png"), caption: [Cap]) <fig:main>
See @intro and @fig:main.
```

## Cross-document accumulation (closure workaround)

Closures can't mutate outer vars. For data spanning the document, use `state` + `final()`:

```typst
#let _items = state("items", ())
#let add(i) = { _items.update(d => { d.push(i); d }) }
#context { let all = _items.final() /* render once */ }
```
