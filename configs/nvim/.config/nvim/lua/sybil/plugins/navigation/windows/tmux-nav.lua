return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  init = function()
    -- The plugin's own maps clobber ours on load. Inside tmux it adds
    -- Vim-style tmaps (`<C-w>:TmuxNavigateLeft`) which nvim types into the
    -- terminal as text, e.g. into the Claude pane. Keep only its netrw <C-l>
    -- workaround, which lives in the same skipped block.
    vim.g.tmux_navigator_no_mappings = 1
    vim.g.Netrw_UserMaps = { { "<C-l>", "<C-U>TmuxNavigateRight<cr>" } }
  end,
  -- Normal-mode only. Terminal-mode <C-hjkl> are defined eagerly in maps.lua:
  -- lazy's `keys` handler registers an <expr> stub, which does not fire
  -- correctly in terminal mode -- the command text ends up typed into the
  -- terminal instead of being executed.
  keys = {
    { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate left" },
    { "<c-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate down" },
    { "<c-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate up" },
    { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate right" },
    { "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate to previous pane" },
  },
}
