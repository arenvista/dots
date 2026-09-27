-- Two separate specs. They used to be one table with the overseer spec nested
-- inside compiler.nvim's, which lazy.nvim reads as a *list* of two specs: the
-- bare "Zeioth/compiler.nvim" string (so its cmd/opts/dependencies were
-- dropped, setup() never ran and :CompilerOpen never existed) and overseer.
return {
    { -- This plugin
        "Zeioth/compiler.nvim",
        cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo" },
        dependencies = { "stevearc/overseer.nvim", "nvim-telescope/telescope.nvim" },
        opts = {},
    },
    { -- The task runner we use
        "stevearc/overseer.nvim",
        commit = "6271cab7ccc4ca840faa93f54440ffae3a3918bd",
        lazy = true, -- loaded as compiler.nvim's dependency
        opts = {
            task_list = {
                direction = "bottom",
                min_height = 25,
                max_height = 25,
                default_detail = 1,
            },
        },
    },
}
