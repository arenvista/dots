local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

return {
	-- ==========================================
	-- 1. SECTIONS & BOILERPLATE
	-- ==========================================

	-- FULL TEMPLATE (NASM Linux x64)
	s(
		{ trig = "base", snippetType = "autosnippet" },
		fmta(
			[[
        section .data
            <>

        section .bss
            <>

        section .text
            global _start

        _start:
            <>

            ; Exit program
            mov rax, 60
            xor rdi, rdi
            syscall
        ]],
			{ i(1), i(2), i(0) }
		)
	),

	-- DATA SECTION
	s(
		{ trig = "sdata", snippetType = "autosnippet" },
		fmta(
			[[
        section .data
            <>
        ]],
			{ i(0) }
		)
	),

	-- BSS SECTION (Uninitialized data)
	s(
		{ trig = "sbss", snippetType = "autosnippet" },
		fmta(
			[[
        section .bss
            <>
        ]],
			{ i(0) }
		)
	),

	-- TEXT SECTION (Code)
	s(
		{ trig = "stext", snippetType = "autosnippet" },
		fmta(
			[[
        section .text
            global <>

        <>:
            <>
        ]],
			{ i(1, "_start"), rep(1), i(0) }
		)
	),

	-- ==========================================
	-- 2. FUNCTIONS & LOGIC
	-- ==========================================

	-- FUNCTION LABEL (Standard Frame)
	s(
		{ trig = "fun", snippetType = "autosnippet" },
		fmta(
			[[
        <>:
            push rbp
            mov rbp, rsp

            <>

            pop rbp
            ret
        ]],
			{ i(1, "label_name"), i(0) }
		)
	),

	-- SIMPLE LABEL
	s(
		{ trig = "lb", snippetType = "autosnippet" },
		fmta(
			[[
        <>:
            <>
        ]],
			{ i(1, "label"), i(0) }
		)
	),

	-- LOOP (Basic Decrement Loop)
	s(
		{ trig = "loop", snippetType = "autosnippet" },
		fmta(
			[[
        mov rcx, <>
        .loop_start:
            <>
            dec rcx
            jnz .loop_start
        ]],
			{ i(1, "count"), i(0) }
		)
	),

	-- ==========================================
	-- 3. SYSCALLS (Linux x64)
	-- ==========================================

	-- GENERIC SYSCALL
	s(
		{ trig = "sys", snippetType = "autosnippet" },
		fmta(
			[[
        mov rax, <>
        mov rdi, <>
        syscall
        ]],
			{ i(1, "sys_num"), i(2, "arg1") }
		)
	),

	-- EXIT (sys_exit)
	s(
		{ trig = "exit", snippetType = "autosnippet" },
		fmta(
			[[
        mov rax, 60       ; sys_exit
        mov rdi, <>        ; error_code
        syscall
        ]],
			{ i(1, "0") }
		)
	),

	-- WRITE (sys_write to stdout)
	s(
		{ trig = "pr", snippetType = "autosnippet" },
		fmta(
			[[
        mov rax, 1        ; sys_write
        mov rdi, 1        ; file descriptor (stdout)
        mov rsi, <>       ; buffer
        mov rdx, <>       ; length
        syscall
        ]],
			{ i(1, "msg_ptr"), i(2, "msg_len") }
		)
	),

	-- ==========================================
	-- 4. COMMON INSTRUCTIONS
	-- ==========================================

	-- MOV
	s({ trig = "mv", snippetType = "autosnippet" }, fmta("mov <>, <>", { i(1, "dest"), i(2, "src") })),

	-- COMPARE & JUMP EQUAL
	s(
		{ trig = "je", snippetType = "autosnippet" },
		fmta(
			[[
        cmp <>, <>
        je <>
        ]],
			{ i(1, "reg1"), i(2, "reg2"), i(3, "label") }
		)
	),

	-- COMPARE & JUMP NOT EQUAL
	s(
		{ trig = "jne", snippetType = "autosnippet" },
		fmta(
			[[
        cmp <>, <>
        jne <>
        ]],
			{ i(1, "reg1"), i(2, "reg2"), i(3, "label") }
		)
	),

	-- DATA DEFINITION (String)
	s({ trig = "db", snippetType = "autosnippet" }, fmta('<> db "<>", 0', { i(1, "var_name"), i(2, "string") })),

	-- DATA DEFINITION (Length calculation)
	s({ trig = "len", snippetType = "autosnippet" }, fmta("<> equ $ - <>", { i(1, "len_name"), i(2, "var_name") })),
}
