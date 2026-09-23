package demolang

import "core:fmt"

print_token :: proc(t: Token) {
	#partial switch t.type {
	case .Identifier, .Number:
		fmt.printfln("%s[%s]", t.type, t.value)
	case:
		fmt.println(t.type)
	}
}

print_help :: proc() {
	fmt.eprintln(
		"""
Demolang is a small programming language designed to be extended.
Fork it, break it, make it cool.

Subcommands:
- 'run <filepath>':  Runs a Demolang (.dl) file
- 'lex <filepath>':  Lexes (tokenizes) a Demolang file, and writes the result to stdout
- 'help': Prints this message
""",
	)
}
