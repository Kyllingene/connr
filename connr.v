/*
			Connr
                COmpiled laNguage learNing pRoject

        V1 Syntax Goal (COMPLETE):
                section(x)    -> section .x
                mov(x, y)     -> mov y, x
                ...

        V2 Syntax Goal (COMPLETE):
                a = 20 -> (.section data) a: dq 20

		V3 Goal:
				Allow choosing between 32/64 bit and Windows/Unix calling conventions
				Tidy up code & add comments
				Add more documentation
				Add more logging information
				
		V4 Syntax Goal:
				def x(str#y, dq#z) (v, w) { ... } -> x: add rsp, 16 \n ... sub rsp, 16
				call x(mystr, 10) -> lea rdi, [mystr] \n mov rsi, 10 \n call x
*/

import os

fn main() {
	prog_args := os.args_after('connr')
	mut filename_out := ''

	if prog_args.len < 2 {
		eprintln('ERROR: Please supply a file')
		return
	} else if prog_args.len < 3 {
		filename_out = prog_args[1].replace(os.file_ext(prog_args[1]), '') + '.asm'
		
	} else {
		filename_out = prog_args[2]
	}

	filename := prog_args[1]
	ext := os.file_ext(filename_out)
	mut filetype_out := ''
	
	if ext in asm_extensions {
		filetype_out = 'asm'
	} else if ext in brain_extensions {
		filetype_out = 'brain'
	} else {
		eprintln('ERROR: Invalid output format: $ext')
		return
	}

	println('INFO: Reading file...')
	if !os.exists(filename) {
		eprintln('ERROR: "$filename" does not exist')
		return
	}
	
	text := os.read_file(filename) or {
		panic('ERROR: Failed to read the file: $err')
	}

	println('INFO: Parsing file...')
	lines := text.split_into_lines()
	
	mut data := ''
	mut output := ''
	
	match filetype_out {
		'asm' { data = asm_data
		output = asm_text }
		
		'brain' { data = brain_data
			output = brain_text }
			
		else { panic('INTERNAL ERROR: Invalid filetype_out: $filetype_out') }
	}
	

	mut globals := map[string]string{}
	for line in lines {
		symbol := tokenize_line(line)
		
		mut line_out := ''
		match filetype_out {
			'asm' { line_out = asm_format(symbol, mut globals) or {eprintln(err) 
																	return }}
																	
			'brain' { line_out = brain_format(symbol, mut globals) or {eprintln(err) 
																	return }}
																	
			else { panic('INTERNAL ERROR: Invalid filetype_out: $filetype_out') }
		}
		
		output += line_out
	}
	
	match filetype_out {
		'asm' { data = asm_format_data(mut globals, data) or { eprintln(err) 
														return }}
		'brain' { data = brain_format_data(mut globals, data) or { eprintln(err)
															return }}
		else { panic('INTERNAL ERROR: Invalid filetype_out: $filetype_out') }
	}
	
	println('INFO: Writing file...')
	os.write_file(filename_out, data+output) or {
		panic('ERROR: Failed to write the file: $err')
	}
	
	println('INFO: Output written to "$filename_out"')
	return
}