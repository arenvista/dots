; injections.scm
;
; NO `extends` modeline on purpose: this file must *replace* the bundled
; markdown_inline injections, which send every `$ .. $` to the latex parser.
;
; Math can be either Typst or LaTeX, decided per buffer -- plain markdown
; defaults to Typst, notebook cells stay LaTeX because Jupyter renders them with
; MathJax.  See `:MdMath`.
;
; PERFORMANCE -- two rules this file must keep, both measured on a 740-line
; lecture note (258 inline trees, 285 math trees):
;
;   1. No `injection.combined` anywhere.  Neovim 0.12 turns *every* injection
;      scan into a full scan of all trees as soon as the query contains one
;      combined pattern (`has_combined_injections` in languagetree.lua), so a
;      one-line parse after a keystroke cost as much as parsing the whole note.
;      The upstream html rule carried it; inline html tags are simply parsed
;      one tag at a time now.  queries/markdown/injections.scm drops it for the
;      same reason.
;
;   2. One pattern per math span.  The `#md-math!` directive (registered in
;      lua/sybil/core/mdmath.lua) looks at the delimiter once and sets the
;      language -- and, for Typst `$$ .. $$`, trims one `$` off each end.  The
;      old four-pattern + `#md-math?` predicate version matched every span four
;      times and ran the predicate twice per span on every scan.
;
; `include-children` keeps the `$` delimiters in the injected text; without
; them Typst would parse the body as markup instead of math.  The `.` anchor
; picks the *opening* delimiter only (a latex_block has two).

((html_tag) @injection.content
  (#set! injection.language "html"))

((latex_block . (latex_span_delimiter) @_delim) @injection.content
  (#md-math! @_delim @injection.content)
  (#set! injection.include-children))
