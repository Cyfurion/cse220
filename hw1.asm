.data
ErrMsg: .asciiz "Invalid Argument"
WrongArgMsg: .asciiz "You must provide exactly two arguments"
EvenMsg: .asciiz "Even"
OddMsg: .asciiz "Odd"

arg1_addr : .word 0
arg2_addr : .word 0
num_args : .word 0

valid_chars: .byte 'O', 'S', 'T', 'I', 'E', 'C', 'X', 'M'
valid_alphanumerics: .byte '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
hex_prefix: .asciiz "0x"

mantissa_prefix: .asciiz "1."

.text:
.globl main
main:
	sw $a0, num_args

	lw $t0, 0($a1)
	sw $t0, arg1_addr
	lw $s1, arg1_addr

	lw $t1, 4($a1)
	sw $t1, arg2_addr
	lw $s2, arg2_addr

	j start_coding_here

# do not change any line of code above this section
# you can add code to the .data section
start_coding_here:
	# Check condition 1: Program must have exactly 2 arguments.
	li $t0, 2
	beq $t0, $a0 condition_1_clear
	# Condition one failed, print error and terminate.
	li $v0, 4
	la $a0, WrongArgMsg
	syscall
	j terminate
	
condition_1_clear:
	# Check condition 2: First argument must be one of valid_chars.
	lbu $s1, 0($s1)
	la $t0, valid_chars
	lbu $t1, 0($t0)
	beq $t1, $s1, condition_2_clear
	lbu $t1, 1($t0)
	beq $t1, $s1, condition_2_clear
	lbu $t1, 2($t0)
	beq $t1, $s1, condition_2_clear
	lbu $t1, 3($t0)
	beq $t1, $s1, condition_2_clear
	lbu $t1, 4($t0)
	beq $t1, $s1, condition_2_clear
	lbu $t1, 5($t0)
	beq $t1, $s1, condition_2_clear
	lbu $t1, 6($t0)
	beq $t1, $s1, condition_2_clear
	lbu $t1, 7($t0)
	beq $t1, $s1, condition_2_clear
	# Condition 2 failed, print error and terminate.
	j condition_2_or_3_fail
	
condition_2_clear:
	# Check condition 3: Second argument must be a valid hexadecimal string.
	
	# Determine if there are at least 10 characters.
	li $t0, -10
	move $t1, $s2
	loop_1:
		lbu $t2, 0($t1)
		beqz $t2, loop_1_check
		addiu $t1, $t1, 1
		addiu $t0, $t0, 1
		j loop_1
		
		loop_1_check:
			bltz $t0, condition_2_or_3_fail
			j loop_1_exit
			
	loop_1_exit:
	# Check for prefix "0x".
	la $t0, hex_prefix
	lbu $t1, 0($t0)
	lbu $t2, 0($s2)
	bne $t1, $t2, condition_2_or_3_fail
	lbu $t1, 1($t0)
	lbu $t2, 1($s2)
	bne $t1, $t2, condition_2_or_3_fail
	
	# Check for valid alphanumerics. If valid, convert to binary and store in $s0.
	move $s0, $0
	li $t0, -8
	move $t1, $s2
	li $t3, 48 # ASCII 0
	li $t4, 57 # ASCII 9
	li $t5, 65 # ASCII A
	li $t6, 70 # ASCII F
	loop_2:
		bgez $t0, condition_3_clear
		addiu $t0, $t0, 1
		lbu $t2, 2($t1)
		beqz $t2, condition_3_clear
		blt $t2, $t3, condition_2_or_3_fail # ASCII < 48
		bgt $t2, $t6, condition_2_or_3_fail # ASCII > 70
		bgt $t2, $t4, loop_2_check # ASCII > 57
		# ASCII determined to be between 48 and 57.
		li $t7, 48
		sll $s0, $s0, 4
		subu $t8, $t2, $t7
		or $s0, $s0, $t8
		addiu $t1, $t1, 1
		j loop_2
		loop_2_check:
			blt $t2, $t5, condition_2_or_3_fail
			# ASCII determined to be between 65 and 70.
			li $t7, 55
			sll $s0, $s0, 4
			subu $t8, $t2, $t7
			or $s0, $s0, $t8
			addiu $t1, $t1, 1
			j loop_2
	
condition_2_or_3_fail:
	# Condition 2 or 3 failed, print error and terminate.
	li $v0, 4
	la $a0, ErrMsg
	syscall
	j terminate
	
condition_3_clear:
	move $a0, $0
	# Determine which operation to perform.
	case_O:
		li $t0, 79
		bne $t0, $s1, case_S
		
		srl $a0, $s0, 26
		li $v0, 36
		syscall
		j terminate
	case_S:
		li $t0, 83
		bne $t0, $s1, case_T
		
		sll $a0, $s0, 6
		srl $a0, $a0, 27
		li $v0, 36
		syscall
		j terminate
	case_T:
		li $t0, 84
		bne $t0, $s1, case_I
		
		sll $a0, $s0, 11
		srl $a0, $a0, 27
		li $v0, 36
		syscall
		j terminate
	case_I:
		li $t0, 73
		bne $t0, $s1, case_E
		
		andi $a0, $s0, 0xFFFF
		move $t1, $a0
		srl $t1, $t1, 15
		li $v0, 1
		bgtz $t1, negative
		syscall
		j terminate
		negative:
			li $t1, 65536
			sub $a0, $a0, $t1
			syscall
			j terminate
	case_E:
		li $t0, 69
		bne $t0, $s1, case_C
		
		andi $t1, $s0, 1
		beqz $t1, even
		li $v0, 4
		la $a0, OddMsg
		syscall
		j terminate
		even:
			li $v0, 4
			la $a0, EvenMsg
			syscall
			j terminate
	case_C:
		li $t0, 67
		bne $t0, $s1, case_X
		
		li $t1, -32
		li $a0, 0
		move $t2, $s0
		loop_3:
			bgtz $t1, loop_3_exit
			addiu $t1, $t1, 1
			andi $t3, $t2, 1
			srl $t2, $t2, 1
			beqz $t3, loop_3
			addi $a0, $a0, 1
			j loop_3
		loop_3_exit:
		li $v0, 36
		syscall
		j terminate
	case_X:
		li $t0, 88
		bne $t0, $s1, case_M
		
		sll $t1, $s0, 1
		srl $t1, $t1, 24
		li $t2, 127
		sub $a0, $t1, $t2
		li $v0, 1
		syscall
		j terminate
	case_M:
		la $a0, mantissa_prefix
		li $v0, 4
		syscall
		sll $a0, $s0, 9
		li $v0, 35
		syscall
		
terminate:
	li $v0, 10
	syscall
