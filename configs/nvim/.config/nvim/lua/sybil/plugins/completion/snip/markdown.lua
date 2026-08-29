local ls = require("luasnip")
local s = ls.snippet
local f = ls.function_node
local i = ls.insert_node
local fmta = require("luasnip.extras.fmt").fmta
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

--- Text that differs between the two modes, chosen when the snippet expands.
local function by_mode(typst, latex)
    return f(function()
        return mdmath.get(0) == "latex" and latex or typst
    end)
end

local function not_in_mathzone()
    return not in_mathzone()
end

return {
    -- ----------------------------------------------------------------------
    -- MATH ZONE ENTRANCE
    -- ----------------------------------------------------------------------
    -- Both are gated out of math: neither trigger contains a `$`, so the guard
    -- sees the state before the snippet and correctly fires in prose only.
    -- Without it, `;;` mis-keyed while reaching for a Greek letter -- or a
    -- variable named `il` -- would drop a nested `$$` inside the equation.
    s({ trig = "il", snippetType = "autosnippet" }, fmta("$<>$<>", { i(1), i(0) }), { condition = not_in_mathzone }),
    s({ trig = ";;", snippetType = "autosnippet" }, fmta("$<>$<>", { i(1), i(0) }), { condition = not_in_mathzone }),

    -- Display math.  Keep the body free of blank lines: a blank line ends the
    -- markdown paragraph and with it the math span.
    s(
        { trig = "dm", snippetType = "autosnippet" },
        fmta(
            [[
        $$
            <>
        $$

        <>
        ]],
            { i(1), i(0) }
        ),
        { condition = not_in_mathzone }
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
