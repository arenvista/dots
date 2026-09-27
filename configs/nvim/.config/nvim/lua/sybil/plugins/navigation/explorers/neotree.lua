return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      -- LSP-aware renames/moves from the tree (moved here from lspconfig.lua,
      -- where it forced neo-tree to load on every file open).
      { "antosha417/nvim-lsp-file-operations", config = true },
      -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    }
}
