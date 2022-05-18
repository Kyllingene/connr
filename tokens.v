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
				op = current.replace(' ', '').replace('\t', '')
				current = ''
				in_args = true
				continue
				
			} else if c == ':' { // just read a label
				label = current
				current = ''
				continue
				
			} else if c == '=' { // just read an assignment
				op = '='
				args << current.replace(' ', '').replace('\t', '')
				current = ''
				in_args = true
				continue
			} else if c == '/' && current == '/' {
				return Symbol{'', '', [], ''}
			}
			
			current += c
			
		} else { // in/after argument list
			if current.replace(' ', '').replace('\t', '') == '//' && !in_str {
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
				
				args << current.replace(' ', '').replace('\t', '')
				current = ''
				
			} else if c == ')' && !in_str && !in_comment {
				args << current.replace(' ', '').replace('\t', '')
				current = ''
				
			} else if c == '/' && current.ends_with('/') {
				args << current[..(current.len)]
				break
				
			} else if !(current == '' && c == ' ') && !in_comment {
				current += c
				
			}
		}
	}
	if op == '=' && current.replace(' ', '').replace('\t', '').replace('|was%a%string|', '') != '' {
		args << current
		current = ''
	}
	
	other = current.replace('|was%a%string|', '') // could be a comment or a curly brace
	if args == [''] { args = [] }
	
	return Symbol{op, label, args, other}
}