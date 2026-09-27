return {
	"vzze/calculator.nvim",
	-- The command is created up front and pulls the plugin in on first use,
	-- instead of the plugin loading at startup.
	lazy = true,
	init = function()
		vim.api.nvim_create_user_command(
			"Calculate",
			'lua require("calculator").calculate()',
			{ ["range"] = 1, ["nargs"] = 0 }
		)
	end,
	-- config = function()
	-- 	vim.keymap.set("v", "<leader>c", function()
	-- 		require("calculator").calculate()
	-- 	end, { desc = "Calculate selection" })
	-- end,
}
