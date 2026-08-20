local wk = require("which-key")
local keymap = vim.keymap

-- ==========================================================
-- LEADER KEYS
-- ==========================================================
vim.g.mapleader = " "
vim.g.localleader = "\\"

_G.Snacks = Snacks -- Snacks is defined in snacks.lua; loaded before this file.

-- ==========================================================
-- STANDARD KEYMAPS (non-leader)
-- ==========================================================
keymap.set("n", "<C-f>f", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "Tmux Sessionizer" })
keymap.set("n", "<C-f>s", "<cmd>silent !tmux neww tmux-attacher<CR>", { desc = "Tmux Attacher" })

keymap.set({ "n", "i", "v" }, "<C-c>", "<Esc>", { desc = "Rebind ESC to CTRL+C" })
keymap.set({ "n", "i", "v" }, "<Del>", "<Esc>")

keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move highlighted lines down" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move highlighted lines up" })

-- ==========================================================
-- WHICH-KEY GROUPS
-- ==========================================================
wk.add({
    { "<leader>b", group = "Buffer", icon = "󰓩 " },
    { "<leader>q", group = "Quit & Session", icon = "󰗼 " },
    { "<leader>s", group = "Search", icon = " " },
    { "<leader>l", group = "LSP", icon = "󱐋 " },
    { "<leader>x", group = "Registers", icon = "󱉵 " },
    { "<leader>u", group = "Toggle", icon = " " },
    { "<leader>g", group = "Git", icon = "󰊢 " },
    { "<leader>e", group = "Explorers", icon = "󰭈 " },
    { "<leader>o", group = "Org", icon = " " },
    { "<leader>f", group = "Finder", icon = "  " },
    { "<leader><c-f>", group = "Tmux", icon = " " },
    { "<leader>a", group = "AI", icon = "  " },
    { "<leader>n", group = "Notifications", icon = "󰎟  " },
    { "<leader>m", group = "Misc.", icon = "  " },
    { "<leader>r", group = "Windows", icon = " " },
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
    },
    {
        "<leader>bd",
        function()
            Snacks.bufdelete()
        end,
        desc = "Delete Buffer",
    },

    -- Clipboard & Registers
    { "<leader>y", [["+y]], desc = "which_key_ignore", mode = { "n", "v" }, icon = "" },
    { "<leader>Y", [["+Y]], desc = "which_key_ignore", mode = "n", icon = "" },
    { "<leader>p", [["_dP]], desc = "which_key_ignore", mode = "x", icon = "" },
    { "<leader>p", [["+p]], desc = "which_key_ignore", mode = { "n", "v" }, icon = "" },
    { "<leader>P", [["+P]], desc = "which_key_ignore", mode = { "n", "v" }, icon = "" },

    -- Save, Quit & Window Close
    { "<leader>w", "<cmd>w<CR>", desc = "which_key_ignore", mode = "n", icon = " " },
    { "<leader>qa", "<cmd>qa<CR>", desc = "Quit All", mode = "n" },
    { "<leader>qx", "<cmd>qa!<CR>", desc = "Quit All Force", mode = "n" },
    { "<leader>qo", "<C-w>o", desc = "Close Others", icon = "󰈆 " },
    { "<leader>qw", "<cmd>q<CR>", desc = "Close Window", mode = "n" },
    { "<c-x>", "<cmd>q<CR>", desc = "Close Window", mode = "n" },
})

-- ==========================================================
-- EXPLORERS
-- ==========================================================
wk.add({
    { "<leader>ee", vim.cmd.Neotree, desc = " Neotree", mode = "n" },
    { "<leader>ea", "<cmd>AerialToggle!<CR>", desc = "Aerial", mode = "n" },
    {
        "<leader>eo",
        function()
            require("oil").open()
        end,
        desc = "󰼙 Oil & Vinegar",
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
        icon = " ",
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
        icon = "",
    },
    {
        "<leader>gdh",
        "<cmd>diffget //2<CR>",
        desc = "Get Left Hunk",
        icon = "",
    },
    {
        "<leader>gdl",
        "<cmd>diffget //3<CR>",
        desc = "Get Right Hunk",
        icon = "",
    },
    {
        "<leader>gb",
        function()
            Snacks.picker.git_branches()
        end,
        desc = "Git Branches",
        icon = " ",
    },
    { "<leader>gf", "<cmd>tab Git<cr>", desc = "Fugitive", icon = "󰊤" },
    {
        "<leader>gl",
        function()
            Snacks.picker.git_log()
        end,
        desc = "Git Log",
        icon = " ",
    },
    {
        "<leader>gL",
        function()
            Snacks.picker.git_log_line()
        end,
        desc = "Git Log Line",
        icon = " ",
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
        icon = " ",
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
        icon = " ",
    },
    {
        "<leader>gI",
        function()
            Snacks.picker.gh_issue({ state = "all" })
        end,
        desc = "GitHub Issues (all)",
        icon = " ",
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
        icon = " ",
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
        mode = { "n", "v" },
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
        icon = " ",
    },
    {
        "<leader>s/",
        function()
            Snacks.picker.search_history()
        end,
        desc = "Search History",
        icon = " ",
    },
    {
        "<leader>sa",
        function()
            Snacks.picker.autocmds()
        end,
        desc = "Search Autocmds",
        icon = " ",
    },
    {
        "<leader>sb",
        function()
            Snacks.picker.lines()
        end,
        desc = "Search Buffer Lines",
        icon = " ",
    },
    {
        "<leader>sc",
        function()
            Snacks.picker.command_history()
        end,
        desc = "Search Command History",
        icon = " ",
    },
    {
        "<leader>sC",
        function()
            Snacks.picker.commands()
        end,
        desc = "Search Commands",
        icon = " ",
    },
    {
        "<leader>sd",
        function()
            Snacks.picker.diagnostics()
        end,
        desc = "Search Diagnostics",
        icon = " ",
    },
    {
        "<leader>sD",
        function()
            Snacks.picker.diagnostics_buffer()
        end,
        desc = "Search Buffer Diagnostics",
        icon = " ",
    },
    {
        "<leader>sh",
        function()
            Snacks.picker.help()
        end,
        desc = "Search Help Pages",
        icon = " ",
    },
    {
        "<leader>sH",
        function()
            Snacks.picker.highlights()
        end,
        desc = "Search Highlights",
        icon = " ",
    },
    {
        "<leader>si",
        function()
            Snacks.picker.icons()
        end,
        desc = "Search Icons",
        icon = " ",
    },
    {
        "<leader>sj",
        function()
            Snacks.picker.jumps()
        end,
        desc = "Search Jumps",
        icon = " ",
    },
    {
        "<leader>sk",
        function()
            Snacks.picker.keymaps()
        end,
        desc = "Search Keymaps",
        icon = " ",
    },
    {
        "<leader>sl",
        function()
            Snacks.picker.loclist()
        end,
        desc = "Search Location List",
        icon = " ",
    },
    {
        "<leader>sm",
        function()
            Snacks.picker.marks()
        end,
        desc = "Search Marks",
        icon = " ",
    },
    {
        "<leader>sM",
        function()
            Snacks.picker.man()
        end,
        desc = "Search Man Pages",
        icon = " ",
    },
    {
        "<leader>sp",
        function()
            Snacks.picker.lazy()
        end,
        desc = "Search Plugin Spec",
        icon = " ",
    },
    {
        "<leader>sq",
        function()
            Snacks.picker.qflist()
        end,
        desc = "Search Quickfix List",
        icon = " ",
    },
    {
        "<leader>sR",
        function()
            Snacks.picker.resume()
        end,
        desc = "Search Resume",
        icon = " ",
    },
    {
        "<leader>su",
        function()
            Snacks.picker.undo()
        end,
        desc = "Search Undo History",
        icon = " ",
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
    { "<leader>ld", goto_definition_or_css, desc = "Goto Definition / CSS Rule Search" },
    {
        "<leader>lD",
        function()
            Snacks.picker.lsp_declarations()
        end,
        desc = "Goto Declaration",
    },
    {
        "<leader>lr",
        function()
            Snacks.picker.lsp_references()
        end,
        nowait = true,
        desc = "References",
    },
    {
        "<leader>li",
        function()
            Snacks.picker.lsp_implementations()
        end,
        desc = "Goto Implementation",
    },
    {
        "<leader>ly",
        function()
            Snacks.picker.lsp_type_definitions()
        end,
        desc = "Goto T[y]pe Definition",
    },
    {
        "<leader>lai",
        function()
            Snacks.picker.lsp_incoming_calls()
        end,
        desc = "C[a]lls Incoming",
    },
    {
        "<leader>lao",
        function()
            Snacks.picker.lsp_outgoing_calls()
        end,
        desc = "C[a]lls Outgoing",
    },
    {
        "<leader>ls",
        function()
            Snacks.picker.lsp_symbols()
        end,
        desc = "LSP Symbols",
    },
    {
        "<leader>lS",
        function()
            Snacks.picker.lsp_workspace_symbols()
        end,
        desc = "LSP Workspace Symbols",
    },
    {
        "<leader>lc",
        function()
            vim.lsp.buf.code_action()
        end,
        desc = "Code Action",
    },
    {
        "<leader>ln",
        function()
            vim.lsp.buf.rename()
        end,
        desc = "Rename Symbol",
    },
    { "<leader>le", vim.diagnostic.open_float, desc = "Line Diagnostics (float)" },
})

-- Diagnostic navigation (mirrors ]t/[t and gitsigns' ]c/[c pattern)
vim.keymap.set("n", "]d", function()
    vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next Diagnostic" })
vim.keymap.set("n", "[d", function()
    vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev Diagnostic" })

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
    {
        "]]",
        function()
            Snacks.words.jump(vim.v.count1)
        end,
        desc = "Next Reference",
        mode = { "n", "t" },
    },
    {
        "[[",
        function()
            Snacks.words.jump(-vim.v.count1)
        end,
        desc = "Prev Reference",
        mode = { "n", "t" },
    },
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
    },
    {
        "<leader>nd",
        function()
            Snacks.notifier.hide()
        end,
        desc = "Dismiss All Notifications",
    },
    {
        "<leader>nl",
        function()
            require("noice").cmd("last")
        end,
        desc = "Last Message",
    },
    {
        "<leader>nh",
        function()
            require("noice").cmd("history")
        end,
        desc = "Message History",
    },
})

-- ==========================================================
-- TOGGLES (static)
-- ==========================================================
wk.add({
    { "<leader>oC", "<cmd>OrgBlocksToggle<cr>", desc = "Org calendar" },
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
    },
    {
        "<leader>uZ",
        function()
            Snacks.zen.zoom()
        end,
        desc = "Toggle Zoom",
    },
    {
        "<c-/>",
        function()
            Snacks.terminal()
        end,
        desc = "Toggle Terminal",
    },
    {
        "<leader>u.",
        function()
            Snacks.scratch()
        end,
        desc = "Toggle Scratch Buffer",
    },
    {
        "<leader>uC",
        function()
            Snacks.picker.colorschemes()
        end,
        desc = "Colorschemes",
    },
    {
        "<leader>ut",
        "<cmd>TableModeToggle<CR>",
        desc = "Toggle Table Mode",
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
    { "<leader>rm", "<cmd>MaximizerToggle<CR>", desc = "Toggle Focus", icon = "" },
})

vim.keymap.set("n", "<a-h>", "<C-w>><C-w>>", { desc = "Move Window Left Twice" })
vim.keymap.set("n", "<a-l>", "<C-w><<C-w><", { desc = "Move Window Right Twice" })
vim.keymap.set("n", "<a-k>", "<C-w>+<C-w>+", { desc = "Move Window Upper Twice" })
vim.keymap.set("n", "<a-j>", "<C-w>-<C-w>-", { desc = "Move Window Down Twice" })

-- ==========================================================
-- AI (CodeCompanion)
-- ==========================================================
wk.add({
    { "<leader>aa", ":'<,'>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "AI Actions Palette" },
    { "<leader>ac", ":'<,'>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "AI Toggle Chat" },
    { "<leader>ai", ":'<,'>CodeCompanion<cr>", mode = { "n", "v" }, desc = "AI Inline Prompt" },
})

-- ==========================================================
-- ARROW (Buffer Bookmarks)
-- ==========================================================
-- Wrap in lazy requires so arrow.nvim only loads on first use (see arrow.lua `keys`).
vim.keymap.set("n", "H", function()
    require("arrow.persist").previous()
end, { desc = "Go to previous Arrow mark" })
vim.keymap.set("n", "L", function()
    require("arrow.persist").next()
end, { desc = "Go to next Arrow mark" })
vim.keymap.set("n", "<c-s>", function()
    require("arrow.persist").toggle()
end, { desc = "Toggle Arrow mark at cursor" })

for i = 1, 9 do
    vim.keymap.set("n", "<A-" .. i .. ">", function()
        require("arrow.persist").go_to(i)
    end, { desc = "Jump to Arrow " .. i })
end
vim.keymap.set("n", "<A-0>", function()
    require("arrow.persist").go_to(0)
end, { desc = "Jump to Arrow 10" })
