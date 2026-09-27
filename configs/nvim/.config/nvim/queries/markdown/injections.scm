; injections.scm
;
; NO `extends` modeline on purpose: this replaces nvim-treesitter's markdown
; injections.  It is the same query minus `injection.combined` on html_block --
; see the PERFORMANCE note in ../markdown_inline/injections.scm.  One combined
; pattern makes Neovim rescan the whole document for injections on every
; parse, which in a long note is the difference between ~5ms and ~50ms per
; keystroke.  Extending files (snacks.nvim's ```math -> latex rule) are still
; appended on top of this one.

(fenced_code_block
  (info_string
    (language) @injection.language)
  (code_fence_content) @injection.content)

((html_block) @injection.content
  (#set! injection.language "html")
  (#set! injection.include-children))

((minus_metadata) @injection.content
  (#set! injection.language "yaml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

((plus_metadata) @injection.content
  (#set! injection.language "toml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

([
  (inline)
  (pipe_table_cell)
] @injection.content
  (#set! injection.language "markdown_inline"))
