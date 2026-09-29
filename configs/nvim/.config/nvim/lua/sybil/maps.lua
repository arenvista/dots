local wk = require("which-key")
local keymap = vim.keymap

-- Leader keys are set in core/options.lua, which runs before lazy.nvim: they
-- have to be in place before any plugin defines a <leader> mapping.
--
-- Icons: every glyph in this file is a Nerd Font `md-*` icon (U+F0000 and up).
-- The entries that showed up blank in which-key had icon strings that were
-- only spaces -- their glyphs, all from the lower private-use block
-- (U+E000-F8FF), were missing -- while every md-* glyph was intact.

-- ==========================================================
-- STANDARD KEYMAPS (non-leader)
-- ==========================================================
wk.add({
    { "<c-f>", group = "Tmux", icon = "󰢩 " },
    {
        "<c-f>f",
        "<cmd>silent !tmux neww ~/.config/zsh_custom/macros/tmux-sessionizer.zsh<CR>",
        desc = "Tmux Sessionizer",
        icon = "󰉕 ",
    },
    { "<c-f>s", "<cmd>silent !tmux neww tmux-attacher<CR>", desc = "Tmux Attacher", icon = "󱘖 " },

    { "<C-c>", "<Esc>", desc = "Rebind ESC to CTRL+C", mode = { "n", "i", "v" }, icon = "󱊷 " },
    { "<Del>", "<Esc>", desc = "Escape", mode = { "n", "i", "v" }, icon = "󱊷 " },

    -- nvzone/menu (menu.lua); the require loads it on first use.
    {
        "<C-t>",
        function()
            require("menu").open("default")
        end,
        desc = "Menu",
        icon = "󰍜 ",
    },
})

-- "x", not "v": "v" also covers Select mode, which is where snippet
-- placeholders live -- typing a J or K into one moved lines instead.
keymap.set("x", "J", ":m '>+1<CR>gv=gv", { desc = "Move highlighted lines down", silent = true })
keymap.set("x", "K", ":m '<-2<CR>gv=gv", { desc = "Move highlighted lines up", silent = true })

-- Terminal-mode window navigation (Claude Code pane, :terminal, snacks terminal).
-- Defined here rather than in the vim-tmux-navigator lazy spec: lazy's `keys`
-- handler registers an <expr> stub, which does not fire correctly in terminal
-- mode -- the command text ends up typed into the terminal. A plain string RHS
-- avoids that; the plugin still loads on demand via its `cmd` list.
for key, dir in pairs({ h = "Left", j = "Down", k = "Up", l = "Right" }) do
    keymap.set(
        "t",
        "<C-" .. key .. ">",
        [[<C-\><C-n><Cmd>TmuxNavigate]] .. dir .. "<CR>",
        { desc = "Navigate " .. dir:lower() }
    )
end

-- Icons for vim-tmux-navigator's normal-mode keys (defined in tmux-nav.lua).
-- `real = true`: shown only while the keymap itself exists.
wk.add({
    { "<c-h>", icon = "󰁍 ", real = true },
    { "<c-j>", icon = "󰁅 ", real = true },
    { "<c-k>", icon = "󰁝 ", real = true },
    { "<c-l>", icon = "󰁔 ", real = true },
    { "<c-\\>", icon = "󰓡 ", real = true },
})

-- ==========================================================
-- WHICH-KEY GROUPS
-- ==========================================================
-- Declared for visual mode too: otherwise <leader>a/b/f/g showed up unnamed
-- and without icons there.
wk.add({
    mode = { "n", "x" },
    { "<leader>b", group = "Buffer", icon = "󰓩 " },
    { "<leader>q", group = "Quit & Session", icon = "󰗼 " },
    { "<leader>s", group = "Search", icon = "󰍉 " },
    { "<leader>l", group = "LSP", icon = "󱐋 " },
    { "<leader>la", group = "Calls", icon = "󰃻 " },
    { "<leader>u", group = "Toggle", icon = "󰨚 " },
    { "<leader>g", group = "Git", icon = "󰊢 " },
    { "<leader>gd", group = "Diff", icon = "󰢪 " },
    { "<leader>e", group = "Explorers", icon = "󰭈 " },
    { "<leader>o", group = "Org", icon = "󰝖 " },
    { "<leader>f", group = "Finder", icon = "󰥩 " },
    { "<leader>a", group = "AI", icon = "󰚩 " },
    { "<leader>n", group = "Notifications", icon = "󰎟  " },
    { "<leader>m", group = "Misc.", icon = "󰦭 " },
    { "<leader>r", group = "Windows", icon = "󱂬 " },
    { "[", group = "Prev", icon = "󰄽 " },
    { "]", group = "Next", icon = "󰄾 " },
})

-- ==========================================================
-- BUFFER / CLIPBOARD / QUIT
-- ==========================================================
wk.add({
    -- Buffer
    {
        "<leader>bf",
        function()
            local view = vim.fn.winsaveview()
            vim.cmd("normal! gg=G")
            vim.fn.winrestview(view)
        end,
        desc = "Format entire buffer with =",
        mode = "n",
        icon = "󰉶 ",
    },
    {
        "<leader>bd",
        function()
            Snacks.bufdelete()
        end,
        desc = "Delete Buffer",
        icon = "󰧧 ",
    },
    -- Defined in conform.lua.
    { "<leader>bc", mode = { "n", "x" }, icon = "󰁨 ", real = true },

    -- Clipboard & Registers. "x" rather than "v" for the same reason as J/K.
    -- (<leader>p used to have a second, visual-only `"_dP` mapping that this
    -- one always overrode; the built-in visual `P` pastes without yanking.)
    { "<leader>y", [["+y]], desc = "which_key_ignore", mode = { "n", "x" }, icon = "󰆏 " },
    { "<leader>Y", [["+Y]], desc = "which_key_ignore", mode = "n", icon = "󰆏 " },
    { "<leader>p", [["+p]], desc = "which_key_ignore", mode = { "n", "x" }, icon = "󰆒 " },
    { "<leader>P", [["+P]], desc = "which_key_ignore", mode = { "n", "x" }, icon = "󰆒 " },

    -- Save, Quit & Window Close
    { "<leader>w", "<cmd>w<CR>", desc = "which_key_ignore", mode = "n", icon = "󰠘 " },
    { "<leader>qa", "<cmd>qa<CR>", desc = "Quit All", mode = "n", icon = "󰩈 " },
    { "<leader>qx", "<cmd>qa!<CR>", desc = "Quit All Force", mode = "n", icon = "󰐥 " },
    { "<leader>qo", "<C-w>o", desc = "Close Others", icon = "󰈆 " },
    { "<leader>qw", "<cmd>q<CR>", desc = "Close Window", mode = "n", icon = "󰖭 " },
    { "<c-x>", "<cmd>q<CR>", desc = "Close Window", mode = "n" },
})

-- ==========================================================
-- EXPLORERS
-- ==========================================================
wk.add({
    { "<leader>ee", vim.cmd.Neotree, desc = "Neotree", mode = "n", icon = "󰙅 " },
    { "<leader>ea", "<cmd>AerialToggle!<CR>", desc = "Aerial", mode = "n", icon = "󰉺 " },
    {
        "<leader>eo",
        function()
            require("oil").open()
        end,
        desc = "Oil & Vinegar",
        icon = "󰼙 ",
    },
    {
        "<leader>eu",
        function()
            require("undotree").toggle()
        end,
        desc = "Undotree",
        icon = "󱘎 ",
    },
})

-- ==========================================================
-- FINDER (Snacks pickers)
-- ==========================================================
wk.add({
    {
        "<leader>fS",
        function()
            Snacks.scratch.select()
        end,
        desc = "Find Scratch Buffer",
        icon = "󱈄 ",
    },
    {
        "<leader>ff",
        function()
            Snacks.picker.smart()
        end,
        desc = "Find Files",
        icon = "󰱼 ",
    },
    {
        "<leader>f:",
        function()
            Snacks.picker.command_history()
        end,
        desc = "Find Command History",
        icon = "󰺅 ",
    },
    {
        "<leader>fb",
        function()
            Snacks.picker.buffers()
        end,
        desc = "Find Buffers",
        icon = "󱦞 ",
    },
    {
        "<leader>fl",
        function()
            Snacks.picker.lines()
        end,
        desc = "Find Buffer Lines",
        icon = "󰺯 ",
    },
    {
        "<leader>fc",
        function()
            Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "Find Config File",
        icon = "󰩊 ",
    },
    {
        "<leader>fg",
        function()
            Snacks.picker.git_files()
        end,
        desc = "Find Git Files",
        icon = "󰱂 ",
    },
    {
        "<leader>fG",
        function()
            Snacks.picker.grep()
        end,
        desc = "Find Grep",
        icon = "󱎸 ",
    },
    {
        "<leader>fp",
        function()
            Snacks.picker.projects()
        end,
        desc = "Find Projects",
        icon = "󰡦 ",
    },
    {
        "<leader>fr",
        function()
            Snacks.picker.recent()
        end,
        desc = "Find Recent",
        icon = "󰹓 ",
    },
    {
        "<leader>fB",
        function()
            Snacks.picker.grep_buffers()
        end,
        desc = "Find in Open Buffers",
        icon = "󱈅 ",
    },
    {
        "<leader>fN",
        function()
            Snacks.picker.notifications()
        end,
        desc = "Find Notification History",
        icon = "󰂜 ",
    },
    {
        "<leader>fw",
        function()
            Snacks.picker.grep_word()
        end,
        desc = "Find Visual selection or word",
        mode = { "n", "x" },
        icon = "󱎸 ",
    },
})

-- ==========================================================
-- GIT
-- ==========================================================
wk.add({
    {
        "<leader>gds",
        "<cmd>Gvdiffsplit!<CR>",
        desc = "Open Diff Split",
        icon = "󰯌 ",
    },
    {
        "<leader>gdh",
        "<cmd>diffget //2<CR>",
        desc = "Get Left Hunk",
        icon = "󰜳 ",
    },
    {
        "<leader>gdl",
        "<cmd>diffget //3<CR>",
        desc = "Get Right Hunk",
        icon = "󰜶 ",
    },
    {
        "<leader>gb",
        function()
            Snacks.picker.git_branches()
        end,
        desc = "Git Branches",
        icon = "󰘬 ",
    },
    { "<leader>gf", "<cmd>tab Git<cr>", desc = "Fugitive", icon = "󰊤" },
    {
        "<leader>gl",
        function()
            Snacks.picker.git_log()
        end,
        desc = "Git Log",
        icon = "󰜘 ",
    },
    {
        "<leader>gL",
        function()
            Snacks.picker.git_log_line()
        end,
        desc = "Git Log Line",
        icon = "󰯔 ",
    },
    {
        "<leader>gs",
        function()
            Snacks.picker.git_status()
        end,
        desc = "Git Status",
        icon = "󱖫 ",
    },
    {
        "<leader>gS",
        function()
            Snacks.picker.git_stash()
        end,
        desc = "Git Stash",
        icon = "󱈎 ",
    },
    {
        "<leader>gD",
        function()
            Snacks.picker.git_diff()
        end,
        desc = "Git Diff (Hunks)",
        icon = "󰕚 ",
    },
    {
        "<leader>gF",
        function()
            Snacks.picker.git_log_file()
        end,
        desc = "Git Log File",
        icon = "󰮗 ",
    },
    {
        "<leader>gi",
        function()
            Snacks.picker.gh_issue()
        end,
        desc = "GitHub Issues (open)",
        icon = "󰗖 ",
    },
    {
        "<leader>gI",
        function()
            Snacks.picker.gh_issue({ state = "all" })
        end,
        desc = "GitHub Issues (all)",
        icon = "󱇮 ",
    },
    {
        "<leader>gp",
        function()
            Snacks.picker.gh_pr()
        end,
        desc = "GitHub Pull Requests (open)",
        icon = "󰊤 ",
    },
    {
        "<leader>gP",
        function()
            Snacks.picker.gh_pr({ state = "all" })
        end,
        desc = "GitHub Pull Requests (all)",
        icon = "󰓂 ",
    },
    {
        "<leader>gg",
        function()
            Snacks.lazygit()
        end,
        desc = "Lazygit",
        icon = "󰊤 ",
    },
    {
        "<leader>gB",
        function()
            Snacks.gitbrowse()
        end,
        desc = "Git Browse",
        mode = { "n", "x" },
        icon = "󰊢 ",
    },
})

-- ==========================================================
-- SEARCH (Snacks pickers)
-- ==========================================================
wk.add({
    {
        '<leader>s"',
        function()
            Snacks.picker.registers()
        end,
        desc = "Search Registers",
        icon = "󱉬 ",
    },
    {
        "<leader>s/",
        function()
            Snacks.picker.search_history()
        end,
        desc = "Search History",
        icon = "󰋚 ",
    },
    {
        "<leader>sa",
        function()
            Snacks.picker.autocmds()
        end,
        desc = "Search Autocmds",
        icon = "󱐌 ",
    },
    {
        "<leader>sb",
        function()
            Snacks.picker.lines()
        end,
        desc = "Search Buffer Lines",
        icon = "󰺯 ",
    },
    {
        "<leader>sc",
        function()
            Snacks.picker.command_history()
        end,
        desc = "Search Command History",
        icon = "󰺅 ",
    },
    {
        "<leader>sC",
        function()
            Snacks.picker.commands()
        end,
        desc = "Search Commands",
        icon = "󰞷 ",
    },
    {
        "<leader>sd",
        function()
            Snacks.picker.diagnostics()
        end,
        desc = "Search Diagnostics",
        icon = "󰓙 ",
    },
    {
        "<leader>sD",
        function()
            Snacks.picker.diagnostics_buffer()
        end,
        desc = "Search Buffer Diagnostics",
        icon = "󰩌 ",
    },
    {
        "<leader>sh",
        function()
            Snacks.picker.help()
        end,
        desc = "Search Help Pages",
        icon = "󰘥 ",
    },
    {
        "<leader>sH",
        function()
            Snacks.picker.highlights()
        end,
        desc = "Search Highlights",
        icon = "󰸌 ",
    },
    {
        "<leader>si",
        function()
            Snacks.picker.icons()
        end,
        desc = "Search Icons",
        icon = "󰇲 ",
    },
    {
        "<leader>sj",
        function()
            Snacks.picker.jumps()
        end,
        desc = "Search Jumps",
        icon = "󰴠 ",
    },
    {
        "<leader>sk",
        function()
            Snacks.picker.keymaps()
        end,
        desc = "Search Keymaps",
        icon = "󰥻 ",
    },
    {
        "<leader>sl",
        function()
            Snacks.picker.loclist()
        end,
        desc = "Search Location List",
        icon = "󰟙 ",
    },
    {
        "<leader>sm",
        function()
            Snacks.picker.marks()
        end,
        desc = "Search Marks",
        icon = "󰃃 ",
    },
    {
        "<leader>sM",
        function()
            Snacks.picker.man()
        end,
        desc = "Search Man Pages",
        icon = "󱓷 ",
    },
    {
        "<leader>sp",
        function()
            Snacks.picker.lazy()
        end,
        desc = "Search Plugin Spec",
        icon = "󱐥 ",
    },
    {
        "<leader>sq",
        function()
            Snacks.picker.qflist()
        end,
        desc = "Search Quickfix List",
        icon = "󰉹 ",
    },
    {
        "<leader>sR",
        function()
            Snacks.picker.resume()
        end,
        desc = "Search Resume",
        icon = "󰦛 ",
    },
    {
        "<leader>su",
        function()
            Snacks.picker.undo()
        end,
        desc = "Search Undo History",
        icon = "󰕍 ",
    },
})

-- ==========================================================
-- LSP
-- ==========================================================

-- Context-aware "goto definition" — falls back to asset-path jump or
-- CSS class grep depending on what's under the cursor.
local function goto_definition_or_css()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1

    -- 1. Asset file path jump (e.g. import "./App.css")
    if line:match("['\"].-%.css['\"]") or line:match("['\"].-%.svg['\"]") or line:match("['\"].-%.png['\"]") then
        local ok = pcall(vim.cmd, "normal! gf")
        if not ok then
            Snacks.picker.lsp_definitions()
        end
        return
    end

    -- 2. CSS class context (e.g. className="tagline")
    local before_cursor = line:sub(1, col)
    local in_class_attr = before_cursor:match("class%s*=%s*['\"][^'\"]*$")
        or before_cursor:match("className%s*=%s*['\"][^'\"]*$")

    if in_class_attr then
        local class_name = vim.fn.expand("<cword>")
        if class_name and class_name ~= "" then
            Snacks.picker.grep({
                search = class_name,
                title = "CSS Class Definition: ." .. class_name,
            })
        else
            vim.notify("No class name found under cursor", vim.log.levels.WARN)
        end
        return
    end

    -- 3. Default structural lookup (types, functions, variables)
    Snacks.picker.lsp_definitions()
end

wk.add({
    {
        "<leader>ld",
        goto_definition_or_css,
        desc = "Goto Definition / CSS Rule Search",
        icon = "󰊕 ",
    },
    {
        "<leader>lD",
        function()
            Snacks.picker.lsp_declarations()
        end,
        desc = "Goto Declaration",
        icon = "󰅴 ",
    },
    {
        "<leader>lr",
        function()
            Snacks.picker.lsp_references()
        end,
        nowait = true,
        desc = "References",
        icon = "󰌹 ",
    },
    {
        "<leader>li",
        function()
            Snacks.picker.lsp_implementations()
        end,
        desc = "Goto Implementation",
        icon = "󱀫 ",
    },
    {
        "<leader>ly",
        function()
            Snacks.picker.lsp_type_definitions()
        end,
        desc = "Goto T[y]pe Definition",
        icon = "󰰤 ",
    },
    {
        "<leader>lai",
        function()
            Snacks.picker.lsp_incoming_calls()
        end,
        desc = "C[a]lls Incoming",
        icon = "󰃺 ",
    },
    {
        "<leader>lao",
        function()
            Snacks.picker.lsp_outgoing_calls()
        end,
        desc = "C[a]lls Outgoing",
        icon = "󰃷 ",
    },
    {
        "<leader>ls",
        function()
            Snacks.picker.lsp_symbols()
        end,
        desc = "LSP Symbols",
        icon = "󰠲 ",
    },
    {
        "<leader>lS",
        function()
            Snacks.picker.lsp_workspace_symbols()
        end,
        desc = "LSP Workspace Symbols",
        icon = "󰇧 ",
    },
    {
        "<leader>lc",
        function()
            vim.lsp.buf.code_action()
        end,
        desc = "Code Action",
        icon = "󰛩 ",
    },
    {
        "<leader>ln",
        function()
            vim.lsp.buf.rename()
        end,
        desc = "Rename Symbol",
        icon = "󰑕 ",
    },
    {
        "<leader>le",
        vim.diagnostic.open_float,
        desc = "Line Diagnostics (float)",
        icon = "󰨄 ",
    },
})

-- Diagnostic navigation (mirrors ]t/[t and gitsigns' ]c/[c pattern).
-- `on_jump` opens the float the way `float = true` did; that option is
-- deprecated in 0.12 and warned on first use. Counts work too (3]d).
local function diagnostic_jump(direction)
    return function()
        vim.diagnostic.jump({
            count = direction * vim.v.count1,
            on_jump = function(_, bufnr)
                vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
            end,
        })
    end
end
vim.keymap.set("n", "]d", diagnostic_jump(1), { desc = "Next Diagnostic" })
vim.keymap.set("n", "[d", diagnostic_jump(-1), { desc = "Prev Diagnostic" })

-- ==========================================================
-- MISC / WORD REFERENCES
-- ==========================================================
wk.add({
    {
        "<c-_>",
        function()
            Snacks.terminal()
        end,
        desc = "which_key_ignore",
    },
    -- Normal mode only. They were also mapped in terminal mode, where `[[` and
    -- `]]` then could not be typed (a [[wikilink]] into the Claude Code pane
    -- jumped instead), and a lone `[` or `]` stalled for 'timeoutlen'.
    {
        "]]",
        function()
            Snacks.words.jump(vim.v.count1)
        end,
        desc = "Next Reference",
        icon = "󰌹 ",
    },
    {
        "[[",
        function()
            Snacks.words.jump(-vim.v.count1)
        end,
        desc = "Prev Reference",
        icon = "󰌹 ",
    },
    -- Bracket motions defined elsewhere: todo-comments.lua and mini.indentscope.
    { "]t", icon = "󰥪 ", real = true },
    { "[t", icon = "󰥪 ", real = true },
    { "]i", mode = { "n", "x" }, icon = "󰘡 ", real = true },
    { "[i", mode = { "n", "x" }, icon = "󰘣 ", real = true },
    -- which-key's own popup (whichkey.lua).
    { "<leader>?", icon = "󰌓 ", real = true },
    {
        "<leader>md",
        function()
            require("datepicker").open({
                week_start = "monday",
                -- What happens when you press <CR> on a date
                on_select = function(date)
                    -- Example: Insert the ISO date (e.g., 2026-04-18) at the cursor
                    vim.api.nvim_put({ date.iso }, "c", true, true)
                end,
            })
        end,
        desc = "Open date picker",
        icon = "󰢧 ",
    },
})

-- vim-table-mode's own visual-mode maps (vim-table-mode.lua). After the plugin
-- loads they carry no description, so it is given here.
wk.add({
    mode = "x",
    { "<leader>t", group = "Table", icon = "󰓫 " },
    { "<leader>tt", desc = "Tableize", icon = "󰩵 ", real = true },
    { "<leader>T", desc = "Tableize (Delimiter)", icon = "󱏂 ", real = true },
})

-- ==========================================================
-- NOTIFICATIONS & MESSAGES
-- ==========================================================
wk.add({
    {
        "<leader>nn",
        function()
            Snacks.notifier.show_history()
        end,
        desc = "Notification History",
        icon = "󰂟 ",
    },
    {
        "<leader>nd",
        function()
            Snacks.notifier.hide()
        end,
        desc = "Dismiss All Notifications",
        icon = "󰪑 ",
    },
    {
        "<leader>nl",
        function()
            require("noice").cmd("last")
        end,
        desc = "Last Message",
        icon = "󰍪 ",
    },
    {
        "<leader>nh",
        function()
            require("noice").cmd("history")
        end,
        desc = "Message History",
        icon = "󱅴 ",
    },
})

-- ==========================================================
-- ORG
-- ==========================================================
wk.add({
    { "<leader>oC", "<cmd>OrgBlocksToggle<cr>", desc = "Org calendar", icon = "󰸗 " },
    -- orgmode's own global maps.
    { "<leader>oa", icon = "󰃯 ", real = true },
    { "<leader>oc", icon = "󰎝 ", real = true },
})

-- ==========================================================
-- TOGGLES (static)
-- ==========================================================
wk.add({
    {
        "<leader>uz",
        function()
            Snacks.zen()
        end,
        desc = "Toggle Zen Mode",
        icon = "󱅻 ",
    },
    {
        "<leader>uZ",
        function()
            Snacks.zen.zoom()
        end,
        desc = "Toggle Zoom",
        icon = "󰊓 ",
    },
    {
        "<c-/>",
        function()
            Snacks.terminal()
        end,
        desc = "Toggle Terminal",
        icon = "󰆍 ",
    },
    {
        "<leader>u.",
        function()
            Snacks.scratch()
        end,
        desc = "Toggle Scratch Buffer",
        icon = "󱞂 ",
    },
    {
        "<leader>uC",
        function()
            Snacks.picker.colorschemes()
        end,
        desc = "Colorschemes",
        icon = "󰏘 ",
    },
    {
        "<leader>ut",
        "<cmd>TableModeToggle<CR>",
        desc = "Toggle Table Mode",
        icon = "󰓰 ",
    },
})

-- ==========================================================
-- TOGGLES (deferred until VeryLazy, since Snacks.toggle needs it)
-- + debug globals
-- ==========================================================
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        -- Debugging globals
        _G.dd = function(...)
            Snacks.debug.inspect(...)
        end
        _G.bt = function()
            Snacks.debug.backtrace()
        end

        -- Route `:=` output through Snacks
        if vim.fn.has("nvim-0.11") == 1 then
            vim._print = function(_, ...)
                dd(...)
            end
        else
            vim.print = _G.dd
        end

        -- Toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle
            .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
            :map("<leader>uc")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        Snacks.toggle.indent():map("<leader>ug")
        Snacks.toggle.dim():map("<leader>uD")

        -- Format on save, for this buffer (f) or everywhere (F). conform.lua
        -- reads these flags. Previously <leader>ubf / <leader>ubF, which made
        -- <leader>ub (above) both a toggle and a prefix.
        Snacks.toggle({
            name = "Format on Save (Buffer)",
            get = function()
                return not vim.b.disable_autoformat
            end,
            set = function(state)
                vim.b.disable_autoformat = not state
            end,
        }):map("<leader>uf")
        Snacks.toggle({
            name = "Format on Save (Global)",
            get = function()
                return not vim.g.disable_autoformat
            end,
            set = function(state)
                vim.g.disable_autoformat = not state
            end,
        }):map("<leader>uF")

        -- Inline math rendering: snacks.image replaces `$..$` / `$$..$$` with a
        -- rendered image, compiled as Typst or LaTeX depending on the buffer's
        -- `:MdMath` mode.  `math.enabled` is re-read every time snacks scans a
        -- buffer for images, so flipping it takes effect on the next scan --
        -- the loop below forces that scan instead of waiting for a scroll or
        -- an edit.  Ordinary images are untouched; only `type == "math"`
        -- matches are gated.
        Snacks.toggle({
            name = "Math Rendering",
            get = function()
                return Snacks.image.config.math.enabled
            end,
            set = function(state)
                Snacks.image.config.math.enabled = state
                -- Float mode (`doc.inline = false`): the only stale artifact is
                -- an open hover window.
                pcall(function()
                    require("snacks.image.doc").hover_close()
                end)
                -- Inline mode: re-run the per-buffer scan that adds/removes
                -- placements, via snacks' own autocmd group so nothing else fires.
                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].snacks_image_attached then
                        pcall(vim.api.nvim_exec_autocmds, "BufWinEnter", {
                            group = "snacks.image.inline." .. buf,
                            buffer = buf,
                        })
                    end
                end
            end,
        }):map("<leader>uM")
    end,
})

-- ==========================================================
-- WINDOW MANAGEMENT
-- ==========================================================
wk.add({
    { "<leader>rh", "<C-w>h", desc = "Move Left", icon = "⟵" },
    { "<leader>rj", "<C-w>j", desc = "Move Down", icon = "↓" },
    { "<leader>rk", "<C-w>k", desc = "Move Up", icon = "↑" },
    { "<leader>rl", "<C-w>l", desc = "Move Right", icon = "⟶" },
    { "<leader>rv", "<C-w>v", desc = "Split Vertical", icon = "󰤼 " },
    { "<leader>rs", "<C-w>s", desc = "Split Horizontal", icon = "󰤻 " },
    { "<leader>rc", "<C-w>c", desc = "Close Window", icon = "󰅗" },
    { "<leader>ro", "<C-w>o", desc = "Close Others", icon = "󰅘" },
    { "<leader>r=", "<C-w>=", desc = "Equalize Size", icon = "=" },
    { "<leader>rm", "<cmd>MaximizerToggle<CR>", desc = "Toggle Focus", icon = "󰖯 " },
})

-- Resize by two cells. (These were described as "Move Window ... Twice", but
-- they change the size, not the position.)
wk.add({
    { "<a-h>", "<C-w>><C-w>>", desc = "Increase Window Width", icon = "󰡎 " },
    { "<a-l>", "<C-w><<C-w><", desc = "Decrease Window Width", icon = "󰡌 " },
    { "<a-k>", "<C-w>+<C-w>+", desc = "Increase Window Height", icon = "󰡏 " },
    { "<a-j>", "<C-w>-<C-w>-", desc = "Decrease Window Height", icon = "󰡍 " },
})

-- ==========================================================
-- AI (Claude Code)
-- ==========================================================
wk.add({
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude", icon = "󱙺 " },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude", icon = "󰓾 " },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude", icon = "󰐍 " },
    {
        "<leader>aC",
        "<cmd>ClaudeCode --continue<cr>",
        desc = "Continue Claude",
        icon = "󰙢 ",
    },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model", icon = "󰧑 " },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer", icon = "󰻭 " },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "x", desc = "Send to Claude", icon = "󱅥 " },
    -- In file trees, <leader>as adds the file under the cursor (autocmd below).
    { "<leader>as", mode = "n", icon = "󱀹 ", real = true },
    -- Diff management
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff", icon = "󰗡 " },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff", icon = "󰜺 " },
})

-- Buffer-local, set per filetype. This was a which-key entry with an `ft`
-- field, which which-key does not have (`:checkhealth which-key` reported it
-- as an error), so the mapping ended up global.
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("sybil-claude-tree-add", { clear = true }),
    pattern = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw", "snacks_picker_list" },
    callback = function(ev)
        keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", { buffer = ev.buf, desc = "Add file" })
    end,
})

-- ==========================================================
-- ARROW (Buffer Bookmarks)
-- ==========================================================
-- Lazy requires, so arrow.nvim only loads on first use. They must not also be
-- in arrow.lua's `keys` (see the comment there).
wk.add({
    {
        "H",
        function()
            require("arrow.persist").previous()
        end,
        desc = "Go to previous Arrow mark",
        icon = "󰁐 ",
    },
    {
        "L",
        function()
            require("arrow.persist").next()
        end,
        desc = "Go to next Arrow mark",
        icon = "󰁗 ",
    },
    {
        "<c-s>",
        function()
            require("arrow.persist").toggle()
        end,
        desc = "Toggle Arrow mark at cursor",
        icon = "󰃄 ",
    },
})

-- <A-1>..<A-9> jump to marks 1-9 and <A-0> to mark 10. (<A-0> used to call
-- go_to(0), which is not a valid index, so it did nothing.)
local arrow_slot_icons = {
    "󰎦 ",
    "󰎩 ",
    "󰎬 ",
    "󰎮 ",
    "󰎰 ",
    "󰎵 ",
    "󰎸 ",
    "󰎻 ",
    "󰎾 ",
    "󰽾 ",
}
for i = 1, 10 do
    wk.add({
        {
            "<A-" .. (i % 10) .. ">",
            function()
                require("arrow.persist").go_to(i)
            end,
            desc = "Jump to Arrow " .. i,
            icon = arrow_slot_icons[i],
        },
    })
end
