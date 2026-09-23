package demolang

Parser :: struct {
	tk: Tokenizer,
	current: Token,
}

make_parser :: proc(source_code: string) -> Parser {
	return Parser {
		tk = Tokenizer {
			source_code = source_code
		}
	}
}

parse_file :: proc(source_code: string) {
	p := make_parser(source_code)
	
	program := parse_statements_until(&p, .EOF)
}

parse_statements_until :: proc(p: ^Parser, until: Token_Type) -> []Statement {
	statements: [dynamic]Statement
	
	for !parser_match(p, until) {
		stmt, failed := parse_statement(p)
		if !failed {
			append(&statements, stmt)
		}
	}

	return statements[:]
}

parse_statement :: proc(p: ^Parser) -> (Statement, bool) {
	unimplemented()
}

parse_expression :: proc(p: ^Parser) -> (Statement, bool) {
	unimplemented()
}

parser_match :: proc(p: ^Parser, type: Token_Type) -> bool {
	if parser_current(p).type == type {
		parser_advance(p)
		return true
	}

	return false
}

parser_current :: proc(p: ^Parser) -> Token {
	for p.current.type == .Invalid {
		parser_advance(p)
	}
	return p.current
}

parser_advance :: proc(p: ^Parser) -> Token {
	token := scan_next_token(&p.tk)
	p.current = token
	return token
}