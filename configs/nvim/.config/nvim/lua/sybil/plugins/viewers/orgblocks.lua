-- ~/.config/nvim/lua/plugins/orgblocks.lua
return {
    {
        dir = vim.fn.expand("/home/sybil/Documents/Projects/orgblocks"),
        name = "orgblocks.nvim",
        cmd = { "OrgBlocks", "OrgBlocksToggle", "OrgBlocksStatus", "OrgBlocksReload" },
        opts = {
            -- files = { "/home/sybil/Documents/Projects/orgblocks/orgblocks.nvim/examples/sample.org" },
            files = {
                "~/orgfiles/refile.org",
                "~/orgfiles/work.org",
                "~/orgfiles/school.org",
                "~/orgfiles/important.org",
            },
            week_start = "monday",

            -- the light/dark pair the #+COLOR: hex fills auto-contrast between
            text_color = { light = "#f8f9fa", dark = "#f8f9fa" },
            window = { fullscreen = true },
        },
    },
}
