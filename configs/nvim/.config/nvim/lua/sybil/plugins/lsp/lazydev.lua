-- Lazydev is the key to recognizing nvim modules: it feeds lua_ls the types
-- for `vim.*`, plugin modules and luv. Its own spec rather than a dependency
-- of nvim-lspconfig, so it only loads for Lua buffers -- as a dependency it
-- was loaded on every file open, whatever the filetype.
return {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
        library = {
            -- Load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
    },
}
