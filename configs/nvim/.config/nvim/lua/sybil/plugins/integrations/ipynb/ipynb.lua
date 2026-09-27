return {
    "ajbucci/ipynb.nvim",
    -- Loaded when a notebook is opened. With no trigger it loaded at startup
    -- (~90ms) and, through the dependencies below, took nvim-lspconfig (mason,
    -- lazydev, ...) and nvim-treesitter with it before any file was open.
    -- setup() registers its BufReadCmd/BufWriteCmd in augroups, and lazy
    -- re-fires those for the buffer that triggered the load.
    event = { "BufReadCmd *.ipynb", "BufNewFile *.ipynb" },
    cmd = { "NotebookCreate", "NotebookListKernels" },
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "neovim/nvim-lspconfig",
        -- "nvim-tree/nvim-web-devicons", -- optional, for language icons
        -- "folke/snacks.nvim", -- optional, for inline images
    },
    opts = {},
    config = function(_, opts)
        -- The entry points as they stand before ipynb.nvim wraps them.
        local pre_ipynb = {
            get_clients = vim.lsp.get_clients,
            buf_request = vim.lsp.buf_request,
            buf_request_all = vim.lsp.buf_request_all,
        }

        require("ipynb").setup(opts)

        -- The plugin installs its LSP wrappers lazily, the first time a notebook
        -- is opened (lsp/shadow.lua -> `install_global_proxy`), which would land
        -- on top of the re-wrap below and undo it.  Forcing it now makes the
        -- order deterministic; the call is guarded by an `_installed` flag
        -- upstream, so the later one becomes a no-op.
        require("ipynb.lsp").install_global_proxy()

        -- WORKAROUND -- upstream bug in lua/ipynb/lsp/request.lua.
        --
        -- The plugin wraps those three functions to redirect a notebook
        -- buffer's LSP traffic to its hidden "shadow" buffer.  The shadow holds
        -- *code cells only* (it is a .py file for a Python notebook), but the
        -- redirect has no cell-type guard, so editing a markdown cell still
        -- sends hover, go-to-definition and completion to pyright.
        --
        -- The plugin's own completion and diagnostics setup already bail out on
        -- `cell.type ~= "code"`; only this proxy is missing the check.  Re-wrap
        -- the three so a cell buffer whose language differs from the shadow's is
        -- left alone, and delete all of this once upstream guards the redirect.
        local proxied = {
            get_clients = vim.lsp.get_clients,
            buf_request = vim.lsp.buf_request,
            buf_request_all = vim.lsp.buf_request_all,
        }

        --- True when `bufnr` is a notebook cell buffer whose language is not the
        --- one the shadow buffer speaks -- a markdown or raw cell, in practice.
        --- Comparing filetypes rather than cell types keeps this correct for
        --- Julia and R notebooks, and survives cells being inserted or deleted.
        local function is_foreign_cell(bufnr)
            local ok, foreign = pcall(function()
                local state = require("ipynb.state").get_from_edit_buf(bufnr)
                if not (state and state.edit_state and state.shadow_buf) then
                    return false
                end
                if not vim.api.nvim_buf_is_valid(state.shadow_buf) then
                    return false
                end
                return vim.bo[bufnr].filetype ~= vim.bo[state.shadow_buf].filetype
            end)
            -- Fail open: if the plugin's internals move, keep its behaviour
            -- rather than breaking LSP in notebooks outright.
            return ok and foreign
        end

        local function resolve(bufnr)
            if bufnr == nil or bufnr == 0 then
                return vim.api.nvim_get_current_buf()
            end
            return bufnr
        end

        vim.lsp.get_clients = function(filter)
            if filter and filter.bufnr ~= nil and is_foreign_cell(resolve(filter.bufnr)) then
                return pre_ipynb.get_clients(filter)
            end
            return proxied.get_clients(filter)
        end

        vim.lsp.buf_request = function(bufnr, ...)
            if is_foreign_cell(resolve(bufnr)) then
                return pre_ipynb.buf_request(bufnr, ...)
            end
            return proxied.buf_request(bufnr, ...)
        end

        vim.lsp.buf_request_all = function(bufnr, ...)
            if is_foreign_cell(resolve(bufnr)) then
                return pre_ipynb.buf_request_all(bufnr, ...)
            end
            return proxied.buf_request_all(bufnr, ...)
        end
    end,
}
