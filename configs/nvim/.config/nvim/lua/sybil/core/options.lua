-------------------------------------------------------------------------------
-- KEYBOARD LEADERS
-------------------------------------------------------------------------------
vim.g.mapleader = " " -- Sets the main leader key to Space
vim.g.maplocalleader = "\\" -- Sets the local leader (often used for filetype-specific plugins)

-------------------------------------------------------------------------------
-- UI & VISUALS
-------------------------------------------------------------------------------
local opt = vim.opt

opt.nu = true -- Show absolute line number for the current line
opt.relativenumber = true -- Show relative line numbers for easier jumping
opt.cursorline = true -- Highlight the line where the cursor is currently sitting
opt.termguicolors = true -- Enable 24-bit RGB colors
opt.background = "dark" -- Tell Neovim to use colors suited for a dark background
opt.signcolumn = "yes" -- Always show the sign column (prevents "shifting" text)
opt.wrap = false -- Don't wrap long lines
opt.scrolloff = 8 -- Keep at least 8 lines visible above/below the cursor
opt.conceallevel = 0 -- Show concealable text as-is (<leader>uc toggles concealing)
opt.guicursor =
    "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"

-------------------------------------------------------------------------------
-- CUSTOM HIGHLIGHTS (Line Numbers)
-------------------------------------------------------------------------------
-- Set in the colorscheme's `custom_highlights` (plugins/ui/theme/cattpuccin.lua)
-- rather than here: set here, they were overwritten by the colorscheme (LineNr)
-- or wiped on the next reload, e.g. by the <leader>ub background toggle.

-------------------------------------------------------------------------------
-- SEARCH SETTINGS
-------------------------------------------------------------------------------
opt.ignorecase = true -- Ignore case in search patterns
opt.smartcase = true -- ...unless the search query contains an uppercase letter
vim.opt.hlsearch = false -- Clear highlights after search is done
vim.opt.incsearch = true -- Show search results as you type

-------------------------------------------------------------------------------
-- TABS & INDENTATION
-------------------------------------------------------------------------------
opt.tabstop = 4 -- Number of visual spaces per TAB
opt.softtabstop = 4 -- Number of spaces a TAB counts for while editing
opt.shiftwidth = 4 -- Number of spaces to use for auto-indentation
opt.expandtab = true -- Convert tabs to spaces
opt.smartindent = true -- Makes indentation "smart" (e.g., after opening a bracket)

-------------------------------------------------------------------------------
-- PERFORMANCE & SYSTEM
-------------------------------------------------------------------------------
opt.updatetime = 250 -- Faster completion and trigger for CursorHold (ms)
opt.timeoutlen = 300 -- Time to wait for a mapped sequence to complete
opt.ttimeoutlen = 50 -- Time to wait for a key code sequence to complete.
-- 10ms was too tight: without tmux extended-keys, Alt+<key> arrives as ESC+<key>,
-- and a late-arriving second byte got read as bare <Esc> plus a motion.
opt.shada = "'100,<50,s10,h" -- Shared Data: controls what is saved between sessions
opt.isfname:append("@-@") -- Include '@' in file name recognition
opt.backspace = "indent,eol,start" -- Allow backspacing over everything in insert mode

-------------------------------------------------------------------------------
-- UNDO & BACKUP (Persistence)
-------------------------------------------------------------------------------
opt.swapfile = false -- Disable swap files
opt.backup = false -- Disable backup files
opt.undofile = true -- Save undo history to a file
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-------------------------------------------------------------------------------
-- FILE EXPLORER & LANGUAGES
-------------------------------------------------------------------------------
vim.cmd("let g:netrw_liststyle = 3") -- Tree view for Netrw
vim.opt.spelllang = "en" -- Set spelling language to English
vim.g.markdown_fenced_languages = { "javascript", "typescript", "bash", "lua", "go", "rust", "c", "cpp", "python" }
-- Resolve .h as C. Set here rather than in a plugin config: nvim's builtin rule
-- guesses c vs cpp from buffer contents, so a lazily-registered override only
-- takes effect from the first file opened after that plugin loads.
vim.g.c_syntax_for_h = 1
vim.filetype.add({ extension = { h = "c" } })
vim.env.TEXINPUTS = "/home/sybil/.tex_templates//:" -- TeX template path

-------------------------------------------------------------------------------
-- WINDOW SPLITS
-------------------------------------------------------------------------------
opt.splitright = true -- Open new vertical splits to the right
opt.splitbelow = true -- Open new horizontal splits below
