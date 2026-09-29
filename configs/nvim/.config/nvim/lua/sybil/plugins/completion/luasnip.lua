return {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter", -- Only loads when you start typing
    -- ...or when a selection is cut for a snippet (`store_selection_keys`
    -- below), which can come before the first InsertEnter of a session.
    keys = { { "<Tab>", mode = "x", desc = "Cut selection for the next snippet" } },
    -- follow latest release.
    -- install jsregexp (optional!).
    build = "make install_jsregexp",
    config = function()
        local ls = require("luasnip")

        -- 1. Options. These come first because lazy_load (step 3) consults
        -- `load_ft_func` straight away for the buffer that triggered InsertEnter.
        ls.setup({
            enable_autosnippets = true,
            -- <Tab> in visual mode cuts the selection and keeps it for the next
            -- snippet: select a paragraph, <Tab>, `thm<Tab>`, and it becomes the
            -- theorem's body. The Typst and markdown snippets read it from
            -- LS_SELECT_RAW / LS_SELECT_DEDENT.
            store_selection_keys = "<Tab>",
            -- Which math snippets a markdown buffer sees depends on the syntax
            -- it is set to -- see lua/sybil/core/mdmath.lua and `:MdMath`.
            -- Other filetypes fall through to LuaSnip's default behaviour,
            -- which is this same split plus the `filetype_extend` chains.
            ft_func = function()
                local fts = vim.split(vim.bo.filetype, ".", { plain = true })
                if vim.bo.filetype == "markdown" then
                    local mode = require("sybil.core.mdmath").get(0)
                    table.insert(fts, mode == "latex" and "mathmode" or "typstmath")
                end
                return fts
            end,
            -- Which snippet files to *load* for a buffer. Markdown loads both math
            -- sets, so `:MdMath` can switch between them without a reload;
            -- `ft_func` above still decides which one expands.
            load_ft_func = function(bufnr)
                local ft = vim.bo[bufnr].filetype
                local fts = vim.split(ft, ".", { plain = true })
                if ft == "markdown" then
                    vim.list_extend(fts, { "typstmath", "mathmode" })
                end
                return fts
            end,
        })

        -- 2. Pull in the shared math snippet sets.
        -- typstmath.lua is the Typst math shared by .typ files and markdown;
        -- mathmode.lua is the LaTeX equivalent, used by .tex files and by
        -- markdown buffers switched over with `:MdMath latex`.
        -- Markdown is deliberately absent here: which of the two it borrows is
        -- a per-buffer choice, so it is decided by `ft_func` above instead of
        -- by a global extend. See lua/sybil/core/mdmath.lua.
        ls.filetype_extend("typst", { "typstmath" })
        ls.filetype_extend("tex", { "mathmode" })

        -- 3. Load your snippets folder, one filetype at a time as buffers need
        -- them (markdown.lua -> "markdown", tex.lua -> "tex", mathmode.lua ->
        -- "mathmode"). `load()` read every file -- C, asm, Typst, both math sets
        -- -- on the first InsertEnter, ~130ms whatever you were editing.
        require("luasnip.loaders.from_lua").lazy_load({ paths = "./lua/sybil/plugins/completion/snip" })
        require("luasnip.loaders.from_vscode").lazy_load()

        -- <Tab> expands or jumps when there is a snippet to act on and is a plain
        -- <Tab> otherwise. Without the fallback it was swallowed, so Tab could not
        -- indent in insert mode. (`remap` lets the <Plug> mapping resolve; the
        -- plain "<Tab>" is not remapped again because it starts the rhs.)
        vim.keymap.set({ "i", "s" }, "<Tab>", function()
            return ls.expand_or_jumpable() and "<Plug>luasnip-expand-or-jump" or "<Tab>"
        end, { expr = true, remap = true, silent = true, desc = "Snippet expand/jump, else Tab" })

        vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
            if ls.jumpable(-1) then
                ls.jump(-1)
            end
        end, { silent = true, desc = "Snippet jump back" })
    end,
}
