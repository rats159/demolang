package demolang

import "core:fmt"
import "core:strings"

print_token :: proc(t: Token) {
	#partial switch t.type {
	case .Identifier, .Number:
		fmt.printfln("%s[%s]", t.type, t.value)
	case:
		fmt.println(t.type)
	}
}

print_program :: proc(program: ^Block_Statement) {
	builder: strings.Builder

	print_statement(program, 0, &builder)

	fmt.println(string(builder.buf[:]))
}

write_indent :: proc(indent: int, builder: ^strings.Builder) {
	for _ in 0 ..< indent {
		fmt.sbprint(builder, "    ")
	}
}

print_statement :: proc(statement: Statement, indent: int, buf: ^strings.Builder) {
	switch type in statement {
	case ^Var_Statement:
		fmt.sbprintln(buf, "Variable declaration: {")
		write_indent(indent + 1, buf)
		fmt.sbprintfln(buf, "Name: %s,", type.name.value)
		if type.value != nil {
			write_indent(indent + 1, buf)
			fmt.sbprintf(buf, "Value: ")
			print_expression(type.value.?, indent + 1, buf)
		}
		write_indent(indent, buf)
		fmt.sbprintln(buf, "}")
	case ^Expression_Statement:
		fmt.sbprintln(buf, "Expression statement: {")
		write_indent(indent + 1, buf)
		fmt.sbprintf(buf, "Value: ")
		print_expression(type.contents, indent + 1, buf)
		write_indent(indent, buf)
		fmt.sbprintln(buf, "}")
	case ^Print_Statement:
		fmt.sbprintln(buf, "Echo statement: {")
		write_indent(indent + 1, buf)
		fmt.sbprintf(buf, "Value: ")
		print_expression(type.target, indent + 1, buf)
		write_indent(indent, buf)
		fmt.sbprintln(buf, "}")
	case ^Block_Statement:
		fmt.sbprintln(buf, "Block statement: {")
		for stmt in type.statements {
			write_indent(indent + 1, buf)
			print_statement(stmt, indent + 1, buf)
		}
		write_indent(indent, buf)
		fmt.sbprintln(buf, "}")
	}
}

print_expression :: proc(expr: Expression, indent: int, buf: ^strings.Builder) {
	switch type in expr {
	case ^Number_Node:
		fmt.sbprintln(buf, type.value)
	case ^Identifier_Node:
		fmt.sbprintln(buf, type.value)
	case ^Call_Expression:
		fmt.sbprintln(buf, "Call {")
		write_indent(indent + 1, buf)
		fmt.sbprint(buf, "Target: ")
		print_expression(type.target, indent + 1, buf)
		write_indent(indent + 1, buf)
		fmt.sbprintfln(buf, "Arguments: [")
		for arg in type.arguments {
			write_indent(indent + 2, buf)
			print_expression(arg, indent + 2, buf)
		}
		write_indent(indent + 1, buf)
		fmt.sbprintfln(buf, "]")
		write_indent(indent, buf)
		fmt.sbprintln(buf, "}")
	case ^Binary_Expression:
		fmt.sbprintln(buf, "Binary Operation {")
		write_indent(indent + 1, buf)
		fmt.sbprintf(buf, "Left: ")
		print_expression(type.left, indent + 1, buf)
		write_indent(indent + 1, buf)
		fmt.sbprintf(buf, "Right: ")
		print_expression(type.right, indent + 1, buf)
		write_indent(indent + 1, buf)
		fmt.sbprintfln(buf, "Operation: %s", type.operator)
		write_indent(indent, buf)
		fmt.sbprintln(buf, "}")
	case ^Unary_Expression:
		fmt.sbprintln(buf, "Unary Operation {")
		write_indent(indent + 1, buf)
		fmt.sbprintf(buf, "Operand: ")
		print_expression(type.operand, indent + 1, buf)
		write_indent(indent + 1, buf)
		fmt.sbprintfln(buf, "Operation: %s", type.operator)
		write_indent(indent, buf)
		fmt.sbprintln(buf, "}")
	case ^Function_Expression:
		fmt.sbprintln(buf, "Function node {")
		write_indent(indent + 1, buf)
		fmt.sbprintfln(buf, "Parameters: %v", type.parameters)
		write_indent(indent + 1, buf)
		fmt.sbprintf(buf, "Body: ")
		print_statement(type.body, indent + 1, buf)
		write_indent(indent, buf)
		fmt.sbprintln(buf, "}")
	}
}


print_help :: proc() {
	fmt.eprintln(
		"""
Demolang is a small programming language designed to be extended.
Fork it, break it, make it cool.

Subcommands:
- 'run <filepath>':  Runs a Demolang (.dl) file
- 'lex <filepath>':  Lexes (tokenizes) a Demolang file, and writes the tokens to stdout
- 'parse <filepath>':  Parses a Demolang file, and writes the AST to stdout
- 'help': Prints this message
""",
	)
}
