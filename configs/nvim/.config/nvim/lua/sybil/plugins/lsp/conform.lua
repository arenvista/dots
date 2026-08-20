return {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local conform = require("conform")

        conform.setup({
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "isort", "black" },
                rust = { "rustfmt", lsp_format = "fallback" },
                javascript = { "prettierd", "prettier", stop_after_first = true },
                typescript = { "prettierd", "prettier", stop_after_first = true },
                json = { "prettierd", "prettier", stop_after_first = true },
                yaml = { "prettierd", "prettier", stop_after_first = true },
                html = { "prettierd", "prettier", stop_after_first = true },
                css = { "prettierd", "prettier", stop_after_first = true },

                -- LaTeX & Typst
                tex = { "latexindent" },
                typst = { "prettypst" },
                -- NOTE: latexindent on markdown assumes math-heavy notes (e.g. via
                -- your snippets' \dm/\il triggers). If a file has no LaTeX in it,
                -- latexindent is a no-op pass-through, so this is safe either way —
                -- but if you ever hit odd markdown reformatting, this is why.
                -- markdown = { "latexindent", "prettier" },
                markdown = { "prettier" },
            },

            -- Format on save, but don't block typing and don't blow up if a
            -- formatter isn't installed for the buffer's filetype.
            format_on_save = function(bufnr)
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                end
                return { timeout_ms = 2000, lsp_fallback = true }
            end,

            -- Override specific formatter settings globally
            formatters = {
                stylua = {
                    prepend_args = { "--indent-width", "4", "--indent-type", "Spaces" },
                },
                prettier = {
                    prepend_args = { "--tab-width", "4" },
                },
                prettierd = {
                    prepend_args = { "--tab-width", "4" },
                },
                -- Force latexindent to use 4 spaces (can also be set via local YAML profiles)
                latexindent = {
                    prepend_args = { "-m", "-g", "/dev/null" },
                },
                -- Tells prettypst to seek configuration files (e.g. prettypst.toml with indent = 4)
                prettypst = {
                    prepend_args = { "--use-configuration" },
                },
            },
        })

        -- Manual format (current buffer or visual selection)
        vim.keymap.set({ "n", "v" }, "<leader>bc", function()
            conform.format({ lsp_fallback = true, timeout_ms = 5000 })
        end, { desc = "Format Buffer / Selection" })

        -- Toggle format-on-save, buffer-local (b) or global (B)
        vim.keymap.set("n", "<leader>ubf", function()
            vim.b.disable_autoformat = not vim.b.disable_autoformat
            vim.notify("Format on save (buffer): " .. (vim.b.disable_autoformat and "OFF" or "ON"), vim.log.levels.INFO)
        end, { desc = "Toggle Format on Save (Buffer)" })

        vim.keymap.set("n", "<leader>ubF", function()
            vim.g.disable_autoformat = not vim.g.disable_autoformat
            vim.notify("Format on save (global): " .. (vim.g.disable_autoformat and "OFF" or "ON"), vim.log.levels.INFO)
        end, { desc = "Toggle Format on Save (Global)" })
    end,
}
