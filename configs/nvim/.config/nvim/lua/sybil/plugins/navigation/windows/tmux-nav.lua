return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
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
