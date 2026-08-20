; injections.scm
;; extends
; Inject latex into block equations $$ ... $$
(latex_block) @injection.content
  (#set! injection.language "latex")
  (#set! injection.combined)

; Inject latex into inline equations $ ... $
(latex_span_delimiter) @injection.content
  (#set! injection.language "latex")
  (#set! injection.combined)
