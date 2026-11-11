; Kairo highlights for Zed.
;
; The same scheme as the Neovim plugin (nvim/queries/kairo/highlights.scm),
; with Zed's capture names. Later patterns win, so this runs general to
; specific. Dotted captures fall back to their prefix in a theme that does not
; define them (`@keyword.import` -> `@keyword`).
;
; This is the syntactic layer. kals lays semantic tokens over it
; (languages/kairo/semantic_token_rules.json).

(identifier) @variable

((identifier) @type
  (#match? @type "^[A-Z][A-Za-z0-9_]*[a-z]"))

((identifier) @constant
  (#match? @constant "^[A-Z][A-Z0-9_]+$"))

; punctuation and operators
["(" ")" "[" "]" "{" "}"] @punctuation.bracket
["," ";" ":" "::" "."] @punctuation.delimiter

[
  "=" "+=" "-=" "*=" "/=" "%=" "&=" "|=" "^=" "<<=" ">>=" "@="
  "+" "-" "*" "/" "%" "^^" "<<" "^" "|" "&" "~" "!" "?" "??"
  "==" "!=" "===" "<=>" "<=" ">=" "&&" "||" "++" "--" ".." "..=" "..."
  "->" "=>" ".*" "->*" "?.*" "?->*" "?." "?->"
] @operator

(binary_expr operator: ["<" ">"] @operator)
(assignment_expr operator: ">" @operator)
(generic_params ["<" ">"] @punctuation.bracket)
(generic_args ["<" ">"] @punctuation.bracket)

; keywords
[
  "derives" "impl" "requires" "where" "op" "as" "test" "macro" "assert"
] @keyword

"fn" @keyword.function

[
  "class" "struct" "union" "interface" "enum" "extend" "type" "module"
] @keyword.type

(kind_bound) @keyword.type

["import" "ffi"] @keyword.import

[
  "var" "const" "static" "thread" "eval" "inline" "virtual" "override"
  "final" "unsafe" "mutable" "volatile" "atomic" "pub" "priv" "prot"
] @keyword.modifier

["if" "else" "match" "case" "default"] @keyword.conditional
["while" "loop" "for" "in" "break" "continue"] @keyword.repeat
["return" "yield"] @keyword.return
["try" "catch" "finally" "panic"] @keyword.exception
["async" "await" "spawn"] @keyword.coroutine

[
  "sizeof" "alignof" "typeof" "delete"
  "and" "or" "xor" "not" "bitand" "bitor" "not_eq" "compl"
  "and_eq" "or_eq" "xor_eq"
] @keyword.operator

(special_body) @keyword

; literals
(boolean) @boolean
(null) @constant.builtin
(builtin) @constant.builtin
(number) @number
(float) @number.float
(tuple_index) @number
(string) @string
(char) @string.special
(raw_block) @embedded

; types
(path_type_segment name: (identifier) @type)
(generic_param name: (identifier) @type)
(class_decl name: (identifier) @type)
(struct_decl name: (identifier) @type)
(union_decl name: (identifier) @type)
(interface_decl name: (identifier) @type)
(enum_decl name: (identifier) @type)
(type_alias_decl name: (identifier) @type)

((identifier) @type.builtin
  (#any-of? @type.builtin
    "void" "bool" "byte" "char" "usize" "isize" "string" "Self"
    "u8" "u16" "u32" "u64" "u128" "u256" "u512"
    "i8" "i16" "i32" "i64" "i128" "i256" "i512"
    "f8" "f16" "f32" "f64" "f128" "f256" "f512"
    "f80" "bf16" "f8e4m3" "f8e5m2"))

; modules
(module_decl name: (path (identifier) @namespace))
(module_pin (path (identifier) @namespace))
(import_path (identifier) @namespace)

; members, parameters, variants
(member_expr member: (identifier) @property)
(field_spec name: (identifier) @property)
(field_initializer name: (identifier) @property)
(field_initializer_tail name: (identifier) @property)
(param name: (identifier) @variable.parameter)
(macro_param (identifier) @variable.parameter)
(capture (identifier) @variable.parameter)
(named_argument name: (identifier) @variable.parameter)
(enum_variant name: (identifier) @variant)
(dotted_variant_expr name: (identifier) @variant)
(dotted_pattern name: (identifier) @variant)
(labeled_stmt label: (identifier) @label)
(break_stmt (identifier) @label)
(continue_stmt (identifier) @label)

(self) @variable.special
(wildcard_pattern) @variable.special

; functions
(function_decl (identifier) @function)
(function_decl (identifier) @type . "::")
(function_decl (identifier) @type . (generic_args) . "::")
(function_decl (operator_name) @operator)
(call_expr function: (identifier_expr (identifier) @function))
(call_expr function: (scope_expr member: (identifier) @function))
(call_expr function: (generic_path_expr name: (identifier_expr (identifier) @function)))
(call_expr function: (member_expr member: (identifier) @function.method))

; macros and attributes
(macro_decl name: (identifier) @function.special)
(macro_invocation name: (identifier) @function.special)
(macro_type (identifier) @function.special)
(annotation "@" @attribute name: (_) @attribute)
(attributed_expr "@" @attribute name: (_) @attribute)
(hash_attribute) @attribute

; comments
[(line_comment) (block_comment)] @comment

((line_comment) @comment.doc
  (#match? @comment.doc "^///"))

((block_comment) @comment.doc
  (#match? @comment.doc "^/\\*\\*[^*]"))
