############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
.text:

str_len: # Requires $t0. Modifies $a0.
	### Initialiations. ###
	li $t0, 0 # $t0 stores next character.
	li $v0, 0 # $v0 stores character count.
	
	### Calculate length of $a0. ###
	str_len_loop:
		lbu $t0, 0($a0) # Load next characater into $t0.
		beqz $t0, str_len_terminate # NUL reached, string is finished. Jump.
		addi $v0, $v0, 1 # Increment character count by 1.
		addi $a0, $a0, 1 # Increment string address pointer by 1.
		j str_len_loop # Parse next character.
	
	### Terminate. ###
	str_len_terminate:
	jr $ra # Return to caller.
	
str_equals: # Requires $t0 - $t2. Modifies $a0, $a1.
	### Initializations. ###
	li $t0, 0 # $t0 stores $a0 character.
	li $t1, 0 # $t1 stores $a1 character.
	li $t2, 0 # $t2 is a function temporary.
	
	### Compare each character. ###
	str_equals_loop:
		lbu $t0, 0($a0) # Load next character from $a0 into $t0.
		lbu $t1, 0($a1) # Load next character from $a1 into $t1.
		add $t2, $t1, $t0 # $t2 is 0 if and only if both $t1 and $t0 are NUL.
		beqz $t2, str_equals_1 # End of string reached for both arguments, jump.
		bne $t0, $t1, str_equals_0 # If characters are different, jump.
		addi $a0, $a0, 1 # Increment $a0 string address pointer by 1.
		addi $a1, $a1, 1 # Increment $a1 string address pointer by 1.
		j str_equals_loop # Parse next character.
	
	# Terminate with $v0 = 0.
	str_equals_0:
	li $v0, 0 # Return 0 (not equal).
	jr $ra # Return to caller.
	
	# Terminate with $v0 = 1.
	str_equals_1:
	li $v0, 1 # Return 1 (equal).
	jr $ra # Return to caller.
	
str_cpy: # Requires $t0. Modifies $a0, $a1.
	### Initializations. ###
	li $t0, 0 # $t0 stores next character.
	li $v0, 0 # $v0 stores character count.
	
	### Copy $a0 to $a1. ###
	str_cpy_loop:
		lbu $t0, 0($a0) # Load next character into $t0.
		beqz $t0, str_cpy_terminate # NUL reached, string is finished. Jump.
		sb $t0, 0($a1) # Store character into $a1.
		addi $v0, $v0, 1 # Increment character count by 1.
		addi $a0, $a0, 1 # Increment $a0 string address pointer by 1.
		addi $a1, $a1, 1 # Increment $a1 stirng address pointer by 1.
		j str_cpy_loop # Parse next character.
	
	### Terminate. ###
	str_cpy_terminate:
	li $t0, 0 # Load ASCII NUL into $t0.
	sb $t0, 0($a1) # Store NUL into $a1.
	jr $ra # Return to caller.
	
create_person: # Requires $t0, $t1.
	### Initializations. ###
	li $t0, 0 # $t0 is a function temporary.
	li $t1, 0 # $t1 is a function temporary.
	
	### Check if network is full. If so, terminate with error. ###
	lw $t0, 0($a0) # $t0 contains maximum number of people in this network.
	lw $t1, 16($a0) # $t1 contains current number of people in this network.
	beq $t0, $t1, create_person_error # Network is full, jump.
	
	### Obtain new node address. ###
	lw $t0, 8($a0) # $t0 contains size of each node.
	lw $t1, 16($a0) # $t1 contains current number of nodes in network.
	mul $t0, $t0, $t1 # $t0 contains byte offset for new node address.
	addi $a0, $a0, 36 # Move network pointer to start of node set.
	add $v0, $a0, $t0 # $v0 contains address of new node.
	addi $a0, $a0, -36 # Return network pointer to original address.
	
	### Add new empty person node to network. ###
	addi $t1, $t1, 1 # Increment current number of nodes in network by 1.
	sw $t1, 16($a0) # Store new current number of nodes in network back in network.
	j create_person_terminate # Jump.
	
	### Terminate with error. ###
	create_person_error:
	li $v0, -1 # Return -1.
	jr $ra # Return to caller.
	
	### Terminate successfully. ###
	create_person_terminate:
	jr $ra # Return to caller.
	
is_person_exists: # Requires $t0 - $t2.
	### Initializations. ###
	li $t0, 0 # $t0 stores last possible address for any person in network.
	li $t1, 0 # $t1 is a function temporary.
	li $t2, 0 # $t2 is a function temporary.
	
	### Determine last possible address for any person. ###
	addi $t0, $a0, 36 # Move network address pointer to start of node set.
	blt $a1, $t0, is_person_exists_not_found # Person is out of node set bounds, jump.
	lw $t1, 8($a0) # $t1 contains size of each node.
	lw $t2, 16($a0) # $t2 contains current number of nodes in network.
	mul $t1, $t1, $t2 # $t1 contains offset for number of people in this network.
	add $t0, $t0, $t1 # $t0 contains last possible address for any person in network.
	bge $a1, $t0, is_person_exists_not_found # Person is out of node set bounds, jump.
	j is_person_exists_found # Person is within node set, jump.

	### Terminate with $v0 = 0 (not found). ###
	is_person_exists_not_found:
	li $v0, 0 # Return 0 (not found).
	jr $ra # Return to caller.
	
	### Terminate with $v0 = 1 (found). ###
	is_person_exists_found:
	li $v0, 1 # Return 1 (found).
	jr $ra # Return to caller.
	
is_person_name_exists: # Requires $t0 - $t4. Modifies $a0.
	### Initializations. ###
	move $t0, $a0 # $t0 contains base address of network.
	addi $t1, $t0, 36 # $t1 contains modifiable address of network starting at node set.
	li $t2, 1 # $t2 contains person counter (never exceeds total current nodes).
	li $t3, 0 # $t3 is a function temporary.
	move $t4, $ra # $t4 contains original return address.
	move $t5, $a1 # $t5 contains base address of name.
	
	### Loop through network searching for name. ###
	is_person_name_exists_loop:
		lw $t3, 16($t0) # $t3 contains current node amount.
		bgt $t2, $t3, is_person_name_exists_not_found # If entire network looped through, person was not found. Jump.
		move $a0, $t1 # $a0 contains starting address of name in network to compare.
		move $a1, $t5 # $a1 contains starting address of name from parameter to compare.
		jal save_temps
		jal str_equals # $v0 contains whether this name in network matches what we are searching for.
		jal load_temps
		bnez $v0, is_person_name_exists_found # $v0 = 1, match was found. Jump.
		addi $t2, $t2, 1 # Increment person counter by 1.
		lw $t3, 8($t0) # $t3 contains size of each node.
		add $t1, $t1, $t3 # Move $t1 pointer to next person in network.
		j is_person_name_exists_loop # Compare next person.
	
	### Terminate with failure ($v0 = 0). ###
	is_person_name_exists_not_found:
	li $v0, 0 # Return 0 (not found).
	move $ra, $t4 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate with success ($v0 = 1, $v1 = reference). ###
	is_person_name_exists_found:
	li $v0, 1 # Return 1 (found).
	move $v1, $t1 # Return reference to this person.
	move $ra, $t4 # Restore original return address.
	jr $ra # Return to caller.
	
add_person_property: # Requires $t0 - $t3. Modifies $a0, $a1.
	### Initializations. ###
	move $t0, $a0 # $t0 contains base network address.
	move $t1, $a1 # $t1 contains address of person to modify.
	li $t2, 0 # $t2 is a function temporary.
	move $t3, $ra # $t3 contains original return address.
	
	### Determine if property name is "NAME". ###
	addi $t2, $t0, 24 # $t2 contains starting address of "NAME" property in network.
	move $a0, $t2 # $a0 contains starting address of "NAME" in network for comparison.
	move $a1, $a2 # $a1 contains starting property name.
	jal save_temps
	jal str_equals # $v0 contains string equality.
	jal load_temps
	beqz $v0, add_person_property_con_1 # If property name is not "NAME", jump.
	
	### Determine if this person exists in the network. ###
	move $a0, $t0 # $a0 contains base network address.
	move $a1, $t1 # $a1 contains address of person to modify.
	jal save_temps
	jal is_person_exists # $v0 contains if this person exists in the network.
	jal load_temps
	beqz $v0, add_person_property_con_2 # If person does not exist in network, jump.
	
	### Determine if the name given can fit in network. ###
	move $a0, $a3 # $a0 contains new name.
	jal save_temps
	jal str_len # $v0 contains length of new name.
	jal load_temps
	lw $t2, 8($t0) # $t2 contains maximum node size.
	bge $v0, $t2, add_person_property_con_3 # If new name exceeds maximum length allowed in network, jump.
	
	### Determine if this name is already being used in network. ###
	move $a0, $t0 # $a0 contains base network address.
	move $a1, $a3 # $a1 contains new name.
	jal save_temps
	jal is_person_name_exists # $v0 contains if this name already exists in network.
	jal load_temps
	bnez $v0, add_person_property_con_4 # If this name is already being used in network, jump.
	
	### Copy new name into network. ###
	move $a0, $a3 # $a0 contains new name address.
	move $a1, $t1 # $a1 contains person to modify.
	jal save_temps
	jal str_cpy # Copy new name into person.
	jal load_temps
	
	### Terminate successfully.
	li $v0, 1 # Return 1.
	move $ra, $t3 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate with condition 1. ###
	add_person_property_con_1:
	li $v0, 0 # Return 0.
	move $ra, $t3 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate with condition 2. ###
	add_person_property_con_2:
	li $v0, -1 # Return -1.
	move $ra, $t3 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate with condition 3. ###
	add_person_property_con_3:
	li $v0, -2 # Return -2.
	move $ra, $t3 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate with condition 4. ###
	add_person_property_con_4:
	li $v0, -3 # Return -3.
	move $ra, $t3 # Restore original return address.
	jr $ra # Return to caller.
	
get_person: # Requires $t0. Modifies $a0.
	### Initializations. ###
	move $t0, $ra # $t0 contains original return address.
	
	### Search for person in network. ###
	jal save_temps
	jal is_person_name_exists # $v0 contains if person exists in network.
	jal load_temps
	beqz $v0, get_person_error # This person does not exist in network, jump.
	
	### Terminate successfully. ###
	move $v0, $v1 # Return address of person found.
	move $ra, $t0 # Restore original return address.
	jr $ra # Return to caller.

	### Terminate with $v0 = 0. ###
	get_person_error:
	li $v0, 0 # Return 0.
	move $ra, $t0 # Restore original return address.
	jr $ra # Return to caller.
	
is_relation_exists: # Requires $t0 - $t4. Modifies $a0.
	### Initializations. ###
	lw $t0, 4($a0) # $t0 contains number of edges in network.
	li $t1, 1 # $t1 contains edge counter (never exceeds total current edges).
	li $t2, 0 # $t2 is a function temporary.
	lw $t3, 12($a0) # $t3 contains size of edge (12).
	li $t4, 0 # $t4 is a function temporary.
	
	### Move network pointer to start of edge set. ###
	lw $t4, 0($a0) # $t0 contains maximum number of nodes in network.
	lw $t2, 8($a0) # $t2 contains size of each node.
	mul $t4, $t4, $t2 # $t0 contains offset to reach start of edge set.
	addi $a0, $a0, 36
	add $a0, $a0, $t4 # Move $a0 to start of edge set.

	### Search edge set for a relationship. ###
	is_relation_exists_loop:
		bgt $t1, $t0, is_relation_exists_not_found # If entire network looped through, relationship was not found. Jump.
		lw $t2, 0($a0) # $t2 contains first node of relationship.
		beq $t2, $a1, is_relation_exists_loop_A # Match found in first node connection, jump.
		lw $t2, 4($a0) # $t2 contains second node of relationship.
		beq $t2, $a1, is_relation_exists_loop_B # Match found in second node connection, jump.
		addi $t1, $t1, 1 # Increment edge counter by 1 (match not found).
		add $a0, $a0, $t3 # Increment network pointer to next relationship.
		j is_relation_exists_loop # Parse next edge.
		
		is_relation_exists_loop_A:
		lw $t2, 4($a0) # $t2 contains second node of relationship.
		beq $t2, $a2, is_relation_exists_found # Match found in second node, jump.
		addi $t1, $t1, 1 # Increment edge counter by 1 (match not found).
		add $a0, $a0, $t3 # Increment network pointer to next relationship.
		j is_relation_exists_loop # Parse next edge.
		
		is_relation_exists_loop_B:
		lw $t2, 0($a0) # $t2 contains first node of relationship.
		beq $t2, $a2, is_relation_exists_found # Match found in first node, jump.
		addi $t1, $t1, 1 # Increment edge counter by 1 (match not found).
		add $a0, $a0, $t3 # Increment network pointer to next relationship.
		j is_relation_exists_loop # Parse next edge.

	### Terminate with $v0 = 0. ###
	is_relation_exists_not_found:
	li $v0, 0 # Return 0 (not found).
	jr $ra # Return to caller.
	
	### Terminate with $v0 = 1. ###
	is_relation_exists_found:
	li $v0, 1 # Return 1 (found).
	move $v1, $a0 # Return address of this relationship. // FOR INTERNAL USE ONLY //
	jr $ra # Return to caller.
	
add_relation: # Requires $t0 - $t5. Modifies $a0 - $a2.
	### Initializations. ###
	move $t0, $a0 # $t0 contains network base address.
	move $t1, $a1 # $t1 contains address of person 1.
	move $t2, $a2 # $t2 contains address of person 2.
	li $t3, 0 # $t3 is a function temporary.
	move $t4, $ra # $t4 contains original return address.
	li $t5, 0 # $t5 is a function temporary.
	
	### Determine if both people actually exist in network. ###
	jal save_temps
	jal is_person_exists # $v0 contains if person 1 exists in network.
	jal load_temps
	beqz $v0, add_relation_con_1 # Person 1 does not exist, jump.
	move $a1, $a2 # $a1 contains person 2.
	jal save_temps
	jal is_person_exists # $v0 contains if person 2 exists in network.
	jal load_temps
	beqz $v0, add_relation_con_1 # Person 2 does not exist, jump.
	
	### Determine if network is at edge capacity. ###
	lw $t3, 4($a0) # $t3 contains maximum number of edges in network.
	lw $t5, 20($a0) # $t5 contains currnet number of edges in network.
	beq $t3, $t5, add_relation_con_2 # Network is at edge capacity, jump.
	
	### Determine if this relationship already exists. ###
	move $a1, $t1 # $a1 contains person 1.
	move $a2, $t2 # $a2 contains person 2.
	jal save_temps
	jal is_relation_exists # $v0 contains if this relationship already exists.
	jal load_temps
	bnez $v0, add_relation_con_3 # Relation already exists, jump.
	
	### Check if person 1 and person 2 are the same person. ###
	beq $t1, $t2, add_relation_con_4 # Person 1 and 2 are the same person, jump.
	
	### Move network pointer to correct position. ###
	move $a0, $t0 # $a0 contains base network address.
	lw $t3, 0($t0) # $t3 contains maximum number of nodes in network.
	lw $t5, 8($t0) # $t5 contains size of each node.
	mul $t3, $t3, $t5 # $t3 contains offset to reach start of edge set.
	addi $a0, $a0, 36
	add $a0, $a0, $t3 # Move $a0 to start of edge set.
	lw $t3, 12($t0) # $t3 contains size of edge (12).
	lw $t5, 20($t0) # $t5 contains current number of edges in network.
	mul $t3, $t3, $t5 # $t3 contains offset to reach new relationship in network.
	add $a0, $a0, $t3 # Move $a0 to correct position.
	
	### Add new relationship to network. ###
	sw $t1, 0($a0) # Store person 1 in new relationship.
	sw $t2, 4($a0) # Store person 2 in new relationship.
	lw $t3, 16($t0) # $t3 contains current number of relationships in network.
	addi $t3, $t3, 1 # Increment number of relationships in network by 1.
	sw $t3, 16($t0) # Store new count of relationships back in network.
	
	### Terminate successfully.
	li $v0, 1 # Return 1.
	move $ra, $t4 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate with condition 1. ###
	add_relation_con_1:
	li $v0, 0 # Return 0.
	move $ra, $t4 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate with condition 2. ###
	add_relation_con_2:
	li $v0, -1 # Return -1.
	move $ra, $t4 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate with condition 3. ###
	add_relation_con_3:
	li $v0, -2 # Return -2.
	move $ra, $t4 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate with condition 4. ###
	add_relation_con_4:
	li $v0, -3 # Return -3.
	move $ra, $t4 # Restore original return address.
	jr $ra # Return to caller.
	
add_relation_property: # Requires $t0 - $t7. Modifies $a0, $a1.
	### Initializations. ###
	move $t0, $a0 # $t0 contains network base address.
	move $t1, $a1 # $t1 contains person 1.
	move $t2, $a2 # $t2 contains person 2.
	move $t3, $a3 # $t3 contains property name.
	lw $t4, 0($sp) # $t4 contains property value.
	move $t5, $ra # $t5 contains original return address.
	li $t6, 0 # $t6 is a function temporary.
	li $t7, 0 # $t7 stores address of relationship (if it exists).
	
	### Determine if a relation exists between these two people. ###
	jal save_temps
	jal is_relation_exists # $v0 contains if this relationship exists. $v1 contains address of this relationship.
	jal load_temps
	beqz $v0, add_relation_property_con_1 # Relationship does not exist, jump.
	move $t7, $v1 # $t7 contains address of relationship.
	
	### Determine if property name is "FRIEND". ###
	addi $a0, $t0, 29 # $a0 contains "FRIEND" string in network.
	move $a1, $t3 # $a1 contains property name.
	jal save_temps
	jal str_equals # $v0 contains if both properties are "FRIEND".
	jal load_temps
	beqz $v0, add_relation_property_con_2 # Property is not "FRIEND", jump.
	
	### Determine if property value is less than 0. ###
	bltz $t4, add_relation_property_con_3 # Property value is less than 0, jump.
	
	### Add property value to relationship. ###
	sw $t4, 8($t7) # Store property value into network relationship.
	
	### Terminate successfully. ###
	li $v0, 1 # Return 1.
	move $ra, $t5 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate with condition 1. ###
	add_relation_property_con_1:
	li $v0, 0 # Return 0.
	move $ra, $t5 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate with condition 2. ###
	add_relation_property_con_2:
	li $v0, -1 # Return -1.
	move $ra, $t5 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate with condition 3. ###
	add_relation_property_con_3:
	li $v0, -2 # Return -2.
	move $ra, $t5 # Restore original return address.
	jr $ra # Return to caller.
	
is_friend_of_friend:
	### Initializations. ###
	move $t0, $a0 # $t0 contains network base address.
	move $t1, $a1 # $t1 contains first name.
	move $t2, $a2 # $t2 contains second name.
	move $t3, $ra # $t3 contains original return address.
	li $t4, 0 # $t4 is a function temporary.
	
	### Determine if both people exist in network. ###
	jal save_temps
	jal is_person_name_exists # $v0 contains if person 1 exists in network.
	jal load_temps
	beqz $v0, is_friend_of_friend_error # Person 1 does not exist in network, jump.
	move $a0, $t0 # $a0 contains network base address.
	move $a1, $t2 # $a1 contains second name.
	jal save_temps
	jal is_person_name_exists # $v0 contains if person 2 exists in network.
	jal load_temps
	beqz $v0, is_friend_of_friend_error # Person 2 does not exist in network, jump.
	
	### Determine if a direct friendship between these two people exists. ###
	move $a0, $t0 # $a0 contains network base address.
	move $a1, $t1 # $a1 contains first name.
	jal save_temps
	jal get_person # $v0 contains address of person in network.
	jal load_temps
	move $t4, $v0 # $t4 contains address of first person in network.
	move $a0, $t0 # $a0 contains network base address.
	move $a1, $t2 # $a1 contains second name.
	jal save_temps
	jal get_person # $v0 contains address of person in network.
	jal load_temps
	move $a1, $v0 # $a1 contains second person.
	move $a2, $t4 # $a2 contains first person.
	move $a0, $t0 # $a0 contains network base address.
	jal save_temps
	jal is_relation_exists # $v0 contains if this relationship exists. $v1 contains relationship address.
	jal load_temps
	beqz $v0, is_friend_of_friend_main # If no relationship exists, jump.
	lw $t4, 8($v1) # $t4 contains friendship status.
	bnez $t4, is_friend_of_friend_false # Friendship already exists, jump.
	
	### Determine if these two people are friend of friend to each other. ###
	is_friend_of_friend_main:
	move $a0, $t1 # $a0 contains first name.
	move $a1, $t2 # $a1 contains second name.
	jal save_temps
	jal str_equals # $v0 contains if this is the same person.
	jal load_temps
	bnez $v0, is_friend_of_friend_false # A person cannot be friend of friend to themselves, jump.
	
	li $v0, 1 # Return 1.
	move $ra, $t3 # Restore original return address.
	jr $ra # Return to caller.
	
	### Terminate with $v0 = 0. ###
	is_friend_of_friend_false:
	li $v0, 0 # Return 0.
	move $ra, $t3 # Restore original return address.
	jr $ra # Return to caller.

	### Terminate with $v0 = -1. ###
	is_friend_of_friend_error:
	li $v0, -1 # Return -1.
	move $ra, $t3 # Restore original return address.
	jr $ra # Return to caller.

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
