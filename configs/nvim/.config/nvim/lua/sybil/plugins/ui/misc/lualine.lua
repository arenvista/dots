return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	config = function()
		local config = require("lualine")

		config.setup({
			options = {
				icons_enabled = true,
				theme = "auto",
				refresh = {
					statusline = 100, -- default 100
				},
			},
			sections = {
				-- Add the macro recording status in the mode section.
				-- lualine's own `mode` component supplies the names (NORMAL,
				-- V-BLOCK, O-PENDING, ...); the hand-rolled table this replaces
				-- keyed V-BLOCK/S-BLOCK as the two-character strings "^V"/"^S",
				-- which never match the real "\22"/"\19", so those modes showed
				-- a raw control character.
				lualine_a = {
					{
						"mode",
						fmt = function(mode)
							local reg = vim.fn.reg_recording()
							-- If a macro is being recorded, show "Recording @<register>"
							return reg ~= "" and ("Recording @" .. reg) or mode
						end,
					},
				},
			},
		})
	end,
}
