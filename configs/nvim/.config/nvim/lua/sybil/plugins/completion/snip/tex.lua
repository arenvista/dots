local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local rep = require("luasnip.extras").rep
local fmta = require("luasnip.extras.fmt").fmta

local function in_mathzone()
    local node = vim.treesitter.get_node({ ignore_injections = false })
    while node do
        local t = node:type()
        -- text_mode overrides math
        if t == "text_mode" then
            return false
        end
        if t == "displayed_equation" or t == "inline_formula" or t == "math_environment" then
            return true
        end
        node = node:parent()
    end
    return false
end

return {
    s(
        { trig = "pff", snippetType = "autosnippet" },
        fmta(
            [[
      \begin{proof}
          <>
      \end{proof}
    ]],
            { i(0) }
        )
    ),
    s({ trig = "bb", snippetType = "autosnippet" }, fmta([[ \textbf{<>} ]], { i(0) })),
    s({ trig = "ii", snippetType = "autosnippet" }, fmta([[ \textit{<>} ]], { i(0) })),
    -- ==========================================
    -- 1. GENERAL ENVIRONMENTS (Regular Triggers)
    -- ==========================================
    s(
        { trig = "beg", snippetType = "autosnippet" },
        fmta(
            [[
      \begin{<>}
          <>
      \end{<>}
    ]],
            { i(1), i(0), rep(1) }
        )
    ),

    -- ==========================================
    -- 2. DOCUMENT STRUCTURE (Sections/Lists)
    -- ==========================================
    -- SECTION
    s(
        { trig = "sec", snippetType = "autosnippet" },
        fmta(
            [[
      \section{<>}

      <>
    ]],
            { i(1), i(0) }
        )
    ),

    s(
        { trig = "ssec", snippetType = "autosnippet" },
        fmta(
            [[
      \subsection{<>}

      <>
    ]],
            { i(1), i(0) }
        )
    ),

    -- SEC*
    s(
        { trig = "*sec", snippetType = "autosnippet" },
        fmta(
            [[
      \section*{<>}

      <>
    ]],
            { i(1), i(0) }
        )
    ),

    s(
        { trig = "*ssec", snippetType = "autosnippet" },
        fmta(
            [[
      \subsection*{<>}

      <>
    ]],
            { i(1), i(0) }
        )
    ),

    -- ITEMIZE LIST
    s(
        { trig = "item", snippetType = "autosnippet" },
        fmta(
            [[
          \item <>
    ]],
            { i(0) }
        )
    ),

    s(
        { trig = "*item", snippetType = "autosnippet" },
        fmta(
            [[
      \begin{itemize*}
          \item <>
      \end{itemize*}
    ]],
            { i(0) }
        )
    ),

    ---ALIGN (Environment Trigger)
    s(
        { trig = "*align", snippetType = "autosnippet" },
        fmta(
            [[
      \begin{align*}
          <>
      \end{align*}
    ]],
            { i(0) }
        )
    ),

    -- FIGURE
    s(
        { trig = "fig", snippetType = "snippet" },
        fmta(
            [[
      \begin{figure}[htpb]
          \centering
          \includegraphics[width=0.8\linewidth]{<>}
          \caption{<>}
          \label{fig:<>}
      \end{figure}
    ]],
            { i(1), i(2), i(3) }
        )
    ),

    -- ==========================================
    -- 3. MATH MODE ENTRANCE TRIGGERS
    -- ==========================================

    -- INLINE MATH ($...$)
    s({ trig = "il", snippetType = "autosnippet" }, fmta("$<>$<>", { i(1), i(0) })),

    -- DISPLAY MATH (\[ ... \])
    s(
        { trig = "dm", snippetType = "autosnippet" },
        fmta(
            [[
      \[
          <>
      \] <>
    ]],
            { i(1), i(0) }
        )
    ),

    s(
        { trig = "center", snippetType = "snippet" },
        fmta(
            [[
        \begin{center}
            <>
        \end{center}
        ]],
            { i(1) }
        )
    ),

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
}
