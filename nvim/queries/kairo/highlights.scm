; Kairo highlights for Neovim. Later patterns win, so this runs general to
; specific.

(identifier) @variable

((identifier) @type
  (#lua-match? @type "^[A-Z][A-Za-z0-9_]*[a-z]"))

((identifier) @constant
  (#lua-match? @constant "^[A-Z][A-Z0-9_]+$"))

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
(char) @character

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
(module_decl name: (path (identifier) @module))
(module_pin (path (identifier) @module))
(import_path (identifier) @module)

; members, parameters, variants
(member_expr member: (identifier) @variable.member)
(field_spec name: (identifier) @variable.member)
(field_initializer name: (identifier) @variable.member)
(field_initializer_tail name: (identifier) @variable.member)
(param name: (identifier) @variable.parameter)
(macro_param (identifier) @variable.parameter)
(named_argument name: (identifier) @variable.parameter)
(enum_variant name: (identifier) @constant)
(dotted_variant_expr name: (identifier) @constant)
(dotted_pattern name: (identifier) @constant)
(labeled_stmt label: (identifier) @label)
(break_stmt (identifier) @label)
(continue_stmt (identifier) @label)

(self) @variable.builtin
(wildcard_pattern) @variable.builtin

; functions
(function_decl (identifier) @function)
(function_decl (identifier) @type . "::")
(function_decl (identifier) @type . (generic_args) . "::")
(function_decl (operator_name) @operator)
(call_expr function: (identifier_expr (identifier) @function.call))
(call_expr function: (scope_expr member: (identifier) @function.call))
(call_expr function: (generic_path_expr name: (identifier_expr (identifier) @function.call)))
(call_expr function: (member_expr member: (identifier) @function.method.call))

; macros and attributes
(macro_decl name: (identifier) @function.macro)
(macro_invocation name: (identifier) @function.macro)
(macro_type (identifier) @function.macro)
(annotation "@" @attribute name: (_) @attribute)
(attributed_expr "@" @attribute name: (_) @attribute)
(hash_attribute) @attribute

; comments
[(line_comment) (block_comment)] @comment @spell

((line_comment) @comment.documentation
  (#lua-match? @comment.documentation "^///"))

((block_comment) @comment.documentation
  (#lua-match? @comment.documentation "^/%*%*[^*]"))
