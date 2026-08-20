return {
	"vzze/calculator.nvim",
	vim.api.nvim_create_user_command(
		"Calculate",
		'lua require("calculator").calculate()',
		{ ["range"] = 1, ["nargs"] = 0 }
	),
	-- config = function()
	-- 	vim.keymap.set("v", "<leader>c", function()
	-- 		require("calculator").calculate()
	-- 	end, { desc = "Calculate selection" })
	-- end,
}
