-- ~/.config/nvim/lua/plugins/codecompanion.lua
--
-- Subscription-only CodeCompanion (Claude Code / ACP). No HTTP anthropic adapter,
-- so nothing ever calls api.anthropic.com or needs ANTHROPIC_API_KEY.
--
-- Because ACP only backs the CHAT interaction, the note-rewriting prompts run as
-- chat prompts (output in the chat buffer, no in-place diff). If you ever want the
-- in-place diff back, you must add an `anthropic` HTTP adapter with a REAL API key
-- (sk-ant-api..., from console.anthropic.com) and set that prompt's strategy to
-- "inline". An OAuth token (sk-ant-oat...) will NOT work as an API key.
--
-- The prompt library is format-aware: the five rewriting prompts build their
-- system message from `context.filetype`, so /rewrite, /textbook, /tighten,
-- /callouts and /proof work in both Markdown (LaTeX/KaTeX) and Typst buffers.
-- Three conversion prompts sit on top: /md2typ, /typ2md and /typstmath.

--------------------------------------------------------------------------------
-- Per-format preservation rules
--------------------------------------------------------------------------------

local RULES = {}

RULES.markdown = [==[
Format: Markdown with LaTeX/KaTeX math.
- Preserve every math expression exactly as written: $...$, $$...$$, and
  \begin{env}...\end{env}. Never change which delimiter kind is used.
- Headings are #/##/###; emphasis is *italic* and **bold**; lists are - and 1.
- Preserve Obsidian callouts (> [!note]), wiki-links, footnotes, and any YAML
  front matter delimited by ---.
- Do not introduce Typst syntax.
]==]

RULES.typst = [==[
Format: Typst markup.
- Preserve every math expression exactly, including its mode: $x$ (no spaces
  just inside the delimiters) is inline, $ x $ (with spaces) is display. Never
  convert one into the other, and never reflow a display block onto one line.
- Preserve code mode verbatim: #let, #set, #show, #import, #figure, #link,
  #cite and every other #-prefixed call, together with its arguments and any
  content blocks written as [ ... ].
- Headings are =, ==, ===; emphasis is _italic_ and *bold*; lists are - and +.
- Keep labels <name> and references @name byte-for-byte.
- Typst math is not LaTeX: never introduce \frac, \begin{}, \mathbb or any
  other backslash command. Idiomatic Typst math (a/b, mat(), cases(),
  sum_(i=1)^n, norm(), lr(), "text") stays exactly as it is.
- Comments (// and /* */) are content: leave them unless the prose they
  annotate is itself being rewritten.
- Do not introduce Markdown or LaTeX syntax.
]==]

RULES.unknown = [==[
Format: lightweight markup, either Markdown with LaTeX/KaTeX math or Typst.
Infer which from the syntax (=/== headings, #-prefixed calls, <labels> and
@refs mean Typst) and stay strictly inside that dialect.
- Preserve every math expression exactly, with its delimiters and — in Typst —
  its inline ($x$) versus display ($ x $) spacing.
- Never mix the two dialects or translate between them.
]==]

local MARKDOWNISH = {
    markdown = true,
    md = true,
    quarto = true,
    rmd = true,
    pandoc = true,
    vimwiki = true,
}

local function markup_rules(context)
    local ft = context and context.filetype or ""
    if ft == "typst" or ft == "typ" then
        return RULES.typst
    elseif MARKDOWNISH[ft] then
        return RULES.markdown
    end
    return RULES.unknown
end

--------------------------------------------------------------------------------
-- Theorem-environment conventions, per format
--------------------------------------------------------------------------------

local ENVIRONMENTS = {}

ENVIRONMENTS.markdown = [==[
Wrap definitions, theorems, lemmas, proofs and remarks in the matching Obsidian
callout: > [!definition], > [!theorem], > [!lemma], > [!proof], > [!note].
]==]

ENVIRONMENTS.typst = [==[
Match whatever theorem environments the selection already uses, e.g.
#theorem[...], #lemma[...], #proof[...] as provided by ctheorems. Do NOT invent
#let definitions and do NOT assume a package that is not already in play: if the
selection uses no theorem environments, fall back to a bolded lead-in such as
*Theorem.* / *Proof.* and otherwise leave the structure alone. A single trailing
// comment naming the import a richer version would need is allowed.
]==]

ENVIRONMENTS.unknown = ENVIRONMENTS.markdown .. ENVIRONMENTS.typst

local function environment_rules(context)
    local ft = context and context.filetype or ""
    if ft == "typst" or ft == "typ" then
        return ENVIRONMENTS.typst
    elseif MARKDOWNISH[ft] then
        return ENVIRONMENTS.markdown
    end
    return ENVIRONMENTS.unknown
end

--------------------------------------------------------------------------------
-- Shared LaTeX <-> Typst math reference
--------------------------------------------------------------------------------

local MATH_MAP = [==[
Math translation reference (LaTeX -> Typst):
- \frac{a}{b} -> (a)/(b)          \sqrt{x} -> sqrt(x)        x^{2} -> x^2
- \sum_{i=1}^{n} -> sum_(i=1)^n   \int_a^b -> integral_a^b
- \lim_{n\to\infty} -> lim_(n -> oo)
- \mathbb{R} -> RR (likewise NN, ZZ, QQ, CC)                 \mathcal{A} -> cal(A)
- \mathbf{v} -> bold(v)   \mathrm{x} -> upright(x)   \mathrm{d}x -> dif x
- \hat{x} -> hat(x)   \bar{x} -> macron(x)   \overline{x} -> overline(x)
- \tilde{x} -> tilde(x)   \vec{v} -> arrow(v)   \dot{x} -> dot(x)
- \text{...} -> "..."             \operatorname{tr} -> op("tr")
- \left(...\right) -> lr((...))   \|x\| -> norm(x)           |x| -> abs(x)
- \langle x, y \rangle -> angle.l x, y angle.r
- \begin{pmatrix} a & b \\ c & d \end{pmatrix} -> mat(a, b; c, d)
  (pass delim: "[" or delim: "|" to match the original brackets)
- \begin{cases} ... \end{cases} -> cases(...)
- \begin{align} ... \end{align} -> a display block, with & alignment points kept
- Symbols are bare words: \alpha -> alpha, \to -> ->, \infty -> oo,
  \cdot -> dot, \times -> times, \leq -> <=, \in -> in, \subseteq -> subset.eq,
  \forall -> forall, \exists -> exists, \partial -> diff, \nabla -> nabla
- In Typst math a run of letters is one identifier, so distinct variables must
  be separated by spaces (xy -> x y); operator names (sin, log, max, lim) stay
  as bare words.
- No backslash command may survive in Typst output.
]==]

--------------------------------------------------------------------------------
-- Prompt assembly
--------------------------------------------------------------------------------

--- Task rules first, then the format rules for the buffer the prompt fired in.
local function system(body)
    return function(context)
        return body .. "\n" .. markup_rules(context)
    end
end

return {
    "olimorris/codecompanion.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd" },
    keys = {
        { "<leader>aa", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion: actions" },
        { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "CodeCompanion: toggle chat" },
        { "ga", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "CodeCompanion: add selection to chat" },
        -- Note prompts (chat strategy). If `prompt()` errors on your version, open chat
        -- with <leader>ac, add the selection with ga, then use the /slash command.
        {
            "<leader>nr",
            function()
                require("codecompanion").prompt("rewrite")
            end,
            mode = "v",
            desc = "Notes: rewrite clearer",
        },
        {
            "<leader>nt",
            function()
                require("codecompanion").prompt("textbook")
            end,
            mode = "v",
            desc = "Notes: textbook prose",
        },
        {
            "<leader>ns",
            function()
                require("codecompanion").prompt("tighten")
            end,
            mode = "v",
            desc = "Notes: tighten",
        },
        {
            "<leader>nk",
            function()
                require("codecompanion").prompt("callouts")
            end,
            mode = "v",
            desc = "Notes: add callouts",
        },
        {
            "<leader>np",
            function()
                require("codecompanion").prompt("proof")
            end,
            mode = "v",
            desc = "Notes: proofread",
        },
        -- Format conversion.
        {
            "<leader>nT",
            function()
                require("codecompanion").prompt("md2typ")
            end,
            mode = "v",
            desc = "Notes: convert to Typst",
        },
        {
            "<leader>nM",
            function()
                require("codecompanion").prompt("typ2md")
            end,
            mode = "v",
            desc = "Notes: convert to Markdown",
        },
        {
            "<leader>nm",
            function()
                require("codecompanion").prompt("typstmath")
            end,
            mode = "v",
            desc = "Notes: LaTeX math -> Typst math",
        },
    },
    opts = {
        interactions = {
            chat = {
                adapter = {
                    name = "claude_code",
                    model = "claude-opus-4-8", -- opus/sonnet aliases or pinned names also work
                },
            },
            -- No `inline` block: it would fall back to an HTTP adapter and need an API key.
        },

        adapters = {
            http = {
                opts = { show_defaults = false }, -- stop loading anthropic/openai/etc.; kills the missing-key warning
            },
            acp = {
                claude_code = function()
                    return require("codecompanion.adapters").extend("claude_code", {
                        env = {
                            -- Usually unnecessary if you've run `/login`: the bridge inherits your
                            -- session. For a headless/explicit token, run `claude setup-token`:
                            -- CLAUDE_CODE_OAUTH_TOKEN = "cmd:cat ~/.config/nvim/.claude-oauth",

                            -- Effort: low|medium|high|xhigh|max. Overrides all other sources.
                            CLAUDE_CODE_EFFORT_LEVEL = "high",
                        },
                        defaults = {
                            mcpServers = "inherit_from_config",
                            timeout = 20000,
                        },
                    })
                end,
            },
            -- No `http` table at all -> Anthropic API is never contacted.
        },

        display = {
            diff = { enabled = true, provider = "default" },
            chat = { show_token_count = true },
        },

        prompt_library = {
            ["Rewrite Notes"] = {
                strategy = "chat",
                description = "Rewrite the selection to be clearer (Markdown or Typst)",
                opts = { short_name = "rewrite", is_slash_cmd = true, modes = { "v" }, auto_submit = true },
                prompts = {
                    {
                        role = "system",
                        content = system([==[
You revise the user's selected notes.
Rules:
- Return ONLY the rewritten markup, in the same format as the input. No code
  fences, no preamble, no commentary.
- Keep all technical claims, symbols, and cross-references intact.
- Improve clarity, flow, and word choice; do not add new facts.]==]),
                    },
                    {
                        role = "user",
                        content = "Rewrite the selection to read more clearly while keeping the same meaning and structure.",
                    },
                },
            },

            ["Notes to Textbook"] = {
                strategy = "chat",
                description = "Turn terse lecture notes into polished textbook prose",
                opts = { short_name = "textbook", is_slash_cmd = true, modes = { "v" }, auto_submit = true },
                prompts = {
                    {
                        role = "system",
                        content = system([==[
You convert terse lecture notes into polished, textbook-style exposition.
Rules:
- Return ONLY the rewritten markup, in the same format as the input. No code
  fences, no preamble.
- Preserve all math exactly and keep every mathematical result.
- Expand shorthand into full sentences and connect steps with clear transitions.
- Keep an expository, precise tone suited to a graduate-level text.
- Preserve existing headings, labels, and cross-references; do not invent
  citations.]==]),
                    },
                    {
                        role = "user",
                        content = "Rewrite the selection as finished textbook exposition, filling in reasoning left implicit in the notes without introducing new claims.",
                    },
                },
            },

            ["Tighten"] = {
                strategy = "chat",
                description = "Make the selection more concise",
                opts = { short_name = "tighten", is_slash_cmd = true, modes = { "v" }, auto_submit = true },
                prompts = {
                    {
                        role = "system",
                        content = system([==[
You tighten the user's selected markup.
Rules:
- Return ONLY the rewritten markup, in the same format as the input. No fences,
  no commentary.
- Cut redundancy and filler; keep every distinct claim, symbol, and math
  expression.
- Do not omit content to save space; compress phrasing, not meaning.]==]),
                    },
                    { role = "user", content = "Tighten the selection: same information, fewer words." },
                },
            },

            ["Add Callouts"] = {
                strategy = "chat",
                description = "Wrap key results in the format's theorem environments",
                opts = { short_name = "callouts", is_slash_cmd = true, modes = { "v" }, auto_submit = true },
                prompts = {
                    {
                        role = "system",
                        content = function(context)
                            return [==[
You add structure to the user's selected notes by marking up their results.
Rules:
- Return ONLY the rewritten markup, in the same format as the input. No fences,
  no preamble.
- Preserve all math and every claim exactly; do not rewrite the mathematics.
- Add headings only where they clarify; keep changes minimal and faithful.
]==] .. environment_rules(context) .. "\n" .. markup_rules(context)
                        end,
                    },
                    {
                        role = "user",
                        content = "Restructure the selection with the appropriate theorem environments, leaving the substance unchanged.",
                    },
                },
            },

            ["Proofread"] = {
                strategy = "chat",
                description = "Fix grammar, spelling, and markup without changing meaning",
                opts = { short_name = "proof", is_slash_cmd = true, modes = { "v" }, auto_submit = true },
                prompts = {
                    {
                        role = "system",
                        content = system([==[
You proofread the user's selected markup.
Rules:
- Return ONLY the corrected markup, in the same format as the input. No fences,
  no commentary.
- Fix grammar, spelling, punctuation, and broken markup or math syntax. In
  Typst this includes unbalanced $ $ delimiters, [ ] content blocks and #call
  parentheses; in Markdown, unbalanced $ / $$ and \begin{}...\end{} pairs.
- Do NOT change wording, tone, or meaning beyond what the corrections require.
- Never alter the value of any math expression.]==]),
                    },
                    { role = "user", content = "Proofread the selection and return the corrected version." },
                },
            },

            ["Markdown to Typst"] = {
                strategy = "chat",
                description = "Translate the selected Markdown + LaTeX into idiomatic Typst",
                opts = { short_name = "md2typ", is_slash_cmd = true, modes = { "v" }, auto_submit = true },
                prompts = {
                    {
                        role = "system",
                        content = [==[
You translate Markdown notes with LaTeX/KaTeX math into idiomatic Typst.
Rules:
- Return ONLY Typst markup. No code fences, no preamble, no commentary.
- Structure: # -> =, ## -> ==, ### -> ===. *italic* and _italic_ -> _italic_;
  **bold** -> *bold*. Bullets stay -, ordered lists become +.
- Elements: [t](u) -> #link("u")[t]; ![alt](p) -> #figure(image("p"),
  caption: [alt]); footnotes -> #footnote[...]; blockquotes ->
  #quote(block: true)[...]; tables -> #table(columns: n, ...). Fenced code
  blocks keep their triple-backtick raw-block form.
- Math delimiters: inline $x$ stays $x$; display $$...$$ becomes a $ ... $
  block with spaces inside the delimiters, on its own lines.
- Math content must be translated, not copied through, using the reference
  below.
- Obsidian callouts become the ctheorems-style call of the same name
  (> [!theorem] -> #theorem[...]). Add at most one trailing // comment naming
  the #import "@preview/ctheorems:..." and #show line the caller will need.
- Drop YAML front matter, or restate it as #set document(...) if it carries a
  title or author.
- Preserve every claim; translate the notation, not the content.

]==] .. MATH_MAP,
                    },
                    { role = "user", content = "Convert the selection to Typst." },
                },
            },

            ["Typst to Markdown"] = {
                strategy = "chat",
                description = "Translate the selected Typst back into Markdown + LaTeX",
                opts = { short_name = "typ2md", is_slash_cmd = true, modes = { "v" }, auto_submit = true },
                prompts = {
                    {
                        role = "system",
                        content = [==[
You translate Typst markup into Markdown with LaTeX/KaTeX math.
Rules:
- Return ONLY Markdown. No code fences around the whole answer, no preamble.
- Structure: =, ==, === -> #, ##, ###. _italic_ -> *italic*, *bold* -> **bold**.
  - and + lists -> - and 1.
- Elements: #link("u")[t] -> [t](u); #figure(image("p"), caption: [c]) ->
  ![c](p); #footnote[x] -> a [^n] footnote; #quote(block: true)[x] -> > x;
  #table(...) -> a pipe table.
- Math delimiters: inline $x$ stays $x$; a display $ x $ block becomes $$...$$
  on its own lines.
- Math content must be translated by applying the reference below in REVERSE
  (Typst -> LaTeX): a/b -> \frac{a}{b}, sqrt(x) -> \sqrt{x}, sum_(i=1)^n ->
  \sum_{i=1}^{n}, RR -> \mathbb{R}, cal(A) -> \mathcal{A}, "text" -> \text{...},
  norm(x) -> \|x\|, mat(a, b; c, d) -> \begin{pmatrix}...\end{pmatrix},
  cases(...) -> \begin{cases}...\end{cases}, lr((...)) -> \left(...\right).
- #theorem[...], #lemma[...], #definition[...], #proof[...] become the matching
  Obsidian callout: > [!theorem], > [!lemma], > [!definition], > [!proof].
- <label> and @label become the note's own anchor convention; if none exists,
  keep the label text in the heading and refer to it by name.
- Drop #set, #show and #import styling rules that have no Markdown meaning
  rather than emitting them as literal text. Keep every claim.

]==] .. MATH_MAP,
                    },
                    { role = "user", content = "Convert the selection to Markdown with LaTeX math." },
                },
            },

            ["Typst Math Cleanup"] = {
                strategy = "chat",
                description = "Rewrite pasted LaTeX math inside a Typst buffer as Typst math",
                opts = { short_name = "typstmath", is_slash_cmd = true, modes = { "v" }, auto_submit = true },
                prompts = {
                    {
                        role = "system",
                        content = [==[
You repair LaTeX math that has been pasted into Typst markup.
Rules:
- Return ONLY Typst markup. No code fences, no preamble, no commentary.
- Leave prose, structure, and already-idiomatic Typst untouched. This is a
  notation pass, not a rewrite.
- Convert delimiters: \( \) -> $...$ (inline), \[ \] and $$ $$ -> $ ... $ on
  their own lines (display, with spaces inside the delimiters).
- Convert every LaTeX construct using the reference below. Preserve the
  mathematical meaning exactly.
- If a construct has no direct Typst equivalent, express it with the closest
  primitive and mark that line with a trailing // TODO comment rather than
  guessing silently.

]==] .. MATH_MAP,
                    },
                    { role = "user", content = "Rewrite the LaTeX math in the selection as Typst math." },
                },
            },
        },
    },
}
