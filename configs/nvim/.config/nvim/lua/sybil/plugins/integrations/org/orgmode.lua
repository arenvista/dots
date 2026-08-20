return {
	"nvim-orgmode/orgmode",
	dependencies = {
		"hamidi-dev/org-super-agenda.nvim",
		"nvim-telescope/telescope.nvim",
		-- { 'lukas-reineke/headlines.nvim', config = true }, -- optional nicety
		"nvim-orgmode/telescope-orgmode.nvim",
		"nvim-orgmode/org-bullets.nvim",
		"danilshvalov/org-modern.nvim",
		-- 'Saghen/blink.cmp'
	},
	event = "VeryLazy",
    ft = "org",
	config = function()
		require("orgmode").setup({
			-- See => https://github.com/nvim-orgmode/orgmode/blob/master/docs/configuration.org
			org_agenda_files = "~/orgfiles/**/*",
			org_default_notes_file = "~/orgfiles/refile.org",
			org_todo_keywords = {
				"TODO",
				"PROG",
				"WAIT",
				"|",
				"DONE",
			},
			org_todo_keyword_faces = {
				-- specific keyword  =  properties string
				TODO = ":foreground #FF5555 :weight bold :slant italic",
				WAIT = ":foreground #BD93F9 :weight bold :slant italic",
				PROG = ":foreground #FFAA00  :weight bold",
				DONE = ":foreground #50FA7B :weight bold",
			},
			win_border = "rounded",
			org_agenda_use_time_grid = true,
			org_agenda_time_grid = {
				type = { "daily", "today", "require-timed" },
				times = { 800, 1000, 1200, 1400, 1600, 1800, 2000 },
				time_separator = "―――――",
				time_label = "―――――――――――――――",
			},
			org_deadline_warning_days = 0,
			org_agenda_current_time_string = "↞―― CURRENT ―――",
			vim.api.nvim_set_hl(0, "@org.agenda.time_grid", { fg = "#5c5f77", bold = true }),

			org_agenda_custom_commands = {
				-- "c" is the shortcut that will be used in the prompt
				c = {
					description = "Combined view", -- Description shown in the prompt for the shortcut
					types = {
						{
							type = "tags_todo", -- Type can be agenda | tags | tags_todo
							match = '+PRIORITY="A"', --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
							org_agenda_overriding_header = "High priority todos",
							org_agenda_todo_ignore_deadlines = "far", -- Ignore all deadlines that are too far in future (over org_deadline_warning_days). Possible values: all | near | far | past | future
						},
						{
							type = "agenda",
							org_agenda_overriding_header = "My daily agenda",
							org_agenda_span = "day", -- can be any value as org_agenda_span
						},
						{
							type = "agenda",
							org_agenda_overriding_header = "Whole week overview",
							org_agenda_span = "week", -- 'week' is default, so it's not necessary here, just an example
							org_agenda_start_on_weekday = 1, -- Start on Monday
							org_agenda_remove_tags = true, -- Do not show tags only for this view
						},
					},
				},
				d = {
					description = "Clean Day",
					types = {
						{
							org_agenda_overriding_header = "xxx",
							type = "agenda",
							org_agenda_span = "day", -- can be any value as org_agenda_span
						},
					},
				},
				f = {
					description = "14-Day View",
					types = {
						{
							type = "agenda",
							org_agenda_overriding_header = "14-Day View",
							org_agenda_span = 14, -- 'week' is default, so it's not necessary here, just an example
							org_agenda_start_on_weekday = false, -- Start on Monday
							org_agenda_remove_tags = false, -- Do not show tags only for this view
							org_agenda_skip_scheduled_if_done = false,
							org_agenda_skip_deadline_if_done = false,
						},
					},
				},
				m = {
					description = "30-Day View",
					types = {
						{
							type = "agenda",
							org_agenda_overriding_header = "30-Day View",
							org_agenda_span = 30, -- 'week' is default, so it's not necessary here, just an example
							org_agenda_start_on_weekday = false, -- Start on Monday
							org_agenda_remove_tags = false, -- Do not show tags only for this view
						},
					},
				},
			},
		})

		require("org-bullets").setup({
			concealcursor = false,
			symbols = {
				list = "•",
				headlines = {
					{ "◉", "MyBulletL1" },
					{ "○", "MyBulletL2" },
					{ "⏵", "MyBulletL3" },
					{ "⏩", "MyBulletL4" },
				},
				checkboxes = {
					half = { "⍻", "@org.checkbox.halfchecked" },
					done = { "✓", "@org.keyword.done" },
					todo = { "", "@org.keyword.todo" },
				},
				vim.api.nvim_set_hl(0, "@org.checkbox.halfchecked", { link = "@constructor" }),
			},
		})

		local Menu = require("org-modern.menu")

		require("orgmode").setup({
			ui = {
				menu = {
					handler = function(data)
						Menu:new({
							window = {
								margin = { 1, 0, 1, 0 },
								padding = { 0, 1, 0, 1 },
								title_pos = "center",
								border = "single",
								zindex = 1000,
							},
							icons = {
								separator = "➜",
							},
						}):open(data)
					end,
				},
			},
		})

		vim.api.nvim_set_hl(0, "@org.priority.highest", { link = "@comment.error" })
		vim.api.nvim_set_hl(0, "@org.priority.default", { bg = "#ef9f76", fg = "#292c3c" })
		vim.api.nvim_set_hl(0, "@org.priority.lowest", { bg = "#f9e2af", fg = "#292c3c" })

		local org_agenda_colors = vim.api.nvim_create_augroup("OrgAgendaCustomColors", { clear = true })

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "orgagenda",
			group = org_agenda_colors,
			callback = function()
				-- 1. Define the specific look you want for the "CURRENT" line
				vim.api.nvim_set_hl(0, "OrgAgendaCurrentTime", {
					fg = "#dce0e8",
					bg = "NONE",
					bold = true,
				})

				-- 2. Use matchadd to force this highlight on your specific string
				-- Priority 100 is usually high enough to override Tree-sitter/TimeGrid
				vim.fn.matchadd("OrgAgendaCurrentTime", "――――― ↞―― CURRENT ―――", 100)
			end,
		})
		vim.lsp.enable("org")
	end,
}
