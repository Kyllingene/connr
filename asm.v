fn asm_format(token Symbol, mut globals map[string]string) ?string {
	mut formatted := ''
	
	mut args := []string{}
	if token.op.to_lower() == 'mov' || token.op.to_lower() == 'lea' {
		args << token.args[1]
		args << token.args[0]
	} else if token.other.replace(' ', '').replace('\t', '') == '{' {
		if token.label != '' { return token.label + ':\n' + 'push rbp\nmov rbp, rsp\n' }
		return 'push rbp\nmov rbp, rsp\n'
	} else if token.other.replace(' ', '').replace('\t', '') == '}' {
		if token.label != '' { return token.label + ':\n' + 'mov rsp, rbp\npop rbp\nret\n' }
		return 'mov rsp, rbp\npop rbp\nret\n'
	} else if token.op == '=' {
		globals[token.args[0]] = token.args[1..].join(', ')
		return ''
	} else {
		args = token.args
	}
	
	for i, arg in args {
		if arg in globals.keys() {
			args[i] = '[$arg]'
		}
	}
	
	
	mut other := token.other
	if other.replace(' ', '').replace('\t', '').starts_with('//') {
		other = ''
	}
	
	if token.label != '' { formatted += token.label + ': ' }
	if token.op    != '' { formatted += token.op + ' ' }
	if args 	   != [] { formatted += args.join(', ') }
	if other       != '' { formatted += other }
	return formatted + '\n'
}

fn asm_format_data(mut globals map[string]string, data_start string) ?string {
	mut data := data_start
	for label, mut value in globals {
		if value in globals.keys() { value = '[$value]' }
		
		mut width := ''
		if value.split('#').len != 1 {
			width = value.split('#')[0] + ' '
			value = value.split('#')[1]
		} else {
			width = get_type(value)
		
		}
		data += label + ': ' + width + value
		if value.contains('"') { data += ', 0' }
		data += '\n'
	}
	
	return data
}

fn get_type(value string) string {
	if value.contains('"') {
		return 'db '
	} else {
		return 'dq '
	}
}

const asm_text = '\n\nsection .text\n'
const asm_data = 'default rel\nsection .rodata\n'
const asm_extensions = ['.asm', '.s', '.nasm']