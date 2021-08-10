# Patrick Fan
# pafan
# 112768858

############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################

.text
load_game: # Requires $t0 - $t8.
	### Initializations. ###
	move $t0, $a0 # $t0 now contains GameState base address.
	move $t1, $sp # $t1 now contains base system stack pointer.
	li $t2, 0 # $t2 now contains line number.
	li $t3, 0 # $t3 is a function temporary.
	li $t4, 0 # $t4 now contains total pocket count (precondition: $t4 <= 98)
	li $t5, 0 # $t5 now contains character counter.
	li $t6, 0 # $t6 now contains stone count (precondition: $t6 <= 99).
	li $t7, 0 # $t7 now contains endline flag (0 = false, 1 = true).
	li $t8, 0 # $t8 is a function temporary.
	
	### Open the file for reading. ###
	li $v0, 13 # Load file syscall opcode.
	move $a0, $a1 # Load filename for syscall.
	li $a1, 0 # Load read-only flag for syscall.
	syscall # Load the file. $v0 now contains file descriptor.
	bltz $v0, load_game_open_error # If an error was encountered, jump.
	
	### Read character and add to system stack, skip if necessary. ###
	move $a0, $v0 # Load file descriptor for syscall.
	li $a2, 1 # Load number of characters to read for syscall (1).
	load_game_next_char:
	li $v0, 14 # Read file syscall opcode.
	addi, $sp, $sp, -4 # Allocate system stack to read character.
	sw $0, 0($sp) # Clear current system stack segment.
	move $a1, $sp # Load input address for syscall.
	syscall # Read one character.
	beqz $v0, load_game_open_error # If end of file, jump (this should not happen).
	li $t3, 13
	lbu $t8, 0($sp)
	beq $t8, $t3, load_game_endline # If character is 'CR', parse endline and skip this character.
	li $t3, 10
	lbu $t8, 0($sp)
	beq $t8, $t3, load_game_endline # If character is 'LF', parse endline and skip this character.
	li $t7, 0 # Set endline flag to false.
	addi $t5, $t5, 1 # Increment character counter.
	j load_game_next_char # Load the next character.

	### Parse this line. ###
	load_game_endline:
	addi $sp, $sp, 4 # Discard current character.
	bnez $t7, load_game_endline_resume # If endline was already reached (endline flag = 1), skip incrementing.
	addi $t2, $t2, 1 # Increment line number.
	li $t7, 1 # Set endline flag to true.
	
	li $t3, 1
	beq $t2, $t3, load_game_mancala_count # If line number is 1, add top mancala stone count to total and append to GameState.
	li $t3, 2
	beq $t2, $t3, load_game_mancala_count # If line number is 2, add bot mancala stone count to total and append to GameState.
	li $t3, 3
	beq $t2, $t3, load_game_pocket_count # If line number is 3, add top and bot pocket count to GameState.
	li $t3, 4
	beq $t2, $t3, load_game_pockets # If line number is 4, add top pockets to game_board in GameState.
	li $t3, 5
	beq $t2, $t3, load_game_pockets # If line number if 5, add bot pockets to game_board in GameState.
	
	load_game_endline_resume:
	move $sp, $t1 # Clear the system stack.
	j load_game_next_char # Read the next character.
	
	# Increment stone count by number in mancala and append to GameState (as integer) and game_board (as string).
	load_game_mancala_count:
		li $t3, 4
		mul $t5, $t5, $t3 # $t5 now contains the character count in bytes.
		addi $sp, $sp, -4
		add $sp, $sp, $t5 # $sp is now at beginning address of system stack for this line (as characters).
		li $t8, 0 # $t8 now contains integer count of mancala stones.
		load_game_mancala_count_loop:
		li $t3, 10
		mul $t8, $t8, $t3 # Multiply $t8 by 10 (to make way for next digit).
		lbu $t3, 0($sp) # $t3 now contains the character from the system stack.
		addi $t3, $t3, -48 # Convert $t3 from character to equivalent integer.
		add $t8, $t8, $t3 # Add the new digit to $t8.
		addi $t5, $t5, -4 # Decrement the character byte count by 4 (1 character).
		addi $sp, $sp, -4 # Decrement the address of mancala stone count to next character.
		bnez $t5, load_game_mancala_count_loop # If there are more characters left (character byte count is not zero), loop again.
		add $t6, $t6, $t8 # Add the number of stones in this mancala to total stone count.
		li $t3, 1
		beq $t2, $t3, load_game_mancala_count_top # This is the bot mancala.
			sb $t8, 0($t0) # Store number of stones in bot mancala in GameState (as integer, 1 byte).
			j load_game_endline_resume # Return to parsing characters.
		load_game_mancala_count_top: # This is the top mancala.
			sb $t8, 1($t0) # Store number of stones in top mancala in GameState (as integer, 1 byte).
			j load_game_endline_resume # Return to parsing characters.
			
	# Append pocket count (as integer) to GameState, as well as fill in moves executed and player turn.
	load_game_pocket_count:
		li $t3, 4
		mul $t5, $t5, $t3 # $t5 now contains the character count in bytes.
		addi $sp, $sp, -4
		add $sp, $sp, $t5 # $sp is now at beginning address of system stack for this line (as characters).
		load_game_pocket_count_loop:
		li $t3, 10
		mul $t4, $t4, $t3 # Multiply $t4 by 10 (to make way for next digit).
		lbu $t3, 0($sp) # $t3 now contains the character from the system stack.
		addi $t3, $t3, -48 # Convert $t3 from character to equivalent integer.
		add $t4, $t4, $t3 # Add the new digit to $t4.
		addi $t5, $t5, -4 # Decrement the character byte count by 4 (1 character).
		addi $sp, $sp, -4 # Decrement the address of pocket count to next character.
		bnez $t5, load_game_pocket_count_loop # If there are more characters left (character byte count is not zero), loop again.
		sb $t4, 2($t0) # Store bot pocket count in GameState.
		sb $t4, 3($t0) # Store top pocket count in GameState.
		li $t3, 2
		mul $t4, $t4, $t3 # $t4 now contains total number of pockets in this game (mancalas do not count as pockets).
		sb $0, 4($t0) # Store number of moves executed (0) in GameState.
		li $t3, 66
		sb $t3, 5($t0) # Store player turn (Player 1 = 'B') in GameState.
		j load_game_endline_resume # Return to parsing characters.
	
	# Append top pockets (as characters) to game_board, and increment total stone count.
	load_game_pockets:
		li $t3, 4
		mul $t5, $t5, $t3 # $t5 now contains the character count in bytes.
		addi $sp, $sp, -4
		add $sp, $sp, $t5 # $sp is now at beginning address of system stack for this line (as characters).
		li $t3, 5
		beq $t2, $t3, load_game_pockets_loop # If line number is 5, these are the bottom pockets. GameState pointer should already be in the correct position.
		addi $t0, $t0, 8 # Move GameState pointer to correct position in game_board (for pocket parsing).
		load_game_pockets_loop:
		li $t8, 0 # $t8 now contains integer count of number of stones in this pocket.
		lbu $t3, 0($sp) # $t3 now contains the first character (of 2) from the system stack for this pocket.
		sb $t3, 0($t0) # Store character in game_board.
		addi $t0, $t0, 1 # Move GameState pointer to accept next character.
		addi $t3, $t3, -48 # Convert $t3 from character to equivalent integer.
		add $t8, $t8, $t3 # Add the new digit to $t8.
		addi $t5, $t5, -4 # Decrement the character byte count by 4 (1 character).
		addi $sp, $sp, -4 # Decrement the address of pockets to next character.
		li $t3, 10
		mul $t8, $t8, $t3 # Multiply $t8 by 10 (to make way for next digit).
		lbu $t3, 0($sp) # $t3 now contains the second character (of 2) from the system stack for this pocket.
		sb $t3, 0($t0) # Store character in game_board.
		addi $t0, $t0, 1 # Move GameState pointer to accept next character.
		addi $t3, $t3, -48 # Convert $t3 from character to equivalent integer.
		add $t8, $t8, $t3 # Add the new digit to $t8.
		addi $t5, $t5, -4 # Decrement the character byte count by 4 (1 character).
		addi $sp, $sp, -4 # Decrement the address of pockets to next character.
		add $t6, $t6, $t8 # Add the number of stones in this pocket to total stone count.
		bnez $t5, load_game_pockets_loop # If there are more characters left (character byte count is not zero), loop again.
		li $t3, 5
		beq $t2, $t3, load_game_pockets_final # If line number if 4, parse the next line.
			j load_game_endline_resume
		load_game_pockets_final: # If line number is 5, perform final parsing.
			li $v0, 16
			syscall # Close the file.
			li $t3, 99
			bgt $t6, $t3, load_game_pockets_final_stones_invalid # Number of stones valid (<= 99). If not, jump.
				li $v0, 1
				j load_game_pockets_final_stones_continue
			load_game_pockets_final_stones_invalid: # Number of stones invalid (> 99).
				li $v0, 0
			load_game_pockets_final_stones_continue:
			li $t3, 98
			bgt $t4, $t3, load_game_pockets_final_pockets_invalid # Number of pockets valid (<= 98). If not, jump.
				move $v1, $t4
				j load_game_pockets_final_pockets_continue
			load_game_pockets_final_pockets_invalid: # Number of pockets invalid (> 98).
				li $v1, 0
			load_game_pockets_final_pockets_continue: # $t6 is now free.
			li $t3, 2
			mul $t4, $t4, $t3 # $t4 now contains the number of bytes (characters) for all pockets.
			sub $t0, $t0, $t4
			addi $t0, $t0, -7 # Move GameState pointer back to beginning of top mancala.
			
			lb $t8, 0($t0) # $t8 now contains number of stones in top mancala (as integer).
			li $t3, 10
			div $t8, $t3
			mflo $t8 # Divide $t8 by 10.
			mfhi $t3 # $t3 now contains least significant digit.
			addi $t3, $t3, 48 # Convert integer to ASCII.
			sb $t3, 6($t0) # Place character in correct spot in game_board.
			li $t3, 10
			div $t8, $t3 # Divide $t8 by 10.
			mfhi $t3 # $t3 now contains least significant digit.
			addi $t3, $t3, 48 # Convert integer to ASCII.
			sb $t3, 5($t0) # Place character in correct spot in game_board.
			
			lb $t8, -1($t0) # $t8 now contains number of stones in bot mancala (as integer).
			li $t3, 10
			div $t8, $t3
			mflo $t8 # Divide $t8 by 10.
			mfhi $t3 # $t3 now contains least significant digit.
			addi $t3, $t3, 48 # Convert integer to ASCII.
			addi $t0, $t0, 6
			add $t0, $t0, $t4 # Move GameState pointer to bot mancala position.
			sb $t3, 2($t0) # Place character in correct spot in game_board.
			li $t3, 10
			div $t8, $t3 # Divide $t8 by 10.
			mfhi $t3 # $t3 now contains least significant digit.
			addi $t3, $t3, 48 # Convert integer to ASCII.
			sb $t3, 1($t0) # Place character in correct spot in game_board.
			j load_game_terminate
		
	# If an error was encountered while opening the file, terminate.
	load_game_open_error:
		li $v0, -1
		li $v1, -1
		j load_game_terminate
	
	### Terminate. ###
	load_game_terminate:
	move $sp, $t1 # Clear the system stack.
	jr $ra # Return to caller.
	
get_pocket: # Requires $t0 - $t3
	### Initializations. ###
	li $t0, 0 # $t0 is a function temporary.
	li $t1, 0 # $t1 will contain number of pockets for player.
	li $t2, 0 # $t2 is a function temporary.
	li $t3, 0 # $t3 is a function temporary.
	
	### Get number of stones in requested pocket. ###
	bltz $a2, get_pocket_error # Distance is negative, jump.
	li $t0, 84
	bne $a1, $t0, get_pocket_B # Player is 'T'. If not, jump.
		lb $t1, 2($a0) # $t1 now contains number of pockets for player.
		addi $t0, $t1, -1 # $t0 now contains maximum distance possible.
		bgt $a2, $t0, get_pocket_error # This offset is not possible, jump.
		addi $a0, $a0, 8 # Move GameState pointer to correct starting position.
		li $t0, 2
		mul $t0, $a2, $t0 # $t0 now contains number of bytes for offset.
		add $a0, $a0, $t0 # Move GameState pointer to correct pocket.
		lbu $t2, 0($a0) # $t2 now contains first (of two) characters.
		addi $t2, $t2, -48 # Convert ASCII to integer.
		li $t0, 10
		mul $t2, $t2, $t0 # Multiply $t2 by 10.
		add $t3, $t3, $t2
		lbu $t2, 1($a0) # $t2 now contains second (of two) characters.
		addi $t2, $t2, -48 # Convert ASCII to integer.
		add $v0, $t3, $t2 # $v0 now contains numerical number of stones in this pocket.
		j get_pocket_terminate
	get_pocket_B:
	li $t0, 66
	bne $a1, $t0, get_pocket_error # Player is 'B'. If not, invalid argument, jump.
		lb $t1, 3($a0) # $t1 now contains number of pockets for player.
		addi $t0, $t1, -1 # $t0 now contains maximum distance possible.
		bgt $a2, $t0, get_pocket_error # This offset is not possible, jump.
		li $t0, 4
		mul $t1, $t1, $t0 # $t1 now contains number of bytes to skip.
		addi $a0, $a0, 6
		add $a0, $a0, $t1 # Move GameState pointer to correct starting position.
		li $t0, -2
		mul $t0, $a2, $t0 # $t0 now contains number of bytes for offset.
		add $a0, $a0, $t0 # Move GameState pointer to correct pocket.
		lbu $t2, 0($a0) # $t2 now contains first (of two) characters.
		addi $t2, $t2, -48 # Convert ASCII to integer.
		li $t0, 10
		mul $t2, $t2, $t0 # Multiply $t2 by 10.
		add $t3, $t3, $t2
		lbu $t2, 1($a0) # $t2 now contains second (of two) characters.
		addi $t2, $t2, -48 # Convert ASCII to integer.
		add $v0, $t3, $t2 # $v0 now contains numerical number of stones in this pocket.
		j get_pocket_terminate
	
	# If an error was encountered, terminate.
	get_pocket_error:
		li $v0, -1
		j get_pocket_terminate
	
	### Terminate. ###
	get_pocket_terminate:
	jr $ra # Return to caller.
	
set_pocket: # Requires $t0 - $t4.
	### Initializations. ###
	li $t0, 0 # $t0 is a function temporary.
	li $t1, 0 # $t1 will contain first (of 2) characters from $a3.
	li $t2, 0 # $t2 will contain second (of 2) characters from $a3.
	li $t3, 0 # $t3 will contain number of pockets for player.
	li $t4, 0 # $t4 will contain original size parameter.
	
	### Convert integer in $a3 to characters. ###
	move $t4, $a3 # $t4 now contains original size parameter.
	li $t0, 10
	div $a3, $t0
	mflo $a3
	mfhi $t2 
	addi $t2, $t2, 48 # $t2 now contains least significant digit in ASCII.
	move $t1, $a3
	addi $t1, $t1, 48 # $t1 now contains most significant digit in ASCII.
	
	### Set pocket. ###
	li $t0, 84
	bne $a1, $t0, set_pocket_B # Player is 'T'. If not, jump.
		bltz $t4, set_pocket_out_of_range # Number of stones to set < 0, jump.
		li $t0, 99
		bgt $t4, $t0, set_pocket_out_of_range # Numver of stones to set > 99, jump.
		lbu $t3, 3($a0) # $t1 now contains number of pockets for player.
		addi $t0, $t3, -1 # $t0 now contains maximum distance possible.
		bgt $a2, $t0, set_pocket_invalid # This offset is not possible, jump.
		addi $a0, $a0, 8 # Move GameState pointer to correct starting position.
		li $t0, 2
		mul $t0, $a2, $t0 # $t0 now contains number of bytes for offset.
		add $a0, $a0, $t0 # Move GameState pointer to correct pocket.
		sb $t2, 1($a0) # Store first character into game_board.
		sb $t1, 0($a0) # Store second character into game_board.
		move $v0, $t4 # Return size.
		j set_pocket_terminate # Terminate.
	set_pocket_B:
	li $t0, 66
	bne $a1, $t0, set_pocket_invalid # Player is 'B'. If not, invalid argument, jump.
		bltz $a3, set_pocket_out_of_range # Number of stones to set < 0, jump.
		li $t0, 99
		bgt $a3, $t0, set_pocket_out_of_range # Numver of stones to set > 99, jump.
		lbu $t3, 2($a0) # $t3 now contains number of pockets for player.
		addi $t0, $t3, -1 # $t0 now contains maximum distance possible.
		bgt $a2, $t0, set_pocket_invalid # This offset is not possible, jump.
		li $t0, 4
		mul $t3, $t3, $t0 # $t3 now contains number of bytes to skip.
		addi $a0, $a0, 6
		add $a0, $a0, $t3 # Move GameState pointer to correct starting position.
		li $t0, -2
		mul $t0, $a2, $t0 # $t0 now contains number of bytes for offset.
		add $a0, $a0, $t0 # Move GameState pointer to correct pocket.
		sb $t2, 1($a0) # Store first character into game_board.
		sb $t1, 0($a0) # Store second character into game_board
		move $v0, $t4 # Return size.
		j set_pocket_terminate # Terminate.
	
	# If player or distance is invalid, terminate.
	set_pocket_invalid:
	li $v0, -1
	j set_pocket_terminate
	
	# If number of stones to set is beyond valid range [0 - 99], terminate.
	set_pocket_out_of_range:	
	li $v0, -2
	j set_pocket_terminate
	
	### Terminate. ###
	set_pocket_terminate:
	jr $ra # Return to caller.
	
collect_stones: # Requires $t0 - $t5.
	### Initializations. ###
	li $t0, 0 # $t0 is a function temporary.
	li $t1, 0 # $t1 is a function temporary.
	li $t2, 0 # $t2 will contain first (of 2) characters from $a2.
	li $t3, 0 # $t3 will contain second (of 2) characters from $a2.
	move $t4, $a2 # $t4 now contains original stones parameter.
	li $t5, 0 # $t5 will contain resulting stone count.
	
	### Add stones to designated mancala. ###
	li $t0, 84
	bne $a1, $t0, collect_stones_B # Player is 'T'. If not, jump.
		bltz $t4, collect_stones_negative # If number of stones to add is negative, jump.
		lbu $t0, 1($a0)
		add $t0, $t0, $a2
		sb $t0, 1($a0)
		move $t5, $t0
		# Convert integer in $t5 to characters.
		li $t0, 10
		div $t5, $t0
		mflo $t5 # Divide $t5 by 10.
		mfhi $t3 # $t3 now contains least significant digit.
		addi $t3, $t3, 48 # $t3 now contains least significant digit in ASCII.
		move $t2, $t5
		addi $t2, $t2, 48 # $t2 now contains most significant digit in ASCII.
		sb $t3, 7($a0) # Store first character into game_board.
		sb $t2, 6($a0) # Store second character into game_board.
		move $v0, $t4 # Return stones.
		j collect_stones_terminate
	collect_stones_B:
	li $t0, 66
	bne $a1, $t0, collect_stones_invalid # Player is 'B'. If not, invalid argument, jump.
		bltz $t4, collect_stones_negative # If number of stones to add is negative, jump.
		lbu $t0, 0($a0)
		add $t0, $t0, $a2
		sb $t0, 0($a0)
		move $t5, $t0
		# Convert integer in $t5 to characters.
		li $t0, 10
		div $t5, $t0
		mflo $t5 # Divide $t5 by 10.
		mfhi $t3 # $t3 now contains least significant digit.
		addi $t3, $t3, 48 # $t3 now contains least significant digit in ASCII.
		move $t2, $t5
		addi $t2, $t2, 48 # $t2 now contains most significant digit in ASCII.
		lbu $t0, 2($a0) # $t0 now contains number of pockets per row.
		li $t1, 4
		mul $t0, $t0, $t1 # $t0 now contains number of bytes to skip.
		addi $a0, $a0, 8
		add $a0, $a0, $t0 # Move GameState pointer to correct position.
		sb $t3, 1($a0) # Store first character into game_board.
		sb $t2, 0($a0) # Store second character into game_board.
		move $v0, $t4 # Return stones.
		j collect_stones_terminate

	# If player is invalid, terminate.
	collect_stones_invalid:
	li $v0, -1
	j collect_stones_terminate
	
	# If number of stones to add is negative, terminate.
	collect_stones_negative:
	li $v0, -2
	j collect_stones_terminate

	### Terminate. ###
	collect_stones_terminate:
	jr $ra # Return to caller.
	
verify_move:
	### Initializations. ###
	li $t0, 0 # $t0 is a function temporary.
	lbu $t1, 5($a0) # $t1 now contains player turn.
	move $t2, $ra # $t2 now contains original return address.
	move $t3, $a1 # $t3 now contains original origin_pocket parameter.
	move $t4, $a2 # $t4 now contains original distance parameter.
	
	bltz $t3, verify_move_size # If origin_pocket is negative, jump.
	
	### If distance = 99, swap player turn. ###
	li $t0, 99
	beq $a2, $t0, verify_move_swap
	
	### Verify if this move is legal. ###
	li $t0, 84
	bne $t1, $t0, verify_move_B # Player is 'T'. If not, jump.
		lbu $t0, 3($a0) # $t0 now contains number of pockets for this player.
		bgt $t3, $t0, verify_move_size # If origin_pocket exceeds number of pockets on this row, jump.
		move $a1, $t1
		move $a2, $t3
		jal save_temps
		jal get_pocket # $v0 now contains number of stones in this pocket.
		jal load_temps
		beqz $v0, verify_move_zero # If pocket has 0 stones, jump.
		bne $t4, $v0, verify_move_unequal # If distance does not equal number of stones in pocket, illegal move, jump.
		beqz $t4, verify_move_unequal # If distance is 0, jump.
		li $v0, 1
		j verify_move_terminate
	verify_move_B: # Player is 'B'.
		lbu $t0, 2($a0) # $t0 now contains number of pockets for this player.
		bgt $t3, $t0, verify_move_size # If origin_pocket exceeds number of pockets on this row, jump.
		move $a1, $t1
		move $a2, $t3
		jal save_temps
		jal get_pocket # $v0 now contains number of stones in this pocket.
		jal load_temps
		beqz $v0, verify_move_zero # If pocket has 0 stones, jump.
		bne $t4, $v0, verify_move_unequal # If distance does not equal number of stones in pocket, illegal move, jump.
		beqz $t4, verify_move_unequal # If distance is 0, jump.
		li $v0, 1
		j verify_move_terminate
		
	# Swap player turn.
	verify_move_swap:
		li $t0, 84
		bne $t1, $t0, verify_move_swap_B # Player is 'T'. If not, jump.
			li $t0, 66 # ASCII 'B'.
			sb $t0, 5($a0)
			li $v0, 2
			# Increment turn counter by 1.
			lbu $t0, 4($a0)
			addi $t0, $t0, 1
			sb $t0, 4($a0)
			j verify_move_terminate
		verify_move_swap_B: # Player is 'B'.
			li $t0, 84 # ASCII 'T'.
			sb $t0, 5($a0)
			li $v0, 2
			# Increment turn counter by 1.
			lbu $t0, 4($a0)
			addi $t0, $t0, 1
			sb $t0, 4($a0)
			j verify_move_terminate

	# origin_pocket is invalid for this row size, terminate.
	verify_move_size:
	li $v0, -1
	j verify_move_terminate
	
	# origin_pocket has 0 stones, terminte.
	verify_move_zero:
	li $v0, 0
	j verify_move_terminate
	
	# Illegal move, terminate.
	verify_move_unequal:
	li $v0, -2
	j verify_move_terminate

	### Terminate. ###
	verify_move_terminate:
	move $ra, $t2
	jr $ra
	
execute_move: # Requires $t0 - $t8
	### Initializations. ###
	li $t0, 0 # $t0 will contain number of stones left in this move.
	move $t1, $ra # $t1 now contains original return address.
	move $t2, $a1 # $t2 now contains origin_pocket parameter.
	lbu $t3, 2($a0) # $t3 now contains number of pockets per row.
	li $t4, 0 # $t4 is a function temporary.
	lbu $t5, 5($a0) # $t5 now contains player turn.
	li $t6, 0 # $t6 now contains how many stones to add to this player's mancala.
	move $t7, $t5 # $t7 now contains player flag.
	move $t8, $a0 # $t8 now contains original GameState address.
	li $t9, 0 # $t9 will contain number of stones in last pocket.
	
	### Determine how many moves this move has to execute (equal to the number of stones in origin_pocket). ###
	move $a1, $t5 # $a1 now contains player turn.
	move $a2, $t2 # $a2 now contains distance.
	jal save_temps
	jal get_pocket # Get number of stones in this pocket.
	jal load_temps
	move $t0, $v0 # $t0 now contains number of stones in this pocket.
	
	### Set number of stones in this pocket to 0. ###
	move $a0, $t8 # $a0 now contains original GameState address.
	li $a3, 0 # $a3 now contains number of stones to set this pocket to (0).
	jal save_temps
	jal set_pocket # Set number of stones in this pocket to 0.
	jal load_temps
	addi $t2, $t2, -1 # Move to next pocket.
	
	### Execute this move, skipping opponent mancala. ###
	execute_move_loop:
	beqz $t0, execute_move_zero # Move is finished.
	bltz $t2, execute_move_loop_mancala # Player mancala reached, jump.
	move $a0, $t8 # $a0 now contains original GameState address.
	move $a1, $t7 # $a1 now contains player flag.
	move $a2, $t2 # $a2 now contains distance.
	jal save_temps
	jal get_pocket # Get number of stones in this pocket.
	jal load_temps
	move $a0, $t8 # $a0 now contains original GameState address.
	addi $a3, $v0, 1 # $a3 now contains new number of stones for this pocket (n + 1).
	move $t9, $a3 # $t9 now contains new nunber of stones for this pocket (n + 1).
	jal save_temps
	jal set_pocket # Increment number of stones in this pocket by 1.
	jal load_temps
	addi $t2, $t2, -1 # Move to next pocket.
	addi $t0, $t0, -1 # Decrement number of stones.
	j execute_move_loop # Parse next stone.
	
	execute_move_loop_mancala:
		bne $t5, $t7, execute_move_loop_mancala_skip # If flag does not agree with player, skip this (opponent) mancala.
		addi $t6, $t6, 1 # Increment number of stones to add to player mancala by 1.
		addi $t0, $t0, -1 # Decrement number of stones.
		execute_move_loop_mancala_skip:
		# Switch the player flag.
		li $t4, 84
		bne $t4, $t7, execute_move_loop_mancala_B # Flag is 'T'. Switch to 'B'. If not, jump.
			li $t7, 66
			addi $t2, $t3, -1 # Reset pocket index counter for bottom row.	
			beqz $t0, execute_move_mancala # Move finished in player mancala, jump.
			j execute_move_loop # Parse next stone.
		execute_move_loop_mancala_B: # Flag is 'B'. Switch to 'T'.
			li $t7, 84
			addi $t2, $t3, -1 # Reset pocket index counter for top row.
			beqz $t0, execute_move_mancala # Move finished in player mancala, jump.
			j execute_move_loop # Parse next stone.
	
	# Move finished in player's respective mancala. Increment turn counter.
	execute_move_mancala:
	lbu $t4, 4($t8) # $t4 now contains turn number.
	addi $t4, $t4, 1 # Increment turn number.
	sb $t4, 4($t8) # Store new turn number in GameState.
	li $v1, 2
	j execute_move_terminate
	
	# Check if last deposit was in player's row and was empty before deposit.
	execute_move_zero:
	# Change player turn.
	move $a0, $t8 # $a0 now contains original GameState address.
	li $a2, 99
	jal save_temps
	jal verify_move
	jal load_temps
	# Fill in $v1.
	li $v1, 0
	bne $t5, $t7, execute_move_terminate # Check if last deposit was in player's row. If not, jump.
	li $t4, 1
	bne $t4, $t9, execute_move_terminate # Check if last pocket was empty before deposit. If not, jump.
	li $v1, 1 # Special conditions fulfilled, $v1 = 1.
	j execute_move_terminate

	### Terminate. ###
	execute_move_terminate:
	# Add all stones accumulated in $t6 to mancala.
	move $a0, $t8 # $a0 now contains original GameState address.
	move $a1, $t5 # $a1 now contains player turn.
	move $a2, $t6 # $a2 now contains amount of stones to increment mancala by.
	jal save_temps
	jal collect_stones # Accumulate respective player's mancala. $v0 now contains number of stones added to player's mancala on this turn.
	jal load_temps
	move $ra, $t1
	jr $ra # Return to caller.
	
steal: # Requires $t0 - $t6.
	### Initializations. ###
	li $t0, 0 # $t0 is a function temporary.
	lbu $t1, 5($a0) # $t1 now contains current player (being stolen from).
	li $t2, 0 # $t2 will contain player stealing.
	move $t3, $ra # $t3 now contains original return address.
	move $t4, $a0 # $t4 now contains original GameState address.
	move $t5, $a1 # $t5 now contains original destination_pocket parameter.
	li $t6, 0 # $t6 now contains number of stones in total being deposited in mancala.
	
	### Determine which player is stealing. ###
	li $t0, 84
	bne $t1, $t0, steal_B # Player is 'T'. If not, jump.
		li $t2, 66 # Player 'B' is stealing.
		j steal_calculate
	steal_B: # Player is 'B'.
		li $t2, 84 # Player 'T' is stealing.
		j steal_calculate
		
	### Calculate how many stones are stolen and deposited into the mancala. Set both pockets to 0. ###
	steal_calculate:
	move $a0, $t4 # $a0 now contains original GameState address.
	move $a1, $t2 # $a1 now contains player that is stealing.
	move $a2, $t5 # $a2 now contains distance.
	jal save_temps
	jal get_pocket # $v0 now contains number of stones in this pocket.
	jal load_temps
	add $t6, $t6, $v0 # Increment $t6 by number of stones in this pocket.
	move $a0, $t4 # $a0 now contains original GameState address.
	li $a3, 0 # $a3 now contains number of stones to set this pocket to (0).
	jal save_temps
	jal set_pocket # This pocket now contains 0 stones.
	jal load_temps
	
	lbu $t0, 2($t4) # $t0 now contains number of pockets per row.
	addi $t0, $t0, -1
	sub $t0, $t0, $t5 # $t0 now contains pocket index to steal from.
	
	move $a0, $t4 # $a0 now contains original GameState address.
	move $a1, $t1 # $a1 now contains player being stolen from.
	move $a2, $t0 # $a2 now contains distance.
	jal save_temps
	jal get_pocket # $v0 now contains number of stones in this pocket.
	jal load_temps
	add $t6, $t6, $v0 # Increment $t6 by number of stones in this pocket.
	move $a0, $t4 # $a0 now contains original GameState address.
	li $a3, 0 # $a3 now contains number of stones to set this pocket to (0).
	jal save_temps
	jal set_pocket # This pocket now contains 0 stones.
	jal load_temps
	
	### Increment the mancala. ###
	move $a0, $t4 # $a0 now contains original GameState address.
	move $a1, $t2 # $a1 now contains player that is stealing.
	move $a2, $t6 # $a2 now contains number of stones stolen.
	jal save_temps
	jal collect_stones # Deposit all stolen stones in mancala.
	jal load_temps
		
	### Terminate. ###
	move $v0, $t6 # Return number of stones added to mancala.
	move $ra, $t3 # Restore original return address.
	jr $ra
	
check_row:
	### Initializations. ###
	li $t0, 0 # $t0 now contains how many stones are in top row.
	li $t1, 0 # $t1 now contains how many stones are in bot row.
	lbu $t2, 2($a0) # $t2 now contains number of pockets per row.
	move $t3, $a0 # $t3 now contains original GameState address.
	li $t4, 0 # $t4 is a function temporary.
	li $t5, 0 # $t5 now contains current pocket index.
	move $t6, $ra
	
	addi $t2, $t2, -1 # $t2 now contains maximum index.
	
	### Count total number of stones in top row. ###
	check_row_T_loop:
		move $a0, $t3 # $a0 now contains original GameState address.
		li $a1, 84 # $a1 now contains top player.
		move $a2, $t5 # $a2 now contains current pocket index.
		jal save_temps
		jal get_pocket # $v0 now contains number of stones in this pocket.
		jal load_temps
		add $t0, $t0, $v0 # Increment total number of stones in top row by amount in this pocket.
		addi $t5, $t5, 1 # Increment index.
		bgt $t5, $t2, check_row_B # If all pockets checked, proceed to bot row.
		j check_row_T_loop # If not, parse next pocket.
	
	### Count number of stones in bot row. ###
	check_row_B:
	li $t5, 0 # Reset index.
	check_row_B_loop:
		move $a0, $t3 # $a0 now contains original GameState address.
		li $a1, 66 # $a1 now contains bot player.
		move $a2, $t5 # $a2 now contains current pocket index.
		jal save_temps
		jal get_pocket # $v0 now contains number of stones in this pocket.
		jal load_temps
		add $t1, $t1, $v0 # Increment total number of stones in bot row by amount in this pocket.
		addi $t5, $t5, 1 # Increment index.
		bgt $t5, $t2, check_row_compare # If all pockets checked, proceed to comparison.
		j check_row_B_loop # If not, parse next pocket.
	
	### Check if any row is empty. ###
	check_row_compare:
	beqz $t0, check_row_T_final # If top row is empty, jump.
	beqz $t1, check_row_B_final # If bot row is empty, jump.
	li $v0, 0 # Neither row is empty.
	j check_row_winner_resume
	
	check_row_T_final: # Top row is empty. Deposit all stones in bot row to bot mancala. Clear entire bot row.
		move $a0, $t3 # $a0 now contains original GameState address.
		li $a1, 66 # $a1 now contains bot player.
		move $a2, $t1 # $a2 now contains total number of stones in bot row.
		jal save_temps
		jal collect_stones # Collect all remaining stones in bot to bot mancala.
		jal load_temps
		
		# Clear out the bottom row.
		li $t5, 0 # Reset index.
		check_row_T_final_loop:
			move $a0, $t3 # $a0 now contains original GameState address.
			li $a1, 66 # $a1 now contains bottom player.
			move $a2, $t5 # $a2 now contains current pocket index.
			li $a3, 0 # $a3 now contains number of stones to set pocket to (0).
			jal save_temps
			jal set_pocket # Zero this pocket.
			jal load_temps
			addi $t5, $t5, 1 # Increment index.
			bgt $t5, $t2, check_row_winner # If all pockets zeroed, jump.
			j check_row_T_final_loop # If not, zero next pocket.
	
	check_row_B_final: # Bot row is empty. Deposit all stones in top row to top mancala. Clear entire top row.
		move $a0, $t3 # $a0 now contains original GameState address.
		li $a1, 84 # $a1 now contains top player.
		move $a2, $t0 # $a2 now contains total number of stones in top row.
		jal save_temps
		jal collect_stones # Collect all remaining stones in top to top mancala.
		jal load_temps
		
		# Clear out the top row.
		li $t5, 0 # Reset index.
		check_row_B_final_loop:
			move $a0, $t3 # $a0 now contains original GameState address.
			li $a1, 84 # $a1 now contains top player.
			move $a2, $t5 # $a2 now contains current pocket index.
			li $a3, 0 # $a3 now contains number of stones to set pocket to (0).
			jal save_temps
			jal set_pocket # Zero this pocket.
			jal load_temps
			addi $t5, $t5, 1 # Increment index.
			bgt $t5, $t2, check_row_winner # If all pockets zeroed, jump.
			j check_row_B_final_loop # If not, zero next pocket.
	
	### Determine winner (if there is one). ###
	check_row_winner:
	li $v0, 1
	li $t4, 68
	sb $t4, 5($t3) # Change player to 'D'.
	check_row_winner_resume:
	lbu $t0, 1($t3) # $t0 now contains total number of stones in top player mancala.
	lbu $t1, 0($t3) # $t1 now contains total number of stones in bot player mancala.
	bne $t0, $t1, check_row_winner_T # Stone count equal. If not, jump.
		li $v1, 0 # Game is tied.
		j check_row_terminate
	check_row_winner_T:
	blt $t0, $t1, check_row_winner_B # Top player has more stones. If not, jump.
		li $v1, 2 # Top player (Player 2) wins.
		j check_row_terminate
	check_row_winner_B: # Bot player has more stones.
		li $v1, 1 # Bot player (Player 1) wins.
		j check_row_terminate
	
	### Terminate. ###
	check_row_terminate:
	move $ra, $t6 # Restore original return address.
	jr $ra
	
load_moves:
	### Initializations. ###
	li $t0, 0 # $t0 is a function temporary.
	li $t1, 0 # $t1 now contains line number.
	li $t2, 0 # $t2 is a function temporary.
	li $t3, 0 # $t3 now contains endline flag.
	li $t4, 0 # $t4 is a function temporary.
	move $t5, $sp # $t5 now contains base system stack pointer.
	li $t6, 0 # $t6 now contains number of columns (precondition: 1 <= $t6 <= 99).
	li $t7, 0 # $t7 now contains number of rows (precondition: 1 <= $t7 <= 99).
	li $t8, 0 # $t8 now contains character counter.
	move $t9, $a0 # $t9 now contains original array pointer.
	
	### Open the file for reading. ###
	li $v0, 13 # Load file syscall opcode.
	move $a0, $a1 # Load filename for syscall.
	li $a1, 0 # Load read-only flag for syscall.
	syscall # Load the file. $v0 now contains file descriptor.
	bltz $v0, load_moves_open_error # If an error was encountered, jump.
	
	### Read character and add to system stack, skip if necessary. ###
	move $a0, $v0 # Load file descriptor for syscall.
	li $a2, 1 # Load number of characters to read for syscall (1).
	load_moves_next_char:
	li $v0, 14 # Read file syscall opcode.
	addi, $sp, $sp, -4 # Allocate system stack to read character.
	sw $0, 0($sp) # Clear current system stack segment.
	move $a1, $sp # Load input address for syscall.
	syscall # Read one character.
	beqz $v0, load_moves_open_error # If end of file, jump (this should not happen).
	li $t2, 13
	lbu $t4, 0($sp)
	beq $t4, $t2, load_moves_endline # If character is 'CR', parse endline and skip this character.
	li $t2, 10
	lbu $t4, 0($sp)
	beq $t4, $t2, load_moves_endline # If character is 'LF', parse endline and skip this character.
	li $t3, 0 # Set endline flag to false.
	addi $t8, $t8, 1 # Increment character counter.
	j load_moves_next_char # Load the next character.
	
	### Parse this line. ###
	load_moves_endline:
	addi $sp, $sp, 4 # Discard current character.
	bnez $t3, load_moves_endline_resume # If endline was already reached (endline flag = 1), skip incrementing.
	addi $t1, $t1, 1 # Increment line number.
	li $t3, 1 # Set endline flag to true.
	
	li $t2, 1
	beq $t2, $t1, load_moves_columns # If line number is 1, store number of columns.
	li $t2, 2
	beq $t2, $t1, load_moves_rows # If line number is 2, store number of rows.
	li $t2, 3
	beq $t2, $t1, load_moves_array # If line number is 3, format moves and add to array.
	
	load_moves_endline_resume:
	move $sp, $t5 # Clear the system stack.
	li $t8, 0 # Reset character counter.
	j load_moves_next_char # Read the next character.
	
	# Store number of columns in $t6 (as integer).
	load_moves_columns:
		li $t2, 1
		bne $t8, $t2, load_moves_columns_two_digit # Parse one digit number. If two digit, jump.
			lbu $t2, 0($sp)
			addi $t6, $t2, -48 # $t6 now contains number of columns (as integer).
			j load_moves_endline_resume # Return to parsing characters.
		load_moves_columns_two_digit: # Parse two digit number.
			lbu $t2, 4($sp)
			addi $t2, $t2, -48 # $t2 now contains most significant digit.
			li $t4, 10
			mul $t2, $t2, $t4 # Multiply $t2 by 10.
			lbu $t4, 0($sp)
			addi $t4, $t4, -48 # $t4 now contains least significant digit.
			add $t6, $t2, $t4 # $t6 now contains number of columns (as integer).
			j load_moves_endline_resume # Return to parsing characters.
			
	# Store number of rows in $t7 (as integer).
	load_moves_rows:
		li $t2, 1
		bne $t8, $t2, load_moves_rows_two_digit # Parse one digit number. If two digit, jump.
			lbu $t2, 0($sp)
			addi $t7, $t2, -48 # $t7 now contains number of rows (as integer).
			j load_moves_endline_resume # Return to parsing characters.
		load_moves_rows_two_digit: # Parse two digit number.
			lbu $t2, 4($sp)
			addi $t2, $t2, -48 # $t2 now contains most significant digit.
			li $t4, 10
			mul $t2, $t2, $t4 # Multiply $t2 by 10.
			lbu $t4, 0($sp)
			addi $t4, $t4, -48 # $t4 now contains least significant digit.
			add $t6, $t2, $t4 # $t6 now contains number of rows (as integer).
			j load_moves_endline_resume # Return to parsing characters.
	
	# Format moves and store into array at $a0.
	load_moves_array:
		addi $t7, $t7, -1 # $t7 now contains remaining number of '99' moves to insert.
		li $v0, 0 # $v0 now contains total move counter.
		move $sp, $t5
		addi $sp, $sp, -4 # Return system stack pointer to first character.
		li $t0, 0 # $t0 now contains row move counter.
		
		load_moves_array_loop:
		lbu $t4, 0($sp) # $t4 now contains first character.
		sb $t4, 0($t9) # Store first character of this move into array.
		addi $t9, $t9, 1 # Increment array pointer.
		addi $sp, $sp, -4 # Move system stack pointer to next character in this move.
		lbu $t4, 0($sp) # $t4 now contains second character.
		sb $t4, 0($t9) # Store second character of this move into array.
		addi $t9, $t9, 1 # Increment array pointer.
		addi $sp, $sp, -4 # Move system stack pointer to next move.
		addi $t0, $t0, 1 # Increment row move counter by 1.
		addi $v0, $v0, 1 # Increment total move counter.
		beq $t0, $t6, load_moves_array_loop_row # End of one row in this array reached, jump.
		j load_moves_array_loop # Parse next move.
		
		# Add '99' to end of row if needed.
		load_moves_array_loop_row:
			beqz $t7, load_moves_terminate # Array is finished formatting, jump.
			li $t2, 57 # ASCII '9'.
			sb $t2, 0($t9) # Store first '9' into array.
			sb $t2, 1($t9) # Store second '9' into array.
			addi $t9, $t9, 2 # Increment array pointer.
			addi $t7, $t7, -1 # Decrement remaining '99' counter.
			li $t0, 0 # Reset row move counter.
			addi $v0, $v0, 1 # Increment total move counter.
			j load_moves_array_loop # Parse next move.
	
	# If an error was encountered while opening the file, terminate.
	load_moves_open_error:
		li $v0, -1
		j load_game_terminate
	
	### Terminate. ###
	load_moves_terminate:
	move $sp, $t5 # Clear the system stack.
	jr $ra
	
play_game:
	### Initializations. ###
	move $t0, $a0 # $t0 now contains original moves_filename.
	move $t1, $a1 # $t1 now contains original board_filename.
	move $t2, $a2 # $t2 now contains original GameState pointer.
	move $t3, $a3 # $t3 now contains original moves array pointer.
	lw $t4, 0($sp) # $t4 now contains original number of moves to execute.
	li $t5, 0 # $t5 is a function temporary.
	li $t6, 0 # $t6 is a function temporary.
	li $t7, 0 # $t7 will contain total number of moves left.
	li $t8, 0 # $t8 now contains number of valid moves executed.
	li $t9, 0 # $t9 will contain move (as byte).
	sw $ra, 0($sp) # Store original return address on system stack.
	
	### Load board from file. ###
	move $a0, $t2 # $a0 now contains GameState pointer.
	move $a1, $t1 # $a1 now contains board_filename.
	jal save_temps
	jal load_game # Game loaded from file.
	jal load_temps
	bltz $v0, play_game_error # An error was encountered, jump.
	
	### Load moves from file. ###
	move $a0, $t3 # $a0 now contains moves array pointer.
	move $a1, $t0 # $a1 now contains moves_filename.
	jal save_temps
	jal load_moves # Load all moves from file into moves array.
	jal load_temps
	move $t7, $v0 # $t7 now contains total number of moves left.
	bltz $v0, play_game_error # An error was encountered, jump.
	blez $t4, play_game_zero # If number of moves to execute is less than or equal to zero, check for winner.
	
	### Play out the game. ###
	play_game_loop:
	beqz $t7, play_game_zero # If no more moves left in array, jump.
	beq $t8, $t4, play_game_zero # If max number of moves reached, jump.
	
	# Load next move.
	lbu $t9, 0($t3) # $t9 now contains most significant digit (as character).
	li $t5, 48
	addi $t9, $t9, -48 # Convert from ASCII to integer.
	li $t5, 10
	mul $t9, $t9, $t5 # Multiply $t9 by 10.
	lbu $t5, 1($t3) # $t5 now contains least significant digit (as character).
	addi $t5, $t5, -48 # Convert from ASCII to integer.
	add $t9, $t9, $t5 # $t9 now contains move number (as integer).
	li $t5, 99
	beq $t5, $t9, play_game_loop
	# Get number of stones in this pocket.
	move $a0, $t2 # $a0 now contains GameState pointer.
	lbu $a1, 5($t2) # $a1 now contains current player.
	move $a2, $t9 # $a2 now contains distance.
	jal save_temps
	jal get_pocket # $v0 now contains number of stones in this pocket.
	jal load_temps
	play_game_loop_skip:
	# Validate move.
	move $a0, $t2 # $a0 now contains GameState pointer.
	move $a1, $t9 # $a1 now contains origin_pocket.
	move $a2, $v0 # $a2 now contains distance.
	li $t6, 0 # Reset $t6.
	sub $t6, $a1, $a2 # $t6 now contains destination pocket.
	jal save_temps
	jal verify_move # $v0 now contains status code for this move.
	jal load_temps
	blez $v0, play_game_loop_invalid # Move is invalid, jump.
	li $t5, 2
	beq $t5, $v0, play_game_loop_99 # Move is 99, jump.
	# Execute move.
	move $a0, $t2 # $a0 now contains GameState pointer.
	move $a1, $t9 # $a1 now contains origin_pocket.
	jal save_temps
	jal execute_move # $v1 now contains move status.
	jal load_temps
	li $t5, 1
	beq $v1, $t5, play_game_loop_steal # If steal conditions are met, jump.
	addi $t7, $t7, -1 # Decrement number of moves left in array.
	addi $t3, $t3, 2 # Increment array pointer to next move.
	addi $t8, $t8, 1 # Increment number of valid moves executed.
	j play_game_loop # Parse next move.
	
	# Invalid move.
	play_game_loop_invalid:
		addi $t7, $t7, -1 # Decrement number of moves left in array.
		addi $t3, $t3, 2 # Increment array pointer to next move.
		j play_game_loop # Parse next move.
		
	# Swap move '99'.
	play_game_loop_99:
		addi $t7, $t7, -1 # Decrement number of moves left in array.
		addi $t3, $t3, 2 # Increment array pointer to next move.
		addi $t8, $t8, 1 # Increment number of valid moves executed.
		j play_game_loop # Parse next move.
		
	# Execute steal.
	play_game_loop_steal:
		move $a0, $t2 # $a0 now contains GameState pointer.
		move $a1, $t6 # $a1 now contains destination pocket.
		jal save_temps
		jal steal
		jal load_temps
		addi $t7, $t7, -1 # Decrement number of moves left in array.
		addi $t3, $t3, 2 # Increment array pointer to next move.
		addi $t8, $t8, 1 # Increment number of valid moves executed.
		j play_game_loop # Parse next move.
	
	# Calculate game at face value and terminate.
	play_game_zero:
	move $a0, $t2 # $a0 now contains GameState pointer.
	jal save_temps
	jal check_row # $v1 now contains winner.
	jal load_temps
	move $v0, $v1 # Return winner in $v0.
	move $v1, $t8 # Return number of valid moves executed.
	j play_game_terminate
	
	# An error was encountered opening a file, terminate.
	play_game_error:
	li $v0, -1
	li $v1, -1
	j play_game_terminate
	
	### Terminate. ###
	play_game_terminate:
	lw $ra, 0($sp) # Restore original return address.
	jr $ra
	
print_board: # Requires $t0 - $t3.
	### Initializations. ###
	move $t0, $a0 # $t0 now contains original GameState pointer.
	lbu $t1, 2($t0) # $t1 now contains number of pockets in each row.
	move $t2, $t0 # $t2 now contains a modifiable GameState pointer.
	li $t3, 0 # $t3 is a function temporary.
	
	### Print the board. ###
	li $v0, 11
	# Print top mancala.
	lbu $a0, 6($t0)
	syscall
	lbu $a0, 7($t0)
	syscall
	li $a0, 10
	syscall
	
	# Print bot mancala.
	addi $t2, $t2, 8
	li $t3, 4
	mul $t3, $t3, $t1
	add $t2, $t2, $t3 # Move GameState pointer to correct location.
	lbu $a0, 0($t2)
	syscall
	lbu $a0, 1($t2)
	syscall
	li $a0, 10
	syscall
	
	# Print top row.
	move $t2, $t0 # Reset GameState pointer.
	addi $t2, $t2, 8
	li $t3, 1 # $t3 now contains pocket counter.
	print_board_top_loop:
	bgt $t3, $t1, print_board_top_done # All top pockets printed.
	lbu $a0, 0($t2)
	syscall
	lbu $a0, 1($t2)
	syscall
	addi $t2, $t2, 2 # Increment GameState pointer.
	addi $t3, $t3, 1 # Increment pocket counter.
	j print_board_top_loop
	
	# Print bot row.
	print_board_top_done:
	li $a0, 10
	syscall
	li $t3, 1 # Reset pocket counter.
	print_board_bot_loop:
	bgt $t3, $t1, print_board_terminate # All pockets printed.
	lbu $a0, 0($t2)
	syscall
	lbu $a0, 1($t2)
	syscall
	addi $t2, $t2, 2 # Increment GameState pointer.
	addi $t3, $t3, 1 # Increment pocket counter.
	j print_board_bot_loop
	
	### Terminate. ###
	print_board_terminate:
	li $a0, 10
	syscall
	jr $ra
	
write_board: # Requires $t0 - $t8.
	### Initializations. ###
	li $t0, 0 # $t0 is a function temporary.
	addi $t1, $a0, 500 # $t1 now contains modifiable buffer address.
	move $t2, $a0 # $t2 now contains original GameState address.
	move $t3, $a0 # $t3 now contains modifiable GameState address.
	lbu $t4, 2($t2) # $t4 now contains number of pockets per row.
	li $t5, 0 # $t5 is a function temporary.
	li $t6, 8 # $t6 will contain buffer length.
	move $t7, $t1 # $t7 now contains original buffer address.
	li $t8, 0 # $t8 will contain file descriptor.
	
	### Calculate buffer length. ###
	li $t0, 4
	mul $t0, $t0, $t4
	add $t6, $t6, $t0 # $t6 now contains buffer length.
	
	### Load "output.txt" into buffer. ###
	li $t0, 111
	sb $t0, 0($t1) # ASCII 'o'.
	li $t0, 117
	sb $t0, 1($t1) # ASCII 'u'.
	li $t0, 116
	sb $t0, 2($t1) # ASCII 't'.
	li $t0, 112
	sb $t0, 3($t1) # ASCII 'p'.
	li $t0, 117
	sb $t0, 4($t1) # ASCII 'u'.
	li $t0, 116
	sb $t0, 5($t1) # ASCII 't'.
	li $t0, 46
	sb $t0, 6($t1) # ASCII '.'.
	li $t0, 116
	sb $t0, 7($t1) # ASCII 't'.
	li $t0, 120
	sb $t0, 8($t1) # ASCII 'x'.
	li $t0, 116
	sb $t0, 9($t1) # ASCII 't'.
	li $t0, 0
	sb $t0, 10($t1) # ASCII 'NUL' to terminate string.
	
	### Create file for writing. ###
	li $v0, 13 # Load file syscall opcode.
	move $a0, $t1 # $a0 now contains filename.
	li $a1, 1 # $a1 now contains write flag.
	li $a2, 0 # $a2 now contains mode (ignored).
	syscall # Create output.txt. $v0 now contains file descriptor.
	bltz $v0, write_board_error # An error was encountered, jump.
	move $t8, $v0 # $t8 now contains file descriptor.
	
	### Write board into buffer. ###
	# Write top mancala.
	lbu $t0, 6($t2)
	sb $t0, 0($t1)
	lbu $t0, 7($t2)
	sb $t0, 1($t1)
	li $t0, 10
	sb $t0, 2($t1)
	addi $t1, $t1, 3
	
	# Write bot mancala.
	addi $t3, $t3, 8
	li $t0, 4
	mul $t0, $t4, $t0
	add $t3, $t3, $t0 # Move GameState pointer to correct location.
	lbu $t0, 0($t3)
	sb $t0, 0($t1)
	lbu $t0, 1($t3)
	sb $t0, 1($t1)
	li $t0, 10
	sb $t0, 2($t1)
	addi $t1, $t1, 3
	
	# Write top row.
	move $t3, $t2 # Reset GameState pointer.
	addi $t3, $t3, 8
	li $t0, 1 # $t0 now contains pocket counter.
	write_board_top_loop:
	bgt $t0, $t4, write_board_top_done # All top pockets printed.
	lbu $t5, 0($t3)
	sb $t5, 0($t1)
	lbu $t5, 1($t3)
	sb $t5, 1($t1)
	addi $t0, $t0, 1 # Increment pocket counter.
	addi $t1, $t1, 2 # Increment buffer pointer.
	addi $t3, $t3, 2 # Increment GameState pointer.
	j write_board_top_loop
	
	# Write bot row.
	write_board_top_done:
	li $t0, 10
	sb $t0, 0($t1) # Store newline.
	addi $t1, $t1, 1 # Increment buffer pointer.
	li $t0, 1 # Reset pocket counter.
	write_board_bot_loop:
	bgt $t0, $t4, write_board_write # All pockets printed.
	lbu $t5, 0($t3)
	sb $t5, 0($t1)
	lbu $t5, 1($t3)
	sb $t5, 1($t1)
	addi $t0, $t0, 1 # Increment pocket counter.
	addi $t1, $t1, 2 # Increment buffer pointer.
	addi $t3, $t3, 2 # Increment GameState pointer.
	j write_board_bot_loop

	### Write to file. ###	
	write_board_write:
	li $t0, 10
	sb $t0, 0($t1) # Store newline.
	addi $t1, $t1, 1 # Increment buffer pointer.
	
	li $v0, 15 # Write to file syscall opcode.
	move $a0, $t8 # $a0 now contains file descriptor.
	move $a1, $t7 # $a1 now contains buffer address.
	move $a2, $t6 # $a2 now contains buffer length.
	syscall # Write to file.
	bltz $v0, write_board_error # An error was encountered, jump.
	li $v0, 16
	move $a0, $t8
	syscall # Close the file.
	li $v0, 1
	j write_board_terminate
	
	# An error was encountered, terminate.
	write_board_error:
	li $v0, -1
	j write_board_terminate
	
	### Terminate. ###
	write_board_terminate:
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
	
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
