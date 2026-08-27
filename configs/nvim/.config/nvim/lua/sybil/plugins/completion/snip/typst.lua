local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local rep = require("luasnip.extras").rep
local fmta = require("luasnip.extras.fmt").fmta
local line_begin = require("luasnip.extras.conditions.expand").line_begin

-- NOTE ON fmta DELIMITERS
-- The default `<>` delimiters clash with Typst labels (`<fig:x>`) and show
-- rules (`it => ..`), so a literal angle bracket has to be doubled: `<<` -> `<`
-- and `>>` -> `>`. Custom delimiters are no help here: `()` collides with math
-- calls and `[]` with content blocks.

-- The Typst grammar wraps `$...$` in a `math` node.  `code` / `string` / `raw`
-- are checked first so that `$ #calc.pi $` and `$ "literal" $` count as text.
-- Limitation: an unterminated `$` parses as ERROR, so math snippets stay
-- inactive until the closing `$` exists (every entry snippet below inserts both).
local function in_mathzone()
    local node = vim.treesitter.get_node({ ignore_injections = false })
    while node do
        local ty = node:type()
        if ty == "code" or ty == "string" or ty == "raw" or ty == "comment" then
            return false
        end
        if ty == "math" then
            return true
        end
        node = node:parent()
    end
    return false
end

local function not_in_mathzone()
    return not in_mathzone()
end

-- Typst already renders `->`, `=>`, `<=`, `>=`, `!=`, `oo`, `RR`, `in`, `subset`
-- natively, and `sum`, `vec`, `hat`, `lim`, `abs`, ... are real function names.
-- Nothing here shadows those as an autosnippet: name-shaped triggers are plain
-- Tab snippets, and the only autosnippets are symbol- or `;`-prefixed.

local function delim_matrix(fn, delim)
    return fmta(
        [[
        <>(delim: "<>",
            <>, <>;
            <>, <>
        )
        ]],
        { t(fn), t(delim), i(1), i(2), i(3), i(4) }
    )
end

local snippets = {
    -- ==========================================================
    -- 1. MATH ZONE ENTRANCE
    -- ==========================================================
    -- `$$` is not valid Typst on its own, so it is safe as an autosnippet.
    -- No math guard: the second `$` completes a `math` node before the snippet
    -- is evaluated, so `not_in_mathzone` would reject its own trigger.
    s({ trig = "$$", snippetType = "autosnippet" }, fmta("$<>$<>", { i(1), i(0) })),
    s({ trig = ";;", snippetType = "autosnippet" }, fmta("$<>$<>", { i(1), i(0) }), { condition = not_in_mathzone }),
    s({ trig = "xx", snippetType = "autosnippet" }, fmta(" times <>", { i(0) }), { condition = in_mathzone }),
    s(
        { trig = "dm", snippetType = "snippet" },
        fmta(
            [[
        $ <> $

        <>
        ]],
            { i(1), i(0) }
        ),
        { condition = not_in_mathzone }
    ),
    -- Numbered display equation with a label to cross-reference via `@eq:..`
    s(
        { trig = "dml", snippetType = "snippet" },
        fmta(
            [[
        $ <> $ <<eq:<>>>

        <>
        ]],
            { i(1), i(2, "name"), i(0) }
        ),
        { condition = not_in_mathzone }
    ),

    -- ==========================================================
    -- 2. MATH: STRUCTURE
    -- ==========================================================
    s({ trig = "//", snippetType = "autosnippet" }, fmta("(<>)/(<>)", { i(1), i(2) }), { condition = in_mathzone }),
    s(
        { trig = "^^", snippetType = "autosnippet", wordTrig = false },
        fmta("^(<>)", { i(1) }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "__", snippetType = "autosnippet", wordTrig = false },
        fmta("_(<>)", { i(1) }),
        { condition = in_mathzone }
    ),
    -- Differential: `dif` is a Typst symbol, `dd` is not, so it can autofire.
    s({ trig = "dd", snippetType = "autosnippet" }, t("dif "), { condition = in_mathzone }),
    -- Literal text inside math is a quoted string.
    s({ trig = "qq", snippetType = "autosnippet" }, fmta('"<>" ', { i(1) }), { condition = in_mathzone }),

    s({ trig = "sqrt", snippetType = "snippet" }, fmta("sqrt(<>)", { i(1) }), { condition = in_mathzone }),
    s(
        { trig = "root", snippetType = "snippet" },
        fmta("root(<>, <>)", { i(1, "3"), i(2) }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "binom", snippetType = "snippet" },
        fmta("binom(<>, <>)", { i(1, "n"), i(2, "k") }),
        { condition = in_mathzone }
    ),
    s({ trig = "abs", snippetType = "snippet" }, fmta("abs(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "norm", snippetType = "snippet" }, fmta("norm(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "floor", snippetType = "snippet" }, fmta("floor(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "ceil", snippetType = "snippet" }, fmta("ceil(<>)", { i(1) }), { condition = in_mathzone }),
    -- Auto-scaling delimiters
    s({ trig = "lr", snippetType = "snippet" }, fmta("lr(( <> ))", { i(1) }), { condition = in_mathzone }),
    s({ trig = "lrb", snippetType = "snippet" }, fmta("lr([ <> ])", { i(1) }), { condition = in_mathzone }),
    s({ trig = "lrc", snippetType = "snippet" }, fmta("lr({ <> })", { i(1) }), { condition = in_mathzone }),

    s(
        { trig = "ub", snippetType = "snippet" },
        fmta("underbrace(<>, <>)", { i(1), i(2) }),
        { condition = in_mathzone }
    ),
    s({ trig = "ob", snippetType = "snippet" }, fmta("overbrace(<>, <>)", { i(1), i(2) }), { condition = in_mathzone }),
    s(
        { trig = "attach", snippetType = "snippet" },
        fmta("attach(<>, t: <>, b: <>)", { i(1), i(2), i(3) }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "op", snippetType = "snippet" },
        fmta('op("<>", limits: <>)', { i(1, "Tr"), i(2, "false") }),
        { condition = in_mathzone }
    ),

    -- ==========================================================
    -- 3. MATH: BIG OPERATORS
    -- ==========================================================
    s(
        { trig = "sum", snippetType = "snippet" },
        fmta("sum_(<>)^(<>) ", { i(1, "n = 1"), i(2, "oo") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "prod", snippetType = "snippet" },
        fmta("product_(<>)^(<>) ", { i(1, "n = 1"), i(2, "oo") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "int", snippetType = "snippet" },
        fmta("integral_(<>)^(<>) <> dif <>", { i(1, "a"), i(2, "b"), i(3), i(4, "x") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "iint", snippetType = "snippet" },
        fmta("integral.double_(<>) <> ", { i(1), i(2) }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "oint", snippetType = "snippet" },
        fmta("integral.cont_(<>) <> ", { i(1), i(2) }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "lim", snippetType = "snippet" },
        fmta("lim_(<> ->> <>) ", { i(1, "n"), i(2, "oo") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "limsup", snippetType = "snippet" },
        fmta("limsup_(<> ->> <>) ", { i(1, "n"), i(2, "oo") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "liminf", snippetType = "snippet" },
        fmta("liminf_(<> ->> <>) ", { i(1, "n"), i(2, "oo") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "part", snippetType = "snippet" },
        fmta("(partial <>)/(partial <>)", { i(1), i(2) }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "der", snippetType = "snippet" },
        fmta("(dif <>)/(dif <>)", { i(1, "y"), i(2, "x") }),
        { condition = in_mathzone }
    ),

    -- ==========================================================
    -- 4. MATH: MATRICES, VECTORS, CASES
    -- ==========================================================
    s(
        { trig = "mat", snippetType = "snippet" },
        fmta(
            [[
        mat(
            <>, <>;
            <>, <>
        )
        ]],
            { i(1), i(2), i(3), i(4) }
        ),
        { condition = in_mathzone }
    ),
    s({ trig = "bmat", snippetType = "snippet" }, delim_matrix("mat", "["), { condition = in_mathzone }),
    s({ trig = "vmat", snippetType = "snippet" }, delim_matrix("mat", "|"), { condition = in_mathzone }),
    s({ trig = "vv", snippetType = "snippet" }, fmta("vec(<>, <>)", { i(1), i(2) }), { condition = in_mathzone }),
    s(
        { trig = "cases", snippetType = "snippet" },
        fmta(
            [[
        cases(
            <> & "if" <>,
            <> & "otherwise",
        )
        ]],
            { i(1), i(2), i(3) }
        ),
        { condition = in_mathzone }
    ),

    -- ==========================================================
    -- 5. MATH: ACCENTS & STYLES
    -- ==========================================================
    -- Tab-only: these are the real Typst function names, so autosnippets here
    -- would hijack someone typing `hat(x)` by hand.
    s({ trig = "hat", snippetType = "snippet" }, fmta("hat(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "bar", snippetType = "snippet" }, fmta("overline(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "vec", snippetType = "snippet" }, fmta("arrow(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "dot", snippetType = "snippet" }, fmta("dot(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "ddot", snippetType = "snippet" }, fmta("dot.double(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "tilde", snippetType = "snippet" }, fmta("tilde(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "bb", snippetType = "snippet" }, fmta("bb(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "cal", snippetType = "snippet" }, fmta("cal(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "frak", snippetType = "snippet" }, fmta("frak(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "bold", snippetType = "snippet" }, fmta("bold(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "up", snippetType = "snippet" }, fmta("upright(<>)", { i(1) }), { condition = in_mathzone }),

    -- ==========================================================
    -- 6. MATH: GREEK (`;` sigil, same convention as mathmode.lua)
    -- ==========================================================
    s({ trig = ";a", snippetType = "autosnippet", wordTrig = false }, t("alpha"), { condition = in_mathzone }),
    s({ trig = ";b", snippetType = "autosnippet", wordTrig = false }, t("beta"), { condition = in_mathzone }),
    s({ trig = ";g", snippetType = "autosnippet", wordTrig = false }, t("gamma"), { condition = in_mathzone }),
    s({ trig = ";G", snippetType = "autosnippet", wordTrig = false }, t("Gamma"), { condition = in_mathzone }),
    s({ trig = ";d", snippetType = "autosnippet", wordTrig = false }, t("delta"), { condition = in_mathzone }),
    s({ trig = ";D", snippetType = "autosnippet", wordTrig = false }, t("Delta"), { condition = in_mathzone }),
    s({ trig = ";e", snippetType = "autosnippet", wordTrig = false }, t("epsilon"), { condition = in_mathzone }),
    s({ trig = ";z", snippetType = "autosnippet", wordTrig = false }, t("zeta"), { condition = in_mathzone }),
    s({ trig = ";h", snippetType = "autosnippet", wordTrig = false }, t("eta"), { condition = in_mathzone }),
    s({ trig = ";t", snippetType = "autosnippet", wordTrig = false }, t("theta"), { condition = in_mathzone }),
    s({ trig = ";T", snippetType = "autosnippet", wordTrig = false }, t("Theta"), { condition = in_mathzone }),
    s({ trig = ";k", snippetType = "autosnippet", wordTrig = false }, t("kappa"), { condition = in_mathzone }),
    s({ trig = ";l", snippetType = "autosnippet", wordTrig = false }, t("lambda"), { condition = in_mathzone }),
    s({ trig = ";L", snippetType = "autosnippet", wordTrig = false }, t("Lambda"), { condition = in_mathzone }),
    s({ trig = ";m", snippetType = "autosnippet", wordTrig = false }, t("mu"), { condition = in_mathzone }),
    s({ trig = ";n", snippetType = "autosnippet", wordTrig = false }, t("nu"), { condition = in_mathzone }),
    s({ trig = ";x", snippetType = "autosnippet", wordTrig = false }, t("xi"), { condition = in_mathzone }),
    s({ trig = ";p", snippetType = "autosnippet", wordTrig = false }, t("pi"), { condition = in_mathzone }),
    s({ trig = ";P", snippetType = "autosnippet", wordTrig = false }, t("Pi"), { condition = in_mathzone }),
    s({ trig = ";r", snippetType = "autosnippet", wordTrig = false }, t("rho"), { condition = in_mathzone }),
    s({ trig = ";s", snippetType = "autosnippet", wordTrig = false }, t("sigma"), { condition = in_mathzone }),
    s({ trig = ";S", snippetType = "autosnippet", wordTrig = false }, t("Sigma"), { condition = in_mathzone }),
    s({ trig = ";u", snippetType = "autosnippet", wordTrig = false }, t("tau"), { condition = in_mathzone }),
    s({ trig = ";f", snippetType = "autosnippet", wordTrig = false }, t("phi"), { condition = in_mathzone }),
    s({ trig = ";F", snippetType = "autosnippet", wordTrig = false }, t("Phi"), { condition = in_mathzone }),
    s({ trig = ";c", snippetType = "autosnippet", wordTrig = false }, t("chi"), { condition = in_mathzone }),
    s({ trig = ";y", snippetType = "autosnippet", wordTrig = false }, t("psi"), { condition = in_mathzone }),
    s({ trig = ";Y", snippetType = "autosnippet", wordTrig = false }, t("Psi"), { condition = in_mathzone }),
    s({ trig = ";o", snippetType = "autosnippet", wordTrig = false }, t("omega"), { condition = in_mathzone }),
    s({ trig = ";O", snippetType = "autosnippet", wordTrig = false }, t("Omega"), { condition = in_mathzone }),
    s({ trig = ";N", snippetType = "autosnippet", wordTrig = false }, t("nabla"), { condition = in_mathzone }),
    s({ trig = ";8", snippetType = "autosnippet", wordTrig = false }, t("oo"), { condition = in_mathzone }),

    -- ==========================================================
    -- 7. MARKUP: HEADINGS & EMPHASIS
    -- ==========================================================
    s({ trig = "h1", snippetType = "snippet" }, fmta("= <>", { i(1) }), { condition = line_begin }),
    s({ trig = "h2", snippetType = "snippet" }, fmta("== <>", { i(1) }), { condition = line_begin }),
    s({ trig = "h3", snippetType = "snippet" }, fmta("=== <>", { i(1) }), { condition = line_begin }),
    s({ trig = "h4", snippetType = "snippet" }, fmta("==== <>", { i(1) }), { condition = line_begin }),

    s({ trig = "bf", snippetType = "snippet" }, fmta("*<>*", { i(1) }), { condition = not_in_mathzone }),
    s({ trig = "em", snippetType = "snippet" }, fmta("_<>_", { i(1) }), { condition = not_in_mathzone }),
    s({ trig = "rawi", snippetType = "snippet" }, fmta("`<>`", { i(1) }), { condition = not_in_mathzone }),

    -- ==========================================================
    -- 8. MARKUP: BLOCKS
    -- ==========================================================
    s(
        { trig = "code", snippetType = "snippet" },
        fmta(
            [[
        ```<>
        <>
        ```
        ]],
            { i(1, "rust"), i(2) }
        ),
        { condition = not_in_mathzone }
    ),
    s(
        { trig = "fig", snippetType = "snippet" },
        fmta(
            [[
        #figure(
            image("<>", width: <>),
            caption: [<>],
        ) <<fig:<>>>
        ]],
            { i(1, "images/.png"), i(2, "80%"), i(3), i(4, "name") }
        ),
        { condition = not_in_mathzone }
    ),
    s(
        { trig = "figc", snippetType = "snippet" },
        fmta(
            [[
        #figure(
            <>,
            caption: [<>],
        ) <<fig:<>>>
        ]],
            { i(1), i(2), i(3, "name") }
        ),
        { condition = not_in_mathzone }
    ),
    s(
        { trig = "table", snippetType = "snippet" },
        fmta(
            [[
        #table(
            columns: <>,
            align: <>,
            table.header(<>),
            <>
        )
        ]],
            { i(1, "(auto, auto)"), i(2, "left"), i(3), i(4) }
        ),
        { condition = not_in_mathzone }
    ),
    s(
        { trig = "grid", snippetType = "snippet" },
        fmta(
            [[
        #grid(
            columns: <>,
            gutter: <>,
            <>
        )
        ]],
            { i(1, "(1fr, 1fr)"), i(2, "1em"), i(3) }
        ),
        { condition = not_in_mathzone }
    ),
    s(
        { trig = "quote", snippetType = "snippet" },
        fmta("#quote(block: true, attribution: [<>])[<>]", { i(1), i(2) }),
        { condition = not_in_mathzone }
    ),

    -- ==========================================================
    -- 9. MARKUP: INLINE CALLS & REFERENCES
    -- ==========================================================
    s(
        { trig = "img", snippetType = "snippet" },
        fmta('#image("<>", width: <>)', { i(1), i(2, "80%") }),
        { condition = not_in_mathzone }
    ),
    s(
        { trig = "link", snippetType = "snippet" },
        fmta('#link("<>")[<>]', { i(1), i(2) }),
        { condition = not_in_mathzone }
    ),
    s({ trig = "fn", snippetType = "snippet" }, fmta("#footnote[<>]", { i(1) }), { condition = not_in_mathzone }),
    s({ trig = "cite", snippetType = "snippet" }, fmta("@<>", { i(1, "key") }), { condition = not_in_mathzone }),
    s(
        { trig = "ref", snippetType = "snippet" },
        fmta("@<><>", { i(1, "fig"), i(2, ":name") }),
        { condition = not_in_mathzone }
    ),
    s({ trig = "lbl", snippetType = "snippet" }, fmta("<<<>>>", { i(1, "name") }), { condition = not_in_mathzone }),
    s(
        { trig = "align", snippetType = "snippet" },
        fmta("#align(<>)[<>]", { i(1, "center"), i(2) }),
        { condition = not_in_mathzone }
    ),
    s({ trig = "box", snippetType = "snippet" }, fmta("#box(<>)[<>]", { i(1), i(2) }), { condition = not_in_mathzone }),
    s(
        { trig = "block", snippetType = "snippet" },
        fmta("#block(<>)[<>]", { i(1), i(2) }),
        { condition = not_in_mathzone }
    ),
    s({ trig = "pb", snippetType = "snippet" }, t("#pagebreak()"), { condition = not_in_mathzone }),
    s({ trig = "lb", snippetType = "snippet" }, t("#linebreak()"), { condition = not_in_mathzone }),
    s({ trig = "vsp", snippetType = "snippet" }, fmta("#v(<>)", { i(1, "1em") }), { condition = not_in_mathzone }),
    s({ trig = "hsp", snippetType = "snippet" }, fmta("#h(<>)", { i(1, "1em") }), { condition = not_in_mathzone }),
    s({ trig = "lorem", snippetType = "snippet" }, fmta("#lorem(<>)", { i(1, "50") }), { condition = not_in_mathzone }),
    s(
        { trig = "outline", snippetType = "snippet" },
        fmta("#outline(title: [<>], depth: <>)", { i(1, "Contents"), i(2, "3") }),
        { condition = not_in_mathzone }
    ),
    s(
        { trig = "bib", snippetType = "snippet" },
        fmta('#bibliography("<>", style: "<>")', { i(1, "refs.bib"), i(2, "ieee") }),
        { condition = not_in_mathzone }
    ),

    -- ==========================================================
    -- 10. SCRIPTING: LET / SET / SHOW / IMPORT
    -- ==========================================================
    s({ trig = "let", snippetType = "snippet" }, fmta("#let <> = <>", { i(1, "name"), i(2) })),
    s(
        { trig = "fun", snippetType = "snippet" },
        fmta(
            [[
        #let <>(<>) = {
            <>
        }
        ]],
            { i(1, "name"), i(2, "body"), i(3) }
        )
    ),
    s({ trig = "set", snippetType = "snippet" }, fmta("#set <>(<>)", { i(1), i(2) })),
    s({ trig = "show", snippetType = "snippet" }, fmta("#show <>: <>", { i(1), i(2) })),
    -- `=>` needs its `>` doubled for fmta.
    s({ trig = "showit", snippetType = "snippet" }, fmta("#show <>: it =>> [<>]", { i(1, "heading"), i(2) })),
    s({ trig = "imp", snippetType = "snippet" }, fmta('#import "<>": <>', { i(1), i(2, "*") })),
    s({ trig = "inc", snippetType = "snippet" }, fmta('#include "<>"', { i(1) })),
    s(
        { trig = "if", snippetType = "snippet" },
        fmta(
            [[
        #if <> {
            <>
        }
        ]],
            { i(1), i(2) }
        )
    ),
    s(
        { trig = "for", snippetType = "snippet" },
        fmta(
            [[
        #for <> in <> {
            <>
        }
        ]],
            { i(1, "item"), i(2, "list"), i(3) }
        )
    ),

    -- ==========================================================
    -- 11. DOCUMENT PREAMBLE
    -- ==========================================================
    s(
        { trig = "preamble", snippetType = "snippet" },
        fmta(
            [[
        #set document(title: "<>", author: "<>")
        #set page(paper: "a4", margin: (x: 2.5cm, y: 2.5cm), numbering: "1")
        #set text(font: "<>", size: 11pt, lang: "en")
        #set par(justify: true, leading: 0.65em)
        #set heading(numbering: "1.1")
        #set math.equation(numbering: "(1)")

        #align(center)[
            #text(17pt)[*<>*] \
            <>
        ]

        <>
        ]],
            { i(1, "Title"), i(2, "Author"), i(3, "New Computer Modern"), rep(1), rep(2), i(0) }
        ),
        { condition = line_begin }
    ),

    -- ==========================================================
    -- 12. TEMPLATE SCAFFOLDING (template.typ)
    -- ==========================================================
    -- These assume `#import "template.typ": *` -- see snippetsGuide.md.
    s(
        { trig = "tmpl", snippetType = "snippet" },
        fmta(
            [[
        #import "template.typ": *

        #show: notes.with(
            title: "<>",
            course: "<>",
            author: "<>",
            date: "<>",
        )

        <>
        ]],
            { i(1, "Topic"), i(2, "MATH 302"), i(3), i(4), i(0) }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = "hw", snippetType = "snippet" },
        fmta(
            [[
        #import "template.typ": *

        #show: homework.with(
            title: "<>",
            course: "<>",
            author: "<>",
            date: "<>",
        )

        <>
        ]],
            { i(1, "MATH 302: Homework 1"), i(2, "MATH 302"), i(3), i(4), i(0) }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = "prob", snippetType = "snippet" },
        fmta(
            [[
        #problem(<>, title: "<>")[
            <>
        ]
        ]],
            { i(1, "1"), i(2), i(3) }
        ),
        { condition = not_in_mathzone }
    ),

    -- Template math helpers (all usable directly inside `$ .. $`)
    s(
        { trig = "ip", snippetType = "snippet" },
        fmta("ip(<>, <>)", { i(1, "u"), i(2, "v") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "setb", snippetType = "snippet" },
        fmta("setb(<>, <>)", { i(1, "x in RR"), i(2, "x > 0") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "dv", snippetType = "snippet" },
        fmta("dv(<>, <>)", { i(1, "y"), i(2, "x") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "pdv", snippetType = "snippet" },
        fmta("pdv(<>, <>)", { i(1, "f"), i(2, "x") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "restr", snippetType = "snippet" },
        fmta("restr(<>, <>)", { i(1, "f"), i(2, "A") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "evalat", snippetType = "snippet" },
        fmta("evalat(<>, <>, <>)", { i(1, "F(x)"), i(2, "a"), i(3, "b") }),
        { condition = in_mathzone }
    ),
}

-- ==========================================================
-- 12b. THEOREM-LIKE ENVIRONMENTS (generated)
-- ==========================================================
-- Each name gets two Tab snippets: the bare trigger, and the trigger + "t"
-- for the `title:` variant.  Tab-only and gated out of math, so none of them
-- can ambush ordinary prose.
local environments = {
    { "def", "definition" },
    { "thm", "theorem" },
    { "lem", "lemma" },
    { "cor", "corollary" },
    { "prop", "proposition" },
    { "claim", "claim" },
    { "conj", "conjecture" },
    { "axm", "axiom" },
    { "qst", "question" },
    { "exr", "exercise" },
    { "sol", "solution" },
    { "ex", "example" },
    { "rmk", "remark" },
    { "obs", "observation" },
    { "nota", "notation" },
    { "warn", "warning" },
    { "case", "case" },
    { "prf", "proof" },
}

for _, env in ipairs(environments) do
    local trig, name = env[1], env[2]
    table.insert(
        snippets,
        s(
            { trig = trig, snippetType = "snippet" },
            fmta("#" .. name .. "[\n    <>\n]", { i(1) }),
            { condition = not_in_mathzone }
        )
    )
    table.insert(
        snippets,
        s(
            { trig = trig .. "t", snippetType = "snippet" },
            fmta("#" .. name .. '(title: "<>")[\n    <>\n]', { i(1), i(2) }),
            { condition = not_in_mathzone }
        )
    )
end

return snippets
