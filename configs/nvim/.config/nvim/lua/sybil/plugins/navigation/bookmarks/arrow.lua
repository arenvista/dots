return {
    "otavioschwanck/arrow.nvim",
    -- Only arrow's own keys belong here. H/L/<c-s>/<A-n> live in maps.lua and
    -- load arrow through a lazy require: listed here as well, they became
    -- rhs-less lazy key stubs, and lazy deletes those the moment the plugin
    -- loads -- taking the maps.lua mappings with them after their first use.
    -- `m` (buffer_leader_key) is listed so the per-buffer menu is arrow's from
    -- the first press, not only once something else has loaded arrow.
    keys = { ";", "m" },
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
