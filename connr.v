/*
			Connr
                COmpiled laNguage learNing pRoject

        V1 Syntax Goal (COMPLETE):
                section(x)    -> section .x
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
				
			} else if c == '=' { // just read an assignment
				op = '='
				args << current.replace(' ', '')
				current = ''
				in_args = true
				continue
			}
			
			current += c
			
		} else { // in/after argument list
			if current.replace(' ', '') == '//' && !in_str {
				in_comment = true
				current += c
			
			} else if c == '"' && !in_comment {
				in_str = !in_str
				current += c
				
				if !in_str {
					args << current
					current = '|was%a%string|' // a bit hacky, FIXME
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
				
			} else if !(current == '' && c == ' ') {
				current += c
				
			}
		}
	}
	if op == '=' && current.replace(' ', '').replace('|was%a%string|', '') != '' {
		args << current
		current = ''
	}
	
	other = current.replace('|was%a%string|', '') // could be a comment or a curly brace
	if args == [''] { args = [] }
	
	return Symbol{op, label, args, other}
}

fn format_tokens(token Symbol, mut globals map[string]string) string {
	mut formatted := ''
	
	mut args := []string{}
	if token.op.to_lower() == 'mov' || token.op.to_lower() == 'lea' {
		args << token.args[1]
		args << token.args[0]
	} else if token.other.replace(' ', '') == '{' {
		if token.label != '' { return token.label + ':\n' + 'push rbp\nmov rbp, rsp\n' }
		return 'push rbp\nmov rbp, rsp\n'
	} else if token.other.replace(' ', '') == '}' {
		if token.label != '' { return token.label + ':\n' + 'mov rsp, rbp\npop rbp\nret\n' }
		return 'mov rsp, rbp\npop rbp\nret\n'
	} else if token.op == '=' {
		globals[token.args[0]] = token.args[1]
		return ''
	} else {
		args = token.args
	}
	
	for i, arg in args {
		if arg in globals.keys() {
			args[i] = '[$arg]'
		}
	}
	
	other := token.other.replace('//', ';')
	
	if token.label != '' { formatted += token.label + ': ' }
	if token.op    != '' { formatted += token.op + ' ' }
	if args 	   != [] { formatted += args.join(', ') }
	if other 	   != '' { formatted += other }
	return formatted + '\n'
}

fn get_type(value string) string {
	if value.contains('"') {
		return 'db '
	} else {
		return 'dq '
	}
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
	mut data := 'default rel\nsection .rodata\n'
	mut output := '\n\nsection .text'
	mut globals := map[string]string{}
	for line in lines {
		symbol := tokenize_line(line)
		output += format_tokens(symbol, mut globals)
	}
	
	for label, mut value in globals {
		if value in globals.keys() { value = '[$value]' }
		data += label + ': ' + get_type(value) + value
		if value.contains('"') { data += ', 0' }
		data += '\n'
		
	}
	
	println('INFO: Writing file...')
	os.write_file(filename_out, data+output) or {
		eprintln('ERROR: Failed to write the file: $err')
		return
	}
	
	println('INFO: Output written to $filename_out')
	return
}