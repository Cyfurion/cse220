# add test cases to data section
.data
src: .asciiz "Ali Tourre"
dest: .asciiz ""

.text:
main:
	la $a0, src
	la $a1, dest
	jal str_cpy
	#write test code
	move $a0, $v0
	li $v0, 1
	syscall
	li $v0, 11
	li $a0, 10
	syscall
	la $a0, src
	li $v0, 4
	syscall
	li $v0, 11
	li $a0, 10
	syscall
	la $a0, dest
	li $v0, 4
	syscall
	li $v0, 11
	li $a0, 10
	syscall
	li $v0, 10
	syscall
	
.include "hw4.asm"
