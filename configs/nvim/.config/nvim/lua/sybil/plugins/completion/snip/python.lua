local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

return {
	-- ==========================================
	-- 1. BOILERPLATE & IMPORTS
	-- ==========================================

	-- SHEBANG
	s(
		{ trig = "#!", snippetType = "snippet" },
		fmta(
			[[
        #!/usr/bin/env python3
        <>
        ]],
			{ i(0) }
		)
	),

	-- MAIN CHECK (if __name__ == "__main__":)
	s(
		{ trig = "ifmain", snippetType = "snippet" },
		fmta(
			[[
        if __name__ == "__main__":
            <>
        ]],
			{ i(0) }
		)
	),

	-- IMPORT
	s({ trig = "imp", snippetType = "snippet" }, fmta("import <>", { i(1) })),

	-- FROM IMPORT
	s({ trig = "fim", snippetType = "snippet" }, fmta("from <> import <>", { i(1, "module"), i(2, "item") })),

	-- ==========================================
	-- 2. FUNCTIONS & CLASSES
	-- ==========================================

	-- FUNCTION DEFINITION
	s(
		{ trig = "def", snippetType = "snippet" },
		fmta(
			[[
        def <>(<>):
            <>
        ]],
			{ i(1, "func_name"), i(2, "args"), i(0) }
		)
	),

	-- METHOD (with self)
	s(
		{ trig = "defs", snippetType = "snippet" },
		fmta(
			[[
        def <>(self, <>):
            <>
        ]],
			{ i(1, "method_name"), i(2, "args"), i(0) }
		)
	),

	-- INIT (__init__)
	s(
		{ trig = "init", snippetType = "snippet" },
		fmta(
			[[
        def __init__(self, <>):
            <>
        ]],
			{ i(1, "args"), i(0) }
		)
	),

	-- CLASS
	s(
		{ trig = "cl", snippetType = "snippet" },
		fmta(
			[[
        class <>:
            def __init__(self, <>):
                <>
        ]],
			{ i(1, "ClassName"), i(2, "args"), i(0) }
		)
	),

	-- DATACLASS
	s(
		{ trig = "dcl", snippetType = "snippet" },
		fmta(
			[[
        @dataclass
        class <>:
            <>: <>
        ]],
			{ i(1, "ClassName"), i(2, "field"), i(3, "Type") }
		)
	),

	-- LAMBDA
	s({ trig = "ld", snippetType = "snippet" }, fmta("lambda <>: <>", { i(1, "vars"), i(2, "expr") })),

	-- ==========================================
	-- 3. CONTROL FLOW
	-- ==========================================

	-- IF
	s(
		{ trig = "if", snippetType = "snippet" },
		fmta(
			[[
        if <>:
            <>
        ]],
			{ i(1, "condition"), i(0) }
		)
	),

	-- ELIF
	s(
		{ trig = "elif", snippetType = "snippet" },
		fmta(
			[[
        elif <>:
            <>
        ]],
			{ i(1, "condition"), i(0) }
		)
	),

	-- ELSE
	s(
		{ trig = "el", snippetType = "snippet" },
		fmta(
			[[
        else:
            <>
        ]],
			{ i(0) }
		)
	),

	-- FOR LOOP (Standard)
	s(
		{ trig = "for", snippetType = "snippet" },
		fmta(
			[[
        for <> in <>:
            <>
        ]],
			{ i(1, "item"), i(2, "iterable"), i(0) }
		)
	),

	-- FOR RANGE
	s(
		{ trig = "forr", snippetType = "snippet" },
		fmta(
			[[
        for <> in range(<>):
            <>
        ]],
			{ i(1, "i"), i(2, "n"), i(0) }
		)
	),

	s(
		{ trig = "eforr", snippetType = "snippet" },
		fmta(
			[[
        for <> in range(len(<>)):
            <>
        ]],
			{ i(1, "i"), i(2, "n"), i(0) }
		)
	),

	-- WHILE
	s(
		{ trig = "wh", snippetType = "snippet" },
		fmta(
			[[
        while <>:
            <>
        ]],
			{ i(1, "condition"), i(0) }
		)
	),

	-- TRY / EXCEPT
	s(
		{ trig = "try", snippetType = "snippet" },
		fmta(
			[[
        try:
            <>
        except <> as <>:
            <>
        ]],
			{ i(1, "pass"), i(2, "Exception"), i(3, "e"), i(0) }
		)
	),

	-- WITH (Context Manager)
	s(
		{ trig = "with", snippetType = "snippet" },
		fmta(
			[[
        with <> as <>:
            <>
        ]],
			{ i(1, "open('file')"), i(2, "f"), i(0) }
		)
	),

	-- ==========================================
	-- 4. UTILITIES & PRINTING
	-- ==========================================

	-- PRINT
	s({ trig = "pr", snippetType = "snippet" }, fmta("print(<>)", { i(1) })),

	-- F-STRING (Print)
	s({ trig = "fpr", snippetType = "snippet" }, fmta('print(f"<>")', { i(1) })),

	-- F-STRING (Inline)
	-- Type "ff" to start an f-string
	s({ trig = "ff", snippetType = "snippet" }, fmta('f"<>"', { i(1) })),

	-- DOCSTRING
	s(
		{ trig = "doc", snippetType = "snippet" },
		fmta(
			[[
        """
        <>
        """
        ]],
			{ i(0) }
		)
	),
}
