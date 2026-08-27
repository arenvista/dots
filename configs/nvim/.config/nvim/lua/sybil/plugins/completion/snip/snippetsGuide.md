# Typst snippets — how to use

Everything here describes `typst.lua` in this directory. It is picked up
automatically by the `from_lua` loader in `../luasnip.lua`, which maps a
filename to a filetype: `typst.lua` → `typst`. There is nothing to register.

165 snippets: 127 for `typst`, plus 38 autosnippets.

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
nvim --headless -u NONE \
  -c 'lua vim.opt.runtimepath:append(vim.fn.expand("~/.local/share/nvim/lazy/LuaSnip"))' \
  -c 'lua local s = loadfile("lua/sybil/plugins/completion/snip/typst.lua")(); print(#s .. " snippets ok")' \
  -c 'qa!'
```
