return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        -- mason must be set up before this config runs (adds servers to PATH,
        -- registers mason-lspconfig handlers). Listing it here guarantees ordering.
        "williamboman/mason.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-cmdline",
        { "antosha417/nvim-lsp-file-operations", config = true },
        -- Lazydev is the key to recognizing nvim modules
        {
            "folke/lazydev.nvim",
            ft = "lua", -- only load on lua files
            opts = {
                library = {
                    -- See the configuration section for more details
                    -- Load luvit types when the `vim.uv` word is found
                    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                    -- Load codecompanion types when the `codecompanion` word is found
                    { path = "codecompanion.nvim", words = { "codecompanion" } },
                },
            },
        },
    },
    config = function()
        local lspconfig = require("lspconfig")
        local cmp_nvim_lsp = require("cmp_nvim_lsp")
        local keymap = vim.keymap

        -- 1. Setup Capabilities
        local capabilities = cmp_nvim_lsp.default_capabilities()

        -- 2. Define Server Specific Configs
        local servers = {
            -- Lua LS
            lua_ls = {
                settings = {
                    Lua = {
                        runtime = {
                            -- Tell the language server which version of Lua you're using
                            -- (most likely LuaJIT in the case of Neovim)
                            version = "LuaJIT",
                        },
                        workspace = {
                            -- Make the server aware of Neovim runtime files
                            -- library = ... -- DON'T set this manually, lazydev does it for you!
                            checkThirdParty = true,
                        },
                        completion = {
                            callSnippet = "Replace",
                        },
                        telemetry = { enable = false },
                        diagnostics = {
                            -- Get the language server to recognize the `vim` global
                            globals = { "vim" },
                            disable = { "missing-fields" }, -- Optional: Ignore noisy warnings
                        },
                    },
                },
            },

            -- Clangd
            clangd = {
                cmd = {
                    "clangd",
                    "--background-index",
                    "--clang-tidy",
                    "--log=verbose",
                    -- Optional: specify compile_commands.json directory if not at root
                    -- '--compile-commands-dir=build',
                },
                init_options = {
                    fallbackFlags = { "-std=c++17" },
                },
                -- Automatically find compile_commands.json in project root
                root_dir = function(fname)
                    return lspconfig.util.root_pattern("compile_commands.json", ".git")(fname)
                        or lspconfig.util.path.dirname(fname)
                end,
            },

            -- Pyright
            pyright = {
                settings = {
                    python = {
                        analysis = {
                            autoSearchPaths = true,
                            diagnosticMode = "workspace",
                            useLibraryCodeForTypes = true,
                        },
                    },
                },
            },

            -- GraphQL
            graphql = {
                filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
            },

            -- Emmet
            emmet_ls = {
                filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
            },

            -- CSS Modules
            cssmodules_ls = {
                filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
                on_attach = function(client, bufnr)
                    -- Prevent cssmodules from overwriting standard typescript go-to-definitions
                    client.server_capabilities.definitionProvider = false

                    -- Map your jump keys to search class definitions via the implementation layer
                    keymap.set("n", "<leader>ld", vim.lsp.buf.implementation, {
                        buffer = bufnr,
                        desc = "Goto Class Definition",
                    })
                end,
            },
        }

        -- 3. Mason Setup & Handlers
        require("mason-lspconfig").setup({
            ensure_installed = vim.tbl_keys(servers),
            handlers = {
                function(server_name)
                    local server_config = servers[server_name] or {}
                    server_config.capabilities =
                        vim.tbl_deep_extend("force", {}, capabilities, server_config.capabilities or {})
                    lspconfig[server_name].setup(server_config)
                end,
            },
        })

        -- 4. LspAttach Autocommand (Global Keybinds)
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
                local client = vim.lsp.get_client_by_id(ev.data.client_id)

                -- A handy wrapper function so we don't have to type out the `{ buffer, desc }` table every time
                local map = function(mode, keys, func, desc)
                    vim.keymap.set(mode, keys, func, { buffer = ev.buf, desc = "LSP: " .. desc })
                end
                map("n", "K", vim.lsp.buf.hover, "Hover Documentation")
                map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
                local function switch_source_header()
                    local bufnr = vim.api.nvim_get_current_buf()
                    local params = { uri = vim.uri_from_bufnr(bufnr) }

                    vim.lsp.buf_request(bufnr, "textDocument/switchSourceHeader", params, function(err, result)
                        if err then
                            vim.notify("Error switching source/header: " .. tostring(err.message), vim.log.levels.ERROR)
                            return
                        end

                        if not result then
                            vim.notify("Corresponding source/header file not found", vim.log.levels.WARN)
                            return
                        end

                        -- Open the returned file
                        vim.cmd("edit " .. vim.uri_to_fname(result))
                    end)
                end

                -- 2. Bind it inside your LspAttach callback
                -- ...
                if client.name == "clangd" then
                    vim.keymap.set(
                        "n",
                        "gs",
                        switch_source_header, -- Call the Lua function directly instead of <cmd>
                        { buffer = ev.buf, desc = "Switch Source/Header" }
                    )
                end
            end,
        })

        -- 5. Diagnostic Signs & Config
        local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
        for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
        end

        -- vim.diagnostic.config({
        -- 	virtual_text = false,
        -- 	signs = true,
        -- 	underline = true,
        -- 	update_in_insert = false,
        -- 	severity_sort = true,
        -- })
    end,
}
