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

        -- 2. Pull in the shared math snippet sets.
        -- typstmath.lua is the Typst math shared by .typ files and markdown;
        -- mathmode.lua is the LaTeX equivalent, used by .tex files and by
        -- markdown buffers switched over with `:MdMath latex`.
        -- Markdown is deliberately absent here: which of the two it borrows is
        -- a per-buffer choice, so it is decided by the `ft_func` in nvim-cmp.lua
        -- instead of by a global extend.  See lua/sybil/core/mdmath.lua.
        ls.filetype_extend("typst", { "typstmath" })
        ls.filetype_extend("tex", { "mathmode" })
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
    end,
}
