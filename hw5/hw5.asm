############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
.text:

create_term: # Modifies $a0.
	### Initializations. ###
	move $t0, $a0 # $t0 contains original first argument.
	
	### Error checking. ###
	beqz $t0, create_term_error # If coefficient is zero, jump.
	bltz $a1, create_term_error # If exponent is negative, jump.
	
	### Allocate heap space (12 bytes). ###
	li $v0, 9 # $v0 contains syscall opcode 9 for heap allocation.
	li $a0, 12 # $a0 contains amount of bytes to allocate (12).
	syscall # Allocate 12 bytes on the heap. $v0 contains start address of allocated memory block.
	
	### Fill allocated space with relevant values. ###
	sw $t0, 0($v0) # Store coefficient into first 4 bytes of memory block.
	sw $a1, 4($v0) # Store exponent into second 4 bytes of memory block.
	sw $0, 8($v0) # Store next pointer (currently 0) into third 4 bytes of memory block.
	
	### Terminate successfully. ###
	jr $ra # Return to caller.
	
	### Terminate with error. ###
	create_term_error:
	li $v0, -1 # Return -1.
	jr $ra # Return to caller.
	
init_polynomial: # Modifies $a0, $a1.
	### Initializations. ###
	move $t0, $a0 # $t0 contains original first argument.
	move $t1, $a1 # $t1 contains original second argument.
	move $t2, $ra # $t2 contains original return address.
	
	### Create the new term from pair array. If failure, terminate. ###
	lw $a0, 0($t1) # $a0 contains coefficient of new term.
	lw $a1, 4($t1) # $a1 contains exponent of new term.
	jal save_temps
	jal create_term # Create new term. $v0 contains address of new term, or error code -1.
	jal load_temps
	bltz $v0, init_polynomial_error # Term creation failed, jump.
	
	### Link head to address of new term. ###
	sw $v0, 0($t0) # Store address of new term in head.
	
	### Terminate successfully. ###
	li $v0, 1 # Return 1.
	move $ra, $t2 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate with error. ###
	init_polynomial_error:
	li $v0, -1 # Return -1.
	move $ra, $t2 # Restore original return address.
	jr $ra # Return to caller.
	
add_N_terms_to_polynomial: # Modifies $a0, $a1.
	### Initializations. ###
	move $t0, $a0 # $t0 contains original first argument.
	move $t1, $a1 # $t1 contains original second argument.
	move $t2, $ra # $t2 contains original return address.
	li $t3, 0 # $t3 contains count of terms considered (not to exceed $a2).
	li $t4, 0 # $t4 is a function temporary.
	li $t5, 0 # $t5 is a function temporary.
	li $t6, 0 # $t6 is a function temporary.
	li $t7, 0 # $t7 is a function temporary.
	li $t8, 0 # $t8 contains count of terms added.
	
	### Repeatedly add terms to polynomial. ###
	add_N_terms_to_polynomial_loop:
		# Create and validate new term from pair.
		bge $t3, $a2, add_N_terms_to_polynomial_terminate # If number of terms considered reaches limit, jump.
		lw $t4, 0($t1) # $t4 contains coefficient of new term.
		beqz $t4, add_N_terms_to_polynomial_loop_exit # If coefficient is 0, jump.
		lw $a0, 0($t1) # $a0 contains coefficient of new term.
		lw $a1, 4($t1) # $a1 contains exponent of new term.
		jal save_temps
		jal create_term # Create new term. $v0 contains address of new term, or error code -1.
		jal load_temps
		bltz $v0, add_N_terms_to_polynomial_loop_skip # If term is invalid, jump.
		
		# Determine if this exponent already exists. If not, determine where new term should be placed.
		lw $t4, 0($t0) # $t4 contains address of first term in polynomial.
		beqz $t4, add_N_terms_to_polynomial_loop_null # Polynomial is empty, link head to term.
		lw $t5, 4($t4) # $t5 contains exponent of first term in polynomial.
		lw $t6, 4($t1) # $t6 contains exponent of new term.
		blt $t5, $t6, add_N_terms_to_polynomial_loop_head # Term should be added between head and first term, jump.
		beq $t5, $t6, add_N_terms_to_polynomial_loop_skip # Exponent already exists, skip this term. Jump.
		
		lw $t5, 8($t4) # $t5 contains address of second term in polynomial.
		beqz $t5, add_N_terms_to_polynomial_loop_end # No duplicate found, $t4 contains address of preceding term. Jump.
		add_N_terms_to_polynomial_loop_exist:
			lw $t7, 4($t5) # $t7 contains exponent of comparison term.
			beq $t7, $t6, add_N_terms_to_polynomial_loop_skip # Exponent already exists, skip this term. Jump.
			blt $t7, $t6, add_N_terms_to_polynomial_loop_insert # Place this term between $t4 and $t5. Jump.
			move $t4, $t5 # $t4 contains the term directly after.
			lw $t5, 8($t5) # $t5 contains the term directly after.
			beqz $t5, add_N_terms_to_polynomial_loop_end # No duplicate found, $t4 contains address of preceding term. Jump.
			j add_N_terms_to_polynomial_loop_exist # Parse next term.
			
		# Place this new term as the first term in a null polynomial.
		add_N_terms_to_polynomial_loop_null:
		sw $v0, 0($t0) # Set head pointer to new term.
		addi $t8, $t8, 1 # Increment number of terms added by 1.
		j add_N_terms_to_polynomial_loop_skip # Proceed to next term, jump.
			
		# Place this new term directly after head.
		add_N_terms_to_polynomial_loop_head:
		sw $v0, 0($t0) # Set head pointer to new term.
		sw $t4, 8($v0) # Set new term next pointer to $t4.
		addi $t8, $t8, 1 # Increment number of terms added by 1.
		j add_N_terms_to_polynomial_loop_skip # Proceed to next term, jump.
		
		# Place this new term at the end.
		add_N_terms_to_polynomial_loop_end:
		sw $v0, 8($t4) # Set $t4 next pointer to new term.
		addi $t8, $t8, 1 # Increment number of terms added by 1.
		j add_N_terms_to_polynomial_loop_skip # Proceed to next term, jump.
		
		# Place this new term in between $t4 and $t5.
		add_N_terms_to_polynomial_loop_insert:
		sw $v0, 8($t4) # Set $t4 next pointer to new term.
		sw $t5, 8($v0) # Set new term next pointer to $t5.
		addi $t8, $t8, 1 # Increment number of terms added by 1.
		
		# Proceed to next term.
		add_N_terms_to_polynomial_loop_skip:
		addi $t1, $t1, 8 # Move array to next pair.
		addi $t3, $t3, 1 # Increment number of terms considered by 1.
		j add_N_terms_to_polynomial_loop # Parse next pair.
		
		# Check if this term is the terminator (0, -1).
		add_N_terms_to_polynomial_loop_exit:
		lw $t4, 4($t1) # $t4 contains exponent of new term.
		li $t5, -1
		beq $t4, $t5, add_N_terms_to_polynomial_terminate # Terminator term (0, -1) reached, jump.
		j add_N_terms_to_polynomial_loop_skip # Term is not the terminator, jump.
	
	### Terminate. ###
	add_N_terms_to_polynomial_terminate:
	move $v0, $t8 # Return number of terms added.
	move $ra, $t2 # Restore original return address.
	jr $ra # Return to caller.
	
update_N_terms_in_polynomial:
	### Initializations. ###
	move $t0, $a0 # $t0 contains original first argument.
	move $t1, $a1 # $t1 contains original second argument.
	move $t2, $ra # $t2 contains original return address.
	li $t3, 0 # $t3 contains count of terms considered (not to exceed $a2).
	li $t4, 0 # $t4 contains number of terms added.
	li $t5, 0 # $t5 is a function temporary.
	li $t6, 0 # $t6 is a function temporary.
	li $t7, 0 # $t7 is a function temporary.
	li $t8, 0 # $t8 is a function temporary.
	
	blez $a2, update_N_terms_in_polynomial_terminate # Arguments invalid, jump.
	
	### Determine if polynomial is empty. ###
	lw $t5, 0($t0) # $t5 contains first term.
	beqz $t5, update_N_terms_in_polynomial_terminate # If polynomial is empty, jump.
	
	### Loop through terms array. ###
	update_N_terms_in_polynomial_terms_loop:
		bge $t3, $a2, update_N_terms_in_polynomial_terminate # If number of terms considered reaches limit, jump.
		lw $t6, 0($t1) # $t6 contains coefficient of update term.
		beqz $t6, update_N_terms_in_polynomial_terms_loop_exit # Coefficient is 0, jump.
		lw $t7, 4($t1) # $t7 contains exponent of update term.
		
		# Loop through polynomial to find relevant term and update.
		update_N_terms_in_polynomial_poly_loop:
			beqz $t5, update_N_terms_in_polynomial_terms_loop_resume # Relevant term not found, jump.
			lw $t8, 4($t5) # $t8 contains exponent of current term.
			beq $t8, $t7, update_N_terms_in_polynomial_poly_loop_found # Relevant term found, jump.
			blt $t8, $t7, update_N_terms_in_polynomial_terms_loop_resume # Relevant term not found, jump.
			lw $t5, 8($t5) # $t5 contains next term in polynomial.
			j update_N_terms_in_polynomial_poly_loop # Scan next term, jump.
			
			# If relevant term found, update coefficient.
			update_N_terms_in_polynomial_poly_loop_found:
			sw $t6, 0($t5) # Store new coefficient into term.
			addi $t4, $t4, 1 # Increment number of terms updated by 1.
			j update_N_terms_in_polynomial_terms_loop_resume # Parse next pair, jump.
			
		# Proceed to next pair.
		update_N_terms_in_polynomial_terms_loop_resume:
		addi $t3, $t3, 1 # Increment number of moves considered by 1.
		addi $t1, $t1, 8 # Increment array to next pair.
		lw $t5, 0($t0) # Reset $t5 to first term.
		j update_N_terms_in_polynomial_terms_loop
	
		# Check if this term is the terminator.	
		update_N_terms_in_polynomial_terms_loop_exit:
		li $t7, -1
		lw $t6, 4($t1) # $t6 contains exponent of update term.
		beq $t6, $t7, update_N_terms_in_polynomial_terminate # Terminator (0, -1) reached, jump.
		j update_N_terms_in_polynomial_terms_loop_resume # Parse next pair.
	 
	### Terminate. ###
	update_N_terms_in_polynomial_terminate:
	move $v0, $t4 # Return number of terms added.
	move $ra, $t2 # Restore original return address.
	jr $ra # Return to caller.
	
get_Nth_term:
	### Initializations. ###
	li $t0, 1 # $t0 contains number of terms checked.
	lw $t1, 0($a0) # $t1 contains address of first term.
	blez $a1, get_Nth_term_error # Invalid argument, jump.
	
	### Loop through polynomial, finding correct term to return. ###
	get_Nth_term_loop:
		beqz $t1, get_Nth_term_error # End of polynomial reached, jump.
		beq $t0, $a1, get_Nth_term_found # Term was found, $t1 contains address of term. Jump.
		lw $t1, 8($t1) # $t1 contains address of next term.
		addi $t0, $t0, 1 # Increment number of terms checked by 1.
		j get_Nth_term_loop # Parse next term.
		
	### Return relevant data from this term. ###
	get_Nth_term_found:
	lw $v0, 4($t1) # $v0 contains exponent of term.
	lw $v1, 0($t1) # $v1 contains coefficient of term.
	jr $ra # Return to caller.
	
	### Terminate with error. ###
	get_Nth_term_error:
	li $v0, -1 # Return -1 as exponent.
	li $v1, 0 # Return 0 as coefficient.
	jr $ra # Return to caller.
	
remove_Nth_term:
	### Initializations. ###
	li $t0, 1 # $t0 contains number of terms checked.
	lw $t1, 0($a0) # $t1 contains address of first term.
	li $t2, 0 # $t2 is a function temporary.
	li $t3, 0 # $t3 is a function temporary.
	
	blez $a1, remove_Nth_term_error # Invalid argument, jump.
	beqz $t1, remove_Nth_term_error # Polynomial is already empty, jump.
	
	### Handle head case. ###
	li $t2, 1
	beq $a1, $t2, remove_Nth_term_head # First term is being remove, jump.
	
	### Loop through polynomial and remove relevant term. ###
	lw $t2, 8($t1) # $t2 contains address of current term.
	remove_Nth_term_loop:
		addi $t0, $t0, 1 # Increment number of terms checked by 1.
		beqz $t2, remove_Nth_term_error # End of polynomial reached, jump.
		beq $t0, $a1, remove_Nth_term_insert # Correct term found, jump.
		move $t1, $t2 # $t1 contains current term.
		lw $t2, 8($t2) # $t2 contains next term.
		j remove_Nth_term_loop # Parse next term.
	
	# Remove the first term.
	remove_Nth_term_head:
	lw $v0, 4($t1) # Return exponent of removed term in $v0.
	lw $v1, 0($t1) # Return coefficient of removed term in $v1.
	lw $t2, 8($t1) # $t2 contains term directly after $t1.
	sw $t2, 0($a0) # Link new term to head.
	jr $ra # Return to caller.
	
	# Remove $t2.
	remove_Nth_term_insert:
	lw $v0, 4($t2) # Return exponent of removed term in $v0.
	lw $v1, 0($t2) # Return coefficient of removed term in $v1.
	lw $t3, 8($t2) # $t3 contains term directly after $t2.
	sw $t3, 8($t1) # Link $t1 to $t3.
	jr $ra # Return to caller.
	
	### Terminate with error. ###
	remove_Nth_term_error:
	li $v0, -1 # Return -1 as exponent.
	li $v1, 0 # Return 0 as coefficient.
	jr $ra # Return to caller.
	
add_poly: # Modifies $a0 - $a2.
	### Initializations. ###
	move $t0, $a0 # $t0 contains original first argument.
	move $t1, $a1 # $t1 contains original second argument.
	move $t2, $a2 # $t2 contains original third argument.
	move $t3, $ra # $t3 contains original return address.
	li $t4, 0 # $t4 is a function temporary.
	li $t5, 0 # $t5 is a function temporary.
	li $t6, 0 # $t6 is a function temporary.
	li $t7, 0 # $t7 is a function temporary.
	
	### Determine if one or both polynomials are empty. ###
	beqz $t0, add_poly_first_empty # First polynomial is empty, jump.
	beqz $t1, add_poly_second_empty # Second polynomial is empty, jump.
	
	### Both polynomials are non-empty, add them. ###
	lw $t4, 0($t0) # $t4 contains first term of first polynomial.
	lw $t5, 0($t1) # $t5 contains first term of second polynomial.
	addi $sp, $sp, -16 # Allocate 4 words (16 bytes) for new terms array on system stack.
	li $t6, 0
	sw $t6, 8($sp) # Store 0 of terminator into allocated array.
	li $t6, -1
	sw $t6, 12($sp) # Store -1 of terminator into allocated array.
	add_poly_loop:
		# Check if end of any polynomial reached.
		beqz $t4, add_poly_loop_first_done # First polynomial is finished, jump.
		beqz $t5, add_poly_loop_case_2_special # Second polynomial is finished, add term from first polynomial. Jump.
	
		lw $t6, 4($t4) # $t6 contains exponent of term from first polynomial.
		lw $t7, 4($t5) # $t7 contains exponent of term from second polynomial.
		
		bne $t6, $t7, add_poly_loop_case_2 # Case 1: Exponents are equal, add coefficients. If not, jump.
			sw $t6, 4($sp) # Store new exponent into allocated array.
			lw $t6, 0($t4) # $t6 contains coefficient of term from first polynomial.
			lw $t7, 0($t5) # $t7 contains coefficient of term from second polynomial.
			add $t6, $t6, $t7 # $t6 contains summed coefficient.
			lw $t4, 8($t4) # Move to next term in first polynomial.
			lw $t5, 8($t5) # Move to next term in second polynomial.
			beqz $t6, add_poly_loop # If coefficient results in 0, proceed to next step.
			sw $t6, 0($sp) # Store new coefficient into allocated array.
			move $a0, $t2 # $a0 contains destination polynomial.
			move $a1, $sp # $a1 contains new terms array.
			li $a2, 1 # $a2 contains number of terms to consider (1).
			jal save_temps
			jal add_N_terms_to_polynomial # Add this new term to destination polynomial.
			jal load_temps
			j add_poly_loop # Proceed to next step.
		add_poly_loop_case_2:
		bge $t7, $t6, add_poly_loop_case_3 # Case 2: First polynomial has greater exponent. If not, jump.
			add_poly_loop_case_2_special:
			lw $t6, 4($t4) # $t6 contains exponent of term from first polynomial.
			sw $t6, 4($sp) # Store new exponent into allocated array.
			lw $t6, 0($t4) # $t6 contains coefficient for this term.
			sw $t6, 0($sp) # Store new coefficient into allocated array.
			move $a0, $t2 # $a0 contains destination polynomial.
			move $a1, $sp # $a1 contains new terms array.
			li $a2, 1 # $a2 contains number of terms to consider (1).
			jal save_temps
			jal add_N_terms_to_polynomial # Add this new term to destination polynomial.
			jal load_temps
			lw $t4, 8($t4) # Move to next term in first polynomial.
			j add_poly_loop # Proceed to next step.
		add_poly_loop_case_3: # Case 3: Second polynomial has greater exponent.
			sw $t7, 4($sp) # Store new exponent into allocated array.
			lw $t6, 0($t5) # $t5 contains coefficient for this term.
			sw $t6, 0($sp) # Store new coefficient into allocated array.
			move $a0, $t2 # $a0 contains destination polynomial.
			move $a1, $sp # $a1 contains new terms array.
			li $a2, 1 # $a2 contains number of terms to consider (1).
			jal save_temps
			jal add_N_terms_to_polynomial # Add this new term to destination polynomial.
			jal load_temps
			lw $t5, 8($t5) # Move to next term in second polynomial.
			j add_poly_loop # Proceed to next step.
			
	# Determine if both polynomials are finished.
	add_poly_loop_first_done:
		beqz $t5, add_poly_terminate # Both polynomials finished, jump.
		lw $t7, 4($t5) # $t7 contains exponent of term from second polynomial.
		j add_poly_loop_case_3 # First polynomial is finished, add term from second polynomial. Jump.
	
	### First polynomial is empty. ###
	add_poly_first_empty:
	beqz $t1, add_poly_null # Both polynomials are empty, jump.
	# Only first polynomial is empty, return second polynomial.
	lw $t4, 0($t1) # $t4 contains first node of second polynomial.
	sw $t4, 0($t2) # Store link to first term of second polynomial into destination.
	li $v0, 1 # Return 1.
	addi $sp, $sp, 16 # Restore system stack pointer.
	move $ra, $t3 # Restore original return address.
	jr $ra # Return to caller.
	
	### Second polynomial is empty. Return first polynomial. ###
	add_poly_second_empty:
	lw $t4, 0($t0) # $t4 contains first node of first polynomial.
	sw $t4, 0($t2) # Store link to first term of first polynomial into destination.
	li $v0, 1 # Return 1.
	addi $sp, $sp, 16 # Restore system stack pointer.
	move $ra, $t3 # Restore original return address.
	jr $ra # Return to caller.
	
	### Both polynomials empty, terminate with error. ###
	add_poly_null:
	li $v0, 0 # Return 0.
	addi $sp, $sp, 16 # Restore system stack pointer.
	move $ra, $t3 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate successfully.
	add_poly_terminate:
	lw $t4, 0($t2) # $t4 contains first term of destination.
	beqz $t4, add_poly_null # If no terms exist in destination, jump.
	li $v0, 1 # Return 1.
	addi $sp, $sp, 16 # Restore system stack pointer.
	move $ra, $t3 # Restore original return address.
	jr $ra # Return to caller.
	
mult_poly:
	li $v0, 1
	jr $ra

save_temps: # Helper function, saves all $t registers to system stack.
	addi $sp, $sp, -40
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t4, 16($sp)
	sw $t5, 20($sp)
	sw $t6, 24($sp)
	sw $t7, 28($sp)
	sw $t8, 32($sp)
	sw $t9, 36($sp)
	jr $ra
	
load_temps: # Helper function, loads all $t registers from system stack.
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t4, 16($sp)
	lw $t5, 20($sp)
	lw $t6, 24($sp)
	lw $t7, 28($sp)
	lw $t8, 32($sp)
	lw $t9, 36($sp)
	addi $sp, $sp, 40
	jr $ra
