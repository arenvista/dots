-- Which syntax `$ .. $` is written in, per buffer: Typst (the default) or LaTeX.
--
-- Two things have to agree, and both are driven from `M.get` below:
--
--   * which parser the math is injected into.  That drives highlighting, the
--     `in_mathzone` guards on the snippets, and `snacks.image`'s inline math
--     rendering (it picks its template from the injected language).
--   * which LuaSnip filetype markdown borrows its math snippets from --
--     `typstmath` or `mathmode`.  See the `ft_func` in
--     ../plugins/completion/luasnip.lua.
--
-- The injection side is a custom `#md-math!` directive, registered here and used
-- by queries/markdown_inline/injections.scm.  Tree-sitter injection queries are
-- global per language, so the directive sets the language per buffer, every
-- time a math span is matched.  That keeps the decision on the *buffer* rather
-- than on a parser instance, which is what lets it reach markdown nested two
-- levels deep inside an `ipynb` notebook.

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
    -- This runs once per math span per injection scan, so bail out before the
    -- pcall when no notebook is open -- the usual case for plain notes.
    local ipynb = package.loaded["ipynb.state"]
    if not ipynb or type(ipynb.notebooks) ~= "table" or next(ipynb.notebooks) == nil then
        return false
    end
    local ok, state = pcall(ipynb.get_from_edit_buf, buf)
    return ok and state ~= nil and state.edit_state ~= nil
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

-- Used by queries/markdown_inline/injections.scm to pick the math language:
--   (#md-math! @_delim @injection.content)
-- @_delim is the opening delimiter, `$` or `$$`, told apart by width alone so no
-- text has to be fetched.  Typst has no `$$` -- its display math is a single `$`
-- with surrounding whitespace -- so for Typst one `$` is trimmed off each end of
-- a `$$ .. $$` block (the same offset `#offset! @c 0 1 0 -1` would store).
-- LaTeX takes `$$ .. $$` as-is.  Registered here, before lazy.nvim runs, so it
-- exists by the time any markdown_inline injection query is parsed.
vim.treesitter.query.add_directive("md-math!", function(match, _, source, pred, metadata)
    local delim = match[pred[2]] and match[pred[2]][1]
    if not delim then
        return
    end
    local mode = type(source) == "number" and M.get(source) or M.default
    metadata["injection.language"] = mode
    local _, start_col, _, end_col = delim:range()
    if mode == "typst" and end_col - start_col == 2 then
        local id = pred[3]
        metadata[id] = metadata[id] or {}
        metadata[id].offset = { 0, 1, 0, -1 }
    end
end, { force = true })

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
