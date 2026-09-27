local ls = require("luasnip")
-- Shorten generic functions for readability
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

-- Lua snippets. Named after the filetype like every other file here: the
-- loader files a module's returned snippets under its basename. (This used
-- to be snip.lua calling ls.add_snippets("lua", ...) as a side effect, which
-- only worked while every file was loaded eagerly.)
return {
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
}
