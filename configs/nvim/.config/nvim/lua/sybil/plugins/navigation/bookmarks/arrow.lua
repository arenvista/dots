return {
    "otavioschwanck/arrow.nvim",
    -- `;` opens the arrow menu; H/L/<c-s>/<A-n> are wired in maps.lua and load
    -- arrow on first use via a lazy require.
    keys = { ";", "H", "L", "<c-s>" },
    dependencies = {
        { "nvim-tree/nvim-web-devicons" },
        -- or if using `mini.icons`
        { "echasnovski/mini.icons" },
    },
    opts = {
        show_icons = true,
        leader_key = ";", -- Recommended to be a single key
        buffer_leader_key = "m", -- Per Buffer Mappings
    },
}
