-- Formatting.
--
-- Two notes on the notes: markdown here is Obsidian markdown whose math is
-- *Typst*, not LaTeX (see ../../core/mdmath.lua), and .typ files are the real
-- thing. That shapes most of the choices below -- in particular why prettier
-- gets an explicit `proseWrap: preserve` and why nothing reflows math.
return {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local conform = require("conform")

        -- Filetypes formatted *after* the write instead of before it. These are
        -- the slow ones -- prettier/latexindent on a 30 KB lecture note used to
        -- blow the 2s BufWritePre budget and log "Formatter 'prettier' timeout"
        -- -- and none of them need the format to land before the bytes hit disk.
        local async_ft = {
            markdown = true,
            tex = true,
            typst = true,
        }

        -- Shared config for prettier *and* prettierd, so the two agree.
        -- Deliberately not named `.prettierrc.json`: prettierd's own cwd search
        -- looks for dotted names, and this file must never be picked up as if
        -- it were a project config for the nvim repo itself.
        local prettier_config = vim.fs.joinpath(vim.fn.stdpath("config"), "prettierrc.json")

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
                -- lsp_format = "fallback" hands off to tinymist (which embeds
                -- typstyle) if prettypst is missing or errors out.
                typst = { "prettypst", lsp_format = "fallback" },
                -- NOTE: latexindent on markdown assumes math-heavy notes (e.g. via
                -- your snippets' \dm/\il triggers). If a file has no LaTeX in it,
                -- latexindent is a no-op pass-through, so this is safe either way --
                -- but if you ever hit odd markdown reformatting, this is why.
                -- markdown = { "latexindent", "prettier" },
                --
                -- prettierd first: it keeps a warm node daemon (~0.1s) where
                -- plain prettier pays a ~0.7s cold start on every save. prettier
                -- stays as the fallback for when the daemon is not up yet.
                markdown = { "prettierd", "prettier", stop_after_first = true },
            },

            -- Fast filetypes format before the write, so the buffer on disk is
            -- always the formatted one. Slow ones are handled by
            -- format_after_save below.
            format_on_save = function(bufnr)
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                end
                if async_ft[vim.bo[bufnr].filetype] then
                    return
                end
                return { timeout_ms = 2000, lsp_format = "fallback" }
            end,

            -- Slow filetypes: format off the write path and write again. Saving
            -- a lecture note is instant; the reformat lands a moment later.
            format_after_save = function(bufnr)
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                end
                if not async_ft[vim.bo[bufnr].filetype] then
                    return
                end
                return { lsp_format = "fallback" }
            end,

            -- Override specific formatter settings globally
            formatters = {
                stylua = {
                    prepend_args = { "--indent-width", "4", "--indent-type", "Spaces" },
                },
                prettier = {
                    -- --config, not --tab-width: keeps prettier and prettierd
                    -- reading the same settings file.
                    prepend_args = { "--config", prettier_config },
                },
                prettierd = {
                    -- NO prepend_args here. prettierd's argv is `$FILENAME` and
                    -- nothing else -- any extra flag makes it exit with
                    -- "Error: Only a single file path is supported", which then
                    -- silently falls through to the slow prettier. Options go
                    -- through the config file instead. A project's own
                    -- .prettierrc still wins; this is only the default.
                    env = {
                        PRETTIERD_DEFAULT_CONFIG = prettier_config,
                    },
                },
                -- Force latexindent to use 4 spaces (can also be set via local YAML profiles)
                latexindent = {
                    prepend_args = { "-m", "-g", "/dev/null" },
                },
                prettypst = {
                    -- prettypst reads stdin, so it has no idea which file this
                    -- is: it resolves prettypst.toml relative to its *process
                    -- cwd*. Without this it searched from wherever nvim happened
                    -- to be started, so even the folders that do have a config
                    -- only got it by luck.
                    cwd = function(_, ctx)
                        return ctx.dirname
                    end,
                    -- ...and --use-configuration is a hard error ("No
                    -- configuration file") when there is no prettypst.toml to
                    -- find, which is true for all but a handful of homework
                    -- folders. Ask for it only when one actually exists;
                    -- everything else formats with the built-in default style.
                    args = function(_, ctx)
                        local args = { "--use-std-in", "--use-std-out" }
                        local found = vim.fs.find("prettypst.toml", {
                            path = ctx.dirname,
                            upward = true,
                            type = "file",
                        })
                        if found[1] then
                            table.insert(args, "--use-configuration")
                        end
                        return args
                    end,
                },
            },
        })

        -- Manual format (current buffer or visual selection). "x", not "v":
        -- "v" also covers Select mode, which snippet placeholders use.
        vim.keymap.set({ "n", "x" }, "<leader>bc", function()
            conform.format({ lsp_format = "fallback", timeout_ms = 5000 })
        end, { desc = "Format Buffer / Selection" })

        -- Format-on-save toggles are <leader>uf (buffer) / <leader>uF (global),
        -- Snacks toggles in maps.lua. They flip the same vim.b / vim.g
        -- `disable_autoformat` flags read above. (They were <leader>ubf/ubF,
        -- which collided with the <leader>ub background toggle.)
    end,
}
