return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot", -- so `:Copilot auth` / `:Copilot status` work on demand
    event = "InsertEnter",
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
}
