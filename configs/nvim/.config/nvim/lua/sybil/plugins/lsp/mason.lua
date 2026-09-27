return {
    "mason-org/mason.nvim",
    -- Loaded on demand: as a dependency of nvim-lspconfig (so mason.setup runs
    -- before the LSP config), or via the :Mason* commands. Keeps ~62ms off startup.
    lazy = true,
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall", "MasonUninstallAll", "MasonLog" },
    dependencies = {
        -- Configured in lspconfig.lua, not here: mason-lspconfig enables servers
        -- as a side effect of setup(), so it has to run *after* the
        -- vim.lsp.config() calls it will enable.
        "mason-org/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
        require("mason").setup({
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
        })

        -- Formatters and linters only — language servers are installed by
        -- mason-lspconfig's ensure_installed (see lspconfig.lua).
        require("mason-tool-installer").setup({
            -- Run the "anything missing?" check once the UI is up rather than
            -- while the first file is being opened.
            start_delay = 3000,
            ensure_installed = {
                "prettier",
                "prettierd",
                "stylua",
                "isort",
                "black",
                "pylint",
                "eslint_d",
                "latexindent",
                "prettypst",
            },
        })
    end,
}
