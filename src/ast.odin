package demolang

Statement :: union {
	^Var_Statement,
	^Print_Statement,
	^Block_Statement,
	^Expression_Statement,
}

Var_Statement :: struct {
	name: Token,
	value: Maybe(Expression)
}

Print_Statement :: struct {
	target: Expression
}

Block_Statement :: struct {
	statements: []Statement
}

Expression_Statement :: struct {
	contains: Expression
}

Expression :: union {
	^Number_Node,
	^Call_Expression,
	^Function_Expression,
}

Call_Expression :: struct {
	target: Expression,
	arguments: []Expression,
}

Function_Expression :: struct {
	parameters: []Token,
	body: Block_Statement,
}

Number_Node :: struct {
	value: f64
}