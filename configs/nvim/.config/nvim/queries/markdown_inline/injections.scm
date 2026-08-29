; injections.scm
;
; NO `extends` modeline on purpose: this file must *replace* the bundled
; markdown_inline injections, which send every `$ .. $` to the latex parser.
; The html rule below is copied over from that query to keep it.
;
; Math can be either Typst or LaTeX, decided per buffer -- plain markdown
; defaults to Typst, notebook cells stay LaTeX because Jupyter renders them with
; MathJax.  Each delimiter therefore carries one rule per language, and the
; `#md-math?` predicate (registered in lua/sybil/core/mdmath.lua) picks between
; them.  See `:MdMath`.
;
; The `.` anchor matters: a latex_block has *two* latex_span_delimiter children,
; so without it every span matches twice and gets parsed twice.
; `include-children` keeps the `$` delimiters in the injected text; without them
; Typst would parse the body as markup instead of math.

((html_tag) @injection.content
  (#set! injection.language "html")
  (#set! injection.combined))

; ---------------------------------------------------------------------------
; Inline math `$x^2$` -- Typst uses the same delimiter, so it is handed over
; verbatim.
; ---------------------------------------------------------------------------
((latex_block . (latex_span_delimiter) @_delim) @injection.content
  (#eq? @_delim "$")
  (#md-math? "typst")
  (#set! injection.language "typst")
  (#set! injection.include-children))

((latex_block . (latex_span_delimiter) @_delim) @injection.content
  (#eq? @_delim "$")
  (#md-math? "latex")
  (#set! injection.language "latex")
  (#set! injection.include-children))

; ---------------------------------------------------------------------------
; Display math `$$ .. $$`.  Typst has no `$$` -- its display math is a single
; `$` with surrounding whitespace -- so one `$` is trimmed from each end before
; the block is handed over.  LaTeX takes `$$ .. $$` as-is.
; ---------------------------------------------------------------------------
((latex_block . (latex_span_delimiter) @_delim) @injection.content
  (#eq? @_delim "$$")
  (#md-math? "typst")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.language "typst")
  (#set! injection.include-children))

((latex_block . (latex_span_delimiter) @_delim) @injection.content
  (#eq? @_delim "$$")
  (#md-math? "latex")
  (#set! injection.language "latex")
  (#set! injection.include-children))
