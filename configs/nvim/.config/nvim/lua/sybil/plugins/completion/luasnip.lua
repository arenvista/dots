return {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter", -- Only loads when you start typing
    -- follow latest release.
    -- install jsregexp (optional!).
    build = "make install_jsregexp",
    config = function()
        local ls = require("luasnip")

        -- 1. Load your snippets folder
        -- This loads markdown.lua -> "markdown", tex.lua -> "tex", mathmode.lua -> "mathmode"
        require("luasnip.loaders.from_lua").load({ paths = "./lua/sybil/plugins/completion/snip" })

        -- 2. Tell markdown and tex to also look at "mathmode" snippets
        ls.filetype_extend("markdown", { "mathmode" })
        ls.filetype_extend("tex", { "mathmode" })
        ls.filetype_extend("h", { "c" })
        ls.filetype_extend("c", { "h" })
        require("luasnip.loaders.from_vscode").lazy_load()

        local luasnip = require("luasnip")
        vim.keymap.set({ "i", "s" }, "<Tab>", function()
            if luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            end
        end, { silent = true })

        vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
            if luasnip.jumpable(-1) then
                luasnip.jump(-1)
            end
        end, { silent = true })
        vim.g.c_syntax_for_h = 1
        vim.filetype.add({
            extension = {
                h = "c",
            },
        })
    end,
}
