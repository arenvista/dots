local ls = require("luasnip")
local s = ls.snippet
-- local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
-- local f = ls.function_node
-- local d = ls.dynamic_node
-- local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
-- local line_begin = require("luasnip.extras.expand_conditions").line_begin

local function in_mathzone()
    local node = vim.treesitter.get_node({ ignore_injections = false })
    while node do
        local type = node:type()
        -- text_mode overrides math
        if type == "text_mode" then
            return false
        end
        if type == "displayed_equation" or type == "inline_formula" or type == "math_environment" then
            return true
        end
        node = node:parent()
    end
    return false
end

-- ----------------------------------------------------------------------------
-- SNIPPETS
-- ----------------------------------------------------------------------------

return {
    -- ----------------------------------------------------------------------------
    -- LATEX
    -- ----------------------------------------------------------------------------
    s({ trig = "contra", snippetType = "autosnippet" }, { t("\\unicode{x21af}") }, { condition = in_mathzone }),
    s({trig = "dm", snippetType="autosnippet"}, fmta(
        [[
          $$
              <>
          $$ <>
        ]],
        { i(1), i(0) }
    )),
    s({ trig = "il", snippetType = "autosnippet" }, fmta("$<>$<>", { i(1), i(0) })),
    s({trig = "beg", snippetType="autosnippet"}, fmta(
        [[
          \begin{<>}
              <>
          \end{<>}
        ]],
        { i(1), i(0), rep(1), }
    ), { condition = in_mathzone }
    ),

    s({trig = "cas", snippetType="autosnippet"}, fmta(
        [[
          \begin{cases}
              <>
          \end{cases}
        ]],
        { i(0) }
    ), { condition = in_mathzone }
    ),

}
