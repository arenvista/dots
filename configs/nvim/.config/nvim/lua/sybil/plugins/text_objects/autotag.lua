return {
    "windwp/nvim-ts-autotag",
    -- Was `lazy = true` with no trigger, so it never loaded. These are the two
    -- events its README suggests if you lazy-load it at all.
    event = { "BufReadPre", "BufNewFile" },
    config = function ()
        require('nvim-ts-autotag').setup({
            opts = {
                -- Defaults
                enable_close = true, -- Auto close tags
                enable_rename = true, -- Auto rename pairs of tags
                enable_close_on_slash = false -- Auto close on trailing </
            },
            -- Also override individual filetype configs, these take priority.
            -- Empty by default, useful if one of the "opts" global settings
            -- doesn't work well in a specific filetype
            per_filetype = {
                ["markdown"] = {
                    enable_close = false,
                },
                ["html"] = {
                    enable_close = true,
                }
            }
        })
    end,
}
