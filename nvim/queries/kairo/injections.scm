((line_comment) @injection.content
  (#set! injection.language "comment"))

((block_comment) @injection.content
  (#set! injection.language "comment"))

(inline_block
  language: (string) @_lang
  body: (raw_block) @injection.content
  (#any-of? @_lang "\"c++\"" "\"cpp\"")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.language "cpp"))

(inline_block
  language: (string) @_lang
  body: (raw_block) @injection.content
  (#eq? @_lang "\"c\"")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.language "c"))

(inline_block
  language: (string) @_lang
  body: (raw_block) @injection.content
  (#eq? @_lang "\"asm\"")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.language "asm"))
