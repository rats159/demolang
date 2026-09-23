package demolang

import "core:unicode/utf8"
Token_Type :: enum {
	Invalid,
	// Keywords
	Var,
	Fun,
	Print,
	// Literals
	Identifier,
	Number,
	// Symbols
	Equals,
	Open_Paren,
	Close_Paren,
	Open_Curly,
	Close_Curly,
	Semicolon,
	EOF,
}

Token :: struct {
	type:  Token_Type,
	value: string,
}

Tokenizer :: struct {
	source_code:    string,
	byte_offset:    int,
	invalid_tokens: [dynamic]Token,
}

keyword_entries := #partial [Token_Type]string {
	.Var   = "var",
	.Fun   = "fun",
	.Print = "print",
}

tokenize_entire_file :: proc(source_code: string) -> []Token {
	tk := Tokenizer {
		source_code = source_code,
		byte_offset = 0,
	}

	tokens: [dynamic]Token

	for {
		tok := scan_next_token(&tk)

		append(&tokens, tok)

		if tok.type == .EOF {
			break
		}
	}

	return tokens[:]
}

scan_next_token :: proc(tk: ^Tokenizer) -> Token {
	if tk.byte_offset >= len(tk.source_code) {
		return Token{type = .EOF, value = "<EOF>"}
	}
	skip_whitespace(tk)
	switch tk_current_char(tk) {
	case 'a' ..= 'z', 'A' ..= 'Z', '_':
		return scan_word_token(tk)
	case '0' ..= '9':
		return scan_number_token(tk)
	case '=':
		return scan_simple_token(tk, .Equals, 1)
	case '(':
		return scan_simple_token(tk, .Open_Paren, 1)
	case ')':
		return scan_simple_token(tk, .Close_Paren, 1)
	case '{':
		return scan_simple_token(tk, .Open_Curly, 1)
	case '}':
		return scan_simple_token(tk, .Close_Curly, 1)
	case ';':
		return scan_simple_token(tk, .Semicolon, 1)
	case:
		return scan_invalid_token(tk)
	}
}

scan_invalid_token :: proc(tk: ^Tokenizer) -> Token {
	start := tk.byte_offset
	tk_advance_char(tk)

	text := tk.source_code[start:tk.byte_offset]
	token := Token {
		type  = .Invalid,
		value = text,
	}

	append(&tk.invalid_tokens, token)

	return token
}

scan_number_token :: proc(tk: ^Tokenizer) -> Token {
	number_start := tk.byte_offset
	integer_loop: for {
		switch tk_current_char(tk) {
		case '0' ..= '9', '_':
			tk_advance_char(tk)
		case:
			break integer_loop
		}
	}

	if tk_current_char(tk) == '.' {
		tk_advance_char(tk)
		decimal_loop: for {
			switch tk_current_char(tk) {
			case '0' ..= '9', '_':
				tk_advance_char(tk)
			case:
				break decimal_loop
			}
		}
	}

	number := tk.source_code[number_start:tk.byte_offset]

	return Token{value = number, type = .Number}
}

scan_word_token :: proc(tk: ^Tokenizer) -> Token {
	word_start := tk.byte_offset
	scanner_loop: for {
		switch tk_current_char(tk) {
		case 'a' ..= 'z', 'A' ..= 'Z', '0' ..= '9', '_':
			tk_advance_char(tk)
		case:
			break scanner_loop
		}
	}

	word := tk.source_code[word_start:tk.byte_offset]

	token_type := Token_Type.Identifier

	for keyword_name, keyword_type in keyword_entries {
		if word == keyword_name {
			token_type = keyword_type
		}
	}

	return Token{value = word, type = token_type}
}

scan_simple_token :: proc(tk: ^Tokenizer, type: Token_Type, length: int) -> Token {
	content := tk.source_code[tk.byte_offset:tk.byte_offset + length]
	tk.byte_offset += length
	return Token{type = type, value = content}
}

skip_whitespace :: proc(tk: ^Tokenizer) {
	for {
		switch tk_current_char(tk) {
		case ' ', '\r', '\n', '\t':
			tk_advance_char(tk)
		case:
			return
		}
	}
}

tk_advance_char :: proc(tk: ^Tokenizer) {
	_, character_size := utf8.decode_rune_in_string(tk.source_code[tk.byte_offset:])
	tk.byte_offset += character_size
}

tk_current_char :: proc(tk: ^Tokenizer) -> rune {
	r, _ := utf8.decode_rune_in_string(tk.source_code[tk.byte_offset:])
	return r
}
