--@enum MILLI_SHADERS
-- local MILLI_SHADERS = {
-- 	attackontitan = "attackontitan",
-- 	aurora = "aurora",
-- 	badge = "badge",
-- 	blackhole = "blackhole",
-- 	cactus = "cactus",
-- 	catwoman = "catwoman",
-- 	chrome = "chrome",
-- 	dancer = "dancer",
-- 	dancerramp = "dancerramp",
-- 	finger = "finger",
-- 	fire = "fire",
-- 	flyingcat = "flyingcat",
-- 	flyingdragon = "flyingdragon",
-- 	ididnot = "ididnot",
-- 	lighningtornado = "lighningtornado",
-- 	lights = "lights",
-- 	retrocircle = "retrocircle",
-- 	robot = "robot",
-- 	shader = "shader",
-- 	shadertwo = "shadertwo",
-- 	skeleton = "skeleton",
-- 	skullone = "skullone",
-- 	skullthree = "skullthree",
-- 	skulltwo = "skulltwo",
-- 	spaceship = "spaceship",
-- 	spinner = "spinner",
-- 	vibecat = "vibecat",
-- 	vibecattwo = "vibecattwo",
-- }
--
-- MILI_SHADER = MILLI_SHADERS.shader

--@param mili_shader MILLI_SHADERS
-- local milli_opts = function(milli_shader)
-- 	local splash = require("milli").load({ splash = milli_shader })
-- 	local dashboard = {
-- 		enabled = true,
-- 		preset = {
-- 			header = table.concat(splash.frames[1], "\n"),
-- 		},
-- 		sections = {
-- 			{ section = "header", padding = 1 },
-- 			{ section = "keys", gap = 1, padding = 1 },
-- 			{ section = "startup" },
-- 		},
-- 	}
-- 	return dashboard
-- end

return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	-- dependencies = { "amansingh-afk/milli.nvim" },
	---@type snacks.Config
	opts = function()
		return {
			-- dashboard = milli_opts(MILI_SHADER),
			dashboard = { enabled = true},
			animate = { enabled = true },
			bigfile = { enabled = true },
			bufdelete = { enabled = true },
			debug = { enabled = true },
			dim = { enabled = true },
			explorer = { enabled = true },
			gh = { enabled = true },
			git = { enabled = true },
			gitbrowse = { enabled = true },
			image = {
				enabled = true,
				doc = {
					-- enable image viewer for documents
					-- a treesitter parser must be available for the enabled languages.
					-- supported language injections: markdown, html
					enabled = true,
					-- render the image inline in the buffer
					-- if your env doesn't support unicode placeholders, this will be disabled
					-- takes precedence over `opts.float` on supported terminals
					inline = false,
					-- render the image in a floating window
					-- only used if `opts.inline` is disabled
					float = true,
					max_width = 40,
					max_height = 40,
				},
				math = {
					enabled = true, -- enable math expression rendering
					-- in the templates below, `${header}` comes from any section in your document,
					-- between a start/end header comment. Comment syntax is language-specific.
					-- * start comment: `// snacks: header start`
					-- * end comment:   `// snacks: header end`
					typst = {
						tpl = [[
        #set page(width: auto, height: auto, margin: (x: 2pt, y: 1pt))
        #show math.equation.where(block: false): set text(top-edge: "bounds", bottom-edge: "bounds")
        #set text(size: 12pt, fill: rgb("${color}"))
        ${header}
        ${content}]],
					},
					latex = {
						font_size = "Large", -- see https://www.sascha-frank.com/latex-font-size.html
						-- for latex documents, the doc packages are included automatically,
						-- but you can add more packages here. Useful for markdown documents.
						packages = { "amsmath", "amssymb", "amsfonts", "amscd", "mathtools" },
						tpl = [[
        \documentclass[preview,border=0pt,varwidth,12pt]{standalone}
        \usepackage{${packages}}
        \begin{document}
        ${header}
        { \${font_size} \selectfont
          \color[HTML]{${color}}
        ${content}}
        \end{document}]],
					},
				},
			},
			indent = { enabled = true },
			input = { enabled = true },
			keymap = { enabled = true },
			layout = { enabled = true },
			lazygit = { enabled = true },
			notifier = { enabled = true },
			notify = { enabled = true },
			picker = { enabled = true },
			profiler = { enabled = true },
			quickfile = { enabled = true },
			rename = { enabled = true },
			scope = { enabled = true },
			scratch = { enabled = true },
			-- scroll = { enabled = true },
			statuscolumn = { enabled = true },
			terminal = { enabled = true },
			toggle = { enabled = true },
			util = { enabled = true },
			win = { enabled = true },
			words = { enabled = true },
			zen = { enabled = true },
			styles = {
				notification = {
					wo = { wrap = true }, -- Wrap notifications
				},
			},
		}
	end,
	config = function(_, opts)
		require("snacks").setup(opts)
		-- require("milli").snacks({ splash = MILI_SHADER, loop = true })
	end,
}
