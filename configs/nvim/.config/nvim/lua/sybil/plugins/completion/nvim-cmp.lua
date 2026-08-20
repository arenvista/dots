return {
    "hrsh7th/nvim-cmp",

    event = "InsertEnter",
    dependencies = {
        "hrsh7th/cmp-buffer", -- source for text in buffer
        "hrsh7th/cmp-path", -- source for file system paths
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
            sources = cmp.config.sources({
                { name = "cmp_ai" },
                { name = "buffer" }, -- text within current buffer
                -- { name = "obsidian", priority = 100 },
                -- { name = "block_ids" },
                -- { name = "calc"},
                -- { name = "dictionary"},
                -- { name = "spell"},
                -- { name = "omni"},
                { name = "bufname" },
                { name = "buffer-lines" },
                { name = "digraphs" },
                { name = "path" }, -- file system paths
                { name = "orgmode" },
                { name = "git" },
                { name = "rg" },
                { name = "ollama" },
                { name = "cmdline" },
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
