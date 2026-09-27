return {
    "jiaoshijie/undotree",
    -- It defines no command or keymap of its own, so it used to load at
    -- VeryLazy with no way to open it. <leader>eu (maps.lua) opens it now,
    -- loading it on first use.
    lazy = true,
    dependencies = "nvim-lua/plenary.nvim",
    config = true,
}
