(function_decl body: (_) @function.inside) @function.around
(closure_expr body: (_) @function.inside) @function.around
(class_decl body: (_) @class.inside) @class.around
(struct_decl body: (_) @class.inside) @class.around
(interface_decl body: (_) @class.inside) @class.around
(enum_decl body: (_) @class.inside) @class.around
(param) @parameter.inside
(line_comment) @comment.inside
(line_comment)+ @comment.around
(block_comment) @comment.inside
(block_comment) @comment.around
