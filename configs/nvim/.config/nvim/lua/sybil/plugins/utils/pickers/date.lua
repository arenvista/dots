-- Date picker. <leader>md (maps.lua) opens it, loading the plugin on first use.
return {
  "dzejkop/datepicker.nvim",
  lazy = true,
  dependencies = {
    "folke/snacks.nvim",
  },
}
