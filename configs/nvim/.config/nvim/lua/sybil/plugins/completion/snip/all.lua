local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node

return {
    -- Typing "todo" anywhere will instantly expand to a TODO comment
    s({ trig = "todo", snippetType = "autosnippet" }, {
        t("TODO: "),
    }),

    -- Typing "email" expands to your email
    s({ trig = "@uv1", snippetType = "autosnippet" }, {
        t("arenv1@umbc.edu"),
    }),
}
