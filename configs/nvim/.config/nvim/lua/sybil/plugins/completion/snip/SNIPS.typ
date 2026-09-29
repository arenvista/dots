// =========================================================================
// SNIPS.typ — the MATH 302 math snippets, and the notes they come from
//
// What ~/Documents/School/2026-Fall/MATH-302/Notes/Lecture/L01–L10.md write
// most often inside `$ … $`, and the snippet that types each one. Every count
// is an occurrence in those ten files (1,921 math spans; cetz drawings left
// out). textbook.typ is generated from the same notes, so it adds nothing new.
//
// The snippets themselves: typstmath.lua, section 8, and the "PREAMBLE MATH"
// block of markdown.lua. snippetsGuide.md covers everything else.
//
// Compile:  typst compile SNIPS.typ /tmp/SNIPS.pdf
// =========================================================================

#set document(title: "MATH 302 Snippets", author: "Aren Vista")
#set page(paper: "a4", margin: (x: 2cm, y: 2cm), numbering: "1")
#set text(font: "New Computer Modern", size: 10pt, lang: "en")
#set par(justify: true)
#set heading(numbering: "1.")
#show heading.where(level: 1): set block(above: 1.4em, below: 0.8em)
#show raw: set text(font: "DejaVu Sans Mono", size: 8.5pt)

// The notes' TypstMate preamble, so the Renders column prints what the notes
// print (the same `#let`s textbook.typ carries).
#let ip(x, y) = $lr(chevron.l #x, #y chevron.r)$
#let intr(A) = $#A^circle.small$
#let cl(A) = $overline(#A)$

#let accent = rgb("#3d7fb8")
#let warm = rgb("#c9652b")
#let rule = luma(215)

// An expansion, written as a string: ⟨x⟩ is a tab stop whose default text is
// x (⟨⟩ is an empty one), «x» is text that mirrors an earlier tab stop.
#let expands(s) = {
  let out = ()
  let last = 0
  for m in s.matches(regex("⟨([^⟩]*)⟩|«([^»]*)»")) {
    out.push(raw(s.slice(last, m.start)))
    let (stop, mirror) = m.captures
    if stop != none {
      out.push(box(
        fill: accent.lighten(85%),
        radius: 2pt,
        inset: (x: 1.5pt),
        outset: (y: 2.5pt),
        text(fill: accent, raw(if stop == "" { "…" } else { stop })),
      ))
    } else {
      out.push(text(fill: warm, underline(raw(mirror))))
    }
    last = m.end
  }
  out.push(raw(s.slice(last)))
  out.join()
}

#let trigger(name, md: false) = {
  raw(name)
  if md { h(4pt) + box(text(size: 7pt, fill: warm, smallcaps[md])) }
}

// One table per group: Trigger · Expands to · Renders · Uses.
#let snippets(..rows) = table(
  columns: (auto, 1fr, auto, auto),
  align: (left + horizon, left + horizon, left + horizon, right + horizon),
  inset: (x: 5pt, y: 5pt),
  stroke: (_, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.4pt + rule) },
  table.header([*Trigger*], [*Expands to*], [*Renders*], [*Uses*]),
  ..rows.pos().flatten(),
)

#align(center)[
  #text(17pt)[*MATH 302 Snippets*] \
  #v(2pt)
  The operations the lecture notes type most, and the snippet for each
]

#v(6pt)

These come from counting every construct inside `$ … $` in `L01.md`–`L10.md`,
then asking which ones cost real keystrokes: the padded set-builder, balls, the
interior and closure, the two metric spaces every example lives in, and the
inequalities that get rewritten in every proof. The operations that were common
but already cost nothing (native Typst, or a snippet you already had) are in
@sec:native, so the list here stays short.

*All of them are `<Tab>` snippets.* Every trigger is name-shaped, and the rule
in `snippetsGuide.md` holds: no autosnippet shadows something you might mean
literally. They fire only inside math, in `.typ` files and in markdown notes,
except the three marked #box(text(size: 7pt, fill: warm, smallcaps[md])),
which exist only in the notes (see @sec:where).

#block(inset: (y: 4pt))[
  *Reading the tables.* #expands("⟨c⟩") is a tab stop: its text is the default,
  so type over it or `<Tab>` past it; #expands("⟨⟩") is an empty one.
  #expands("«c»") repeats an earlier stop and changes as you type there. The
  Renders column fills empty stops with an example.
]

= The topology of a set

#snippets(
  (trigger("intr", md: true), expands("intr(⟨⟩)"), $intr(A)$, [224]),
  (trigger("cl", md: true), expands("cl(⟨⟩)"), $cl(A)$, [110]),
  (trigger("bdy"), expands("\"Bdy\"(⟨⟩)"), $"Bdy"(A)$, [8]),
)

The most-typed things in the course. All three take a visual selection: select
`A union B`, press `<Tab>` (it disappears), type `cl<Tab>`, and it comes back as
#raw("cl(A union B)"). The complement needs no snippet, `A^c` is three keys.

= Balls

#snippets(
  (trigger("ball"), expands("B(⟨c⟩, ⟨r⟩)"), $B(c, r)$, [122]),
  (trigger("cball"), expands("B[⟨c⟩, ⟨r⟩]"), $B[c, r]$, [22]),
  (trigger("sph"), expands("S(⟨c⟩, ⟨r⟩)"), $S(c, r)$, [13]),
  (trigger("bsub"), expands("B(⟨c⟩, ⟨r⟩) subset.eq ⟨A⟩"), $B(c, r) subset.eq A$, [40]),
  (
    trigger("ipt"),
    expands("exists thin ⟨r⟩ > 0 \"such that\" B(⟨c⟩, «r») subset.eq ⟨A⟩"),
    $exists thin r > 0 "such that" B(c, r) subset.eq A$,
    [8],
  ),
)

`ipt` is the interior-point condition, the one every "is open" proof starts
from. Type the radius once (`epsilon`, `r_1`) and the ball picks it up.

= Sets

#snippets(
  (
    trigger("sb"),
    expands("{ thin ⟨x in M⟩ med bar.v med ⟨⟩ thin }"),
    ${ thin x in M med bar.v med d(x, c) < r thin }$,
    [29],
  ),
  (trigger("bcup"), expands("union.big_(⟨i in I⟩) ⟨A_i⟩"), $union.big_(i in I) A_i$, [23]),
  (trigger("bcap"), expands("inter.big_(⟨i in I⟩) ⟨A_i⟩"), $inter.big_(i in I) A_i$, [13]),
  (trigger("lst"), expands("⟨x⟩_1, dots.h, «x»_⟨n⟩"), $x_1, dots.h, x_n$, [7]),
  (trigger("tup"), expands("(⟨x⟩_1, dots.h, «x»_⟨n⟩)"), $(x_1, dots.h, x_n)$, [7]),
)

`sb` writes the set-builder with the spacing the notes use, the part that
takes twenty keystrokes to type by hand. It is not `set`, which is `#set` in a
`.typ` file; folio's `setb` gives the colon form instead. `bcup` and `bcap`
borrow the LaTeX names. For $union.big_(n = 1)^oo$, type `n = 1` over the
index and add `^oo` after the parenthesis.

= Metrics and inequalities

#snippets(
  (trigger("usual"), expands("(⟨RR⟩, \"usual\")"), $(RR, "usual")$, [37]),
  (trigger("disc"), expands("(⟨M⟩, \"discrete\")"), $(M, "discrete")$, [13]),
  (
    trigger("tri"),
    expands("d(⟨a⟩, ⟨b⟩) <= d(«a», ⟨c⟩) + d(«c», «b»)"),
    $d(a, b) <= d(a, c) + d(c, b)$,
    [8],
  ),
  (
    trigger("ntri"),
    expands("norm(⟨x⟩ + ⟨y⟩) <= norm(«x») + norm(«y»)"),
    $norm(x + y) <= norm(x) + norm(y)$,
    [5],
  ),
  (trigger("ip", md: true), expands("ip(⟨x⟩, ⟨y⟩)"), $ip(x, y)$, [103]),
)

`tri` asks for three points and writes all six slots in the right order, which
is exactly where a hand-typed triangle inequality goes wrong. The same with
`ntri` and two vectors.

= Common, but no snippet needed <sec:native>

Typst or an existing snippet already types these in a few keys. The
ones on the left are what the notes write, some of them the long way.

#table(
  columns: (auto, auto, 1fr),
  align: (left + horizon, right + horizon, left + horizon),
  inset: (x: 5pt, y: 4pt),
  stroke: (_, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.4pt + rule) },
  table.header([*In the notes*], [*Uses*], [*Type instead*]),
  [`bb(R)`, `bb(Q)`, …], [343], [`RR` `QQ` `ZZ` `CC` `NN`: native, and `RR^n` for $RR^n$],
  [`norm(…)`, `abs(…)`], [282], [the names themselves, or the existing `norm`, `abs` snippets],
  [`d(x, y)`], [187], [just type it; `tri` covers the triangle inequality],
  [`A^c`], [164], [just type it],
  [`subset.eq`], [160], [`sub=` (auto) for $subset.eq$, `sup=` for $supset.eq$],
  [`med` `thin` `quad`], [322], [just type them; `sb` writes the set-builder's for you],
  [`"text"`], [202], [`qq` (auto) gives #expands("\"⟨⟩\"")],
  [`nothing`], [81], [`;0` (auto)],
  [`lambda` `epsilon` `tau`], [153], [`;l` `;e` `;u` (auto)],
  [`<=` `==>` `<==>` `:=` `!=` `>=`], [212], [native shorthands, no snippet],
  [`union` `inter`], [77], [native names; `bcup` `bcap` for the indexed ones],
  [`dot.op`], [44], [`dot` alone is $dot$, so `norm(dot)` is $norm(dot)$],
  [`1 slash n`], [27], [#raw("1 \\/ n"): the escaped slash, as L01 already does],
  [`dots.h`, `dots`], [28], [`...` is $...$, a native shorthand],
  [`sqrt`, `underbrace`], [49], [the existing `sqrt` and `ub` snippets],
  [`in.not`], [11], [`!in` (auto)],
  [`(M, d)`], [35], [just type it; `usual` and `disc` cover the two named spaces],
)

= Where they work <sec:where>

- *In a markdown note* every snippet above works, inside `$ … $` or
  `$$ … $$`. `intr`, `cl` and `ip` are macros of the vault's TypstMate
  preamble (`.obsidian/plugins/typst-mate/data.json`), so they live in
  `markdown.lua` and exist only there.
- *In a `.typ` file* everything except the three #box(text(size: 7pt, fill: warm, smallcaps[md]))
  ones. There `ip` is folio's (from `typst.lua`, defaulting to `u, v`); `intr`
  and `cl` need their `#let`s, which `textbook.typ` has at the top.
- *After `:MdMath latex`* none of these fire: the buffer takes `mathmode.lua`'s
  LaTeX snippets instead, and the three preamble ones check the mode.
