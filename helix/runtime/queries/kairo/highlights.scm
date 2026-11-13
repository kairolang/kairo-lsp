; Kairo highlights for Helix. The first pattern that matches a node wins, so
; this runs specific to general (the reverse of the Neovim file).

; comments
((line_comment) @comment.line.documentation
  (#match? @comment.line.documentation "^///"))
((block_comment) @comment.block.documentation
  (#match? @comment.block.documentation "^/\\*\\*[^*]"))
(line_comment) @comment.line
(block_comment) @comment.block

; macros and attributes
(macro_decl name: (identifier) @function.macro)
(macro_invocation name: (identifier) @function.macro)
(macro_type (identifier) @function.macro)
(annotation "@" @attribute name: (_) @attribute)
(attributed_expr "@" @attribute name: (_) @attribute)
(hash_attribute) @attribute

; functions
(function_decl (identifier) @type . "::")
(function_decl (identifier) @type . (generic_args) . "::")
(function_decl (operator_name) @operator)
(function_decl (identifier) @function)
(call_expr function: (member_expr member: (identifier) @function.method))
(call_expr function: (identifier_expr (identifier) @function))
(call_expr function: (scope_expr member: (identifier) @function))
(call_expr function: (generic_path_expr name: (identifier_expr (identifier) @function)))

; modules
(module_decl name: (path (identifier) @namespace))
(module_pin (path (identifier) @namespace))
(import_path (identifier) @namespace)

; members, parameters, variants, labels
(member_expr member: (identifier) @variable.other.member)
(field_spec name: (identifier) @variable.other.member)
(field_initializer name: (identifier) @variable.other.member)
(field_initializer_tail name: (identifier) @variable.other.member)
(param name: (identifier) @variable.parameter)
(macro_param (identifier) @variable.parameter)
(named_argument name: (identifier) @variable.parameter)
(enum_variant name: (identifier) @type.enum.variant)
(dotted_variant_expr name: (identifier) @type.enum.variant)
(dotted_pattern name: (identifier) @type.enum.variant)
(labeled_stmt label: (identifier) @label)
(break_stmt (identifier) @label)
(continue_stmt (identifier) @label)

(self) @variable.builtin
(wildcard_pattern) @variable.builtin

; types
((identifier) @type.builtin
  (#any-of? @type.builtin
    "void" "bool" "byte" "char" "usize" "isize" "string" "Self"
    "u8" "u16" "u32" "u64" "u128" "u256" "u512"
    "i8" "i16" "i32" "i64" "i128" "i256" "i512"
    "f8" "f16" "f32" "f64" "f128" "f256" "f512"
    "f80" "bf16" "f8e4m3" "f8e5m2"))
(path_type_segment name: (identifier) @type)
(generic_param name: (identifier) @type.parameter)
(class_decl name: (identifier) @type)
(struct_decl name: (identifier) @type)
(union_decl name: (identifier) @type)
(interface_decl name: (identifier) @type)
(enum_decl name: (identifier) @type)
(type_alias_decl name: (identifier) @type)

; literals
(boolean) @constant.builtin.boolean
(null) @constant.builtin
(builtin) @constant.builtin
(float) @constant.numeric.float
(number) @constant.numeric.integer
(tuple_index) @constant.numeric.integer
(string) @string
(char) @constant.character

; keywords
"fn" @keyword.function
[
  "class" "struct" "union" "interface" "enum" "extend" "type" "module"
] @keyword.storage.type
(kind_bound) @keyword.storage.type
["import" "ffi"] @keyword.control.import
[
  "var" "const" "static" "thread" "eval" "inline" "virtual" "override"
  "final" "unsafe" "mutable" "volatile" "atomic" "pub" "priv" "prot"
] @keyword.storage.modifier
["if" "else" "match" "case" "default"] @keyword.control.conditional
["while" "loop" "for" "in" "break" "continue"] @keyword.control.repeat
["return" "yield"] @keyword.control.return
["try" "catch" "finally" "panic"] @keyword.control.exception
["async" "await" "spawn"] @keyword.control
[
  "sizeof" "alignof" "typeof" "delete"
  "and" "or" "xor" "not" "bitand" "bitor" "not_eq" "compl"
  "and_eq" "or_eq" "xor_eq"
] @keyword.operator
[
  "derives" "impl" "requires" "where" "op" "as" "test" "macro" "assert"
] @keyword
(special_body) @keyword

; punctuation and operators
(generic_params ["<" ">"] @punctuation.bracket)
(generic_args ["<" ">"] @punctuation.bracket)
(binary_expr operator: ["<" ">"] @operator)
(assignment_expr operator: ">" @operator)
[
  "=" "+=" "-=" "*=" "/=" "%=" "&=" "|=" "^=" "<<=" ">>=" "@="
  "+" "-" "*" "/" "%" "^^" "<<" "^" "|" "&" "~" "!" "?" "??"
  "==" "!=" "===" "<=>" "<=" ">=" "&&" "||" "++" "--" ".." "..=" "..."
  "->" "=>" ".*" "->*" "?.*" "?->*" "?." "?->"
] @operator
["(" ")" "[" "]" "{" "}"] @punctuation.bracket
["," ";" ":" "::" "."] @punctuation.delimiter

; names by spelling, last: anything above is more specific
((identifier) @constant
  (#match? @constant "^[A-Z][A-Z0-9_]+$"))
((identifier) @type
  (#match? @type "^[A-Z][A-Za-z0-9_]*[a-z]"))
(identifier) @variable
