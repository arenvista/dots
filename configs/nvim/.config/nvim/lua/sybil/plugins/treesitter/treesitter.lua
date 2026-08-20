return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = function()
        local TS = require("nvim-treesitter")
        if not TS.get_installed then
            error("Please restart Neovim and run `:TSUpdate` to use the `nvim-treesitter` **main** branch.")
            return
        end
    end,
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
    opts = {
        highlight = { enable = true },
        ensure_installed = {
            "bash",
            "c",
            "diff",
            "html",
            "javascript",
            "jsdoc",
            "json",
            "lua",
            "luadoc",
            "luap",
            "markdown",
            "markdown_inline",
            "printf",
            "python",
            "query",
            "regex",
            "toml",
            "tsx",
            "typescript",
            "vim",
            "vimdoc",
            "xml",
            "yaml",
        },
    },
    config = function(_, opts)
        local TS = require("nvim-treesitter")

        setmetatable(require("nvim-treesitter.install"), {
            __newindex = function(_, k)
                if k == "compilers" then
                    vim.schedule(function()
                        error({
                            "Setting custom compilers for `nvim-treesitter` is no longer supported.",
                            "",
                            "For more info, see:",
                            "- [compilers](https://docs.rs/cc/latest/cc/#compile-time-requirements)",
                        })
                    end)
                end
            end,
        })

        if not TS.get_installed then
            vim.notify("Please use `:Lazy` and update `nvim-treesitter`", vim.log.levels.ERROR)
            return
        elseif type(opts.ensure_installed) ~= "table" then
            vim.notify("`nvim-treesitter` opts.ensure_installed must be a table", vim.log.levels.ERROR)
            return
        end

        TS.setup(opts)

        -- 1. Global folding defaults
        vim.opt.foldenable = true       -- Enable folding at startup
        vim.opt.foldlevel = 99          -- Start with all folds open
        vim.opt.foldlevelstart = 99

        -- 2. Apply Tree-sitter folding automatically to all files
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "*",
            callback = function(event)
                -- Start highlighting natively
                pcall(vim.treesitter.start, event.buf)

                -- Enable native Treesitter folds (requires Neovim 0.10+)
                vim.wo.foldmethod = "expr"
                vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
            end,
        })
    end,
}
