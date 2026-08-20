return {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function()
        -- Disable all default mappings
        vim.g.nvim_surround_no_mappings = true

        -- Setup (only for options, not keymaps)
        require("nvim-surround").setup({})

        -- Insert mode
        vim.keymap.set("i", "<C-g>s", "<Plug>(nvim-surround-insert)")
        vim.keymap.set("i", "<C-g>S", "<Plug>(nvim-surround-insert-line)")

        -- Normal mode
        vim.keymap.set("n", "ys", "<Plug>(nvim-surround-normal)")
        vim.keymap.set("n", "yss", "<Plug>(nvim-surround-normal-cur)")
        vim.keymap.set("n", "yS", "<Plug>(nvim-surround-normal-line)")
        vim.keymap.set("n", "ySS", "<Plug>(nvim-surround-normal-cur-line)")
        vim.keymap.set("n", "ds", "<Plug>(nvim-surround-delete)")
        vim.keymap.set("n", "cs", "<Plug>(nvim-surround-change)")
        vim.keymap.set("n", "cS", "<Plug>(nvim-surround-change-line)")

        -- Visual mode
        vim.keymap.set("x", "S", "<Plug>(nvim-surround-visual)")
        vim.keymap.set("x", "gS", "<Plug>(nvim-surround-visual-line)")
    end
}
