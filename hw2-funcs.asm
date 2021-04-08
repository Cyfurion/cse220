############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################

############################## Do not .include any files! #############################

.text
eval:
	# Save $s0 and $ra on system stack.
	addi $sp, $sp, -8
	sw $s0, 0($sp)
	sw $ra, 4($sp)

	la $t8, val_stack
	addi $t8, $t8, 20
	la $t9, op_stack
	addi $t9, $t9, 1000 # Prevent overlap of stacks.
	li $t2, -1 # $t2 contains current character status. 0 = number, 1 = operator, -1 = start.
	li $t3, 0 # $t3 contains the top of stack pointer for the value stack.
	li $t4, 0 # $t4 contains the top of stack pointer for the operator stack.
	move $s0, $a0 # $s0 contains the expression.
	
	# Initial check if the expression starts with an operator (ill-formed).
	lbu $a0, 0($s0)
	jal save_temporaries
	jal valid_ops
	jal load_temporaries
	bnez $v0, eval_ill_formed
		
	addi $s0, $s0, -1
	loop:
		addi $s0, $s0, 1 # Increment to next character in expression.
		lbu $t7, 0($s0) # Load next character of expression into $t7.
		beqz $t7, eval_stop # If null character reached, stop parsing.
		move $a0, $t7
		
		jal save_temporaries
		jal is_digit # Check if character is a digit.
		jal load_temporaries
		bnez $v0, digit # If character is a digit, jump to label digit.
		
		jal save_temporaries
		jal valid_ops # Check is character is an operator.
		jal load_temporaries
		bnez $v0, operator # If character is an operator, jump to label operator.
		
		digit: # Push character onto the value stack.
			addi $t7, $t7, -48 # Convert from character to integer.
			beqz $t2, multi_digit_number # If this is a multi-digit number, jump to label multi_digit_number.
			move $a0, $t7
			move $a1, $t3
			move $a2, $t8
			jal save_temporaries
			jal stack_push
			jal load_temporaries
			move $t3, $v0
			li $t2, 0
			j loop
		multi_digit_number: # Parse a multi-digit number.
			addi $a0, $t3, -4
			move $a1, $t8
			jal save_temporaries
			jal stack_pop
			jal load_temporaries
			li $t5, 10
			mult $v0, $t5
			mflo $t5
			add $a0, $t5, $t7
			move $a1, $t3
			move $a2, $t8
			jal save_temporaries
			jal stack_push
			jal load_temporaries
			move $t3, $v0
			j loop
		operator:
			bgtz $t2, eval_ill_formed # Two operators in a row (ill-formed).
			beqz $t4, push_operator
			
			addi $a0, $t4, -4
			move $a1, $t9
			jal save_temporaries
			jal stack_peek
			move $a0, $v0
			jal op_precedence
			jal load_temporaries
			move $t0, $v0 # $t0 contains operator precedence for operator inside stack.
			move $a0, $t7
			jal save_temporaries
			jal op_precedence
			jal load_temporaries
			move $t1, $v0 # $t1 contains operator precedence for new operator.
			bge $t0, $t1, apply_previous_operator
			j push_operator
			
			apply_previous_operator:
				# Retrieve first number from val_stack.
				addi $a0, $t3, -4
				move $a1, $t8
				jal save_temporaries
				jal stack_pop
				jal load_temporaries
				move $t3, $v0
				move $t0, $v1
				# Retrieve second number from val_stack.
				addi $a0, $t3, -4
				move $a1, $t8
				jal save_temporaries
				jal stack_pop
				jal load_temporaries
				move $t3, $v0
				move $t1, $v1
				# Retrieve operator from op_stack.
				addi $a0, $t4, -4
				move $a1, $t9
				jal save_temporaries
				jal stack_pop
				jal load_temporaries
				move $t4, $v0
				move $a1, $v1
				# Apply binary operation.
				move $a0, $t1
				move $a2, $t0
				jal save_temporaries
				jal apply_bop
				jal load_temporaries
				# Return new number into val_stack.
				move $a0, $v0
				move $a1, $t3
				move $a2, $t8
				jal save_temporaries
				jal stack_push
				jal load_temporaries
				move $t3, $v0
			push_operator: # Push new operator into op_stack.
				move $a0, $t7
				move $a1, $t4
				move $a2, $t9
				jal save_temporaries
				jal stack_push
				jal load_temporaries
				move $t4, $v0
			li $t2, 1
			j loop
		
	eval_ill_formed:
		la $a0, ParseError
		li $v0, 4
		syscall
		li $v0, 10
		syscall
	eval_stop: # Finish evaluating anything left in the stack.
		beqz $t4, eval_final
		# Retrieve first number from val_stack.
		addi $a0, $t3, -4
		move $a1, $t8
		jal save_temporaries
		jal stack_pop
		jal load_temporaries
		move $t3, $v0
		move $t0, $v1
		# Retrieve second number from val_stack.
		addi $a0, $t3, -4
		move $a1, $t8
		jal save_temporaries
		jal stack_pop
		jal load_temporaries
		move $t3, $v0
		move $t1, $v1
		# Retrieve operator from op_stack.
		addi $a0, $t4, -4
		move $a1, $t9
		jal save_temporaries
		jal stack_pop
		jal load_temporaries
		move $t4, $v0
		move $a1, $v1
		# Apply binary operation.
		move $a0, $t1
		move $a2, $t0
		jal save_temporaries
		jal apply_bop
		jal load_temporaries
		# Return new number into val_stack.
		move $a0, $v0
		move $a1, $t3
		move $a2, $t8
		jal save_temporaries
		jal stack_push
		jal load_temporaries
		move $t3, $v0
		j eval_stop
	eval_final:
		# Retrieve final result from val_stack and print.
		addi $a0, $t3, -4
		move $a1, $t8
		jal save_temporaries
		jal stack_pop
		jal load_temporaries
		move $t3, $v0
		move $a0, $v1
		li $v0, 1
		syscall
		# Restore $s0 and $ra from system stack.
		lw $s0, 0($sp)
		lw $ra, 4($sp)
		addi $sp, $sp, 8
		jr $ra # Return to caller.

is_digit:
	li $t0, 48 # ASCII 0
	li $t1, 57 # ASCII 9
	blt $a0, $t0, is_digit_fail
	bgt $a0, $t1, is_digit_fail
	li $v0, 1 # ASCII is between 48 and 57 (inclusive).
	j is_digit_final
	is_digit_fail:
		li $v0, 0 # ASCII is outside valid range.
	is_digit_final:
		jr $ra # Return to caller.

stack_push:
	li $t0, 4
	div $a1, $t0
	mflo $t0 # $t0 contains number of elements in this stack.
	li $t1, 500
	bgt $t0, $t1, stack_push_overflow # Check if stack at maximum.
	add $a2, $a2, $a1 # Move $a2 to top of stack.
	sw $a0, 0($a2) # Store new element on stack.
	addi $v0, $a1, 4 # Increment top of stack.
	jr $ra # Return to caller.
	stack_push_overflow: # Stack at maximum capacity (500 elements).
		la $a0, BadToken
		li $v0, 4
		syscall
		li $v0, 10
		syscall

stack_peek:
	bltz $a0, stack_peek_empty # Check if stack is empty.
	add $a1, $a1, $a0 # Move $a1 to top of stack.
	lw $v0, 0($a1) # Retrieve top element from stack.
	jr $ra # Return to caller.
	stack_peek_empty: # Stack is empty.
		la $a0, BadToken
		li $v0, 4
		syscall
		li $v0, 10
		syscall

stack_pop:
	bltz $a0, stack_pop_empty # Check if stack is empty.
	add $a1, $a1, $a0 # Move $a1 to top of stack.
	lw $v1, 0($a1) # Retrieve top element from stack.
	move $v0, $a0 # Decrement top of stack (should be decremented -4 by caller).
	jr $ra # Return to caller.
	stack_pop_empty: # Stack is empty.
		la $a0, BadToken
		li $v0, 4
		syscall
		li $v0, 10
		syscall

is_stack_empty:
	li $t0, -4 # Top of stack must be -4 for stack to be empty.
	beq $a0, $t0, is_stack_empty_true
	li $v0, 0 # Stack is not empty.
	j is_stack_empty_final
	is_stack_empty_true:
		li $v0, 1 # Stack is empty.
	is_stack_empty_final:
		jr $ra # Return to caller.

valid_ops:
	li $t0, 42 # ASCII *
	li $t1, 43 # ASCII +
	li $t2, 45 # ASCII -
	li $t3, 47 # ASCII /
	beq $a0, $t0, valid_ops_pass
	beq $a0, $t1, valid_ops_pass
	beq $a0, $t2, valid_ops_pass
	beq $a0, $t3, valid_ops_pass
	li $v0, 0 # ASCII is outside valid range.
	j valid_ops_final
	valid_ops_pass:
		li $v0, 1 # ASCII is one of 42, 43, 45, 47.
	valid_ops_final:
		jr $ra # Return to caller.

op_precedence:
	# + and - have precedence 0.
	# * and / have precedence 1.
	addi $sp, $sp, -4 # Allocate stack space.
	sw $ra, 0($sp) # Save $ra (return register) on stack.
	jal valid_ops
	lw $ra, 0($sp) # Restore $ra (return register) from stack.
	addi $sp, $sp, 4 # Deallocate stack space.
	beqz $v0, op_precedence_invalid
	li $t0, 42 # ASCII *
	li $t1, 47 # ASCII /
	
	beq $a0, $t0, op_precedence_1
	beq $a0, $t1, op_precedence_1
	li $v0, 0 # Operation precedence is 0.
	j op_precedence_final
	op_precedence_1:
		li $v0, 1 # Operation precedence is 1.
		j op_precedence_final
	op_precedence_invalid:
		la $a0, BadToken
		li $v0, 4
		syscall
		li $v0, 10
		syscall
		
	op_precedence_final:
		jr $ra # Return to caller.

apply_bop:
	# Multiplication
	li $t0, 42
	bne $t0, $a1, case_add
	mult $a0, $a2
	mflo $v0
	j apply_bop_final
	case_add: # Addition
		li $t0, 43
		bne $t0, $a1, case_sub
		add $v0, $a0, $a2
		j apply_bop_final
	case_sub: # Subtraction
		li $t0, 45
		bne $t0, $a1, case_div
		sub $v0, $a0, $a2
		j apply_bop_final
	case_div: # Division
		beqz $a2, apply_bop_div_fail
		div $a0, $a2
		mflo $v0
		j apply_bop_final
		apply_bop_div_fail: # Divide by zero error.
			la $a0, ApplyOpError
			li $v0, 4
			syscall
			li $v0, 10
			syscall	
	apply_bop_final:
		jr $ra # Return to caller.
		
save_temporaries: # Helper function to save $t0 - $t7 into the system stack.
	addi $sp, $sp, -32
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t4, 16($sp)
	sw $t5, 20($sp)
	sw $t6, 24($sp)
	sw $t7, 28($sp)
	jr $ra

load_temporaries: # Helper function to restore $t0 - $t7 from the system stack.
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t4, 16($sp)
	lw $t5, 20($sp)
	lw $t6, 24($sp)
	lw $t7, 28($sp)
	addi $sp, $sp, 32
	jr $ra
