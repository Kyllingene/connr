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

struct Symbol {
	op string
	label string
	args []string
	other string
}


fn tokenize_line(line string) Symbol {
	mut op := ''
	mut args := []string{}
	mut label := ''
	mut other := ''
	
	mut in_args := false
	mut in_str := false
	mut in_comment := false
	
	mut current := ''
	for cc in line {
		c := cc.ascii_str()
		
		if !in_args { // still reading label/operator
			if c == '(' { // finished reading operator
				op = current.replace(' ', '')
				current = ''
				in_args = true
				continue
				
			} else if c == ':' { // just read a label
				label = current
				current = ''
				continue
				
			}
			
			current += c
			
		} else { // in/after argument list
			if current.replace(' ', '') == '//' {
				in_comment = true
				current += c
			
			} else if c == '"' && !in_comment {
				in_str = !in_str
				current += c
				
				if !in_str {
					args << current
					current = '|was%a%string|' // a bit hacky, fix later
				}
			
			} else if c == ',' && !in_str && !in_comment {
				if current == '|was%a%string|' {
					current = ''
					continue
				}
				
				args << current.replace(' ', '')
				current = ''
				
			} else if c == ')' && !in_str && !in_comment {
				args << current.replace(' ', '')
				current = ''
				
			} else {
				current += c
				
			}
		}
	}
	
	other = current
	if args == [''] { args = [] }
	
	return Symbol{op, label, args, other}
}

fn format_tokens(token Symbol) string {
	mut formatted := ''
	
	mut args := []string{}
	if token.op == 'section' {
		args << '.' + token.args[0]
	} else {
		args = token.args
	}
	
	other := token.other.replace('//', ';')
	
	if token.label != '' { formatted += token.label + ': ' }
	if token.op    != '' { formatted += token.op + ' ' }
	if args 	   != [] { formatted += args.join(', ') }
	if other 	   != '' { formatted += other }
	return formatted
}

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
		symbol := tokenize_line(line)
		output += format_tokens(symbol) + "\n"
	}
	
	println('INFO: Writing file...')
	os.write_file(filename_out, output) or {
		eprintln('ERROR: Failed to write the file: $err')
		return
	}
	
	println('INFO: Output written to $filename_out')
	return
}