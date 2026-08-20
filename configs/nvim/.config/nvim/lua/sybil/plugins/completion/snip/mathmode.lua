local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local function array_snippet(open, close)
    return fmta(
        [[
        <> 
        \begin{array}{<>}
            <>
        \end{array}
        <>
        ]],
        {
            t(open or ""),
            i(1, "ccc"),
            i(2),
            t(close or ""),
        }
    )
end

local function in_mathzone()
    local node = vim.treesitter.get_node({ ignore_injections = false })
    while node do
        local t = node:type()
        -- text_mode overrides math
        if t == "text_mode" then
            return false
        end
        if
            t == "displayed_equation"
            or t == "inline_formula"
            or t == "math_environment"
            or t == "superscript"
            or t == "subscript"
        then
            return true
        end
        node = node:parent()
    end
    return false
end

return {
    -- ==========================================================
    -- 0. FONT SHORTCUTS
    -- ==========================================================
    s({ trig = "mb", snippetType = "autosnippet" }, fmta("\\mathbf{<>}", { i(0) }), { condition = in_mathzone }),
    s({ trig = "mbf", snippetType = "autosnippet" }, fmta("\\mathbf{<>}", { i(1) }), { condition = in_mathzone }),
    s({ trig = "mcal", snippetType = "autosnippet" }, fmta("\\mathcal{<>}", { i(1) }), { condition = in_mathzone }),
    s({ trig = "tt", snippetType = "autosnippet" }, fmta("\\text{<>}", { i(1) }), { condition = in_mathzone }),
    s({ trig = "hat", snippetType = "autosnippet" }, fmta("\\hat{<>}", { i(1) }), { condition = in_mathzone }),
    s({ trig = "vec", snippetType = "autosnippet" }, fmta("\\vec{<>}", { i(1) }), { condition = in_mathzone }),
    s({ trig = "bar", snippetType = "autosnippet" }, fmta("\\overline{<>}", { i(1) }), { condition = in_mathzone }),
    s({ trig = "   ", snippetType = "autosnippet" }, t("\\quad"), { condition = in_mathzone }),

    -- ==========================================================
    -- 1. SETS & NUMBER SYSTEMS
    -- ==========================================================
    s({ trig = "RR", snippetType = "autosnippet" }, t("\\mathbb{R}"), { condition = in_mathzone }),
    s({ trig = "NN", snippetType = "autosnippet" }, t("\\mathbb{N}"), { condition = in_mathzone }),
    s({ trig = "ZZ", snippetType = "autosnippet" }, t("\\mathbb{Z}"), { condition = in_mathzone }),
    s({ trig = "QQ", snippetType = "autosnippet" }, t("\\mathbb{Q}"), { condition = in_mathzone }),
    s({ trig = "CC", snippetType = "autosnippet" }, t("\\mathbb{C}"), { condition = in_mathzone }),
    s({ trig = "FF", snippetType = "autosnippet" }, t("\\mathbb{F}"), { condition = in_mathzone }),

    s({ trig = "eset", snippetType = "autosnippet" }, t("\\emptyset"), { condition = in_mathzone }),
    s({ trig = "_set", snippetType = "autosnippet" }, t("\\subset"), { condition = in_mathzone }),
    s({ trig = "=set", snippetType = "autosnippet" }, t("\\subseteq"), { condition = in_mathzone }),
    s({ trig = "in", snippetType = "autosnippet" }, t("\\in "), { condition = in_mathzone }),
    s({ trig = "nin", snippetType = "autosnippet" }, t("\\not\\in "), { condition = in_mathzone }),

    -- ==========================================================
    -- 2. LOGIC & RELATIONS
    -- ==========================================================
    s({ trig = "for", snippetType = "autosnippet" }, t("\\forall~ "), { condition = in_mathzone }),
    s({ trig = "exi", snippetType = "autosnippet" }, t("\\exists~ "), { condition = in_mathzone }),
    s({ trig = "!!", snippetType = "autosnippet" }, t("\\neg "), { condition = in_mathzone }),

    s({ trig = "imp", snippetType = "autosnippet" }, t("\\implies "), { condition = in_mathzone }),
    s(
        { trig = "x->", snippetType = "autosnippet", wordTrig = false },
        fmta("\\xrightarrow{<>} ", { i(1, "\\text{}") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "x<-", snippetType = "autosnippet", wordTrig = false },
        fmta("\\xleftarrow{<>} ", { i(1, "\\text{}") }),
        { condition = in_mathzone }
    ),
    s({ trig = "->", snippetType = "autosnippet", wordTrig = false }, t("\\rightarrow "), { condition = in_mathzone }),
    s({ trig = "<-", snippetType = "autosnippet", wordTrig = false }, t("\\leftarrow "), { condition = in_mathzone }),
    s({ trig = "<->", snippetType = "autosnippet" }, t("\\iff "), { condition = in_mathzone }),
    s({ trig = "and", snippetType = "autosnippet" }, t("\\land "), { condition = in_mathzone }),
    s({ trig = "or", snippetType = "autosnippet" }, t("\\lor "), { condition = in_mathzone }),
    s({ trig = "xor", snippetType = "autosnippet" }, t("\\oplus "), { condition = in_mathzone }),
    s({ trig = "there", snippetType = "autosnippet" }, t("\\therefore "), { condition = in_mathzone }),

    s({ trig = ">=", snippetType = "autosnippet" }, t("\\geq "), { condition = in_mathzone }),
    s({ trig = "<=", snippetType = "autosnippet" }, t("\\leq "), { condition = in_mathzone }),
    s({ trig = "==", snippetType = "autosnippet" }, t("\\equiv "), { condition = in_mathzone }),
    s({ trig = "-=", snippetType = "autosnippet" }, t("\\neq "), { condition = in_mathzone }),
    s({ trig = "~=", snippetType = "autosnippet" }, t("\\approx "), { condition = in_mathzone }),
    s({ trig = "<->", snippetType = "autosnippet" }, { t("\\lightning") }),
    s({ trig = "_qed", snippetType = "autosnippet" }, { t("$\\blacksquare$") }),

    -- ==========================================================
    -- DOTS
    -- ==========================================================
    -- s({ trig = "...", snippetType = "autosnippet", wordTrig=false }, t("\\hdots "), { condition = in_mathzone }),
    s({ trig = "...", snippetType = "autosnippet" }, t("\\dots "), { condition = in_mathzone }),
    s({ trig = "d..", snippetType = "autosnippet" }, t("\\ddots "), { condition = in_mathzone }),
    s({ trig = "c..", snippetType = "autosnippet" }, t("\\cdots "), { condition = in_mathzone }),
    s({ trig = "v..", snippetType = "autosnippet" }, t("\\vdots "), { condition = in_mathzone }),
    s({ trig = "ss", snippetType = "autosnippet" }, t("& "), { condition = in_mathzone }),
    s({ trig = "./", snippetType = "autosnippet", wordTrig = false }, t("\\ "), { condition = in_mathzone }),

    -- ==========================================================
    -- 3. BASIC OPERATORS
    -- ==========================================================
    s({ trig = " *", snippetType = "autosnippet" }, t("\\cdot "), { condition = in_mathzone }),
    s({ trig = "xx", snippetType = "autosnippet" }, t("\\times "), { condition = in_mathzone }),
    s({ trig = "_inf", snippetType = "autosnippet" }, t("\\infty"), { condition = in_mathzone }),
    s({ trig = ".p", snippetType = "autosnippet" }, t("\\perp"), { condition = in_mathzone }),

    -- ==========================================================
    -- 4. STRUCTURE SHORTCUTS
    -- ==========================================================
    s(
        { trig = "//", snippetType = "autosnippet" },
        fmta("\\frac{<>}{<>}", { i(1), i(2) }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "^^", snippetType = "autosnippet", wordTrig = false },
        fmta("^{<>}", { i(1) }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "__", snippetType = "autosnippet", wordTrig = false },
        fmta("_{<>}", { i(1) }),
        { condition = in_mathzone }
    ),
    s({ trig = "set", snippetType = "autosnippet" }, fmta("\\{ <> \\}", { i(1) }), { condition = in_mathzone }),
    s({ trig = "sq", snippetType = "autosnippet" }, fmta("\\sqrt{<>}", { i(1) }), { condition = in_mathzone }),

    -- ==========================================================
    -- 5. CALCULUS
    -- ==========================================================
    s(
        { trig = "lim", snippetType = "snippet" },
        fmta("\\lim_{<> \\to <>} ", { i(1, "n"), i(2, "\\infty") }),
        { condition = in_mathzone }
    ),

    s(
        { trig = "sum", snippetType = "snippet" },
        fmta("\\sum_{<>}^{<>} ", { i(1, "n=1"), i(2, "\\infty") }),
        { condition = in_mathzone }
    ),

    s(
        { trig = "int", snippetType = "snippet" },
        fmta("\\int_{<>}^{<>} <> \\, d<>", { i(1), i(2), i(3), i(0) }),
        { condition = in_mathzone }
    ),

    s(
        { trig = "part", snippetType = "snippet" },
        fmta("\\frac{\\partial <>}{\\partial <>}", { i(1), i(2) }),
        { condition = in_mathzone }
    ),

    -- ==========================================================
    -- 6. DELIMITERS
    -- ==========================================================
    s({ trig = "()", snippetType = "snippet" }, fmta("\\left( <> \\right", { i(1) }), { condition = in_mathzone }),
    s(
        { trig = "<>", snippetType = "snippet" },
        fmta("\\left< [1] \\right>", { i(1) }, { delimiters = "[]" }),
        { condition = in_mathzone }
    ),
    s({ trig = "[]", snippetType = "snippet" }, fmta("\\left[ <> \\right", { i(1) }), { condition = in_mathzone }),
    s({ trig = "{}", snippetType = "snippet" }, fmta("\\left\\{ <> \\right\\}", { i(1) }), { condition = in_mathzone }),
    s({ trig = "|", snippetType = "snippet" }, fmta("\\left| <> \\right|", { i(1) }), { condition = in_mathzone }),
    s({ trig = "||", snippetType = "snippet" }, fmta("\\left\\| <> \\right\\|", { i(1) }), { condition = in_mathzone }),

    -- ==========================================================
    -- 7. MATRICES & ARRAYS
    -- ==========================================================

    -- pmatrix
    s(
        { trig = "pmat", snippetType = "autosnippet" },
        fmta(
            [[
        \begin{pmatrix}
            <>
        \end{pmatrix}
        ]],
            { i(1) }
        ),
        { condition = in_mathzone }
    ),

    -- bmatrix
    s(
        { trig = "bmat", snippetType = "autosnippet" },
        fmta(
            [[
        \begin{bmatrix}
            <>
        \end{bmatrix}
        ]],
            { i(1) }
        ),
        { condition = in_mathzone }
    ),

    -- Plain array
    s({ trig = "arr", snippetType = "snippet" }, array_snippet("", ""), { condition = in_mathzone }),

    -- ( )
    s({ trig = "ar(", snippetType = "snippet" }, array_snippet("\\left(", "\\right)"), { condition = in_mathzone }),

    -- [ ]
    s({ trig = "ar[]", snippetType = "snippet" }, array_snippet("\\left[", "\\right]"), { condition = in_mathzone }),

    -- { }
    s(
        { trig = "ar{}", snippetType = "snippet" },
        array_snippet("\\left\\{", "\\right\\}"),
        { condition = in_mathzone }
    ),

    -- | |
    s({ trig = "arr|", snippetType = "snippet" }, array_snippet("\\left|", "\\right|"), { condition = in_mathzone }),

    -- || ||
    s(
        { trig = "arr||", snippetType = "snippet" },
        array_snippet("\\left\\|", "\\right\\|"),
        { condition = in_mathzone }
    ),

    -- ⟨ ⟩
    s(
        { trig = "ar<>", snippetType = "snippet" },
        array_snippet("\\left\\langle", "\\right\\rangle"),
        { condition = in_mathzone }
    ),

    --- singles
    s({ trig = "ar(", snippetType = "snippet" }, array_snippet("\\left(", "\\right ."), { condition = in_mathzone }),

    -- [ ]
    s({ trig = "ar[", snippetType = "snippet" }, array_snippet("\\left[", "\\right ."), { condition = in_mathzone }),

    -- { }
    s({ trig = "ar{", snippetType = "snippet" }, array_snippet("\\left\\{", "\\right ."), { condition = in_mathzone }),

    -- | |
    s({ trig = "ar|", snippetType = "snippet" }, array_snippet("\\left|", "\\right ."), { condition = in_mathzone }),

    -- || ||
    s({ trig = "ar||", snippetType = "snippet" }, array_snippet("\\left\\|", "\\right ."), { condition = in_mathzone }),

    -- ⟨ ⟩
    s(
        { trig = "ar<", snippetType = "snippet" },
        array_snippet("\\left\\langle", "\\right ."),
        { condition = in_mathzone }
    ),

    -- ==========================================================
    -- 8. GREEK LETTERS
    -- ==========================================================
    s(
        { trig = "limsup", snippetType = "autosnippet", wordTrig = false },
        t("\\overline{\\lim}"),
        { condition = in_mathzone }
    ),
    s(
        { trig = "liminf", snippetType = "autosnippet", wordTrig = false },
        t("\\underline{\\lim}"),
        { condition = in_mathzone }
    ),
    s({ trig = ";n", snippetType = "autosnippet", wordTrig = false }, t("\\nabla"), { condition = in_mathzone }),
    s({ trig = ";a", snippetType = "autosnippet", wordTrig = false }, t("\\alpha"), { condition = in_mathzone }),
    s({ trig = ";b", snippetType = "autosnippet", wordTrig = false }, t("\\beta"), { condition = in_mathzone }),
    s({ trig = ";g", snippetType = "autosnippet", wordTrig = false }, t("\\gamma"), { condition = in_mathzone }),
    s({ trig = ";d", snippetType = "autosnippet", wordTrig = false }, t("\\delta"), { condition = in_mathzone }),
    s({ trig = ";D", snippetType = "autosnippet", wordTrig = false }, t("\\Delta"), { condition = in_mathzone }),
    s({ trig = ";t", snippetType = "autosnippet", wordTrig = false }, t("\\theta"), { condition = in_mathzone }),
    s({ trig = ";l", snippetType = "autosnippet", wordTrig = false }, t("\\lambda"), { condition = in_mathzone }),
    s({ trig = ";L", snippetType = "autosnippet", wordTrig = false }, t("\\Lambda"), { condition = in_mathzone }),
    s({ trig = ";s", snippetType = "autosnippet", wordTrig = false }, t("\\sigma"), { condition = in_mathzone }),
    s({ trig = ";s", snippetType = "autosnippet", wordTrig = false }, t("\\Sigma"), { condition = in_mathzone }),
    s({ trig = ";p", snippetType = "autosnippet", wordTrig = false }, t("\\phi"), { condition = in_mathzone }),
    s({ trig = ";o", snippetType = "autosnippet", wordTrig = false }, t("\\omega"), { condition = in_mathzone }),
    s({ trig = ";O", snippetType = "autosnippet", wordTrig = false }, t("\\Omega"), { condition = in_mathzone }),
    s({ trig = ";x", snippetType = "autosnippet", wordTrig = false }, t("\\xi"), { condition = in_mathzone }),
    s({ trig = ";e", snippetType = "autosnippet", wordTrig = false }, t("\\epsilon"), { condition = in_mathzone }),
    s({ trig = ";m", snippetType = "autosnippet", wordTrig = false }, t("\\mu"), { condition = in_mathzone }),

    -- ==========================================================
    -- colors
    -- ==========================================================
    s(
        { trig = "gathered", snippetType = "snippet" },
        fmta(
            [[
        \begin{gathered}
        <>
        \end{gathered}
        ]],
            { i(1) }
        )
    ),
    s(
        { trig = "._", snippetType = "snippet" },
        fmta(
            [[
            \underbrace{<>}_{<>}
            ]],
            { i(1), i(2) }
        )
    ),
}
