-- Obsidian-flavoured markdown that marksman does not implement.
--
-- marksman speaks CommonMark plus the plain `[[wiki-link]]`. Obsidian adds two
-- things on top that these notes lean on constantly, and marksman reports every
-- use of either as a broken link:
--
--   [[Note#^block-id]]   a *block reference* -- the anchor points at a line
--                        tagged `^block-id`, not at a heading. marksman strips
--                        the caret, looks for a heading by that name, and
--                        reports "Link to non-existent heading 'block-id'".
--   [[Alias#Heading]]    the document addressed by one of the `aliases:` in its
--                        YAML frontmatter rather than by its filename. marksman
--                        never resolves the document, so its heading check
--                        inside that document is meaningless too.
--
-- The temptation is to drop every "non-existent heading" diagnostic and be done
-- with it, but that throws away the linting along with the false positives. So
-- this module indexes the vault the way Obsidian reads it -- filenames,
-- aliases, block ids, heading slugs -- and re-checks each flagged link against
-- that index. Links that really do resolve are dropped; links that really are
-- broken survive, and keep pointing at the right place.
--
-- Hooked up in ../plugins/lsp/lspconfig.lua, as a handler on marksman.

local M = {}

--- Index per vault root, built on demand and thrown away when a note is
--- written. Roots are keyed by absolute path.
--- @type table<string, { docs: table<string,string>, aliases: table<string,string>, blocks: table<string,table<string,true>>, headings: table<string,table<string,true>> }>
local cache = {}

--- Marksman lowercases and dash-joins a heading to match it against a link
--- anchor ("Inner Product and Norm" -> "inner-product-and-norm"). Close enough
--- to the real GitHub-style slug for note headings, which are prose.
--- @param s string
--- @return string
local function slug(s)
    return (s:lower():gsub("[^%w%s-]", ""):gsub("%s+", "-"))
end

--- A vault root is whatever marksman itself rooted at, so the index and the
--- diagnostics always agree on scope.
--- @param bufnr integer
--- @return string|nil
local function root_of(bufnr)
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = "marksman" })) do
        if client.root_dir then
            return client.root_dir
        end
    end
    return nil
end

--- Every markdown file under `root` that is not ignored. Shells out to ripgrep
--- so the vault's `.ignore` is honoured -- the same file that keeps marksman
--- out of `.obsidian/` and `.venv/`. Falls back to a plain walk if rg is gone.
--- @param root string
--- @return string[]
local function note_paths(root)
    if vim.fn.executable("rg") == 1 then
        local res = vim.system({ "rg", "--files", "--glob", "*.md" }, { cwd = root, text = true }):wait(5000)
        if res.code == 0 and res.stdout then
            local out = {}
            for line in res.stdout:gmatch("[^\n]+") do
                out[#out + 1] = vim.fs.joinpath(root, line)
            end
            return out
        end
    end
    return vim.fn.glob(root .. "/**/*.md", true, true)
end

--- Read one note and file away everything a link might address.
local function index_note(path, index)
    local ok, lines = pcall(vim.fn.readfile, path)
    if not ok then
        return
    end

    local name = vim.fn.fnamemodify(path, ":t:r")
    index.docs[name:lower()] = path
    index.blocks[path] = {}
    index.headings[path] = {}

    -- Frontmatter, if the very first line opens it. Both YAML spellings show up
    -- in this vault: `aliases: [A, B]` and a `-` list on following lines.
    local i = 1
    if lines[1] == "---" then
        i = 2
        local in_aliases = false
        while i <= #lines and lines[i] ~= "---" do
            local line = lines[i]
            local inline = line:match("^aliases:%s*%[(.*)%]%s*$")
            if inline then
                for raw in inline:gmatch("[^,]+") do
                    local alias = vim.trim(raw):gsub('^["\']', ""):gsub('["\']$', "")
                    if alias ~= "" then
                        index.aliases[alias:lower()] = path
                    end
                end
                in_aliases = false
            elseif line:match("^aliases:%s*$") then
                in_aliases = true
            elseif in_aliases then
                local raw = line:match("^%s*-%s*(.+)$")
                if raw then
                    local item = vim.trim(raw):gsub('^["\']', ""):gsub('["\']$', "")
                    if item ~= "" then
                        index.aliases[item:lower()] = path
                    end
                else
                    in_aliases = false
                end
            end
            i = i + 1
        end
        i = i + 1
    end

    for j = i, #lines do
        local line = lines[j]
        local heading = line:match("^#+%s+(.+)$")
        if heading then
            index.headings[path][slug(heading)] = true
        end
        -- A block id is `^id` either alone on its line or trailing the block it
        -- tags. Obsidian allows letters, digits and dashes.
        local block = line:match("%^([%w-]+)%s*$")
        if block then
            index.blocks[path][block:lower()] = true
        end
    end
end

--- @param root string
local function build(root)
    local index = { docs = {}, aliases = {}, blocks = {}, headings = {} }
    for _, path in ipairs(note_paths(root)) do
        index_note(path, index)
    end
    cache[root] = index
    return index
end

--- @param root string
local function get_index(root)
    return cache[root] or build(root)
end

--- Resolve a link's document part the way Obsidian does: by filename first,
--- then by frontmatter alias. An empty name means "this file".
--- @return string|nil path, boolean via_alias
local function resolve(index, name, self_path)
    if name == "" then
        return self_path, false
    end
    -- Links may carry a path prefix ("Notes/L02"); Obsidian matches on the
    -- basename, so index lookups do too.
    local base = name:gsub(".*/", ""):gsub("%.md$", ""):lower()
    if index.docs[base] then
        return index.docs[base], false
    end
    if index.aliases[name:lower()] then
        return index.aliases[name:lower()], true
    end
    return nil, false
end

--- LSP positions count UTF-16 code units; `string.sub` counts bytes. Any note
--- with an em dash or a `⟨` before a link puts the two out of step, which is
--- exactly the kind of line these notes are full of. This is the bridge.
--- @param line string
--- @param encoding string client offset encoding
--- @param character integer 0-based position in `encoding` units
--- @return integer 0-based byte offset
local function byte_offset(line, encoding, character)
    local ok, idx = pcall(vim.str_byteindex, line, encoding, character, false)
    if ok then
        return idx
    end
    return math.min(character, #line)
end

--- Does this marksman diagnostic point at a link that Obsidian resolves fine?
--- @param bufnr integer
--- @param diagnostic lsp.Diagnostic the raw LSP diagnostic
--- @param root string
--- @param encoding string
--- @return boolean
local function resolves_in_obsidian(bufnr, diagnostic, root, encoding)
    -- Only "non-existent heading" is ever a false positive here: a missing
    -- *document* is missing in Obsidian too, unless it is an alias -- which the
    -- alias branch below covers.
    if not diagnostic.message:match("non%-existent heading") then
        return false
    end

    local r = diagnostic.range
    if r.start.line ~= r["end"].line then
        return false
    end
    local line = vim.api.nvim_buf_get_lines(bufnr, r.start.line, r.start.line + 1, false)[1]
    if not line then
        return false
    end
    -- marksman spans the whole `[[...]]`, which is what makes this exact.
    local from = byte_offset(line, encoding, r.start.character)
    local to = byte_offset(line, encoding, r["end"].character)
    local text = line:sub(from + 1, to)
    local inner = text:match("^%[%[(.*)%]%]$")
    if not inner then
        return false
    end

    local target = inner:match("^([^|]*)")
    local doc, anchor = target:match("^([^#]*)#?(.*)$")
    if not anchor or anchor == "" then
        return false
    end

    local index = get_index(root)
    local self_path = vim.api.nvim_buf_get_name(bufnr)
    local path, via_alias = resolve(index, vim.trim(doc), self_path)
    if not path then
        return false
    end

    local block_id = anchor:match("^%^([%w-]+)$")
    if block_id then
        -- A block reference. Real if the target note actually tags that block.
        return (index.blocks[path] or {})[block_id:lower()] == true
    end

    -- A heading anchor. marksman already checks these correctly whenever it
    -- found the document itself, so only second-guess it for alias links.
    if via_alias then
        return (index.headings[path] or {})[slug(anchor)] == true
    end
    return false
end

--- Drop the diagnostics that only look broken because marksman is not Obsidian.
--- @param bufnr integer
--- @param diagnostics lsp.Diagnostic[]
--- @param encoding string? client offset encoding, defaults to utf-16
--- @return lsp.Diagnostic[]
function M.filter(bufnr, diagnostics, encoding)
    if not vim.api.nvim_buf_is_loaded(bufnr) then
        return diagnostics
    end
    local root = root_of(bufnr)
    if not root then
        return diagnostics
    end
    local kept = {}
    for _, d in ipairs(diagnostics) do
        local ok, drop = pcall(resolves_in_obsidian, bufnr, d, root, encoding or "utf-16")
        if not (ok and drop) then
            kept[#kept + 1] = d
        end
    end
    return kept
end

--- Writing a note can add a block id or an alias, so the index for its vault
--- goes stale. Cheaper to rebuild on the next diagnostic than to patch it.
vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("sybil-obsidian-index", { clear = true }),
    pattern = "*.md",
    callback = function(ev)
        local root = root_of(ev.buf)
        if root then
            cache[root] = nil
        end
    end,
})

--- Escape hatch: `:ObsidianReindex` after editing notes outside nvim.
vim.api.nvim_create_user_command("ObsidianReindex", function()
    cache = {}
    vim.notify("Obsidian link index cleared")
end, { desc = "Rebuild the Obsidian alias/block-id index used to filter marksman diagnostics" })

return M
