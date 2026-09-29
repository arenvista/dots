# Typst and Markdown snippets — how to use

Everything here describes the Typst and Markdown snippets in this directory.
They are picked up automatically by the `from_lua` loader in `../luasnip.lua`,
which maps a filename to a filetype. There is nothing to register.

They live in three files:

| File            | Filetype    | Holds                                                                                               |
| --------------- | ----------- | --------------------------------------------------------------------------------------------------- |
| `typstmath.lua` | `typstmath` | Everything that goes _inside_ `$ … $` — 102 snippets, 47 of them auto                               |
| `typst.lua`     | `typst`     | `.typ` markup, scripting, folio scaffolding and environments — 130 triggers, 3 auto                 |
| `markdown.lua`  | `markdown`  | Math delimiters, the vault's callouts, block links, the lecture header — 105 snippets, 3 auto       |

`typst.lua` holds 231 snippets for its 130 triggers: every `#call` comes in a
markup and a code version (see [`#` or no `#`](#-or-no-)).

The MATH 302 notation — balls, the set-builder, interior, closure and
boundary, the triangle inequalities — is outlined in `SNIPS.typ`, with how
often the lecture notes use each construct. Those snippets are section 8 of
`typstmath.lua` and the "PREAMBLE MATH" block of `markdown.lua`.

`typstmath` is not a real filetype; `../luasnip.lua` pulls it into `typst` with
`filetype_extend`, and into `markdown` per buffer through its `ft_func` (see
[Markdown](#markdown)).

**Math in markdown is Typst too, not LaTeX.** See [Markdown](#markdown) below.

---

## Expanding

| Key       | Where          | Does                                                                         |
| --------- | -------------- | ---------------------------------------------------------------------------- |
| `<Tab>`   | insert, select | Expand the trigger under the cursor, or jump to the next placeholder         |
| `<S-Tab>` | insert, select | Jump to the previous placeholder                                             |
| `<Tab>`   | visual         | Cut the selection and keep it for the next snippet                           |
| —         | insert         | **Autosnippets** fire the instant you finish typing the trigger — no `<Tab>` |

All three maps, `enable_autosnippets = true` and `store_selection_keys` are set
in `../luasnip.lua`.

### Wrapping text you already wrote

Select it, press `<Tab>` (it disappears), type a trigger and `<Tab>`: the text
comes back as the snippet's body. `Vjj<Tab>thmt<Tab>` turns three lines into a
titled theorem with the cursor in the title. In a callout every line of it gets
its `> `.

It works for every environment and label-only box, `qsol`'s question, `bf`
`em` `rawi`, and `link` `lref` `fn` `box` `block` `align` `quote` `prob` in
Typst; for every callout, `bf` `em` and `lref` in Markdown; and in math, `bdy`
everywhere and `intr` `cl` in Markdown. Any other snippet
expands as usual and the cut text is gone — `u` brings it back.

## The one design rule

**Nothing here shadows syntax Typst already has.**

Typst is not LaTeX. It already renders `->`, `<-`, `=>`, `<=>`, `>=`, `<=`,
`!=`, `oo`, `in`, `subset`, `union`, and `RR`/`NN`/`ZZ`/`QQ`/`CC` natively, and
`sum`, `vec`, `hat`, `lim`, `abs`, `norm`, `mat` are real function names you can
just type. Porting the LaTeX-style autosnippets from `mathmode.lua` would have
_broken_ all of that — an autosnippet on `vec` hijacks you typing `vec(1,2)`.

So the split is:

- **Autosnippets** — only triggers that are never valid Typst on their own:
  symbols (`$$`, `^^`, `__`, `+-`, `~=`, `!in`, `sub=`, `sup=`), the
  `;`-prefixed Greek letters, and a few letter pairs that name nothing (`dd`,
  `qq`, `xx`, `ff`). That is 47 in math, plus the entry triggers `$$` `;;` `dm`
  and `contra` (↯).
- **Everything else is `<Tab>`-only.** A name-shaped trigger like `sqrt` or `thm`
  can never ambush you, because it only expands when you ask.

Snippets are also gated by context: math snippets fire only inside `$ … $`,
markup snippets only in markup — not in math, and not in raw blocks, strings or
comments either. Typing `fig` inside an equation does nothing, and `for (;;)` in
a code block stays `for (;;)`.

---

## Math — entering

| Trigger |        | Expands to                                                     |
| ------- | ------ | -------------------------------------------------------------- |
| `$$`    | _auto_ | `$⟨cursor⟩$` — inline math                                     |
| `;;`    | _auto_ | `$⟨⟩$` — same, easier to reach                                 |
| `dm`    |        | `$ ⟨⟩ $` — display block                                       |
| `dml`   |        | `$ ⟨⟩ $ <eq:name>` — display block with a label for `@eq:name` |
| `dma`   |        | an aligned display over two lines: `⟨⟩ &= ⟨⟩ \` / `&= ⟨⟩`      |

## Math — structure

| Trigger          |        | Expands to                                     |
| ---------------- | ------ | ---------------------------------------------- |
| `ff`             | _auto_ | `(⟨⟩)/(⟨⟩)` — fraction                         |
| `^^`             | _auto_ | `^(⟨⟩)`                                        |
| `__`             | _auto_ | `_(⟨⟩)`                                        |
| `dd`             | _auto_ | `dif ` — differential                          |
| `qq`             | _auto_ | `"⟨⟩"` — literal text inside math              |
| `xx`             | _auto_ | `times`                                        |
| `sqrt` `root`    |        | `sqrt(⟨⟩)`, `root(3, ⟨⟩)`                      |
| `binom`          |        | `binom(n, k)`                                  |
| `abs` `norm`     |        | `abs(⟨⟩)`, `norm(⟨⟩)`                          |
| `floor` `ceil`   |        | `floor(⟨⟩)`, `ceil(⟨⟩)`                        |
| `lr` `lrb` `lrc` |        | auto-scaling `lr(( ))`, `lr([ ])`, `lr({ })`   |
| `ub` `ob`        |        | `underbrace(⟨⟩, ⟨⟩)`, `overbrace(…)`           |
| `attach`         |        | `attach(⟨⟩, t: ⟨⟩, b: ⟨⟩)`                     |
| `op`             |        | `op("Tr", limits: #false)` — a custom operator |

The fraction used to be `//`, which can never work: `//` starts a comment even
inside math — see [Gotchas](#gotchas).

## Math — symbols

Only the ones Typst has no shorthand for.

| Trigger       |        | Expands to                                  |
| ------------- | ------ | ------------------------------------------- |
| `+-`          | _auto_ | `plus.minus` ±                              |
| `~=`          | _auto_ | `approx` ≈ — the same trigger as in LaTeX   |
| `!in`         | _auto_ | `in.not` ∉                                  |
| `sub=` `sup=` | _auto_ | `subset.eq` ⊆, `supset.eq` ⊇                |
| `;0`          | _auto_ | `nothing` ∅ — 0 for the empty set, 8 for ∞  |

`+-` and `~=` fire straight after a letter too, and put a space in: `a+-` gives
`a plus.minus`, not the unknown variable `aplus.minus`. The others need a space
or a symbol before them, so `n!in` stays a factorial.

Already built in, no snippet needed: `...` is `dots.h` (…), `dot` is
`dot.op` (⋅), and `-->` ⟶, `|->` ↦, `==>` ⟹, `<==>` ⟺ are shorthands.

## Math — big operators

| Trigger                 | Expands to                                 |
| ----------------------- | ------------------------------------------ |
| `sum` `prod`            | `sum_(n = 1)^(oo)`, `product_(n = 1)^(oo)` |
| `int`                   | `integral_(a)^(b) ⟨⟩ dif x`                |
| `iint` `oint`           | `integral.double_()`, `integral.cont_()`   |
| `lim` `limsup` `liminf` | `lim_(n -> oo)` etc.                       |
| `part`                  | `(partial ⟨⟩)/(partial ⟨⟩)`                |
| `der`                   | `(dif y)/(dif x)`                          |

## Math — matrices

| Trigger       | Expands to                             |
| ------------- | -------------------------------------- |
| `mat`         | `mat(a, b; c, d)` across four lines    |
| `bmat` `vmat` | same with `delim: "["` / `delim: "\|"` |
| `vv`          | `vec(⟨⟩, ⟨⟩)`                          |
| `cases`       | `cases(x & "if" …, y & "otherwise")`   |

## Math — accents and styles

`hat` `bar` `vec` `dot` `ddot` `tilde` → `hat(⟨⟩)`, `overline(⟨⟩)`, `arrow(⟨⟩)`,
`dot(⟨⟩)`, `dot.double(⟨⟩)`, `tilde(⟨⟩)`

`bb` `cal` `frak` `bold` `up` → `bb(⟨⟩)`, `cal(⟨⟩)`, `frak(⟨⟩)`, `bold(⟨⟩)`,
`upright(⟨⟩)`

## Math — Greek (all autosnippets)

Type `;` then the letter. Lowercase gives lowercase, uppercase gives uppercase.

|            |            |             |             |              |            |            |
| ---------- | ---------- | ----------- | ----------- | ------------ | ---------- | ---------- |
| `;a` alpha | `;b` beta  | `;g` gamma  | `;d` delta  | `;e` epsilon | `;z` zeta  | `;h` eta   |
| `;t` theta | `;i` iota  | `;k` kappa  | `;l` lambda | `;m` mu      | `;n` nu    | `;x` xi    |
| `;p` pi    | `;r` rho   | `;s` sigma  | `;u` tau    | `;f` phi     | `;c` chi   | `;y` psi   |
| `;o` omega | `;G` Gamma | `;D` Delta  | `;T` Theta  | `;L` Lambda  | `;X` Xi    | `;P` Pi    |
| `;S` Sigma | `;F` Phi   | `;Y` Psi    | `;O` Omega  | `;N` nabla   | `;8` oo    | `;0` ∅     |

---

## Markup

| Trigger                 | Expands to                                                                                  |
| ----------------------- | ------------------------------------------------------------------------------------------- |
| `h1`–`h4`               | `= `, `== `, `=== `, `==== ` (start of line only)                                           |
| `bf` `em` `rawi`        | `*⟨⟩*`, `_⟨⟩_`, `` `⟨⟩` ``                                                                  |
| `code`                  | fenced ` ```python ` block                                                                  |
| `fig` `figc`            | `#figure(…)` with caption and `<fig:name>` label — `figc` takes content instead of an image |
| `table` `grid`          | `#table(columns: …, table.header(…))`, `#grid(…)`                                           |
| `quote`                 | `#quote(block: true, attribution: [⟨⟩])[⟨⟩]`                                                |
| `img` `link` `fn`       | `#image(…)`, `#link("…")[…]`, `#footnote[…]`                                                |
| `lref`                  | `#link(<⟨label⟩>)[⟨text⟩]` — a link to a labelled box, see `thml` below                    |
| `cite` `ref` `lbl`      | `@key`, `@fig:name`, `<name>`                                                               |
| `align` `box` `block`   | `#align(center)[…]`, `#box(…)[…]`, `#block(…)[…]`                                           |
| `pb` `lb` `vsp` `hsp`   | `#pagebreak()`, `#linebreak()`, `#v(1em)`, `#h(1em)`                                        |
| `lorem` `outline` `bib` | `#lorem(50)`, `#outline(…)`, `#bibliography(…)`                                             |

## Scripting

| Trigger               | Expands to                                                                                                             |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `let` `fun`           | `#let name = ⟨⟩`, `#let name(body) = { … }`                                                                            |
| `set` `show` `showit` | `#set ⟨⟩(⟨⟩)`, `#show ⟨⟩: ⟨⟩`, `#show heading: it => [⟨⟩]`                                                             |
| `imp` `inc`           | `#import "⟨⟩": *`, `#include "⟨⟩"`                                                                                     |
| `if` `for`            | `#if ⟨⟩ { … }`, `#for item in list { … }`                                                                              |
| `preamble`            | a standalone document header (page/text/par/heading/equation setup + title block) — for documents _not_ using folio |

### `#` or no `#`

Every snippet that writes a `#call` — the Markup rows from `fig` down except
`cite` `ref` `lbl`, all of Scripting except `preamble`, and the folio
environments and `prob` below — checks whether it is in markup or in code:

- in markup, `let<Tab>` gives `#let name = ⟨⟩`;
- inside a `{ … }` block it gives `let name = ⟨⟩`, because a `#` there is a
  syntax error;
- straight after a `#` you already typed it drops its own, so `#thm<Tab>` gives
  `#theorem[…]`, not `##theorem[…]`.

The completion menu only lists the one that applies.

---

## Using it with folio

folio (`@local/folio`, source in `~/Documents/Projects/typstTemplates`) defines
the theorem-like environments and math helpers these snippets scaffold. **They
assume `#import "@local/folio:0.1.0": *` at the top** — `tmpl`, `hw`, `paper`
and `book` write it for you.

### Starting a document

| Trigger | Expands to                                                                     |
| ------- | ------------------------------------------------------------------------------ |
| `tmpl`  | the import plus `#show: notes.with(title:, course:, author:, date:)`           |
| `hw`    | the same with `homework.with(…, count-h1: true)` — `= Question` gets numbered  |
| `paper` | `paper.with(title:, author:, date:, abstract: […])`                            |
| `book`  | `book.with(title:, course:, author:, date:)` — title page, contents, chapters  |
| `qsol`  | one homework question: `= Question`, `#question[…]`, `#solution[…]`            |
| `prob`  | `#problem(1, title: "…")[ … ]` — folio's unnumbered problem heading            |

The header fills itself in from where the file lives. The course comes from the
path (`…/MATH-475/…` gives `MATH 475`), `hw`'s title from the folder
(`…/Homework/06/…` gives `MATH 475: Homework 6`), the date is today
(`September 28, 2026`) and the author is you. They are all placeholders, so
`<Tab>` past them or type over them.

### Environments

Every environment has **three** triggers:

| Trigger | Expands to                                                                  |
| ------- | --------------------------------------------------------------------------- |
| `thm`   | `#theorem[ ⟨⟩ ]`                                                            |
| `thmt`  | `#theorem(title: "⟨⟩")[ ⟨⟩ ]`                                               |
| `thml`  | `#theorem(title: "⟨⟩")[ ⟨⟩ ] <thm-⟨⟩>` — a label that follows the title |

| Bare    | Environment          | Label / callout |
| ------- | -------------------- | --------------- |
| `def`   | `#definition[…]`     | `def`           |
| `thm`   | `#theorem[…]`        | `thm`           |
| `lem`   | `#lemma[…]`          | `lem`           |
| `cor`   | `#corollary[…]`      | `cor`           |
| `prop`  | `#proposition[…]`    | `prop`          |
| `claim` | `#claim[…]`          | `claim`         |
| `conj`  | `#conjecture[…]`     | `conj`          |
| `axm`   | `#axiom[…]`          | `ax`            |
| `qst`   | `#question[…]`       | `q` / `?`       |
| `exr`   | `#exercise[…]`       | `exer`          |
| `sol`   | `#solution[…]`       | `soln`          |
| `ex`    | `#example[…]`        | `ex`            |
| `rmk`   | `#remark[…]`         | `rem`           |
| `obs`   | `#observation[…]`    | `obs`           |
| `nota`  | `#notation[…]`       | `notn`          |
| `warn`  | `#warning[…]`        | `warn`          |
| `case`  | `#case[…]`           | `case`          |
| `prf`   | `#proof[…]` — gets a `∎` tombstone, never numbered | `pf` |
| `form`  | `#formula[…]`        | `form`          |
| `key`   | `#key[…]`            | `key`           |
| `hum`   | `#intuition[…]`      | `hum`           |
| `aside` | `#aside[…]`          | `aside`         |
| `impo`  | `#important[…]` — not `imp`, which is `#import` | `imp` |

So `thmt<Tab>` gives you `#theorem(title: "⟨⟩")[ ⟨⟩ ]` with the cursor in the
title and `<Tab>` moving to the body.

The label is the title, lowercased and hyphenated, behind the prefix in the
last column: `Real Number System` gives `<def-real-number-system>`, the same
name the Markdown note uses as its block id (`^def-real-number-system`, see
[Callouts](#callouts)). It fills in when you `<Tab>` out of the title; `<Tab>`
into it to change it. folio's boxes cannot be `@`-referenced, so link to one
with `lref`: `#link(<def-metric>)[metric space]`.

folio's label-only boxes take a body and nothing else, so they have one
trigger each: `pit` → `#pitfall[…]`, `idea` → `#idea[…]`, `recall` →
`#recall[…]`.

### folio math helpers

These are functions folio defines; they work directly inside `$ … $`.

| Trigger    | Expands to              | Renders           |
| ---------- | ----------------------- | ----------------- |
| `ip`       | `ip(u, v)`              | ⟨u, v⟩            |
| `setb`     | `setb(x in RR, x > 0)`  | { x ∈ ℝ : x > 0 } |
| `dv` `pdv` | `dv(y, x)`, `pdv(f, x)` | dy/dx, ∂f/∂x      |
| `restr`    | `restr(f, A)`           | f\|_A             |
| `evalat`   | `evalat(F(x), a, b)`    | F(x)\|_a^b        |
| `contra`   | `arrow.zigzag` (_auto_) | ↯                 |

folio also defines things you just type, no snippet needed: `RR` `NN` `ZZ` `QQ`
`CC` `FF` `PP` `EE` `HH` `KK`, `eps`, `dt`, `norm` `abs` `card`, the bracketed
`vv(1, 2)` and `mm(1, 2; 3, 4)`, and the operators `rank` `span` `Span` `Nul`
`Col` `Row` `sgn` `diag` `adj` `nullity` `proj` `comp` `argmin` `argmax` `grad`
`curl` `divg` `st` `Aut` `End` `Hom` `GL` `SL`.

### Numbering

`notes`, `paper` and `book` number the result-like boxes ("Theorem 3.2"),
restarting at each level-1 heading; `homework` numbers none. `numbered: true`
or `numbered: false` in the `.with(…)` overrides it either way. Proofs,
solutions, remarks and the other asides never take a number.

---

## Markdown

Math in `.md` files is written in Typst by default, not LaTeX. Two things make
that work:

- `queries/markdown_inline/injections.scm` sends every `$ … $` span to the
  **typst** parser instead of the latex one. That drives highlighting, the
  `in_mathzone` guard, and `snacks.image`'s inline math rendering (which shells
  out to `typst`, so the binary has to be on `$PATH`).
- the `ft_func` in `../luasnip.lua` adds `typstmath` to a markdown buffer's
  snippet chain, so every snippet in the math tables above is available in
  markdown as well.

### Math delimiters

| Trigger  |        | Expands to                                              |
| -------- | ------ | ------------------------------------------------------- |
| `;;`     | _auto_ | `$⟨⟩$` — inline math                                    |
| `il`     |        | `$⟨⟩$` — the same, on `<Tab>`                           |
| `dm`     | _auto_ | `$$` / `⟨⟩` / `$$` on their own lines — display         |
| `dma`    |        | the same with `⟨⟩ &= ⟨⟩ \` / `&= ⟨⟩` — aligned display  |
| `contra` | _auto_ | `arrow.zigzag` (↯), inside math                         |

`il` used to be an autosnippet, and it fired at the start of every word
beginning with "il" — "illustrate", "illegal". It is `<Tab>`-only now; `;;` is
the instant one.

Inside a callout `dm` and `dma` put the `> ` in front of every line they add,
so the block stays in the callout — the way the notes write it:

```markdown
> $$
> norm(x+y)^2 &= ip(x+y, x+y) \
> &= norm(x)^2 + 2 ip(x,y) + norm(y)^2
> $$
>
```

The same goes for a nested quote (`> > `) and a list item (indented under the
item's text). At the top level the body is indented four spaces, as before.

### Callouts

The vault's theorem environments (`.obsidian/snippets/callouts.css`, matched
to folio), on the same triggers as the folio environments above — `thm` is a
theorem box in either file:

| Trigger | Expands to                                                                      |
| ------- | ------------------------------------------------------------------------------- |
| `thm`   | `> [!thm\|b]` / `> ⟨⟩`                                                          |
| `thmt`  | `> [!thm\|b t] ⟨title⟩` / `> ⟨⟩`                                                |
| `thml`  | the same, then the block id `^thm-⟨⟩` under it, filled in from the title       |

`|b t` is how the notes write them: `t` shows the title, `b` draws the
stronger border. The block-id prefix is the last column of the environment
table (`qst` gives `[!?|b]` and `^q-…`).

Where the callout's own name differs from the Typst trigger, it works too:
`pf` (`prf`), `rem` (`rmk`), `notn` (`nota`), `ax` (`axm`), `exer` (`exr`),
`soln` (`sol`) and `imp` (`impo`). `check` is Markdown-only; folio has no
counterpart.

They expand only at the start of a line, so a callout never lands in the middle
of a sentence. On a `> ` line you get a nested callout (`> > [!thm|b]`). `imp`
is this and not friendly-snippets' `> [!IMPORTANT]`.

### Text and links

| Trigger    | Expands to                                                                            |
| ---------- | ------------------------------------------------------------------------------------- |
| `bf` `em`  | `**⟨⟩**`, `_⟨⟩_` — the same triggers as in Typst                                      |
| `lref`     | `[[⟨note⟩#^⟨id⟩\|⟨text⟩]]` — a block link; leave the note empty for this file         |
| `lec`      | front matter (`tags`, `cssclasses: [numbered]`) and `# Lecture 05: ⟨Title⟩`, numbered from the file name (`L05.md`, `05.md`) |

friendly-snippets still supplies the rest of markdown: `h1`–`h6`, `link`,
`img`, `codeblock`, `table`, `task`, and the GitHub callouts on `note`, `tip`,
`warning`.

### Switching a buffer back to LaTeX

`:MdMath latex` flips **the current buffer** to LaTeX; `:MdMath typst` flips it
back and a bare `:MdMath` toggles. It is per buffer, so an old LaTeX note and a
new Typst one can be open side by side, and it sticks across a `:edit`. It
accepts markdown and `ipynb` buffers.

**Notebooks are the exception, and they are LaTeX by default.** Jupyter renders
markdown cells with MathJax, so `$ .. $` in an `.ipynb` — the notebook facade
and the buffer opened for a single cell alike — is LaTeX regardless of
`M.default`, and gets `mathmode.lua`'s snippets. An explicit `:MdMath typst` on
a notebook buffer still wins if you want it.

Plain markdown buffers start on Typst. To change that, edit `M.default` in
`lua/sybil/core/mdmath.lua` and restart; buffers already open when you change it
pick the new value up unpredictably, on their next re-parse.

There is no auto-detect for ordinary files: an old LaTeX note needs
`:MdMath latex` once per session, every session.

The command moves both halves at once, which is the point — a buffer whose
injection says one thing and whose snippets say the other is useless:

|                             | Typst mode      | LaTeX mode                 |
| --------------------------- | --------------- | -------------------------- |
| `$ … $` parses as           | typst           | latex                      |
| Snippets come from          | `typstmath.lua` | `mathmode.lua`             |
| `snacks.image` renders with | `typst`         | `pdflatex` + `ghostscript` |
| `;a` gives                  | `alpha`         | `\alpha`                   |
| `_qed` gives                | `$qed$`         | `$\blacksquare$`           |

Tree-sitter injection queries are global per language, so
`queries/markdown_inline/injections.scm` has a single math pattern whose
`#md-math!` directive, registered in `lua/sybil/core/mdmath.lua`, sets the
language for each span it matches. Because a directive runs per match against
the _buffer_, the choice reaches markdown nested two levels down inside a
notebook (`ipynb` → `markdown` → `markdown_inline`), which a per-parser option
could not. `mdmath.get()` is the single place that answers the question; the
directive and the snippet `ft_func` both call it.

`markdown.lua` itself is shared by both modes: its `in_mathzone` knows both sets
of node types, its prose guard treats a typst or a latex span alike as math,
and `contra` picks its body when it expands.

**Display math stays `$$ … $$` here.** That is markdown's delimiter, not
Typst's — Typst has no `$$`, its display math is a single `$` with surrounding
whitespace. The injection query bridges the two by trimming one `$` off each
end before handing the block to the Typst parser, so `$$ … $$` highlights,
renders, and fires snippets exactly like a `.typ` equation does. The trim is
markdown-only; `.typ` files keep the single-`$` form from `typst.lua`.

A single `$` on its own lines also works in markdown if you prefer it — the
inline rule already covers it, and Typst reads it as a block equation.

**Keep a blank line out of the body.** A blank line ends the markdown paragraph
and with it the math span, so the injection stops at that point.

Not covered: `markdown-preview.nvim` renders with KaTeX and obsidian.nvim with
its own renderer, so neither shows Typst math. In-editor rendering via
`snacks.image` is the one that works. Fenced ` ```math ` blocks are also still
LaTeX — that mapping is hardcoded in snacks' own `queries/markdown/images.scm`.

---

## Gotchas

**Math snippets need a closing `$`.** The Typst parser treats an unterminated
`$` as an error node, so the "am I in math?" check returns false and nothing
fires. Every entry snippet (`$$`, `;;`, `dm`, `dma`) inserts both delimiters,
so this only bites if you type a lone `$` by hand.

**`//` is a comment, even inside math.** Typing `//` in an equation comments
out the rest of the line — the closing `$` included — so the equation breaks
until you delete it. That is why the fraction is `ff`. A plain `/` is a
fraction too: `a/b`.

**`#` code inside math is _not_ math.** `$ x = #calc.pi $` — the cursor inside
`#calc.pi` counts as code, so math snippets stay quiet. Same for `$ "text" $`.

**`dml` does not work under `homework`.** `homework` sets
`eq-numbering: none`, and Typst refuses to reference an unnumbered equation —
`@eq:name` fails the build with _"cannot reference equation without
numbering"_. Add `eq-numbering: "flat"` to the `homework.with(…)`, or use
`notes`.

**folio boxes are not `@`-referenceable.** `@thm-x` on a labelled box fails
with _"cannot reference sequence"_. Link to it instead: `lref` gives
`#link(<thm-x>)[…]`.

**Enter does not continue a callout.** Neovim's markdown ftplugin takes `r`
out of `formatoptions`, so a new line inside a callout starts without `> `.
The snippets write their own `> ` lines. For Enter to continue the quote,
`setlocal formatoptions+=r` in a markdown `FileType` autocmd — it also makes
Enter under a list item indent to the item's text rather than start at the
margin.

---

## Editing the snippets

Snippet bodies use LuaSnip's `fmta`, whose placeholders are `<>`. That collides
with Typst — labels are `<fig:x>` and show rules contain `=>`. **A literal angle
bracket has to be doubled:**

```lua
fmta("<<eq:<>>>", { i(1, "name") })   -- produces  <eq:name>
fmta("it =>> [<>]", { i(1) })         -- produces  it => []
```

Custom `delimiters` are no help: `()` collides with math calls and `[]` with
content blocks. Doubling is the way. The markdown callouts go the other way and
use `fmt`, whose placeholders are `{}`: a callout is all `>` and has no braces.

To add a `#call` snippet to `typst.lua`, use `call` rather than `s`: it builds
both the markup and the code version. Write the body without the `#`, and pass
the nodes as a function, since one node cannot belong to two snippets:

```lua
add(call("vsp", "v(<>)", function()
    return { i(1, "1em") }
end))
```

To reload after an edit, restart Neovim or:

```vim
:lua require("luasnip.loaders.from_lua").load({ paths = "./lua/sybil/plugins/completion/snip" })
```

To check your edit before trusting it — this catches unescaped brackets,
duplicate triggers, and syntax errors without leaving the shell:

```sh
for f in typst typstmath markdown; do
  nvim --headless -u NONE \
    -c 'lua vim.opt.runtimepath:append(vim.fn.expand("~/.local/share/nvim/lazy/LuaSnip"))' \
    -c "lua local s = loadfile('lua/sybil/plugins/completion/snip/$f.lua')(); print('$f: ' .. #s .. ' snippets ok')" \
    -c 'qa!'
done
```
