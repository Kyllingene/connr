/*
	Registers:
		RAX, RBX, RCX, RDX, RSI, RDI, RSP, RBP, R8 -> R15
		RSP and RBP are unused
		
	Memory Layout:
		| Width       | Register |     |     |     |     |     |          |
		|-------------|----------|-----|-----|-----|-----|-----|----------|
		| Upper 8-bit | AH       | BH  | CH  | DH  | N/A | N/A | N/A      |
		| Lower 8-bit | AL       | BL  | CL  | DL  | SIL | DIL | R8B-R15B |
		
		[ AH AL BH BL CH CL DH DL SIL DIL (R8B-R15B) jnk1 jnk2 (mem) ]
		                    /\ instructions start/return here
							
	Stage 1:
		Basic .cnr support
	Stage 2:
		If/while support
	Stage 3:
		Character support
	Stage 4:
		String/Array support
*/

import strconv { parse_int }

enum Registers {
	ah   = -6
	al   = -5
	bh   = -4
	bl   = -3
	ch   = -2
	cl   = -1
	dh   = 0
	dl   = 1
	sil  = 2
	dil  = 3
	r8b  = 4
	r9b  = 5
	r10b = 6
	r11b = 7
	r12b = 8
	r13b = 9
	r14b = 10
	r15b = 11
	jnk1 = 12
	jnk2 = 13
}

fn get_approach(x int) (string, string) {
	mut approach, mut finish := '', ''
	
	if x == 0 {
		return '', ''
	} else if x < 0 {
		approach = '<'.repeat(-x)
		finish = '>'.repeat(-x)
	} else {
		approach = '>'.repeat(x)
		finish = '<'.repeat(x)
	}
	
	return approach, finish
}

fn clear(x int) string {
	approach, finish := get_approach(x)
	
	return '$approach [-] $finish'
}

fn set(x int, y int) string {
	approach, finish := get_approach(x)
	increments := "+".repeat(y)
	
	return clear(x) + '$approach $increments $finish'
}

fn add(x int, y int) string {
	approach_x, finish_x := get_approach(x)
	approach_y, finish_y := get_approach(y)
	approach_j, finish_j := get_approach(int(Registers.jnk1))
	
	return clear(int(Registers.jnk1)) + '$approach_y [- $finish_y $approach_j + $finish_j $approach_x + $finish_x $approach_y] $finish_y' + movd(y, int(Registers.jnk1))
}

fn sub(x int, y int) string {
	approach_x, finish_x := get_approach(x)
	approach_y, finish_y := get_approach(y)
	approach_j, finish_j := get_approach(int(Registers.jnk1))
	
	return clear(int(Registers.jnk1)) + '$approach_y [- $finish_y $approach_j - $finish_j $approach_x + $finish_x $approach_y] $finish_y' + movd(y, int(Registers.jnk1))
}

fn putch(x int) string {
	approach, finish := get_approach(x)

	return '$approach . $finish'
}

fn getch(x int) string {
	approach, finish := get_approach(x)
	
	return '$approach , $finish'
}

fn movd(x int, y int) string {
	approach_x, finish_x := get_approach(x)
	approach_y, finish_y := get_approach(y)
	
	return clear(x) + '$approach_y [- $finish_y $approach_x + $finish_x $approach_y ] $finish_y'
}

fn chr(x string, y int) string {
	if x.len != 1 { panic("ERROR: Invalid size for type 'chr': ${x.len}") }
	cc := x[0]
	
	return set(x.int(), cc)
}

fn mov(x int, y int) string {
	approach_x, finish_x := get_approach(x)
	approach_y, finish_y := get_approach(y)
	approach_j, finish_j := get_approach(int(Registers.jnk1))
	
	return clear(y) + clear(int(Registers.jnk1)) + '$approach_y [- $finish_y $approach_j + $finish_j $approach_x + $finish_x $approach_y] $finish_y' + movd(x, int(Registers.jnk1))
}

fn do_while(cond_block string, cond int, block string) string {
	approach_c, finish_c := get_approach(cond)
	
	return '$cond_block $approach_c [ $finish_c $block $cond_block $approach_c ] $finish_c'
}

fn if_else(cond_block string, cond int, if_block string, else_block string) string {
	approach_c, finish_c := get_approach(cond)
	approach_j1, finish_j1 := get_approach(int(Registers.jnk1))
	approach_j2, finish_j2 := get_approach(int(Registers.jnk2))

	return clear(int(Registers.jnk1)) + clear(int(Registers.jnk2)) + ' $cond_block $approach_c [ $approach_j1 + $finish_j1 $approach_j2 + $finish_j2 $approach_c - ] $finish_c $approach_j1 [ $finish_j1 $approach_c + $finish_c $approach_j1 - ] + [ $finish_j1 $if_block $approach_j2 - $finish_j2 $approach_j1 [-] ] [ $finish_j1 $else_block $approach_j1 - ] ' 
}

fn parse_mem(mmap_s string) []int {
	mut mmap := []int{}
	mut current := ''
	for cc in mmap_s {
		c := cc.ascii_str()
		if c == ',' {
			mmap << current.replace(' ', '').int()
			current = ''
		} else {
			current += c
		}
	}
	
	return mmap
}

fn alloc(mmap_s string) (int, string) {
	if mmap_s == '' { return 14, '14' }

	mut mmap := parse_mem(mmap_s)
	address := mmap.last() + 1
	
	return address, mmap_s + ',' + address.str()
}

fn allocate_string(len int, mmap_s string) (int, string) {
	start, mut new_mmap := alloc(mmap_s)
	for _ in 0..(len - 1) {
		_, new_mmap = alloc(new_mmap)
	}
	
	return start, new_mmap
}

fn set_string(start int, str string) string {
	mut out := ''
	len := str.len
	
	for i in 1..(len + 1) {
		out += chr(str[i].str(), start + i)
	}
	
	return out
}

// FIXME: isnt getting accurate argument i guess???
fn puts(start int) string {
	approach, finish := get_approach(start)
	
	return '$approach >[.>]<[<] $finish'
}

fn gets(start int, len int) string {
	approach, finish := get_approach(start)
	
	return '$approach $(",>".repeat(len) + "<".repeat(len)) $finish'
}

fn brain_format(token Symbol, mut globals map[string]string) ?string {
	
	if !('||MMAP||' in globals.keys()) { // initialize memory map
		registers := ["ah", "al", "bh", "bl", "ch", "cl", "dh", "dl", "sil", "dil", "r8b", "r9b", "r10b", "r11b", "r12b", "r13b", "r14b", "r15b", "jnk1", "jnk2"]
		for i in registers {
			globals[i] = (registers.index(i) - 6).str()
		}
		
		globals['||MMAP||'] = ''
	}

	// FIXME: why isnt it setting the string properly???
	match token.op.to_lower() {
		'=' {
			if !(token.args[0].to_lower() in globals.keys()) {
				address, new_mmap := alloc(globals['||MMAP||'])
				
				globals['||MMAP||'] = new_mmap
				globals[token.args[0].to_lower()] = address.str()
			}
			
			if token.args[1].int() == 0 {
				return clear(globals[token.args[0].to_lower()].int()) // TODO: return error message when improperly formatted
				
			} else if token.args[1].len == 3 && token.args[1].starts_with("'") && token.args[1].ends_with("'") {
				return chr(token.args[1], token.args[0].int()) // TODO: return error message when improperly formatted
				
			} else if token.args[1].starts_with('"') && token.args[1].ends_with('"') && (token.args[1].count('"') == 2) {
				
				start, new_mmap := allocate_string(token.args[1].len - 2, globals['||MMAP||'])
				globals['||MMAP||'] = new_mmap
				
				return set_string(start, token.args[1].replace('"', ''))
			}
			
			value := int(parse_int(token.args[1], 10, 0) or {
				return error('ERROR: Invalid syntax: `${token.args[1]}`')
			})
			
			return set(globals[token.args[0].to_lower()].int(), value) // TODO: return error message when improperly formatted
		}
	
		'if' {
			panic('if statement is unimplemented')
		}
		
		'while' {
			panic('while statement is unimplemented')
		}
		 
		'mov' { // TODO: return error message when improperly formatted
			return mov(globals[token.args[0]].int(), globals[token.args[1]].int())
		}
		 
		'movd' { // TODO: return error message when improperly formatted
			return movd(globals[token.args[0]].int(), globals[token.args[1]].int())
		}
		 
		'clear', 'zero' { // TODO: return error message when improperly formatted
			return clear(globals[token.args[0]].int())
		}
		
		'add' { // TODO: return error message when improperly formatted
			return add(globals[token.args[0]].int(), globals[token.args[1]].int())
		}
		
		'sub' { // TODO: return error message when improperly formatted
			return sub(globals[token.args[0]].int(), globals[token.args[1]].int())
		}
		
		'putch' { // TODO: return error message when improperly formatted
			return putch(globals[token.args[0]].int())
		}
		
		'getch' { // TODO: return error message when improperly formatted
			return getch(globals[token.args[0]].int())
		}
		
		'puts' { // TODO: return error message when improperly formatted
			return puts(token.args[0].int())
		}
		
		'gets' { // TODO: return error message when improperly formatted
			return gets(token.args[0].int(), token.args[1].int())
		}
		
		'', ' ', '\t', '//' {}
		 
		 else { println('INFO: Invalid operator: ${token.op.to_lower()}') }
	}
	
	return ''
}

fn brain_format_data(mut globals map[string]string, data string) ?string {
	return '' // this function is for compatibility with output languages like assembly that have a dedicated data storage section, which this does not need
}

const brain_text = '>>>>>>'
const brain_data = ''
const brain_extensions = ['.bf']