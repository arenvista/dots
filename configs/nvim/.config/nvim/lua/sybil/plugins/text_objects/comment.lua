return {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    dependencies = {
        "JoosepAlviste/nvim-ts-context-commentstring",
    },
    opts = function()
        -- 1. Configure the context plugin first
        require("ts_context_commentstring").setup({
            enable_autocmd = false,
        })

        -- 2. Return the setup opts for Comment.nvim with the hook injected
        return {
            pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
        }
    end,
}
