return {
    "hrsh7th/nvim-cmp",

    event = "InsertEnter",
    dependencies = {
        "hrsh7th/cmp-buffer", -- source for text in buffer
        "hrsh7th/cmp-path", -- source for file system paths
        -- Kept here (not on nvim-lspconfig) on purpose: cmp-cmdline's
        -- after/plugin does `require("cmp")`, so hanging it off an eager
        -- plugin pulls nvim-cmp in during lazy.nvim's startup pass, before
        -- `Loader.init_done`. Every other cmp source is registered from its
        -- own after/plugin file, and lazy skips those while init_done is
        -- false -- so buffer/path/luasnip/vimtex silently never register.
        "hrsh7th/cmp-cmdline",
        {
            "L3MON4D3/LuaSnip",
            -- install jsregexp (optional!).
            build = "make install_jsregexp",
        },
        "saadparwaiz1/cmp_luasnip", -- for autocompletion
        "rafamadriz/friendly-snippets", -- useful snippets
        "onsails/lspkind.nvim", -- vs-code like pictograms
        "micangl/cmp-vimtex",
    },
    config = function()
        local cmp = require("cmp")
        local compare = cmp.config.compare
        local luasnip = require("luasnip")
        local lspkind = require("lspkind")
        luasnip.setup({
            enable_autosnippets = true,
        })
        cmp.setup({
            sorting = {
                priority_weight = 1.0,
                comparators = {
                    compare.score, -- Jupyter kernel completion shows prior to LSP
                    compare.recently_used,
                    compare.locality,
                },
            },
            completion = {
                completeopt = "menu,menuone,preview,noselect",
            },
            snippet = { -- configure how nvim-cmp interacts with snippet engine
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },
            mapping = cmp.mapping.preset.insert({
                -- ["<C-k>"] = cmp.mapping.select_prev_item(),
                -- ["<C-j>"] = cmp.mapping.select_next_item(),
                -- ["<C-Space>"] = cmp.mapping.complete(),
                -- ["<C-Backspace>"] = cmp.mapping.abort(),
                ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                ["<CR>"] = cmp.mapping.confirm({ select = false }),
            }),
            -- sources for autocompletion
            -- Only sources whose provider is actually installed. cmp silently
            -- ignores names nothing registered, so a stale entry here is invisible
            -- rather than an error -- check `cmp.core.sources` before adding one.
            sources = cmp.config.sources({
                { name = "buffer" }, -- text within current buffer
                -- { name = "obsidian", priority = 100 },
                -- { name = "block_ids" },
                -- { name = "calc"},
                -- { name = "dictionary"},
                -- { name = "spell"},
                -- { name = "omni"},
                -- orgmode.nvim is installed but registers no cmp source of its
                -- own; re-add once its completion is turned on in its setup.
                -- { name = "orgmode" },
                { name = "path" }, -- file system paths
                { name = "vimtex" }, -- LaTeX refs/citations (cmp-vimtex, above)
                { name = "nvim_lsp", priority = 1000 },
                { name = "luasnip", priority = 10000 },
            }),

            -- configure lspkind for vs-code like pictograms in completion menu
            formatting = {
                format = lspkind.cmp_format({
                    maxwidth = 50,
                    ellipsis_char = "...",
                }),
            },
        })
        cmp.setup.cmdline(":", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
                { name = "path" }, -- Autocomplete file paths
            }, {
                { name = "cmdline" }, -- Autocomplete vim commands/functions
            }),
        })

        -- 3. ENABLE SEARCH AUTOCOMPLETE (/)
        cmp.setup.cmdline("/", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
                { name = "buffer" },
            },
        })
    end,
}
