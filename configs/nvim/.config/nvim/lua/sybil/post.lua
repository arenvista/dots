-- 2. Configure folding to use Tree-sitter
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

-- 3. Folding defaults
vim.opt.foldenable = true       -- Enable folding at startup
vim.opt.foldlevel = 99          -- Start with all folds open (set to 0 to start with all closed)
vim.opt.foldlevelstart = 99

vim.opt.suffixesadd:append({ ".tsx", ".ts", ".jsx", ".js", ".css", ".scss" })
