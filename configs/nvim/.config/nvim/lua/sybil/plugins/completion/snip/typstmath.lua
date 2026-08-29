local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmta = require("luasnip.extras.fmt").fmta

-- Typst math snippets shared by the `typst` and `markdown` filetypes -- see
-- the `filetype_extend` calls in ../luasnip.lua.  Nothing here may depend on
-- Typst markup or on `template.typ`: in a markdown buffer the surrounding
-- document is markdown and only the `$ .. $` span is Typst.
--
-- NOTE ON fmta DELIMITERS
-- The default `<>` delimiters clash with Typst's own angle brackets, so a
-- literal one has to be doubled: `<<` -> `<` and `>>` -> `>`.  Custom
-- delimiters are no help: `()` collides with math calls and `[]` with content
-- blocks.

-- Both filetypes reach math through the Typst parser: in `.typ` directly, and
-- in markdown through the `$ .. $` -> typst injection in
-- queries/markdown_inline/injections.scm.  Either way the node to look for is
-- `math`, and `code` / `string` / `raw` are checked first so that
-- `$ #calc.pi $` and `$ "literal" $` count as text.
-- Limitation: an unterminated `$` parses as ERROR, so math snippets stay
-- inactive until the closing `$` exists.
local function in_mathzone()
    local node = vim.treesitter.get_node({ ignore_injections = false })
    while node do
        local ty = node:type()
        if ty == "code" or ty == "string" or ty == "raw" or ty == "comment" then
            return false
        end
        if ty == "math" then
            return true
        end
        node = node:parent()
    end
    return false
end

local function not_in_mathzone()
    return not in_mathzone()
end

local function delim_matrix(fn, delim)
    return fmta(
        [[
        <>(delim: "<>",
            <>, <>;
            <>, <>
        )
        ]],
        { t(fn), t(delim), i(1), i(2), i(3), i(4) }
    )
end

return {
    -- ==========================================================
    -- 1. MATH: STRUCTURE
    -- ==========================================================
    s({ trig = "xx", snippetType = "autosnippet" }, fmta(" times <>", { i(0) }), { condition = in_mathzone }),
    s({ trig = "//", snippetType = "autosnippet" }, fmta("(<>)/(<>)", { i(1), i(2) }), { condition = in_mathzone }),
    s(
        { trig = "^^", snippetType = "autosnippet", wordTrig = false },
        fmta("^(<>)", { i(1) }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "__", snippetType = "autosnippet", wordTrig = false },
        fmta("_(<>)", { i(1) }),
        { condition = in_mathzone }
    ),
    -- Differential: `dif` is a Typst symbol, `dd` is not, so it can autofire.
    s({ trig = "dd", snippetType = "autosnippet" }, t("dif "), { condition = in_mathzone }),
    -- Literal text inside math is a quoted string.
    s({ trig = "qq", snippetType = "autosnippet" }, fmta('"<>" ', { i(1) }), { condition = in_mathzone }),

    s({ trig = "sqrt", snippetType = "snippet" }, fmta("sqrt(<>)", { i(1) }), { condition = in_mathzone }),
    s(
        { trig = "root", snippetType = "snippet" },
        fmta("root(<>, <>)", { i(1, "3"), i(2) }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "binom", snippetType = "snippet" },
        fmta("binom(<>, <>)", { i(1, "n"), i(2, "k") }),
        { condition = in_mathzone }
    ),
    s({ trig = "abs", snippetType = "snippet" }, fmta("abs(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "norm", snippetType = "snippet" }, fmta("norm(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "floor", snippetType = "snippet" }, fmta("floor(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "ceil", snippetType = "snippet" }, fmta("ceil(<>)", { i(1) }), { condition = in_mathzone }),
    -- Auto-scaling delimiters
    s({ trig = "lr", snippetType = "snippet" }, fmta("lr(( <> ))", { i(1) }), { condition = in_mathzone }),
    s({ trig = "lrb", snippetType = "snippet" }, fmta("lr([ <> ])", { i(1) }), { condition = in_mathzone }),
    s({ trig = "lrc", snippetType = "snippet" }, fmta("lr({ <> })", { i(1) }), { condition = in_mathzone }),

    s(
        { trig = "ub", snippetType = "snippet" },
        fmta("underbrace(<>, <>)", { i(1), i(2) }),
        { condition = in_mathzone }
    ),
    s({ trig = "ob", snippetType = "snippet" }, fmta("overbrace(<>, <>)", { i(1), i(2) }), { condition = in_mathzone }),
    s(
        { trig = "attach", snippetType = "snippet" },
        fmta("attach(<>, t: <>, b: <>)", { i(1), i(2), i(3) }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "op", snippetType = "snippet" },
        fmta('op("<>", limits: <>)', { i(1, "Tr"), i(2, "false") }),
        { condition = in_mathzone }
    ),

    -- ==========================================================
    -- 2. MATH: BIG OPERATORS
    -- ==========================================================
    s(
        { trig = "sum", snippetType = "snippet" },
        fmta("sum_(<>)^(<>) ", { i(1, "n = 1"), i(2, "oo") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "prod", snippetType = "snippet" },
        fmta("product_(<>)^(<>) ", { i(1, "n = 1"), i(2, "oo") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "int", snippetType = "snippet" },
        fmta("integral_(<>)^(<>) <> dif <>", { i(1, "a"), i(2, "b"), i(3), i(4, "x") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "iint", snippetType = "snippet" },
        fmta("integral.double_(<>) <> ", { i(1), i(2) }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "oint", snippetType = "snippet" },
        fmta("integral.cont_(<>) <> ", { i(1), i(2) }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "lim", snippetType = "snippet" },
        fmta("lim_(<> ->> <>) ", { i(1, "n"), i(2, "oo") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "limsup", snippetType = "snippet" },
        fmta("limsup_(<> ->> <>) ", { i(1, "n"), i(2, "oo") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "liminf", snippetType = "snippet" },
        fmta("liminf_(<> ->> <>) ", { i(1, "n"), i(2, "oo") }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "part", snippetType = "snippet" },
        fmta("(partial <>)/(partial <>)", { i(1), i(2) }),
        { condition = in_mathzone }
    ),
    s(
        { trig = "der", snippetType = "snippet" },
        fmta("(dif <>)/(dif <>)", { i(1, "y"), i(2, "x") }),
        { condition = in_mathzone }
    ),

    -- ==========================================================
    -- 3. MATH: MATRICES, VECTORS, CASES
    -- ==========================================================
    s(
        { trig = "mat", snippetType = "snippet" },
        fmta(
            [[
        mat(
            <>, <>;
            <>, <>
        )
        ]],
            { i(1), i(2), i(3), i(4) }
        ),
        { condition = in_mathzone }
    ),
    s({ trig = "bmat", snippetType = "snippet" }, delim_matrix("mat", "["), { condition = in_mathzone }),
    s({ trig = "vmat", snippetType = "snippet" }, delim_matrix("mat", "|"), { condition = in_mathzone }),
    s({ trig = "vv", snippetType = "snippet" }, fmta("vec(<>, <>)", { i(1), i(2) }), { condition = in_mathzone }),
    s(
        { trig = "cases", snippetType = "snippet" },
        fmta(
            [[
        cases(
            <> & "if" <>,
            <> & "otherwise",
        )
        ]],
            { i(1), i(2), i(3) }
        ),
        { condition = in_mathzone }
    ),

    -- ==========================================================
    -- 4. MATH: ACCENTS & STYLES
    -- ==========================================================
    -- Tab-only: these are the real Typst function names, so autosnippets here
    -- would hijack someone typing `hat(x)` by hand.
    s({ trig = "hat", snippetType = "snippet" }, fmta("hat(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "bar", snippetType = "snippet" }, fmta("overline(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "vec", snippetType = "snippet" }, fmta("arrow(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "dot", snippetType = "snippet" }, fmta("dot(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "ddot", snippetType = "snippet" }, fmta("dot.double(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "tilde", snippetType = "snippet" }, fmta("tilde(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "bb", snippetType = "snippet" }, fmta("bb(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "cal", snippetType = "snippet" }, fmta("cal(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "frak", snippetType = "snippet" }, fmta("frak(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "bold", snippetType = "snippet" }, fmta("bold(<>)", { i(1) }), { condition = in_mathzone }),
    s({ trig = "up", snippetType = "snippet" }, fmta("upright(<>)", { i(1) }), { condition = in_mathzone }),

    -- ==========================================================
    -- 5. MATH: GREEK (`;` sigil, same convention as mathmode.lua)
    -- ==========================================================
    s({ trig = ";a", snippetType = "autosnippet", wordTrig = false }, t("alpha"), { condition = in_mathzone }),
    s({ trig = ";b", snippetType = "autosnippet", wordTrig = false }, t("beta"), { condition = in_mathzone }),
    s({ trig = ";g", snippetType = "autosnippet", wordTrig = false }, t("gamma"), { condition = in_mathzone }),
    s({ trig = ";G", snippetType = "autosnippet", wordTrig = false }, t("Gamma"), { condition = in_mathzone }),
    s({ trig = ";d", snippetType = "autosnippet", wordTrig = false }, t("delta"), { condition = in_mathzone }),
    s({ trig = ";D", snippetType = "autosnippet", wordTrig = false }, t("Delta"), { condition = in_mathzone }),
    s({ trig = ";e", snippetType = "autosnippet", wordTrig = false }, t("epsilon"), { condition = in_mathzone }),
    s({ trig = ";z", snippetType = "autosnippet", wordTrig = false }, t("zeta"), { condition = in_mathzone }),
    s({ trig = ";h", snippetType = "autosnippet", wordTrig = false }, t("eta"), { condition = in_mathzone }),
    s({ trig = ";t", snippetType = "autosnippet", wordTrig = false }, t("theta"), { condition = in_mathzone }),
    s({ trig = ";T", snippetType = "autosnippet", wordTrig = false }, t("Theta"), { condition = in_mathzone }),
    s({ trig = ";k", snippetType = "autosnippet", wordTrig = false }, t("kappa"), { condition = in_mathzone }),
    s({ trig = ";l", snippetType = "autosnippet", wordTrig = false }, t("lambda"), { condition = in_mathzone }),
    s({ trig = ";L", snippetType = "autosnippet", wordTrig = false }, t("Lambda"), { condition = in_mathzone }),
    s({ trig = ";m", snippetType = "autosnippet", wordTrig = false }, t("mu"), { condition = in_mathzone }),
    s({ trig = ";n", snippetType = "autosnippet", wordTrig = false }, t("nu"), { condition = in_mathzone }),
    s({ trig = ";x", snippetType = "autosnippet", wordTrig = false }, t("xi"), { condition = in_mathzone }),
    s({ trig = ";p", snippetType = "autosnippet", wordTrig = false }, t("pi"), { condition = in_mathzone }),
    s({ trig = ";P", snippetType = "autosnippet", wordTrig = false }, t("Pi"), { condition = in_mathzone }),
    s({ trig = ";r", snippetType = "autosnippet", wordTrig = false }, t("rho"), { condition = in_mathzone }),
    s({ trig = ";s", snippetType = "autosnippet", wordTrig = false }, t("sigma"), { condition = in_mathzone }),
    s({ trig = ";S", snippetType = "autosnippet", wordTrig = false }, t("Sigma"), { condition = in_mathzone }),
    s({ trig = ";u", snippetType = "autosnippet", wordTrig = false }, t("tau"), { condition = in_mathzone }),
    s({ trig = ";f", snippetType = "autosnippet", wordTrig = false }, t("phi"), { condition = in_mathzone }),
    s({ trig = ";F", snippetType = "autosnippet", wordTrig = false }, t("Phi"), { condition = in_mathzone }),
    s({ trig = ";c", snippetType = "autosnippet", wordTrig = false }, t("chi"), { condition = in_mathzone }),
    s({ trig = ";y", snippetType = "autosnippet", wordTrig = false }, t("psi"), { condition = in_mathzone }),
    s({ trig = ";Y", snippetType = "autosnippet", wordTrig = false }, t("Psi"), { condition = in_mathzone }),
    s({ trig = ";o", snippetType = "autosnippet", wordTrig = false }, t("omega"), { condition = in_mathzone }),
    s({ trig = ";O", snippetType = "autosnippet", wordTrig = false }, t("Omega"), { condition = in_mathzone }),
    s({ trig = ";N", snippetType = "autosnippet", wordTrig = false }, t("nabla"), { condition = in_mathzone }),
    s({ trig = ";8", snippetType = "autosnippet", wordTrig = false }, t("oo"), { condition = in_mathzone }),

    -- ==========================================================
    -- 6. MISC
    -- ==========================================================
    -- The LaTeX counterpart lives in mathmode.lua, so a markdown buffer gets
    -- whichever one its `:MdMath` mode selected.
    s({ trig = "_qed", snippetType = "autosnippet" }, t("$qed$"), { condition = not_in_mathzone }),
}
