-- LSP setup.
--
-- Neovim 0.11+ / nvim-lspconfig v2 do this natively: the plugin ships a
-- `lsp/<server>.lua` for every server (cmd, filetypes, root_markers), and we
-- layer overrides on top with `vim.lsp.config()`. Configs resolve in this order
-- (`:h vim.lsp.config`):
--
--   vim.lsp.config("*")  ->  lsp/<name>.lua from the runtimepath  ->  vim.lsp.config("<name>")
--
-- so anything not set below keeps upstream's defaults. `require("lspconfig")`
-- is never called; the plugin is here only to supply those `lsp/` definitions.
--
-- Servers are turned on by mason-lspconfig's `automatic_enable`, which calls
-- `vim.lsp.enable()` for *every* mason-installed server it can map to a config
-- — not just the ones named below. So anything installed by hand via :MasonInstall
-- (ts_ls, rust_analyzer, marksman, ...) attaches on upstream defaults too. That is
-- intended; `ensure_installed` below is the floor, not the whole list.
return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        -- mason must be set up before this config runs (it adds servers to PATH).
        -- Listing it here guarantees that ordering.
        "mason-org/mason.nvim",
        "hrsh7th/cmp-nvim-lsp",
        { "antosha417/nvim-lsp-file-operations", config = true },
        -- Lazydev is the key to recognizing nvim modules
        {
            "folke/lazydev.nvim",
            ft = "lua", -- only load on lua files
            opts = {
                library = {
                    -- Load luvit types when the `vim.uv` word is found
                    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                },
            },
        },
    },
    config = function()
        ------------------------------------------------------------------
        -- 1. Defaults applied to every server
        ------------------------------------------------------------------
        vim.lsp.config("*", {
            capabilities = require("cmp_nvim_lsp").default_capabilities(),
        })

        ------------------------------------------------------------------
        -- 2. Per-server overrides
        ------------------------------------------------------------------
        vim.lsp.config("lua_ls", {
            settings = {
                Lua = {
                    -- Neovim runs LuaJIT
                    runtime = { version = "LuaJIT" },
                    workspace = {
                        -- DON'T set `library` manually — lazydev does it for you,
                        -- which is also why this is false: left true, lua_ls keeps
                        -- prompting to add luv & friends as a third-party workspace
                        -- library that lazydev has already loaded.
                        checkThirdParty = false,
                    },
                    completion = { callSnippet = "Replace" },
                    telemetry = { enable = false },
                    diagnostics = {
                        globals = { "vim" },
                        disable = { "missing-fields" }, -- noisy on plugin opts tables
                    },
                },
            },
        })

        vim.lsp.config("clangd", {
            -- Replaces upstream's `{ "clangd" }` wholesale (lists don't merge).
            cmd = {
                "clangd",
                "--background-index",
                "--clang-tidy",
                -- If compile_commands.json lives in a build dir:
                -- "--compile-commands-dir=build",
            },
            init_options = {
                fallbackFlags = { "-std=c++17" },
            },
            -- No root_dir override: upstream's root_markers already cover
            -- compile_commands.json / compile_flags.txt / .clangd / .git.
            -- Its on_attach also defines :LspClangdSwitchSourceHeader.
        })

        vim.lsp.config("pyright", {
            settings = {
                python = {
                    analysis = {
                        autoSearchPaths = true,
                        diagnosticMode = "workspace",
                        useLibraryCodeForTypes = true,
                    },
                },
            },
        })

        -- Upstream's list plus "svelte". No "gql" — .gql files already resolve to
        -- filetype "graphql", so listing it does nothing but warn in checkhealth.
        vim.lsp.config("graphql", {
            filetypes = { "graphql", "typescriptreact", "javascriptreact", "svelte" },
        })

        -- No emmet_ls / cssmodules_ls `filetypes` override: upstream's lists are
        -- a superset of / identical to what we want, and filetypes is a list, so
        -- overriding replaces rather than merges (emmet would lose vue, astro,
        -- pug, templ, htmldjango, eruby, htmlangular).
        vim.lsp.config("cssmodules_ls", {
            on_attach = function(client)
                -- Keep cssmodules out of go-to-definition so ts_ls wins it.
                -- Class lookups go through <leader>ld (see maps.lua), which
                -- greps for the rule when the cursor is in a class attribute.
                client.server_capabilities.definitionProvider = false
            end,
        })

        ------------------------------------------------------------------
        -- 3. Install + enable
        --
        -- Must come after the vim.lsp.config() calls above — setup() enables
        -- servers as a side effect, and an enabled config is resolved and cached
        -- on first attach. Names here are lspconfig names, not mason package names.
        ------------------------------------------------------------------
        require("mason-lspconfig").setup({
            ensure_installed = {
                -- configured above
                "lua_ls",
                "clangd",
                "pyright",
                "graphql",
                "emmet_ls",
                "cssmodules_ls",
                -- upstream defaults are fine for these
                "cssls",
                "html",
                "texlab",
                "taplo",
            },
            automatic_enable = {
                -- mason installs stylua as a formatter for conform, but the
                -- package also advertises an LSP mode (`stylua --lsp`), which
                -- automatic_enable would otherwise start on every Lua buffer.
                exclude = { "stylua" },
            },
        })

        ------------------------------------------------------------------
        -- 4. Buffer-local keymaps on attach
        --    (0.11+ already maps K=hover, grn/gra/grr/gri, gO; the rest of
        --     the LSP keymaps live in maps.lua under <leader>l)
        ------------------------------------------------------------------
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
                vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, {
                    buffer = ev.buf,
                    desc = "LSP: Signature Help",
                })
            end,
        })

        ------------------------------------------------------------------
        -- 5. Diagnostics
        --    virtual_text is deliberately absent — inline-diagnotic.lua owns it.
        ------------------------------------------------------------------
        vim.diagnostic.config({
            severity_sort = true,
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = " ",
                    [vim.diagnostic.severity.WARN] = " ",
                    [vim.diagnostic.severity.HINT] = "󰠠 ",
                    [vim.diagnostic.severity.INFO] = " ",
                },
            },
        })
    end,
}
