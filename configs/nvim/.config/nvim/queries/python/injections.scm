; extends
;
; `extends` keeps nvim-treesitter's own python injections (regex inside re.*()
; calls, printf-style `%` strings, comments). Without it this file replaced
; them outright.

; SQL in `cursor.execute("...")` / `conn.execute("...")`. Uses the `sql` parser
; (in ensure_installed, see lua/sybil/plugins/treesitter/treesitter.lua). The
; content is the string's inside -- injecting the whole `(string)` node would
; hand the quotes to the SQL parser too.
(call
  function: (attribute
    attribute: (identifier) @_attribute)
  arguments: (argument_list
    (string
      (string_content) @injection.content))
  (#eq? @_attribute "execute")
  (#set! injection.language "sql"))
