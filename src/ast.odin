package demolang

Statement :: union {
	^Var_Statement,
	^Print_Statement,
	^Block_Statement,
	^Expression_Statement,
}

Var_Statement :: struct {
	name:  Token,
	value: Maybe(Expression),
}

Print_Statement :: struct {
	target: Expression,
}

Block_Statement :: struct {
	statements: []Statement,
}

Expression_Statement :: struct {
	contents: Expression,
}

Expression :: union {
	^Number_Node,
	^Identifier_Node,
	^Call_Expression,
	^Binary_Expression,
	^Unary_Expression,
	^Function_Expression,
}

Call_Expression :: struct {
	target:    Expression,
	arguments: []Expression,
}

Function_Expression :: struct {
	parameters: []string,
	body:       ^Block_Statement,
}

Number_Node :: struct {
	value: f64,
}

Identifier_Node :: struct {
	value: string,
}

Binary_Op_Type :: enum {
	Invalid,
	Addition,
	Subtraction,
	Multiplication,
	Division,
}

binary_op_types := #partial [Token_Type]Binary_Op_Type {
	.Plus = .Addition,
	.Minus = .Subtraction,
	.Star = .Multiplication,
	.Slash = .Division
}

Unary_Op_Type :: enum {
	Invalid,
	Plus,
	Negation,
	Not,
}

unary_op_types := #partial [Token_Type]Unary_Op_Type {
	.Plus = .Plus,
	.Minus = .Negation,
}

Binary_Expression :: struct {
	left, right: Expression,
	operator:    Binary_Op_Type,
}

Unary_Expression :: struct {
	operand:  Expression,
	operator: Unary_Op_Type,
}

