package demolang

import "core:fmt"
import "core:os"
import "core:strconv"

Parser :: struct {
	tk:            Tokenizer,
	current_token: Token,
}

parse_entire_file :: proc(souce_code: string) -> ^Block_Statement {
	p := Parser {
		tk = Tokenizer{source_code = souce_code},
	}
	parser_advance(&p)
	return parse_statements_until(&p, .EOF)
}

parse_statements_until :: proc(p: ^Parser, token_type: Token_Type) -> ^Block_Statement {
	statements: [dynamic]Statement
	for !parser_match(p, token_type) {
		append(&statements, parse_statement(p))
	}

	block := parser_new(p, Block_Statement)
	block.statements = statements[:]
	return block
}

parse_statement :: proc(p: ^Parser) -> Statement {
	#partial switch parser_current(p).type {
	case .Var:
		return parse_variable_declaration(p)
	case .Print:
		return parse_print_statement(p)
	case .Open_Curly:
		_ = parser_expect(p, .Open_Curly)
		return parse_statements_until(p, .Close_Curly)
	case:
		return parse_expression_statement(p)
	}
}

parse_expression_statement :: proc(p: ^Parser) -> Statement {
	expr := parse_expression(p, .None)
	_ = parser_expect(p, .Semicolon)

	node := parser_new(p, Expression_Statement)
	node.contents = expr

	return node
}

parse_print_statement :: proc(p: ^Parser) -> Statement {
	_ = parser_expect(p, .Print)
	val := parse_expression(p, .None)
	_ = parser_expect(p, .Semicolon)

	node := parser_new(p, Print_Statement)
	node.target = val

	return node
}

parse_variable_declaration :: proc(p: ^Parser) -> Statement {
	_ = parser_expect(p, .Var)
	name := parser_expect(p, .Identifier)
	_ = parser_expect(p, .Equals)
	value := parse_expression(p, .None)
	_ = parser_expect(p, .Semicolon)

	node := parser_new(p, Var_Statement)
	node.name = name
	node.value = value

	return node
}

Binding_Power :: enum {
	None,
	Add_Sub_Left,
	Add_Sub_Right,
	Mul_Div_Left,
	Mul_Div_Right,
	Unary_Plus_Minus,
	Not,
}

binary_binding_power :: proc(operation: Binary_Op_Type) -> (Binding_Power, Binding_Power) {
	switch operation {
	case .Invalid:
		panic("")
	case .Addition, .Subtraction:
		return .Add_Sub_Left, .Add_Sub_Right
	case .Multiplication, .Division:
		return .Mul_Div_Left, .Mul_Div_Right
	}

	panic("unreachable")
}

unary_binding_power :: proc(operation: Unary_Op_Type) -> Binding_Power {
	switch operation {
	case .Invalid:
		panic("")
	case .Plus, .Negation:
		return .Unary_Plus_Minus
	case .Not:
		return .Not
	}

	panic("unreachable")
}

parse_expression :: proc(p: ^Parser, min_bp: Binding_Power) -> Expression {
	left := parse_prefix_expression(p, min_bp)

	for {
		operator_token := parser_current(p)
		operation := binary_op_types[operator_token.type]

		if operation == .Invalid {
			break
		}

		left_bp, right_bp := binary_binding_power(operation)

		if left_bp < min_bp {
			break
		}

		parser_advance(p)

		right := parse_expression(p, right_bp)

		node := parser_new(p, Binary_Expression)
		node.left = left
		node.right = right
		node.operator = operation
		left = node
	}

	return left
}

parse_prefix_expression :: proc(p: ^Parser, in_bp: Binding_Power) -> Expression {
	operator_token := parser_current(p)
	node: Expression

	operation := unary_op_types[operator_token.type]

	if operation == .Invalid {
		node = parse_value_expression(p)
	} else {
		parser_advance(p)
		new_bp := unary_binding_power(operation)
	}

	return parse_postfix_expression(p, node, in_bp)
}

parse_postfix_expression :: proc(p: ^Parser, lhs: Expression, bp: Binding_Power) -> Expression {
	lhs := lhs

	outer: for {
		#partial switch parser_current(p).type {
		case .Open_Paren:
			lhs = parse_call(p, lhs)
		case:
			return lhs
		}
	}
}

parse_call :: proc(p: ^Parser, target: Expression) -> Expression {
	_ = parser_expect(p, .Open_Paren)
	arguments: [dynamic]Expression
	for !parser_match(p, .Close_Paren) {
		argument := parse_expression(p, .None)
		append(&arguments, argument)
		if parser_match(p, .Close_Paren) {
			break
		}
		_ = parser_expect(p, .Comma)
	}

	new_node := parser_new(p, Call_Expression)
	new_node.arguments = arguments[:]
	new_node.target = target

	return new_node
}

parse_value_expression :: proc(p: ^Parser) -> Expression {
	token := parser_current(p)
	#partial switch token.type {
	case .Open_Paren:
		parser_advance(p)
		expr := parse_expression(p, .None)
		parser_expect(p, .Close_Paren)
		return expr
	case .Number:
		return parse_number_node(p)
	case .Identifier:
		return parse_identifier_node(p)
	case .Fun:
		return parse_fun_node(p)
	}

	parser_error(p, token, "Unexpected token '%v'", token.value)
}

parse_fun_node :: proc(p: ^Parser) -> Expression {
	_ = parser_expect(p, .Fun)


	parameters: [dynamic]string
	_ = parser_expect(p, .Open_Paren)
	if !parser_match(p, .Close_Paren) {
		for {
			param_name := parser_expect(p, .Identifier)
			append(&parameters, param_name.value)
			if !parser_match(p, .Comma) {
				parser_expect(p, .Close_Paren)
				break
			}
		}
	}
	_ = parser_expect(p, .Open_Curly)
	body := parse_statements_until(p, .Close_Curly)

	node := parser_new(p, Function_Expression)
	node.parameters = parameters[:]
	node.body = body

	return node
}

parse_number_node :: proc(p: ^Parser) -> Expression {
	tok := parser_expect(p, .Number)
	num, ok := strconv.parse_f64(tok.value)
	assert(ok, "Tokenizer created bad number")

	node := parser_new(p, Number_Node)
	node.value = num
	return node
}

parse_identifier_node :: proc(p: ^Parser) -> Expression {
	tok := parser_expect(p, .Identifier)
	node := parser_new(p, Identifier_Node)
	node.value = tok.value
	return node
}

parser_match :: proc(p: ^Parser, type: Token_Type) -> bool {
	if parser_current(p).type == type {
		parser_advance(p)
		return true
	}
	return false
}

parser_expect :: proc(p: ^Parser, type: Token_Type) -> Token {
	token := parser_current(p)
	if token.type == type {
		parser_advance(p)
		return token
	}
	parser_error(p, token, "Expected '%v' but received '%v'", type, token.type)
}

parser_new :: proc(p: ^Parser, $T: typeid) -> ^T {
	return new(T)
}

parser_current :: proc(p: ^Parser) -> Token {
	assert(p.current_token.type != .Invalid)
	return p.current_token
}

parser_advance :: proc(p: ^Parser) {
	token := scan_next_token(&p.tk)
	p.current_token = token
}

parser_error :: proc(p: ^Parser, tk: Token, format_string: string, args: ..any) -> ! {
	line, col := find_line_col_from_offset(p.tk.source_code, tk.offset)
	fmt.eprintf("Parser error at %d:%d: ", line, col)
	fmt.eprintfln(format_string, ..args)
	os.exit(1)
}
