package demolang

import "base:runtime"
import "core:fmt"
import "core:os"

Subcommand :: enum {
	Run,
	Lex,
	Help,
}

Subcommand_Info :: enum {
	Needs_Filepath,
}

subcommands := [Subcommand]bit_set[Subcommand_Info] {
	.Help = {},
	.Run  = {.Needs_Filepath},
	.Lex  = {.Needs_Filepath},
}

main :: proc() {
	subcommand := get_subcommand()
	process_subcommand(subcommand, subcommands[subcommand])
}

process_subcommand :: proc(cmd: Subcommand, info: bit_set[Subcommand_Info]) {
	source_code: string
	if .Needs_Filepath in info {
		if len(os.args) < 3 {
			fmt.eprintln("Error: Expected a file path for this subcommand")
			os.exit(1)
		}
		path := os.args[2]
		file_info, file_err := os.stat(path, context.temp_allocator)

		if file_err != nil {
			if file_err == .Not_Exist {
				fmt.eprintfln("Error: The path '%s' does not exist")
			} else {
				fmt.eprintfln("Error: %v", file_err)
			}
			os.exit(1)
		}

		if file_info.type != .Regular {
			fmt.eprintln("Error: Expected a file for this subcommand")
			os.exit(1)
		}

		file_contents, read_err := os.read_entire_file(file_info.fullpath, context.allocator)
		if read_err != nil {
			fmt.eprintln("Error: Failed to read file", read_err)
			os.exit(1)
		}
		source_code = string(file_contents)
	}

	switch cmd {
	case .Lex:
		tokens := tokenize_entire_file(source_code)
		for token in tokens {
			print_token(token)
		}
	case .Run:
		unimplemented("Run subcommand")
	case .Help:
		print_help()
		os.exit(0)
	}
}

get_subcommand :: proc() -> Subcommand {
	if len(os.args) < 2 {
		fmt.eprintln(
			"Error: Expected at least 1 argument to the program. Try 'help' for more information",
		)
		os.exit(1)
	}

	switch os.args[1] {
	case "run":
		return .Run
	case "help":
		return .Help
	case "lex":
		return .Lex
	case:
		{
			fmt.eprintfln(
				"Error: Invalid subcommand '%s'. Try 'help' for more information",
				os.args[1],
			)
			os.exit(1)
		}
	}


}
