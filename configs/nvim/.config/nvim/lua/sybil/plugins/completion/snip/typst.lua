local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local rep = require("luasnip.extras").rep
local fmta = require("luasnip.extras.fmt").fmta
local make_condition = require("luasnip.extras.conditions").make_condition
local line_begin = require("luasnip.extras.conditions.expand").line_begin

-- NOTE ON fmta DELIMITERS
-- The default `<>` delimiters clash with Typst labels (`<fig:x>`) and show
-- rules (`it => ..`), so a literal angle bracket has to be doubled: `<<` -> `<`
-- and `>>` -> `>`. Custom delimiters are no help here: `()` collides with math
-- calls and `[]` with content blocks.

-- The general math snippets live in typstmath.lua, which is shared with the
-- `markdown` filetype; only the `.typ`-specific ones are here.  What stays: the
-- math zone entrance (markdown uses different delimiters) and the folio math
-- helpers in section 5, which need `#import "@local/folio:0.1.0": *`.

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

-- Which kind of Typst the cursor is in: "math", "markup", "code", or
-- "literal" -- raw text, a string, a comment, or another language injected
-- into a raw block, where `;;` and `$$` are only characters.
--
-- It reads the character *before* the cursor: at the end of a line the cursor
-- sits past the last node, so `// note ;;|` would otherwise look like plain
-- markup.  Memoised per keystroke, because the `show_condition` of every
-- `#call` snippet below asks on each completion request.
local memo = {}
local function context()
    local buf = vim.api.nvim_get_current_buf()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local tick = vim.api.nvim_buf_get_changedtick(buf)
    if memo.buf == buf and memo.tick == tick and memo.row == row and memo.col == col then
        return memo.kind
    end
    local kind = "markup"
    local pos = { row - 1, math.max(col - 1, 0) }
    local parser = vim.treesitter.get_parser(buf, nil, { error = false })
    if parser and parser:language_for_range({ pos[1], pos[2], pos[1], pos[2] }):lang() ~= "typst" then
        kind = "literal"
    else
        local node = vim.treesitter.get_node({ bufnr = buf, pos = pos, ignore_injections = false })
        while node do
            local ty = node:type()
            if ty == "raw_span" or ty == "raw_blck" or ty == "string" or ty == "comment" then
                kind = "literal"
                break
            elseif ty == "math" then
                kind = "math"
                break
            elseif ty == "content" then -- `[ .. ]` is markup, even as a call's argument
                kind = "markup"
                break
            elseif ty == "code" or ty == "block" then -- `#expr`, or a `{ .. }` block
                kind = "code"
                break
            end
            node = node:parent()
        end
    end
    memo = { buf = buf, tick = tick, row = row, col = col, kind = kind }
    return kind
end

local markup = make_condition(function()
    return context() == "markup"
end)
local code = make_condition(function()
    return context() == "code"
end)
local not_literal = make_condition(function()
    return context() ~= "literal"
end)

-- A `#name(..)` call, as two snippets on one trigger: `#name(..)` in markup,
-- and a bare `name(..)` in code -- inside a `{ .. }` block, or straight after
-- a `#` you already typed, so `#thm<Tab>` still gives a single `#`.
-- `body` is the fmta string without the `#`; `nodes` builds the node list,
-- because one node cannot belong to two snippets.  The `show_condition`s keep
-- the completion menu to the variant that applies.
local function call(trig, body, nodes)
    return {
        s(
            { trig = trig, snippetType = "snippet" },
            fmta(body:gsub("^(%s*)", "%1#", 1), nodes()),
            { condition = markup, show_condition = markup }
        ),
        s({ trig = trig, snippetType = "snippet" }, fmta(body, nodes()), { condition = code, show_condition = code }),
    }
end

-- A box's body: whatever was cut with <Tab> in visual mode (see
-- `store_selection_keys` in ../luasnip.lua), re-indented under the opening
-- line, or an empty placeholder when nothing was.
local function body(k)
    return d(k, function(_, parent)
        local sel = parent.snippet.env.LS_SELECT_DEDENT
        if type(sel) ~= "table" or #sel == 0 or (#sel == 1 and sel[1] == "") then
            return sn(nil, i(1))
        end
        return isn(nil, i(1, sel), "$PARENT_INDENT    ")
    end)
end

-- The same for inline markup: the cut text as it was, or an empty placeholder.
local function inline(k)
    return d(k, function(_, parent)
        local sel = parent.snippet.env.LS_SELECT_RAW
        if type(sel) ~= "table" or #sel == 0 then
            return sn(nil, i(1))
        end
        return sn(nil, i(1, sel))
    end)
end

-- A title as a label: "Real Number System" -> "real-number-system", the way
-- the notes' labels (and the Markdown block ids they mirror) are written.
local function slug(title)
    return (title:lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", ""))
end

-- A label that follows the title (insert node `title`) as it is typed; <Tab>
-- into it to change it.
local function label_from(k, title)
    return d(k, function(args)
        return sn(nil, i(1, slug(args[1][1] or "")))
    end, { title })
end

-- Header defaults, read off the file's path when the snippet expands:
-- .../MATH-475/Homework/05/05.typ gives the course "MATH 475" and homework 5.
-- Whatever the path does not say falls back to a placeholder.
local function course_of(path)
    local dept, num = path:match("(%u%u+)[-_ ](%d%d%d)%f[^%w]")
    return dept and (dept .. " " .. num) or nil
end

local function homework_of(path)
    return path:match("[Hh]omework/0*(%d+)") or path:match("[Hh][Ww]0*(%d+)")
end

-- "September 28, 2026", the form the existing homework headers use.
local function today()
    return os.date("%B ") .. tonumber(os.date("%d")) .. os.date(", %Y")
end

-- A placeholder whose default text is worked out when the snippet expands.
local function computed(k, fn)
    return d(k, function(_, parent)
        return sn(nil, i(1, fn(parent.snippet.env.TM_FILEPATH or "")))
    end)
end

local function course_default(path)
    return course_of(path) or "MATH 302"
end

local function homework_title(path)
    local course, n = course_of(path), homework_of(path)
    return (course or "MATH 302") .. ": Homework " .. (n or "1")
end

-- Typst already renders `->`, `=>`, `<=`, `>=`, `!=`, `oo`, `RR`, `in`, `subset`
-- natively, and `sum`, `vec`, `hat`, `lim`, `abs`, ... are real function names.
-- Nothing here shadows those as an autosnippet: name-shaped triggers are plain
-- Tab snippets, and the only autosnippets are `$$`, `;;`, and `contra` (which
-- names nothing in Typst) inside math.

local snippets = {
    -- ==========================================================
    -- 1. MATH ZONE ENTRANCE
    -- ==========================================================
    -- `$$` is not valid Typst on its own, so it is safe as an autosnippet.
    -- No math guard: the second `$` completes a `math` node before the snippet
    -- is evaluated, so a not-in-math guard would reject its own trigger.  It does
    -- stay out of raw text, strings and comments, where `$$` is just two
    -- dollar signs (a PID in a shell block).
    s({ trig = "$$", snippetType = "autosnippet" }, fmta("$<>$<>", { i(1), i(0) }), { condition = not_literal }),
    -- Markup only: in a raw block `for (;;)` has to stay `for (;;)`.
    s({ trig = ";;", snippetType = "autosnippet" }, fmta("$<>$<>", { i(1), i(0) }), { condition = markup }),
    s(
        { trig = "dm", snippetType = "snippet" },
        fmta(
            [[
        $ <> $

        <>
        ]],
            { i(1), i(0) }
        ),
        { condition = markup }
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
        { condition = markup }
    ),
    -- Aligned display: `&` marks the column, `\` ends the line.
    s(
        { trig = "dma", snippetType = "snippet" },
        fmta(
            [[
        $
            <> &= <> \
            &= <>
        $

        <>
        ]],
            { i(1), i(2), i(3), i(0) }
        ),
        { condition = markup }
    ),

    -- ==========================================================
    -- 2. MARKUP: HEADINGS & EMPHASIS
    -- ==========================================================
    s({ trig = "h1", snippetType = "snippet" }, fmta("= <>", { i(1) }), { condition = line_begin * markup }),
    s({ trig = "h2", snippetType = "snippet" }, fmta("== <>", { i(1) }), { condition = line_begin * markup }),
    s({ trig = "h3", snippetType = "snippet" }, fmta("=== <>", { i(1) }), { condition = line_begin * markup }),
    s({ trig = "h4", snippetType = "snippet" }, fmta("==== <>", { i(1) }), { condition = line_begin * markup }),

    s({ trig = "bf", snippetType = "snippet" }, fmta("*<>*", { inline(1) }), { condition = markup }),
    s({ trig = "em", snippetType = "snippet" }, fmta("_<>_", { inline(1) }), { condition = markup }),
    s({ trig = "rawi", snippetType = "snippet" }, fmta("`<>`", { inline(1) }), { condition = markup }),

    -- ==========================================================
    -- 3. MARKUP: RAW BLOCKS & REFERENCES
    -- ==========================================================
    s(
        { trig = "code", snippetType = "snippet" },
        fmta(
            [[
        ```<>
        <>
        ```
        ]],
            { i(1, "python"), i(2) }
        ),
        { condition = markup }
    ),
    -- The `#call` snippets that used to sit here (fig, img, link, fn, ...) are
    -- in section 6, generated for markup and code alike.
    s({ trig = "cite", snippetType = "snippet" }, fmta("@<>", { i(1, "key") }), { condition = markup }),
    s({ trig = "ref", snippetType = "snippet" }, fmta("@<><>", { i(1, "fig"), i(2, ":name") }), { condition = markup }),
    s({ trig = "lbl", snippetType = "snippet" }, fmta("<<<>>>", { i(1, "name") }), { condition = markup }),

    -- ==========================================================
    -- 4. DOCUMENT PREAMBLE
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
        { condition = line_begin * markup }
    ),

    -- ==========================================================
    -- 5. FOLIO SCAFFOLDING (@local/folio)
    -- ==========================================================
    -- One snippet per folio shell.  The course and the homework number come
    -- from the path (.../MATH-475/Homework/05/05.typ), the date is today's;
    -- all of them are placeholders to overwrite.  See snippetsGuide.md.
    s(
        { trig = "tmpl", snippetType = "snippet" },
        fmta(
            [[
        #import "@local/folio:0.1.0": *

        #show: notes.with(
            title: "<>",
            course: "<>",
            author: "<>",
            date: "<>",
        )

        <>
        ]],
            { i(1, "Topic"), computed(2, course_default), i(3, "Aren Vista"), computed(4, today), i(0) }
        ),
        { condition = line_begin * markup }
    ),
    -- `count-h1` numbers `= Question` headings as "Question 1", "Question 2", ..
    -- which is what `qsol` below writes.
    s(
        { trig = "hw", snippetType = "snippet" },
        fmta(
            [[
        #import "@local/folio:0.1.0": *

        #show: homework.with(
            title: "<>",
            course: "<>",
            author: "<>",
            date: "<>",
            count-h1: true,
        )

        <>
        ]],
            { computed(1, homework_title), computed(2, course_default), i(3, "Aren Vista"), computed(4, today), i(0) }
        ),
        { condition = line_begin * markup }
    ),
    s(
        { trig = "paper", snippetType = "snippet" },
        fmta(
            [[
        #import "@local/folio:0.1.0": *

        #show: paper.with(
            title: "<>",
            author: "<>",
            date: "<>",
            abstract: [<>],
        )

        <>
        ]],
            { i(1, "Title"), i(2, "Aren Vista"), computed(3, today), i(4), i(0) }
        ),
        { condition = line_begin * markup }
    ),
    s(
        { trig = "book", snippetType = "snippet" },
        fmta(
            [[
        #import "@local/folio:0.1.0": *

        #show: book.with(
            title: "<>",
            course: "<>",
            author: "<>",
            date: "<>",
        )

        <>
        ]],
            { i(1, "Title"), computed(2, course_default), i(3, "Aren Vista"), computed(4, today), i(0) }
        ),
        { condition = line_begin * markup }
    ),
    -- One homework question: the prompt, then the answer.
    s(
        { trig = "qsol", snippetType = "snippet" },
        fmta(
            [[
        = Question
        #question[
            <>
        ]

        #solution[
            <>
        ]

        <>
        ]],
            { body(1), i(2), i(0) }
        ),
        { condition = line_begin * markup }
    ),

    -- folio math helpers (all usable directly inside `$ .. $`)
    s(
        { trig = "ip", snippetType = "snippet" },
        fmta("ip(<>, <>)", { i(1, "u"), i(2, "v") }),
        { condition = in_mathzone }
    ),

    s({ trig = "=set", snippetType = "autosnippet" }, fmta("subset.eq <>", { i(1) }), { condition = in_mathzone }),

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
    -- Contradiction mark, as markdown.lua has it.
    s({ trig = "contra", snippetType = "autosnippet" }, t("arrow.zigzag"), { condition = in_mathzone }),
}

local function add(list)
    vim.list_extend(snippets, list)
end

-- ==========================================================
-- 6. CALLS: FIGURES, INLINE CALLS, SCRIPTING (generated)
-- ==========================================================
-- Each of these is a `#call` in markup and a bare call in code; see `call`
-- above.  Bodies are written without the `#`.
add(call(
    "fig",
    [[
    figure(
        image("<>", width: <>),
        caption: [<>],
    ) <<fig:<>>>
    ]],
    function()
        return { i(1, "images/.png"), i(2, "80%"), i(3), i(4, "name") }
    end
))
add(call(
    "figc",
    [[
    figure(
        <>,
        caption: [<>],
    ) <<fig:<>>>
    ]],
    function()
        return { i(1), i(2), i(3, "name") }
    end
))
add(call(
    "table",
    [[
    table(
        columns: <>,
        align: <>,
        table.header(<>),
        <>
    )
    ]],
    function()
        return { i(1, "(auto, auto)"), i(2, "left"), i(3), i(4) }
    end
))
add(call(
    "grid",
    [[
    grid(
        columns: <>,
        gutter: <>,
        <>
    )
    ]],
    function()
        return { i(1, "(1fr, 1fr)"), i(2, "1em"), i(3) }
    end
))
add(call("quote", "quote(block: true, attribution: [<>])[<>]", function()
    return { i(1), body(2) }
end))

add(call("img", 'image("<>", width: <>)', function()
    return { i(1), i(2, "80%") }
end))
add(call("link", 'link("<>")[<>]', function()
    return { i(1), inline(2) }
end))
-- A cross-reference to a labelled box (see `thml` below).  folio's boxes
-- cannot be `@`-referenced ("cannot reference sequence"), so the notes link
-- to the label instead: #link(<def-metric>)[metric space].
add(call("lref", "link(<<<>>>)[<>]", function()
    return { i(1), inline(2) }
end))
add(call("fn", "footnote[<>]", function()
    return { inline(1) }
end))
add(call("align", "align(<>)[<>]", function()
    return { i(1, "center"), body(2) }
end))
add(call("box", "box(<>)[<>]", function()
    return { i(1), inline(2) }
end))
add(call("block", "block(<>)[<>]", function()
    return { i(1), body(2) }
end))
add(call("pb", "pagebreak()", function()
    return {}
end))
add(call("lb", "linebreak()", function()
    return {}
end))
add(call("vsp", "v(<>)", function()
    return { i(1, "1em") }
end))
add(call("hsp", "h(<>)", function()
    return { i(1, "1em") }
end))
add(call("lorem", "lorem(<>)", function()
    return { i(1, "50") }
end))
add(call("outline", "outline(title: [<>], depth: <>)", function()
    return { i(1, "Contents"), i(2, "3") }
end))
add(call("bib", 'bibliography("<>", style: "<>")', function()
    return { i(1, "refs.bib"), i(2, "ieee") }
end))

-- Scripting.  In markup these carry the `#`; inside `{ .. }` they must not.
add(call("let", "let <> = <>", function()
    return { i(1, "name"), i(2) }
end))
add(call(
    "fun",
    [[
    let <>(<>) = {
        <>
    }
    ]],
    function()
        return { i(1, "name"), i(2, "body"), i(3) }
    end
))
add(call("set", "set <>(<>)", function()
    return { i(1), i(2) }
end))
add(call("show", "show <>: <>", function()
    return { i(1), i(2) }
end))
-- `=>` needs its `>` doubled for fmta.
add(call("showit", "show <>: it =>> [<>]", function()
    return { i(1, "heading"), i(2) }
end))
add(call("imp", 'import "<>": <>', function()
    return { i(1), i(2, "*") }
end))
add(call("inc", 'include "<>"', function()
    return { i(1) }
end))
add(call(
    "if",
    [[
    if <> {
        <>
    }
    ]],
    function()
        return { i(1), i(2) }
    end
))
add(call(
    "for",
    [[
    for <> in <> {
        <>
    }
    ]],
    function()
        return { i(1, "item"), i(2, "list"), i(3) }
    end
))

-- folio's `#problem(n, title:)[..]`: an unnumbered level-1 heading.
add(call(
    "prob",
    [[
    problem(<>, title: "<>")[
        <>
    ]
    ]],
    function()
        return { i(1, "1"), i(2), body(3) }
    end
))

-- ==========================================================
-- 7. FOLIO ENVIRONMENTS (generated)
-- ==========================================================
-- Each environment gets three triggers, all Tab-only and gated to markup
-- (with the bare-call variant in code, like every `#call` above):
--
--   thm   #theorem[ .. ]
--   thmt  #theorem(title: "..")[ .. ]
--   thml  #theorem(title: "..")[ .. ] <thm-..>   label follows the title
--
-- The third column is the label prefix, the same one the Markdown notes use
-- for their block ids (`^thm-..`), so a label here and a block id there name
-- the same result.  With text cut by <Tab> in visual mode, it becomes the body.
local environments = {
    { "def", "definition", "def" },
    { "thm", "theorem", "thm" },
    { "lem", "lemma", "lem" },
    { "cor", "corollary", "cor" },
    { "prop", "proposition", "prop" },
    { "claim", "claim", "claim" },
    { "conj", "conjecture", "conj" },
    { "axm", "axiom", "ax" },
    { "qst", "question", "q" },
    { "exr", "exercise", "exer" },
    { "sol", "solution", "soln" },
    { "ex", "example", "ex" },
    { "rmk", "remark", "rem" },
    { "obs", "observation", "obs" },
    { "nota", "notation", "notn" },
    { "warn", "warning", "warn" },
    { "case", "case", "case" },
    { "prf", "proof", "pf" },
    { "form", "formula", "form" },
    { "key", "key", "key" },
    { "hum", "intuition", "hum" },
    { "aside", "aside", "aside" },
    -- Not `imp`: that one is `#import` (section 6).
    { "impo", "important", "imp" },
}

for _, env in ipairs(environments) do
    local trig, name, prefix = env[1], env[2], env[3]
    add(call(trig, name .. "[\n    <>\n]", function()
        return { body(1) }
    end))
    add(call(trig .. "t", name .. '(title: "<>")[\n    <>\n]', function()
        return { i(1), body(2) }
    end))
    add(call(trig .. "l", name .. '(title: "<>")[\n    <>\n] <<' .. prefix .. "-<>>>", function()
        return { i(1), body(2), label_from(3, 1) }
    end))
end

-- folio's label-only boxes take a body and nothing else.
for _, box in ipairs({ { "pit", "pitfall" }, { "idea", "idea" }, { "recall", "recall" } }) do
    add(call(box[1], box[2] .. "[\n    <>\n]", function()
        return { body(1) }
    end))
end

return snippets
