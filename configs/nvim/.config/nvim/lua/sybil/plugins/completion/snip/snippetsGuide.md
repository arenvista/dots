# Typst snippets — how to use

Everything here describes the Typst snippets in this directory. They are picked
up automatically by the `from_lua` loader in `../luasnip.lua`, which maps a
filename to a filetype. There is nothing to register.

They live in two files:

| File            | Filetype     | Holds                                                            |
| --------------- | ------------ | ---------------------------------------------------------------- |
| `typstmath.lua` | `typstmath`  | Everything that goes _inside_ `$ … $` — 78 snippets, 38 of them auto |
| `typst.lua`     | `typst`      | `.typ` markup, scripting, preamble, `template.typ` helpers — 88 snippets, 2 auto |

`typstmath` is not a real filetype; `../luasnip.lua` pulls it into both `typst`
and `markdown` with `filetype_extend`.

**Math in markdown is Typst too, not LaTeX.** See [Markdown](#markdown) below.

---

## Expanding

| Key       | Where          | Does                                                                         |
| --------- | -------------- | ---------------------------------------------------------------------------- |
| `<Tab>`   | insert, select | Expand the trigger under the cursor, or jump to the next placeholder         |
| `<S-Tab>` | insert, select | Jump to the previous placeholder                                             |
| —         | insert         | **Autosnippets** fire the instant you finish typing the trigger — no `<Tab>` |

Both maps are set in `../luasnip.lua`; `enable_autosnippets = true` is set in
`../nvim-cmp.lua`.

## The one design rule

**Nothing here shadows syntax Typst already has.**

Typst is not LaTeX. It already renders `->`, `<-`, `=>`, `<=>`, `>=`, `<=`,
`!=`, `oo`, `in`, `subset`, `union`, and `RR`/`NN`/`ZZ`/`QQ`/`CC` natively, and
`sum`, `vec`, `hat`, `lim`, `abs`, `norm`, `mat` are real function names you can
just type. Porting the LaTeX-style autosnippets from `mathmode.lua` would have
_broken_ all of that — an autosnippet on `vec` hijacks you typing `vec(1,2)`.

So the split is:

- **Autosnippets** — only symbol-shaped or `;`-prefixed triggers, which are never
  valid Typst on their own: `$$`, `//`, `^^`, `__`, `dd`, `qq`, and the Greek
  letters. 38 total.
- **Everything else is `<Tab>`-only.** A name-shaped trigger like `sqrt` or `thm`
  can never ambush you, because it only expands when you ask.

Snippets are also gated by context: math snippets fire only inside `$ … $`,
markup snippets only outside it. Typing `fig` inside an equation does nothing.

---

## Math — entering

| Trigger |        | Expands to                                                     |
| ------- | ------ | -------------------------------------------------------------- |
| `$$`    | _auto_ | `$⟨cursor⟩$` — inline math                                     |
| `im`    |        | `$⟨⟩$`                                                         |
| `dm`    |        | `$ ⟨⟩ $` — display block                                       |
| `dml`   |        | `$ ⟨⟩ $ <eq:name>` — display block with a label for `@eq:name` |

## Math — structure

| Trigger          |        | Expands to                                    |
| ---------------- | ------ | --------------------------------------------- |
| `//`             | _auto_ | `(⟨⟩)/(⟨⟩)`                                   |
| `^^`             | _auto_ | `^(⟨⟩)`                                       |
| `__`             | _auto_ | `_(⟨⟩)`                                       |
| `dd`             | _auto_ | `dif ` — differential                         |
| `qq`             | _auto_ | `"⟨⟩"` — literal text inside math             |
| `sqrt` `root`    |        | `sqrt(⟨⟩)`, `root(3, ⟨⟩)`                     |
| `binom`          |        | `binom(n, k)`                                 |
| `abs` `norm`     |        | `abs(⟨⟩)`, `norm(⟨⟩)`                         |
| `floor` `ceil`   |        | `floor(⟨⟩)`, `ceil(⟨⟩)`                       |
| `lr` `lrb` `lrc` |        | auto-scaling `lr(( ))`, `lr([ ])`, `lr({ })`  |
| `ub` `ob`        |        | `underbrace(⟨⟩, ⟨⟩)`, `overbrace(…)`          |
| `attach`         |        | `attach(⟨⟩, t: ⟨⟩, b: ⟨⟩)`                    |
| `op`             |        | `op("Tr", limits: false)` — a custom operator |

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
| `;t` theta | `;k` kappa | `;l` lambda | `;m` mu     | `;n` nu      | `;x` xi    | `;p` pi    |
| `;r` rho   | `;s` sigma | `;u` tau    | `;f` phi    | `;c` chi     | `;y` psi   | `;o` omega |
| `;G` Gamma | `;D` Delta | `;T` Theta  | `;L` Lambda | `;P` Pi      | `;S` Sigma | `;F` Phi   |
| `;Y` Psi   | `;O` Omega | `;N` nabla  | `;8` oo     |              |            |            |

---

## Markup

| Trigger                 | Expands to                                                                                  |
| ----------------------- | ------------------------------------------------------------------------------------------- |
| `h1`–`h4`               | `= `, `== `, `=== `, `==== ` (start of line only)                                           |
| `bf` `em` `rawi`        | `*⟨⟩*`, `_⟨⟩_`, `` `⟨⟩` ``                                                                  |
| `code`                  | fenced ` ```rust ` block                                                                    |
| `fig` `figc`            | `#figure(…)` with caption and `<fig:name>` label — `figc` takes content instead of an image |
| `table` `grid`          | `#table(columns: …, table.header(…))`, `#grid(…)`                                           |
| `quote`                 | `#quote(block: true, attribution: [⟨⟩])[⟨⟩]`                                                |
| `img` `link` `fn`       | `#image(…)`, `#link("…")[…]`, `#footnote[…]`                                                |
| `cite` `ref` `lbl`      | `@key`, `@fig:name`, `<name>`                                                               |
| `align` `box` `block`   | `#align(center)[…]`, `#box(…)[…]`, `#block(…)[…]`                                           |
| `pb` `lb` `vsp` `hsp`   | `#pagebreak()`, `#linebreak()`, `#v(1em)`, `#h(1em)`                                        |
| `lorem` `outline` `bib` | `#lorem(50)`, `#outline(…)`, `#bibliography(…)`                                             |

## Scripting

| Trigger               | Expands to                                                                                                               |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `let` `fun`           | `#let name = ⟨⟩`, `#let name(body) = { … }`                                                                              |
| `set` `show` `showit` | `#set ⟨⟩(⟨⟩)`, `#show ⟨⟩: ⟨⟩`, `#show heading: it => [⟨⟩]`                                                               |
| `imp` `inc`           | `#import "⟨⟩": *`, `#include "⟨⟩"`                                                                                       |
| `if` `for`            | `#if ⟨⟩ { … }`, `#for item in list { … }`                                                                                |
| `preamble`            | a standalone document header (page/text/par/heading/equation setup + title block) — for notes _not_ using `template.typ` |

---

## Using it with `template.typ`

`template.typ` (the math notetaking template) defines theorem-like environments
and math helpers. These snippets scaffold them. **They assume you have
`#import "template.typ": *` at the top** — `tmpl` and `hw` write that for you.

### Starting a document

| Trigger | Expands to                                                                  |
| ------- | --------------------------------------------------------------------------- |
| `tmpl`  | the import plus `#show: notes.with(title:, course:, author:, date:)`        |
| `hw`    | the same but `#show: homework.with(…)` — no equation numbers, roomier enums |
| `prob`  | `#problem(1, title: "…")[ … ]`                                              |

### Environments

Every environment has **two** triggers: the bare one, and the same plus `t` for
the `title:` variant.

| Bare    | Titled   | Environment                                        |
| ------- | -------- | -------------------------------------------------- |
| `def`   | `deft`   | `#definition[…]`                                   |
| `thm`   | `thmt`   | `#theorem[…]`                                      |
| `lem`   | `lemt`   | `#lemma[…]`                                        |
| `cor`   | `cort`   | `#corollary[…]`                                    |
| `prop`  | `propt`  | `#proposition[…]`                                  |
| `claim` | `claimt` | `#claim[…]`                                        |
| `conj`  | `conjt`  | `#conjecture[…]`                                   |
| `axm`   | `axmt`   | `#axiom[…]`                                        |
| `qst`   | `qstt`   | `#question[…]`                                     |
| `exr`   | `exrt`   | `#exercise[…]`                                     |
| `sol`   | `solt`   | `#solution[…]`                                     |
| `ex`    | `ext`    | `#example[…]`                                      |
| `rmk`   | `rmkt`   | `#remark[…]`                                       |
| `obs`   | `obst`   | `#observation[…]`                                  |
| `nota`  | `notat`  | `#notation[…]`                                     |
| `warn`  | `warnt`  | `#warning[…]`                                      |
| `case`  | `caset`  | `#case[…]`                                         |
| `prf`   | `prft`   | `#proof[…]` — gets a `∎` tombstone, never numbered |

So `thmt<Tab>` gives you `#theorem(title: "⟨⟩")[ ⟨⟩ ]` with the cursor in the
title and `<Tab>` moving to the body.

### Template math helpers

These are functions the template defines; they work directly inside `$ … $`.

| Trigger    | Expands to              | Renders           |
| ---------- | ----------------------- | ----------------- |
| `ip`       | `ip(u, v)`              | ⟨u, v⟩            |
| `setb`     | `setb(x in RR, x > 0)`  | { x ∈ ℝ : x > 0 } |
| `dv` `pdv` | `dv(y, x)`, `pdv(f, x)` | dy/dx, ∂f/∂x      |
| `restr`    | `restr(f, A)`           | f\|_A             |
| `evalat`   | `evalat(F(x), a, b)`    | F(x)\|_a^b        |

The template also defines things you just type, no snippet needed: `RR` `NN`
`ZZ` `QQ` `CC` `FF` `PP` `EE` `HH` `KK`, `norm` `abs` `card`, `eps`, and the
operators `rank` `span` `sgn` `diag` `adj` `nullity` `proj` `argmin` `argmax`
`grad` `curl` `divg` `st` `Aut` `End` `Hom` `GL` `SL`.

### Numbered environments

Off by default, so existing notes render unchanged. Turn it on per document:

```typst
#show: notes.with(title: "Topic", numbered: true)
```

Environments then read `Definition 1.1.`, `Theorem 1.2.` and so on, restarting
at each level-1 heading. Proofs are skipped — they neither show a number nor
consume one.

`homework` passes its arguments straight through, so it works there too:

```typst
#show: homework.with(title: "MATH 302: Homework 1", numbered: true)
```

---

## Markdown

Math in `.md` files is written in Typst by default, not LaTeX. Two things make
that work:

- `queries/markdown_inline/injections.scm` sends every `$ … $` span to the
  **typst** parser instead of the latex one. That drives highlighting, the
  `in_mathzone` guard, and `snacks.image`'s inline math rendering (which shells
  out to `typst`, so the binary has to be on `$PATH`).
- the `ft_func` in `../nvim-cmp.lua` adds `typstmath` to a markdown buffer's
  snippet chain, so every snippet in the math tables above is available in
  markdown as well.

Only the delimiters differ, and they live in `markdown.lua`:

| Trigger  |        | Expands to                          |
| -------- | ------ | ----------------------------------- |
| `il`     | _auto_ | `$⟨⟩$` — inline math                |
| `;;`     | _auto_ | `$⟨⟩$` — same, easier to reach      |
| `dm`     | _auto_ | `$$` / `⟨⟩` / `$$` on their own lines — display |
| `contra` | _auto_ | `arrow.zigzag` (↯), inside math     |

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

| | Typst mode | LaTeX mode |
| --- | --- | --- |
| `$ … $` parses as | typst | latex |
| Snippets come from | `typstmath.lua` | `mathmode.lua` |
| `snacks.image` renders with | `typst` | `pdflatex` + `ghostscript` |
| `;a` gives | `alpha` | `\alpha` |
| `_qed` gives | `$qed$` | `$\blacksquare$` |

Tree-sitter injection queries are global per language, so
`queries/markdown_inline/injections.scm` carries a rule per language per
delimiter — four math rules — and a custom `#md-math?` predicate, registered in
`lua/sybil/core/mdmath.lua`, picks between them. Because a predicate is
evaluated per match against the *buffer*, the choice reaches markdown nested two
levels down inside a notebook (`ipynb` → `markdown` → `markdown_inline`), which
a per-parser option could not. `mdmath.get()` is the single place that answers
the question; the predicate and the snippet `ft_func` both call it.

`markdown.lua` itself is shared by both modes: its `in_mathzone` knows both sets
of node types, and `contra` picks its body when it expands.

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
fires. Every entry snippet (`$$`, `im`, `dm`) inserts both delimiters, so this
only bites if you type a lone `$` by hand.

**`#` code inside math is _not_ math.** `$ x = #calc.pi $` — the cursor inside
`#calc.pi` counts as code, so math snippets stay quiet. Same for `$ "text" $`.

**`dml` does not work under `homework`.** The `homework` variant sets
`math.equation(numbering: none)`, and Typst refuses to reference an unnumbered
equation — `@eq:name` fails the build with _"cannot reference equation without
numbering"_. Use `notes` for documents with labelled equations, or add
`#set math.equation(numbering: "(1)")` after the `#show: homework.with(…)` line.

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
content blocks. Doubling is the way.

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
