local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    { import = "sybil.plugins.ui" },
    { import = "sybil.plugins.navigation" },
    { import = "sybil.plugins.treesitter" },
    { import = "sybil.plugins.utils" },
    { import = "sybil.plugins.lsp" },
    { import = "sybil.plugins.completion" },
    { import = "sybil.plugins.text_objects" },
    { import = "sybil.plugins.integrations" },
    { import = "sybil.plugins.viewers" },
}, {
    checker = {
        enabled = true,
        notify = false,
    },
    change_detection = {
        notify = false,
    },
})
vim.opt.laststatus = 1
vim.cmd.colorscheme("catppuccin-frappe")
