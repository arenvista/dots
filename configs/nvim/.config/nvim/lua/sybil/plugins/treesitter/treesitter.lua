return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = function()
        local TS = require("nvim-treesitter")
        if not TS.get_installed then
            error("Please restart Neovim and run `:TSUpdate` to use the `nvim-treesitter` **main** branch.")
            return
        end
        -- Parsers must match the plugin's queries, so update them whenever the
        -- plugin itself is updated (the README's `build = ":TSUpdate"`).
        TS.update(nil, { summary = true })
    end,
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
    opts = {
        -- (Highlighting is started per buffer by the FileType autocmd in
        -- `config`; the main branch has no `highlight` option.)
        -- Installed by `config` below if missing -- the main branch's setup()
        -- ignores this list.
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
            "sql", -- injected into python `.execute("...")` (queries/python/injections.scm)
            "toml",
            "tsx",
            "typescript",
            "typst",
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

        -- The main branch's setup() only understands `install_dir`, so
        -- ensure_installed was never acted on: a fresh machine got no parsers.
        -- Install whatever is missing (async; compiled with the tree-sitter CLI).
        local installed = TS.get_installed()
        local missing = vim.tbl_filter(function(lang)
            return not vim.tbl_contains(installed, lang)
        end, opts.ensure_installed)
        if #missing > 0 then
            TS.install(missing, { summary = true })
        end

        -- 1. Global folding defaults
        vim.opt.foldenable = true       -- Enable folding at startup
        vim.opt.foldlevel = 99          -- Start with all folds open
        vim.opt.foldlevelstart = 99

        -- Filetypes whose own ftplugin installs a better `foldexpr` than the
        -- generic Tree-sitter one.  This autocmd runs *after* ftplugin, so
        -- without the opt-out it would overwrite theirs.
        -- ipynb.nvim folds by notebook cell via `ipynb.folding`; Tree-sitter
        -- folds would break on the facade's cell markers.
        local fold_optout = {
            ipynb = true,
        }

        -- 2. Apply Tree-sitter folding automatically to all files
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "*",
            callback = function(event)
                -- Start highlighting natively
                pcall(vim.treesitter.start, event.buf)

                if fold_optout[event.match] then
                    return
                end

                -- Enable native Treesitter folds (requires Neovim 0.10+)
                vim.wo.foldmethod = "expr"
                vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
            end,
        })
    end,
}
