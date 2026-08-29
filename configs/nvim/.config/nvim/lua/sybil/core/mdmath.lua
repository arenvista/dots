-- Which syntax `$ .. $` is written in, per buffer: Typst (the default) or LaTeX.
--
-- Two things have to agree, and both are driven from `M.get` below:
--
--   * which parser the math is injected into.  That drives highlighting, the
--     `in_mathzone` guards on the snippets, and `snacks.image`'s inline math
--     rendering (it picks its template from the injected language).
--   * which LuaSnip filetype markdown borrows its math snippets from --
--     `typstmath` or `mathmode`.  See the `ft_func` in
--     ../plugins/completion/nvim-cmp.lua.
--
-- The injection side is a custom `#md-math?` predicate, registered here and used
-- by queries/markdown_inline/injections.scm.  Tree-sitter injection queries are
-- global per language, so the query carries a rule for each mode and the
-- predicate picks between them per buffer, every time a match is evaluated.
-- That keeps the decision on the *buffer* rather than on a parser instance,
-- which is what lets it reach markdown nested two levels deep inside an
-- `ipynb` notebook.

local M = {}

M.default = "typst"

--- Notebook markdown cells are rendered by Jupyter with MathJax, so their math
--- is LaTeX no matter what plain markdown files are set to.  Covers both the
--- notebook facade and the isolated buffer `ipynb.nvim` opens for a cell.
--- @param buf integer
--- @return boolean
local function is_notebook(buf)
    if vim.bo[buf].filetype == "ipynb" then
        return true
    end
    -- Only ask ipynb.nvim if it is already loaded; this module must not pull it in.
    if not package.loaded["ipynb.state"] then
        return false
    end
    local ok, in_notebook = pcall(function()
        local state = require("ipynb.state").get_from_edit_buf(buf)
        return state ~= nil and state.edit_state ~= nil
    end)
    return ok and in_notebook
end

--- The one place that answers "which syntax is this buffer's math?".
--- An explicit `:MdMath` choice wins; otherwise notebooks are LaTeX and
--- everything else takes `M.default`.
--- @param buf integer? defaults to the current buffer
--- @return "typst"|"latex"
function M.get(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    if buf == 0 then
        buf = vim.api.nvim_get_current_buf()
    end
    local explicit = vim.b[buf].md_math
    if explicit then
        return explicit
    end
    if is_notebook(buf) then
        return "latex"
    end
    return M.default
end

-- Used by queries/markdown_inline/injections.scm to pick the math language.
-- Registered here, before lazy.nvim runs, so it exists by the time any
-- markdown_inline injection query is parsed.
vim.treesitter.query.add_predicate("md-math?", function(_, _, source, predicate)
    if type(source) ~= "number" then
        return predicate[2] == M.default
    end
    return M.get(source) == predicate[2]
end, { force = true, all = false })

--- Re-derive the injected trees so a mode change shows up immediately.
--- @param buf integer
local function refresh(buf)
    local parser = vim.treesitter.get_parser(buf, nil, { error = false })
    if parser then
        parser:invalidate(true)
        pcall(parser.parse, parser, true)
    end
    -- The highlighter caches per-tree state, so it has to be restarted too.
    if vim.treesitter.highlighter.active[buf] then
        vim.treesitter.stop(buf)
        vim.treesitter.start(buf)
    end
end

--- @param mode "typst"|"latex"
--- @param buf integer? defaults to the current buffer
function M.set(mode, buf)
    buf = buf or vim.api.nvim_get_current_buf()
    if mode ~= "typst" and mode ~= "latex" then
        vim.notify("MdMath: expected 'typst' or 'latex', got " .. vim.inspect(mode), vim.log.levels.ERROR)
        return
    end
    local ft = vim.bo[buf].filetype
    if ft ~= "markdown" and ft ~= "ipynb" then
        vim.notify("MdMath: not a markdown or notebook buffer", vim.log.levels.WARN)
        return
    end
    vim.b[buf].md_math = mode
    refresh(buf)
    vim.notify("markdown math: " .. mode)
end

--- @param buf integer? defaults to the current buffer
function M.toggle(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    M.set(M.get(buf) == "typst" and "latex" or "typst", buf)
end

vim.api.nvim_create_user_command("MdMath", function(a)
    if a.args == "" then
        M.toggle()
    else
        M.set(a.args)
    end
end, {
    nargs = "?",
    complete = function()
        return { "typst", "latex" }
    end,
    desc = "Math syntax for this markdown/notebook buffer: typst | latex (no argument toggles)",
})

return M
