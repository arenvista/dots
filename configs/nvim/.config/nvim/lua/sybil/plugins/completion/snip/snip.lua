local ls = require("luasnip")
-- Shorten generic functions for readability
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("lua", {
  -- Trigger is "fn", expands to a function block
  s("fn", {
    t("local function "),
    i(1, "myFunc"),      -- Jump point 1 (default text "myFunc")
    t("("),
    i(2, "args"),        -- Jump point 2
    t(")"),
    t({ "", "  " }),     -- New line + indentation
    i(0),                -- Final cursor position
    t({ "", "end" }),    -- New line + end
  }),
})
