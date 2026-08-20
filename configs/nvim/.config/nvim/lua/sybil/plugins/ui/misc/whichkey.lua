return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "helix", -- The 'modern' preset gives you the floating window look
		win = {
			border = "rounded", -- Adds the rounded borders
			padding = { 1, 2 }, -- Adds some spacing inside the window
		},
		icons = {
			mappings = true, -- Ensures icons are displayed next to the descriptions
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
	},
}
