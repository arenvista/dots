return {
  "dzejkop/datepicker.nvim",
  dependencies = { 
    "folke/snacks.nvim", 
  },
  config = function()
    vim.keymap.set("n", "<leader>md", function()
      require("datepicker").open({
        week_start = "monday",
        -- What happens when you press <CR> on a date
        on_select = function(date)
          -- Example: Insert the ISO date (e.g., 2026-04-18) at the cursor
          vim.api.nvim_put({ date.iso }, "c", true, true)
        end,
      })
    end, { desc = "Open date picker" })
  end,
}
