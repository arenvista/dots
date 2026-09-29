local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local f = ls.function_node
local i = ls.insert_node
local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local make_condition = require("luasnip.extras.conditions").make_condition
local line_begin = require("luasnip.extras.conditions.expand").line_begin
local mdmath = require("sybil.core.mdmath")

-- Math in markdown is written in Typst by default, not LaTeX.  The `$ .. $`
-- spans are injected into the Typst parser by
-- queries/markdown_inline/injections.scm, so the bulk of the math snippets live
-- in typstmath.lua and are shared with the `typst` filetype; only the
-- delimiters below are markdown-specific.
--
-- `:MdMath latex` flips a single buffer back to LaTeX -- the injection *and*
-- the snippet set, see lua/sybil/core/mdmath.lua.  Everything in this file has
-- to work in both modes, so the guard below knows both sets of node types and
-- the handful of snippets whose body differs pick it at expansion time.
--
-- Display math keeps markdown's own `$$ .. $$`.  Typst itself has no `$$` --
-- there display math is a single `$` with surrounding whitespace -- so the
-- injection query trims one `$` off each end before handing the block over.
-- That conversion is markdown-only; `.typ` files still use the single-`$` form
-- from typst.lua.  A single `$` on its own lines works here too, but `$$` is
-- what the rest of the markdown world reads.

local function in_mathzone()
    local node = vim.treesitter.get_node({ ignore_injections = false })
    while node do
        local ty = node:type()
        -- Typst: `#code`, strings and raw blocks are not math.
        -- LaTeX: `text_mode` (`\text{..}`) overrides an enclosing formula.
        if ty == "code" or ty == "string" or ty == "raw" or ty == "comment" or ty == "text_mode" then
            return false
        end
        -- `math` is the Typst node; the rest are the LaTeX ones.
        if
            ty == "math"
            or ty == "inline_formula"
            or ty == "displayed_equation"
            or ty == "math_environment"
        then
            return true
        end
        node = node:parent()
    end
    return false
end

-- Typst math only: the snippets for the vault's TypstMate preamble would be
-- nonsense in a buffer switched to LaTeX.
local function in_typst_math()
    return mdmath.get(0) ~= "latex" and in_mathzone()
end

--- Text that differs between the two modes, chosen when the snippet expands.
local function by_mode(typst, latex)
    return f(function()
        return mdmath.get(0) == "latex" and latex or typst
    end)
end

-- Plain markdown text: not math, and not code, html or front matter either,
-- where `;;` and `dm` are only characters (`for (;;)` in a C block).
-- Injections give most of that away -- math is typst or latex, a fenced block
-- with an info string is its own language, front matter is yaml -- and the rest
-- is read off the markdown trees.  It looks at the character *before* the
-- cursor, since at the end of a line the cursor sits past every node.
local function in_prose()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local pos = { row - 1, math.max(col - 1, 0) }
    local parser = vim.treesitter.get_parser(0, nil, { error = false })
    if not parser then
        return true
    end
    local lang = parser:language_for_range({ pos[1], pos[2], pos[1], pos[2] }):lang()
    if lang ~= "markdown" and lang ~= "markdown_inline" then
        return false
    end
    local node = vim.treesitter.get_node({ pos = pos, ignore_injections = false })
    while node do
        local ty = node:type()
        if
            ty == "code_span"
            or ty == "fenced_code_block"
            or ty == "indented_code_block"
            or ty == "html_block"
            or ty == "html_tag"
        then
            return false
        end
        node = node:parent()
    end
    return true
end

local prose = make_condition(in_prose)

-- Nothing but whitespace and `>` before the trigger, so a callout is never
-- dropped into the middle of a sentence: `thm`, or `> thm` for a nested one.
local block_start = make_condition(function(line_to_cursor, matched_trigger)
    return line_to_cursor:sub(1, -(#matched_trigger + 1)):match("^[%s>]*$") ~= nil
end)

-- ---------------------------------------------------------------------------
-- Continuation lines
-- ---------------------------------------------------------------------------
-- A multi-line snippet expanded inside a callout has to put `> ` in front of
-- every line it adds, or the callout ends after the first one.  LuaSnip only
-- repeats the line's leading *whitespace*, so the rest is done here.

--- The container the line sits in, as the text a continuation line needs:
--- a blockquote/callout marker is repeated (`> ` stays `> `), a list marker
--- becomes spaces of the same width.  Leading whitespace is left out; LuaSnip
--- already indents every new line by that much.
local function container(line)
    local rest = line:match("^%s*(.*)$")
    local out = ""
    while true do
        local ws, mark = rest:match("^(%s*)(>%s?)")
        if mark then
            out = out .. ws .. mark
        else
            ws, mark = rest:match("^(%s*)([-*+]%s+)")
            if not mark then
                ws, mark = rest:match("^(%s*)(%d+[.)]%s+)")
            end
            if not mark then
                break
            end
            out = out .. ws .. string.rep(" ", #mark)
        end
        rest = rest:sub(#ws + #mark + 1)
    end
    return out
end

local function container_of(parent)
    return container(parent.snippet.env.TM_CURRENT_LINE or "")
end

--- Start of a continuation line.
local function cont()
    return f(function(_, parent)
        return container_of(parent)
    end)
end

--- A blank line inside the container: `>` on its own, no trailing space,
--- the way the notes write them.
local function blank()
    return f(function(_, parent)
        return (container_of(parent):gsub("%s+$", ""))
    end)
end

--- Start of a display-math body line: indented at the top level, flush
--- against the `> ` inside a callout, which is how the notes have it.
local function math_line()
    return f(function(_, parent)
        local c = container_of(parent)
        return c == "" and "    " or c
    end)
end

-- The body of a callout: whatever was cut with <Tab> in visual mode (see
-- `store_selection_keys` in ../luasnip.lua), each further line quoted, or an
-- empty placeholder when nothing was.
local function quoted_body(k)
    return d(k, function(_, parent)
        local sel = parent.snippet.env.LS_SELECT_DEDENT
        if type(sel) ~= "table" or #sel == 0 or (#sel == 1 and sel[1] == "") then
            return sn(nil, i(1))
        end
        local quote = container_of(parent) .. ">"
        local lines = { sel[1] }
        for n = 2, #sel do
            lines[n] = sel[n] == "" and quote or (quote .. " " .. sel[n])
        end
        return sn(nil, i(1, lines))
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

-- A title as a block id: "Generalized Binomial Theorem" ->
-- "generalized-binomial-theorem", the way the notes' `^def-..` ids are written.
local function slug(title)
    return (title:lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", ""))
end

-- A block id that follows the title (insert node `title`) as it is typed;
-- <Tab> into it to change it.
local function id_from(k, title)
    return d(k, function(args)
        return sn(nil, i(1, slug(args[1][1] or "")))
    end, { title })
end

-- "05" out of L05.md or 05.md, for the lecture heading.
local function lecture_number(parent)
    local name = vim.fn.fnamemodify(parent.snippet.env.TM_FILENAME or "", ":r")
    return name:match("(%d+)$") or "01"
end

local snippets = {
    -- ----------------------------------------------------------------------
    -- MATH ZONE ENTRANCE
    -- ----------------------------------------------------------------------
    -- Prose only: neither trigger contains a `$`, so the guard sees the state
    -- before the snippet.  Without it, `;;` mis-keyed while reaching for a
    -- Greek letter would drop a nested `$$` inside the equation, and a C block
    -- could never say `for (;;)`.
    s({ trig = ";;", snippetType = "autosnippet" }, fmta("$<>$<>", { i(1), i(0) }), { condition = prose }),
    -- Tab, not auto: as an autosnippet it fired at the start of every word
    -- that begins with "il" -- "illustrate", "illegal".  `;;` is the instant one.
    s({ trig = "il", snippetType = "snippet" }, fmta("$<>$<>", { i(1), i(0) }), { condition = prose }),

    -- Display math.  Keep the body free of blank lines: a blank line ends the
    -- markdown paragraph and with it the math span.  Inside a callout (or a
    -- list item) every line it adds carries the container's `> `, so the block
    -- stays inside:
    --
    --     > $$
    --     > x = 1
    --     > $$
    --     >
    s(
        { trig = "dm", snippetType = "autosnippet" },
        fmta(
            [[
        $$
        <><>
        <>$$
        <>
        <><>
        ]],
            { math_line(), i(1), cont(), blank(), cont(), i(0) }
        ),
        { condition = prose }
    ),
    -- Aligned display: `&` marks the column, `\` ends the line.
    s(
        { trig = "dma", snippetType = "snippet" },
        fmta(
            [[
        $$
        <><> &= <> \
        <>&= <>
        <>$$
        <>
        <><>
        ]],
            { math_line(), i(1), i(2), math_line(), i(3), cont(), blank(), cont(), i(0) }
        ),
        { condition = prose }
    ),

    -- ----------------------------------------------------------------------
    -- TEXT
    -- ----------------------------------------------------------------------
    -- The same triggers as typst.lua.  friendly-snippets' `b` and `i` stay.
    s({ trig = "bf", snippetType = "snippet" }, fmta("**<>**", { inline(1) }), { condition = prose }),
    s({ trig = "em", snippetType = "snippet" }, fmta("_<>_", { inline(1) }), { condition = prose }),
    -- A link to a block id, the way the notes cross-reference each other:
    -- [[L03#^def-orthogonal|orthogonal]].  Leave the note empty for one in
    -- the same file.  The `lref` in typst.lua is its folio counterpart.
    s({ trig = "lref", snippetType = "snippet" }, fmt("[[{}#^{}|{}]]", { i(1), i(2), inline(3) }), { condition = prose }),

    -- A new lecture note: front matter, then `# Lecture 05: ..` numbered from
    -- the file name (L05.md, 05.md).
    s(
        { trig = "lec", snippetType = "snippet" },
        fmt(
            [[
        ---
        tags: [{}]
        cssclasses: [numbered]
        ---

        # Lecture {}: {}

        {}
        ]],
            {
                i(1),
                d(2, function(_, parent)
                    return sn(nil, i(1, lecture_number(parent)))
                end),
                i(3, "Title"),
                i(0),
            }
        ),
        { condition = line_begin * prose }
    ),

    -- ----------------------------------------------------------------------
    -- PREAMBLE MATH
    -- ----------------------------------------------------------------------
    -- The macros of the vault's TypstMate preamble
    -- (.obsidian/plugins/typst-mate/data.json), which exist in the notes and
    -- nowhere else -- textbook.typ copies `intr` and `cl`, folio has `ip`.
    -- Text cut with <Tab> in visual mode becomes the argument:
    -- `A union B` -> `cl(A union B)`.  The rest of the course's notation is in
    -- typstmath.lua, section 8.
    s({ trig = "intr", snippetType = "snippet" }, fmta("intr(<>)", { inline(1) }), { condition = in_typst_math }),
    s({ trig = "cl", snippetType = "snippet" }, fmta("cl(<>)", { inline(1) }), { condition = in_typst_math }),
    -- typst.lua has the folio `ip`; this one takes the notes' x and y.
    s(
        { trig = "ip", snippetType = "snippet" },
        fmta("ip(<>, <>)", { i(1, "x"), i(2, "y") }),
        { condition = in_typst_math }
    ),

    -- ----------------------------------------------------------------------
    -- MISC
    -- ----------------------------------------------------------------------
    -- `_qed` is not here: typstmath.lua and mathmode.lua each carry their own,
    -- so it follows the mode without a branch.
    s(
        { trig = "contra", snippetType = "autosnippet" },
        by_mode("arrow.zigzag", "\\unicode{x21af}"),
        { condition = in_mathzone }
    ),
}

-- ---------------------------------------------------------------------------
-- CALLOUTS (generated)
-- ---------------------------------------------------------------------------
-- The vault's theorem environments (.obsidian/snippets/callouts.css), with the
-- same triggers as the folio environments in typst.lua, so `thm<Tab>` means a
-- theorem box in either file:
--
--   thm   > [!thm|b]
--         > ..
--   thmt  > [!thm|b t] Title
--         > ..
--   thml  the same, then the block id `^thm-title` under it, following the
--         title as you type it
--
-- `|b t` is how the notes write them: `t` shows the title, `b` the stronger
-- border.  Where the callout's own name differs from the Typst trigger it
-- works as well (`pf` as `prf`, `rem` as `rmk`, ..).  Text cut with <Tab> in
-- visual mode becomes the body, every line of it quoted.  Nested callouts come
-- out right too: `thm` on a `> ` line gives `> > [!thm|b]`.
--
-- Priority 1100 so `imp` is this, not friendly-snippets' `> [!IMPORTANT]`.
local callouts = {
    -- triggers              callout  block-id prefix
    { { "def" }, "def" },
    { { "thm" }, "thm" },
    { { "lem" }, "lem" },
    { { "cor" }, "cor" },
    { { "prop" }, "prop" },
    { { "claim" }, "claim" },
    { { "conj" }, "conj" },
    { { "axm", "ax" }, "ax" },
    { { "qst" }, "?", "q" },
    { { "exr", "exer" }, "exer" },
    { { "sol", "soln" }, "soln" },
    { { "ex" }, "ex" },
    { { "rmk", "rem" }, "rem" },
    { { "obs" }, "obs" },
    { { "nota", "notn" }, "notn" },
    { { "warn" }, "warn" },
    { { "case" }, "case" },
    { { "prf", "pf" }, "pf" },
    { { "form" }, "form" },
    { { "key" }, "key" },
    { { "hum" }, "hum" },
    { { "aside" }, "aside" },
    { { "impo", "imp" }, "imp" },
    { { "check" }, "check" },
}

local callout_opts = { condition = block_start * prose }

for _, c in ipairs(callouts) do
    local kind, prefix = c[2], c[3] or c[2]
    for _, trig in ipairs(c[1]) do
        table.insert(
            snippets,
            s(
                { trig = trig, snippetType = "snippet", priority = 1100 },
                fmt("> [!" .. kind .. "|b]\n{}> {}\n{}\n{}{}", {
                    cont(),
                    quoted_body(1),
                    blank(),
                    cont(),
                    i(0),
                }),
                callout_opts
            )
        )
        table.insert(
            snippets,
            s(
                { trig = trig .. "t", snippetType = "snippet", priority = 1100 },
                fmt("> [!" .. kind .. "|b t] {}\n{}> {}\n{}\n{}{}", {
                    i(1),
                    cont(),
                    quoted_body(2),
                    blank(),
                    cont(),
                    i(0),
                }),
                callout_opts
            )
        )
        table.insert(
            snippets,
            s(
                { trig = trig .. "l", snippetType = "snippet", priority = 1100 },
                fmt("> [!" .. kind .. "|b t] {}\n{}> {}\n{}\n{}^" .. prefix .. "-{}\n{}\n{}{}", {
                    i(1),
                    cont(),
                    quoted_body(2),
                    blank(),
                    cont(),
                    id_from(3, 1),
                    blank(),
                    cont(),
                    i(0),
                }),
                callout_opts
            )
        )
    end
end

return snippets
