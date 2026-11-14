# Typst Basics: Paths and Pitfalls

Model baseline covers markup, types, functions, math. This file covers only what models get wrong. Full reference: https://typst.app/docs/reference/

## Modes (one rule)

`#` enters code, `[ ]` returns to markup, `#(...)` embeds a value:

```typst
#let x = 1 + 2
The answer is #(1 + 2). // not [1 + 2]
```

## Imports and Paths

```typst
#import "utils.typ": helper        // relative to CURRENT file
#import "/src/lib.typ": *          // relative to project --root
#include "chapter1.typ"            // inserts content as-is (no scope leak)
```

| Path | Resolves to |
| ---- | ----------- |
| `"utils.typ"` | Current file's directory |
| `"/src/lib.typ"` | Project root (`--root`) |
| `"@preview/pkg:1.0"` | Typst Universe — check https://typst.app/universe for version |

```bash
typst compile src/main.typ          # root = src/
typst compile src/main.typ --root . # root = ., use when "/" imports fail
```

| Error | Fix |
| ----- | --- |
| "file not found" (relative) | Resolve relative to importing file, not project root |
| "file not found" (`/...`) | Pass `--root .` or fix path |
| "access denied" | File is outside `--root` |

Images, JSON, reads follow the same rules: `#image("fig.png")`, `#let d = json("data.json")`.

## Include vs Import

- `import`: brings functions/variables into scope.
- `include`: pastes document content. Variables defined inside do NOT leak out.

```typst
// vars.typ: #let title = "Hi"
// main.typ:
#import "vars.typ": title  // works
#include "chapters/intro.typ" // content only
```

## Pitfalls

**Closures cannot mutate captured variables:**

```typst
// WRONG: #let add(x) = { results.push(x) }
// RIGHT:
#let results = ()
#for item in items { results.push(transform(item)) }
// Or: #let d = items.fold((:), (acc, i) => { acc.insert(i.key, i.value); acc })
```

**Missing branch returns `none` — guard it:**

```typst
#let v = if x > 0 { x } // none if x <= 0
#if v != none { [Got: #v] }
```

**Spacing:** `#[A]#[B]` renders "AB". Add explicit `#[A] #[B]` or `#h(1em)`.
