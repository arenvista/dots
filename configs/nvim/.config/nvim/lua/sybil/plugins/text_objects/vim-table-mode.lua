return {
    "dhruvasagar/vim-table-mode",
    -- Loaded on first use instead of at startup. <leader>ut runs
    -- :TableModeToggle; the visual-mode keys keep tableizing a selection
    -- working before anything else has loaded the plugin.
    cmd = { "TableModeToggle", "TableModeEnable", "TableModeDisable", "Tableize", "TableModeRealign" },
    keys = {
        { "<leader>tt", mode = "x", desc = "Tableize" },
        { "<leader>T", mode = "x", desc = "Tableize (Delimiter)" },
    },
    config = function()
    vim.keymap.del("n", "<leader>tm")
    vim.keymap.del("n", "<leader>tt")
    end
}
