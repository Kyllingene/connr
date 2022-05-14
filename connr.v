/*
			Connr
                COmpiled laNguage learNing pRoject

        V1 Syntax Goal:
                .section(x)    -> .section x
                .section(text) -> .section text \n default rel
                mov(x, y)      -> mov y, x
                ...

        V2 Syntax Goal:
                a = 20 -> (.section data) a: dq 20
*/
import os

fn main() {
	prog_args := os.args_after('connr')

	if prog_args.len < 2 {
		eprintln('ERROR: Please supply a file')
		return
	} else if prog_args.len < 3 {
		eprintln('ERROR: Please supply an output file')
	}

	filename := prog_args[1]
	filename_out := prog_args[2]

	println('INFO: Reading file...')
	text := os.read_file(filename) or {
		eprintln('ERROR: Failed to read the file: $err')
		return
	}

	println('INFO: Parsing file...')
	lines := text.split_into_lines()
	mut output := 'default rel\n'
	for line in lines {
		if line.replace(' ', '') == '' {
			output += '\n'
		} else if line.starts_with('//') {
			output += line.replace('//', ';') + '\n'
		} else if line.starts_with('section') {
			output += 'section '
			output += '.' + line.split('(')[1].split(')')[0].replace('.', '') + '\n'
		} else if !line.contains("(") || !line.contains(")") {
			eprintln("ERROR: Invalid syntax:\n   $line")
			return
		} else {
			op := line.split('(')[0].replace(' ', '')
			args := line.split('(')[1].split(')')[0]
			
			output += op + ' '
			output += args + '\n'
			
		}
	}
	
	println('INFO: Writing file...')
	os.write_file(filename_out, output) or {
		eprintln('ERROR: Failed to write the file: $err')
		return
	}
	
	println('INFO: Output written to $filename_out')
	return
}