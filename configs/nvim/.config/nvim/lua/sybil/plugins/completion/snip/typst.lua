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

-- The general math snippets live in typstmath.lua, which is shared with the
-- `markdown` filetype; only the `.typ`-specific ones are here.  What stays: the
-- math zone entrance (markdown uses different delimiters) and the template math
-- helpers in section 7, which need `#import "template.typ"`.

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

local snippets = {
    -- ==========================================================
    -- 1. MATH ZONE ENTRANCE
    -- ==========================================================
    -- `$$` is not valid Typst on its own, so it is safe as an autosnippet.
    -- No math guard: the second `$` completes a `math` node before the snippet
    -- is evaluated, so `not_in_mathzone` would reject its own trigger.
    s({ trig = "$$", snippetType = "autosnippet" }, fmta("$<>$<>", { i(1), i(0) })),
    s({ trig = ";;", snippetType = "autosnippet" }, fmta("$<>$<>", { i(1), i(0) }), { condition = not_in_mathzone }),
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
    -- 2. MARKUP: HEADINGS & EMPHASIS
    -- ==========================================================
    s({ trig = "h1", snippetType = "snippet" }, fmta("= <>", { i(1) }), { condition = line_begin }),
    s({ trig = "h2", snippetType = "snippet" }, fmta("== <>", { i(1) }), { condition = line_begin }),
    s({ trig = "h3", snippetType = "snippet" }, fmta("=== <>", { i(1) }), { condition = line_begin }),
    s({ trig = "h4", snippetType = "snippet" }, fmta("==== <>", { i(1) }), { condition = line_begin }),

    s({ trig = "bf", snippetType = "snippet" }, fmta("*<>*", { i(1) }), { condition = not_in_mathzone }),
    s({ trig = "em", snippetType = "snippet" }, fmta("_<>_", { i(1) }), { condition = not_in_mathzone }),
    s({ trig = "rawi", snippetType = "snippet" }, fmta("`<>`", { i(1) }), { condition = not_in_mathzone }),

    -- ==========================================================
    -- 3. MARKUP: BLOCKS
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
    -- 4. MARKUP: INLINE CALLS & REFERENCES
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
    -- 5. SCRIPTING: LET / SET / SHOW / IMPORT
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
    -- 6. DOCUMENT PREAMBLE
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
    -- 7. TEMPLATE SCAFFOLDING (template.typ)
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
-- 7b. THEOREM-LIKE ENVIRONMENTS (generated)
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
