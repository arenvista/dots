return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot", -- so `:Copilot auth` / `:Copilot status` work on demand
    -- The language server takes a few seconds to initialize, and copilot.lua
    -- drops (never retries) requests made before then, so the first burst of
    -- typing in a session got no suggestions. VeryLazy starts it before the
    -- first InsertEnter; the LspAttach hook in `config` covers the rest.
    event = "VeryLazy",
    opts = {
        suggestion = {
            enabled = true,
            auto_trigger = true, -- show ghost text as you type, no keypress needed
            keymap = {
                accept = "<M-l>", -- Alt-l accepts the whole suggestion
                accept_word = false,
                accept_line = false,
                next = "<M-]>",
                prev = "<M-[>",
                dismiss = "<C-]>",
            },
        },
        panel = { enabled = false }, -- ghost-text only; no separate suggestions window
        -- copilot.lua disables a handful of filetypes by default (markdown, help,
        -- gitcommit, ...). Re-enable the ones used in this config's notes workflow.
        filetypes = {
            markdown = true,
            tex = true,
            gitcommit = true,
            yaml = true,
        },
    },
    config = function(_, opts)
        require("copilot").setup(opts)
        -- LspAttach fires once the server finishes initializing. If we're
        -- already typing, replay CursorMovedI into copilot's own augroup so it
        -- requests a suggestion instead of waiting for the next keystroke.
        -- vim.schedule runs this after copilot.lua's own (scheduled) on_init
        -- marks the client ready.
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("sybil.copilot", { clear = true }),
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if not client or client.name ~= "copilot" then
                    return
                end
                vim.schedule(function()
                    if args.buf == vim.api.nvim_get_current_buf() and vim.fn.mode() == "i" then
                        pcall(vim.api.nvim_exec_autocmds, "CursorMovedI", {
                            group = "copilot.suggestion",
                            buffer = args.buf,
                        })
                    end
                end)
            end,
        })
    end,
}
