return {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    config = function ()
    require('mini.ai').setup({
        custom_textobjects = {
            -- Create a text object for '$' specifically
            ['$'] = { '%b$$', '^.().*().$' },
        }
    })
    end,
}

