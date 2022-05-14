default rel
section .rodata
myvar: db "Hello, World!", 0

section .text
global hello

hello: 
; open function
push rbp
mov rbp, rsp

lea rax, [myvar] ; return "Hello, World!"

; close function
mov rsp, rbp
pop rbp
ret 
